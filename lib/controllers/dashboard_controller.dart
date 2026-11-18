import 'dart:convert';
import 'dart:math';
import 'package:get/get.dart';
import '../data/models/order.dart';
import '../services/auth_service.dart';
import '../services/paystack_service.dart';
import 'admin_controller.dart';
import 'auth_controller.dart';

/// Controller for the live Customer Dashboard, Paystack Wallet Funding, Orders, Notifications & Settings.
class DashboardController extends GetxController {
  final orders = <Order>[].obs;
  final filteredOrders = <Order>[].obs;
  final transactions = <Transaction>[].obs;
  final notifications = <AppNotification>[].obs;
  final selectedOrderFilter = 'All'.obs;
  final activeTab = 0.obs; // 0: Overview, 1: Orders, 2: Wallet & Invoices, 3: Notifications, 4: Settings

  // Wallet balance (in NGN) & Paystack checkout state
  final walletBalance = 0.0.obs;
  final isFundingWallet = false.obs;
  final fundingError = ''.obs;
  final creditedReferences = <String>[].obs;

  // Profile fields synced from AuthController
  final fullName = ''.obs;
  final email = ''.obs;
  final phone = ''.obs;
  final avatarUrl = ''.obs;
  final isSavingProfile = false.obs;

  // Notification preferences
  final emailNotifications = true.obs;
  final orderUpdates = true.obs;
  final promotionalEmails = false.obs;

  final List<String> orderFilters = [
    'All',
    'Completed',
    'Processing',
    'Pending',
    'Cancelled',
  ];

  @override
  void onInit() {
    super.onInit();
    _syncFromAuth();

    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      ever(auth.userFullName, (_) => _syncFromAuth());
      ever(auth.userEmail, (_) => _syncFromAuth());
      ever(auth.userPhone, (_) => _syncFromAuth());
      ever(auth.userAvatarUrl, (_) => _syncFromAuth());
      ever(auth.isLoggedIn, (bool loggedIn) {
        if (loggedIn) {
          _syncFromAuth();
          _hydrateWalletFromSupabase();
          _ensureWelcomeNotification();
        } else {
          orders.clear();
          filteredOrders.clear();
          transactions.clear();
          notifications.clear();
          creditedReferences.clear();
          walletBalance.value = 0.0;
        }
      });

      if (auth.isLoggedIn.value) {
        _hydrateWalletFromSupabase();
        _ensureWelcomeNotification();
      }
    }
  }

  String get _cacheKey {
    final mail = email.value.trim().toLowerCase();
    return 'resolva_wallet_${mail.isNotEmpty ? mail : "default"}';
  }

  void _syncFromAuth() {
    if (!Get.isRegistered<AuthController>()) return;
    final auth = Get.find<AuthController>();
    fullName.value = auth.userFullName.value.isNotEmpty
        ? auth.userFullName.value
        : (auth.userEmail.value.isNotEmpty
            ? auth.userEmail.value.split('@').first
            : 'Member');
    email.value = auth.userEmail.value;
    phone.value = auth.userPhone.value;
    avatarUrl.value = auth.userAvatarUrl.value;
  }

  /// Hydrates the user's wallet balance, credited Paystack references, and
  /// recent transactions from Supabase (`public.profiles` + `user_metadata`)
  /// and local browser cache.
  Future<void> _hydrateWalletFromSupabase() async {
    // 1. Hydrate from local browser cache immediately if available
    final cachedRaw = PaystackService.getCachedJson(_cacheKey);
    if (cachedRaw != null && cachedRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedRaw) as Map<String, dynamic>;
        final bal = (decoded['balance'] as num?)?.toDouble();
        if (bal != null && bal > walletBalance.value) {
          walletBalance.value = bal;
        }
        final refs = (decoded['refs'] as List?)?.map((e) => '$e').toList();
        if (refs != null) {
          for (final r in refs) {
            if (!creditedReferences.contains(r)) creditedReferences.add(r);
          }
        }
        final txList = decoded['transactions'] as List?;
        if (txList != null && transactions.isEmpty) {
          for (final item in txList) {
            if (item is Map<String, dynamic>) {
              transactions.add(_transactionFromJson(item));
            }
          }
        }
      } catch (_) {}
    }

    // 2. Hydrate from Supabase Auth user_metadata & profiles RPC
    final meta = AuthService.getCurrentUserMetadata();
    final metaRefs = (meta['resolva_credited_refs'] as List?)
        ?.map((e) => '$e')
        .toList();
    if (metaRefs != null) {
      for (final r in metaRefs) {
        if (!creditedReferences.contains(r)) creditedReferences.add(r);
      }
    }
    final metaTxs = meta['resolva_transactions'] as List?;
    if (metaTxs != null && transactions.isEmpty) {
      for (final item in metaTxs) {
        if (item is Map) {
          transactions.add(
            _transactionFromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final cloudBalance = await AuthService.fetchCloudWalletBalance();
    if (cloudBalance != null) {
      walletBalance.value = cloudBalance;
      _saveLocalCache();
    }
  }

  void _saveLocalCache() {
    try {
      final payload = jsonEncode({
        'balance': walletBalance.value,
        'refs': creditedReferences.toList(),
        'transactions': transactions.take(40).map(_transactionToJson).toList(),
      });
      PaystackService.setCachedJson(_cacheKey, payload);
    } catch (_) {}
  }

  Map<String, dynamic> _transactionToJson(Transaction t) => {
        'reference': t.reference,
        'description': t.description,
        'date': t.date.toIso8601String(),
        'amount': t.amount,
        'paymentMethod': t.paymentMethod,
        'status': t.status.name,
      };

  Transaction _transactionFromJson(Map<String, dynamic> m) => Transaction(
        reference: (m['reference'] ?? '').toString(),
        description: (m['description'] ?? 'Wallet Transaction').toString(),
        date: DateTime.tryParse('${m['date']}') ?? DateTime.now(),
        amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
        paymentMethod: (m['paymentMethod'] ?? 'Paystack').toString(),
        status: switch (m['status']) {
          'pending' => TransactionStatus.pending,
          'failed' => TransactionStatus.failed,
          _ => TransactionStatus.successful,
        },
      );

  void _ensureWelcomeNotification() {
    if (notifications.isNotEmpty) return;
    final displayName = fullName.value.isNotEmpty ? fullName.value : 'there';
    notifications.add(
      AppNotification(
        id: 'NOTIF-WELCOME',
        title: 'Welcome to RESOLVA, $displayName!',
        message:
            'Your account is active. Fund your wallet via Paystack to boost your social media accounts or access other services like Examination E-Pins.',
        date: DateTime.now(),
        type: NotificationType.support,
        isRead: false,
      ),
    );
  }

  /// Dynamic initials derived from the user's real name or email.
  String get userInitials {
    final name = fullName.value.trim();
    if (name.isEmpty) return 'U';
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  // Summary statistics
  int get totalOrders => orders.length;
  int get completedOrders => orders
      .where((o) => o.fulfilmentStatus == OrderFulfilmentStatus.completed)
      .length;
  int get pendingOrders => orders
      .where(
        (o) =>
            o.fulfilmentStatus == OrderFulfilmentStatus.pending ||
            o.fulfilmentStatus == OrderFulfilmentStatus.processing,
      )
      .length;
  int get unreadNotifications => notifications.where((n) => !n.isRead).length;
  double get totalSpent => orders
      .where((o) => o.paymentStatus == OrderPaymentStatus.paid)
      .fold(0.0, (sum, item) => sum + item.amount);

  void filterOrders(String filter) {
    selectedOrderFilter.value = filter;
    if (filter == 'All') {
      filteredOrders.assignAll(orders);
    } else {
      final status = switch (filter) {
        'Completed' => OrderFulfilmentStatus.completed,
        'Processing' => OrderFulfilmentStatus.processing,
        'Pending' => OrderFulfilmentStatus.pending,
        'Cancelled' => OrderFulfilmentStatus.cancelled,
        _ => null,
      };
      if (status != null) {
        filteredOrders.assignAll(
          orders.where((o) => o.fulfilmentStatus == status).toList(),
        );
      }
    }
  }

  void setTab(int index) {
    activeTab.value = index;
  }

  /// Launches the live Paystack Payment Gateway popup, verifies the completed
  /// transaction via `GET https://api.paystack.co/transaction/verify/:reference`,
  /// and updates the user's wallet balance in Supabase and on the Dashboard.
  Future<PaystackVerificationResult> fundWalletWithPaystack({
    required double amount,
    required String selectedMethod,
  }) async {
    fundingError.value = '';
    if (amount < 100) {
      fundingError.value = 'Minimum wallet top-up is ₦100.';
      return PaystackVerificationResult.failure('', fundingError.value);
    }

    isFundingWallet.value = true;
    try {
      final userId = Get.isRegistered<AuthController>()
          ? Get.find<AuthController>().userId.value
          : '';
      final result = await PaystackService.checkoutAndVerify(
        email: email.value,
        amountNaira: amount,
        selectedMethod: selectedMethod,
        fullName: fullName.value,
        userId: userId,
      );

      if (result.cancelled) {
        return result;
      }

      if (!result.isSuccess) {
        fundingError.value = result.message;
        return result;
      }

      await _applyVerifiedPaystackCredit(
        result,
        fallbackMethod: selectedMethod,
      );
      return result;
    } finally {
      isFundingWallet.value = false;
    }
  }

  /// Verifies an existing Paystack transaction reference with Paystack's API
  /// (`GET /transaction/verify/:reference`) and credits the wallet if not yet credited.
  Future<PaystackVerificationResult> verifyAndCreditReference(
    String reference,
  ) async {
    fundingError.value = '';
    final cleanRef = reference.trim();
    if (cleanRef.isEmpty) {
      fundingError.value = 'Please enter a valid Paystack reference.';
      return PaystackVerificationResult.failure('', fundingError.value);
    }

    if (creditedReferences.contains(cleanRef)) {
      fundingError.value =
          'This Paystack reference ($cleanRef) has already been credited to your wallet.';
      return PaystackVerificationResult.failure(cleanRef, fundingError.value);
    }

    isFundingWallet.value = true;
    try {
      final result = await PaystackService.verifyTransaction(cleanRef);
      if (!result.isSuccess) {
        fundingError.value = result.message;
        return result;
      }

      await _applyVerifiedPaystackCredit(
        result,
        fallbackMethod: 'Paystack',
      );
      return result;
    } finally {
      isFundingWallet.value = false;
    }
  }

  Future<void> _applyVerifiedPaystackCredit(
    PaystackVerificationResult result, {
    required String fallbackMethod,
  }) async {
    final ref = result.reference.trim();
    if (ref.isNotEmpty && creditedReferences.contains(ref)) {
      return;
    }
    if (ref.isNotEmpty) {
      creditedReferences.insert(0, ref);
    }

    final creditedAmount = result.amountNaira;
    final methodLabel = PaystackService.formatChannelLabel(
      result.channel,
      fallback: fallbackMethod,
    );

    walletBalance.value += creditedAmount;

    transactions.insert(
      0,
      Transaction(
        reference: ref,
        description: 'Wallet Top-Up ($methodLabel)',
        date: result.paidAt,
        amount: creditedAmount,
        paymentMethod: methodLabel,
        status: TransactionStatus.successful,
      ),
    );

    notifications.insert(
      0,
      AppNotification(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Paystack Payment Confirmed',
        message:
            'Your RESOLVA wallet has been credited with ₦${creditedAmount.toStringAsFixed(0)} via $methodLabel (Ref: $ref).',
        date: DateTime.now(),
        type: NotificationType.payment,
        isRead: false,
      ),
    );

    _saveLocalCache();

    // Sync to Supabase (both public.profiles RPC + auth.users user_metadata)
    final syncedBalance = await AuthService.creditWalletOnSupabase(
      reference: ref,
      amount: creditedAmount,
      paymentMethod: methodLabel,
      channel: result.channel,
      newBalance: walletBalance.value,
      creditedRefs: creditedReferences.toList(),
      recentTransactions: transactions.map(_transactionToJson).toList(),
      metadata: result.rawData,
    );

    if (syncedBalance != null && syncedBalance >= walletBalance.value) {
      walletBalance.value = syncedBalance;
      _saveLocalCache();
    }
  }

  /// Direct wallet credit helper (used by tests or internal adjustments).
  void fundWallet({
    required double amount,
    required String paymentMethod,
    String? reference,
  }) {
    if (amount <= 0) return;
    final now = DateTime.now();
    final ref = reference ?? 'RSV-${now.millisecondsSinceEpoch.toString().substring(6)}';
    if (creditedReferences.contains(ref)) return;
    creditedReferences.insert(0, ref);

    walletBalance.value += amount;

    transactions.insert(
      0,
      Transaction(
        reference: ref,
        description: 'Wallet Top-Up ($paymentMethod)',
        date: now,
        amount: amount,
        paymentMethod: paymentMethod,
        status: TransactionStatus.successful,
      ),
    );

    notifications.insert(
      0,
      AppNotification(
        id: 'NOTIF-${now.millisecondsSinceEpoch}',
        title: 'Wallet Funded Successfully',
        message:
            'Your RESOLVA wallet has been credited with ₦${amount.toStringAsFixed(0)} via $paymentMethod (Ref: $ref).',
        date: now,
        type: NotificationType.payment,
        isRead: false,
      ),
    );

    _saveLocalCache();
    AuthService.creditWalletOnSupabase(
      reference: ref,
      amount: amount,
      paymentMethod: paymentMethod,
      channel: 'paystack',
      newBalance: walletBalance.value,
      creditedRefs: creditedReferences.toList(),
      recentTransactions: transactions.map(_transactionToJson).toList(),
    );
  }

  /// Places a live customer order for Examination E-Pins or Social Media Services.
  Order placeOrder({
    required String productName,
    required String category,
    required double amount,
    required int quantity,
    required String paymentMethod,
    String? details,
    String? targetUrl,
    bool isInstantPin = false,
  }) {
    final now = DateTime.now();
    final rng = Random();
    final orderId = 'ORD-${now.year}-${(1000 + rng.nextInt(9000))}';
    final txnRef = 'TXN-${now.millisecondsSinceEpoch.toString().substring(6)}';

    final usedWallet =
        paymentMethod == 'Wallet Balance' && walletBalance.value >= amount;
    if (usedWallet) {
      walletBalance.value -= amount;
    }

    List<String>? generatedPins;
    if (isInstantPin) {
      generatedPins = List.generate(
        quantity,
        (_) =>
            '${1000 + rng.nextInt(9000)}-${1000 + rng.nextInt(9000)}-${1000 + rng.nextInt(9000)}',
      );
    }

    final newOrder = Order(
      id: orderId,
      productName: productName,
      category: category,
      date: now,
      amount: amount,
      paymentStatus: OrderPaymentStatus.paid,
      fulfilmentStatus: isInstantPin
          ? OrderFulfilmentStatus.completed
          : OrderFulfilmentStatus.processing,
      details: details ?? '$productName (x$quantity)',
      quantity: quantity,
      recipientEmail:
          email.value.isNotEmpty ? email.value : 'customer@resolva.ng',
      targetUrl: targetUrl,
      pins: generatedPins,
    );

    orders.insert(0, newOrder);
    filterOrders(selectedOrderFilter.value);

    transactions.insert(
      0,
      Transaction(
        reference: txnRef,
        description: '$productName (x$quantity)',
        date: now,
        amount: amount,
        paymentMethod: paymentMethod,
        status: TransactionStatus.successful,
      ),
    );

    notifications.insert(
      0,
      AppNotification(
        id: 'NOTIF-${now.millisecondsSinceEpoch}',
        title: isInstantPin ? 'E-Pin Order Delivered' : 'Order Confirmed',
        message: isInstantPin
            ? 'Your $productName e-pin(s) under order $orderId are ready in your dashboard.'
            : 'Your order $orderId for $productName has been confirmed and is processing.',
        date: now,
        type: isInstantPin
            ? NotificationType.orderCompleted
            : NotificationType.orderConfirmed,
        isRead: false,
      ),
    );

    _saveLocalCache();

    if (usedWallet) {
      AuthService.debitWalletOnSupabase(
        reference: txnRef,
        amount: amount,
        description: '$productName (x$quantity)',
        newBalance: walletBalance.value,
        creditedRefs: creditedReferences.toList(),
        recentTransactions: transactions.map(_transactionToJson).toList(),
      );
    }

    if (Get.isRegistered<AdminController>() && email.value.isNotEmpty) {
      Get.find<AdminController>().recordUserPurchase(
        email: email.value,
        orderId: orderId,
        productName: productName,
        category: category,
        amount: amount,
      );
    }

    return newOrder;
  }

  void markNotificationRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final old = notifications[index];
      notifications[index] = AppNotification(
        id: old.id,
        title: old.title,
        message: old.message,
        date: old.date,
        type: old.type,
        isRead: true,
      );
    }
  }

  void markAllNotificationsRead() {
    for (int i = 0; i < notifications.length; i++) {
      final old = notifications[i];
      if (!old.isRead) {
        notifications[i] = AppNotification(
          id: old.id,
          title: old.title,
          message: old.message,
          date: old.date,
          type: old.type,
          isRead: true,
        );
      }
    }
  }

  /// Updates the user's profile in Supabase and local state.
  Future<bool> updateProfile({
    required String name,
    required String emailAddr,
    required String phoneNum,
  }) async {
    isSavingProfile.value = true;
    try {
      bool ok = true;
      if (Get.isRegistered<AuthController>()) {
        ok = await Get.find<AuthController>().updateProfile(
          fullName: name,
          phone: phoneNum,
        );
      }
      if (ok) {
        fullName.value = name.trim();
        email.value = emailAddr.trim();
        phone.value = phoneNum.trim();
      }
      return ok;
    } finally {
      isSavingProfile.value = false;
    }
  }
}
