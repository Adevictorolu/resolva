import 'dart:convert';
import 'dart:math';
import 'package:get/get.dart';
import '../data/models/exam_product.dart';
import '../data/models/order.dart';
import '../data/models/social_service.dart';
import '../services/auth_service.dart';
import '../services/bigisub_service.dart';
import '../services/paystack_service.dart';
import 'admin_controller.dart';
import 'auth_controller.dart';

/// Controller for the live Customer Dashboard, Paystack Wallet Funding,
/// Bigisub Social Media Boosting & Examination E-Pin Orders, Notifications & Settings.
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
        final orderList = decoded['orders'] as List?;
        if (orderList != null && orders.isEmpty) {
          for (final item in orderList) {
            if (item is Map<String, dynamic>) {
              orders.add(_orderFromJson(item));
            }
          }
          filterOrders(selectedOrderFilter.value);
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
    final metaOrders = meta['resolva_orders'] as List?;
    if (metaOrders != null && orders.isEmpty) {
      for (final item in metaOrders) {
        if (item is Map) {
          orders.add(_orderFromJson(Map<String, dynamic>.from(item)));
        }
      }
      filterOrders(selectedOrderFilter.value);
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
        'orders': orders.take(40).map(_orderToJson).toList(),
      });
      PaystackService.setCachedJson(_cacheKey, payload);
    } catch (_) {}
  }

  Map<String, dynamic> _orderToJson(Order o) => {
        'id': o.id,
        'productName': o.productName,
        'category': o.category,
        'date': o.date.toIso8601String(),
        'amount': o.amount,
        'paymentStatus': o.paymentStatus.name,
        'fulfilmentStatus': o.fulfilmentStatus.name,
        'details': o.details,
        'quantity': o.quantity,
        'recipientEmail': o.recipientEmail,
        'targetUrl': o.targetUrl,
        'pins': o.pins,
        'bigisubTranId': o.bigisubTranId,
        'bigisubReference': o.bigisubReference,
        'platform': o.platform,
        'unitPrice': o.unitPrice,
        'startCount': o.startCount,
        'remains': o.remains,
        'deliveredCount': o.deliveredCount,
        'deliveryPercentage': o.deliveryPercentage,
        'statusNote': o.statusNote,
        'canCancel': o.canCancel,
        'canRefill': o.canRefill,
        'canRefresh': o.canRefresh,
      };

  Order _orderFromJson(Map<String, dynamic> m) => Order(
        id: (m['id'] ?? '').toString(),
        productName: (m['productName'] ?? '').toString(),
        category: (m['category'] ?? 'Social Media Boosting').toString(),
        date: DateTime.tryParse('${m['date']}') ?? DateTime.now(),
        amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
        paymentStatus: OrderPaymentStatus.paid,
        fulfilmentStatus: switch (m['fulfilmentStatus']) {
          'completed' => OrderFulfilmentStatus.completed,
          'pending' => OrderFulfilmentStatus.pending,
          'cancelled' => OrderFulfilmentStatus.cancelled,
          _ => OrderFulfilmentStatus.processing,
        },
        details: m['details']?.toString(),
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
        recipientEmail: (m['recipientEmail'] ?? '').toString(),
        targetUrl: m['targetUrl']?.toString(),
        pins: (m['pins'] as List?)?.map((e) => '$e').toList(),
        bigisubTranId: m['bigisubTranId']?.toString(),
        bigisubReference: m['bigisubReference']?.toString(),
        platform: m['platform']?.toString(),
        unitPrice: (m['unitPrice'] as num?)?.toDouble(),
        startCount: (m['startCount'] as num?)?.toInt(),
        remains: (m['remains'] as num?)?.toInt(),
        deliveredCount: (m['deliveredCount'] as num?)?.toInt(),
        deliveryPercentage: (m['deliveryPercentage'] as num?)?.toInt(),
        statusNote: m['statusNote']?.toString(),
        canCancel: m['canCancel'] == true,
        canRefill: m['canRefill'] == true,
        canRefresh: m['canRefresh'] != false,
      );

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
    final parts =
        name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
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

  /// Direct wallet credit helper.
  void fundWallet({
    required double amount,
    required String paymentMethod,
    String? reference,
  }) {
    if (amount <= 0) return;
    final now = DateTime.now();
    final ref =
        reference ?? 'RSV-${now.millisecondsSinceEpoch.toString().substring(6)}';
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

  /// Places a live **Social Media Boosting** order via Bigisub Marketing Hub
  /// (`POST https://api.bigisub.ng/api/v2/marketinghub/order/create/`) and deducts
  /// the cost from the user's RESOLVA Wallet Balance.
  Future<({Order? order, String? error})> placeSocialBoostingOrder({
    required SocialService service,
    required String platformName,
    required String targetLinkOrUsername,
    required int quantity,
    String? customText,
    int? pollAnswerNumber,
    String? hashtag,
    int? oldPosts,
    int? futurePosts,
    int? delayMinutes,
  }) async {
    final total = service.calculatePrice(quantity);
    if (walletBalance.value < total) {
      final shortfall = (total - walletBalance.value).ceil();
      return (
        order: null,
        error:
            'Insufficient wallet balance. You need ₦$shortfall more in your wallet to place this order.',
      );
    }

    final apiRes = await BigisubService.createMarketingOrder(
      service: service,
      targetLinkOrUsername: targetLinkOrUsername,
      quantity: quantity,
      customText: customText,
      pollAnswerNumber: pollAnswerNumber,
      hashtag: hashtag,
      oldPosts: oldPosts,
      futurePosts: futurePosts,
      delayMinutes: delayMinutes,
    );

    if (!apiRes.isSuccess) {
      return (order: null, error: apiRes.message);
    }

    final now = DateTime.now();
    final orderId = apiRes.tranId.isNotEmpty
        ? apiRes.tranId
        : 'SOCL_${now.millisecondsSinceEpoch.toString().substring(5)}';
    final txnRef = 'TXN-$orderId';

    walletBalance.value = (walletBalance.value - total).clamp(0.0, double.infinity);

    final newOrder = Order(
      id: orderId,
      productName: service.name,
      category: 'Social Media Boosting',
      date: now,
      amount: total,
      paymentStatus: OrderPaymentStatus.paid,
      fulfilmentStatus: apiRes.status == 'completed'
          ? OrderFulfilmentStatus.completed
          : OrderFulfilmentStatus.processing,
      details:
          '$platformName (${service.countryLabel}) — ${service.name} • Qty: $quantity • Target: $targetLinkOrUsername',
      quantity: quantity,
      recipientEmail:
          email.value.isNotEmpty ? email.value : 'customer@resolva.ng',
      targetUrl: targetLinkOrUsername,
      bigisubTranId: apiRes.tranId,
      platform: service.platformId,
      unitPrice: apiRes.unitPrice,
      startCount: apiRes.startCount,
      remains: apiRes.remains,
      deliveredCount: apiRes.deliveredCount,
      deliveryPercentage: apiRes.deliveryPercentage,
      statusNote: apiRes.statusNote,
      canCancel: apiRes.canCancel,
      canRefill: apiRes.canRefill,
      canRefresh: apiRes.canRefresh,
    );

    orders.insert(0, newOrder);
    filterOrders(selectedOrderFilter.value);

    transactions.insert(
      0,
      Transaction(
        reference: txnRef,
        description: '${service.name} (x$quantity)',
        date: now,
        amount: total,
        paymentMethod: 'Wallet Balance',
        status: TransactionStatus.successful,
      ),
    );

    notifications.insert(
      0,
      AppNotification(
        id: 'NOTIF-${now.millisecondsSinceEpoch}',
        title: 'Social Boosting Order Placed ($orderId)',
        message:
            'Your order for ${service.name} (Qty: $quantity) has been sent to Bigisub Marketing Hub.',
        date: now,
        type: NotificationType.orderConfirmed,
        isRead: false,
      ),
    );

    _saveLocalCache();

    AuthService.debitWalletOnSupabase(
      reference: txnRef,
      amount: total,
      description: '${service.name} (x$quantity)',
      newBalance: walletBalance.value,
      creditedRefs: creditedReferences.toList(),
      recentTransactions: transactions.map(_transactionToJson).toList(),
    );

    AuthService.syncOrderToSupabase(
      orderCode: orderId,
      category: 'Social Media Boosting',
      productName: service.name,
      targetUrl: targetLinkOrUsername,
      quantity: quantity,
      amount: total,
      paymentMethod: 'Wallet Balance',
      status: 'processing',
      details: newOrder.details ?? service.name,
      recentOrders: orders.map(_orderToJson).toList(),
    );

    if (Get.isRegistered<AdminController>() && email.value.isNotEmpty) {
      Get.find<AdminController>().recordUserPurchase(
        email: email.value,
        orderId: orderId,
        productName: service.name,
        category: 'Social Media Boosting',
        amount: total,
      );
    }

    return (order: newOrder, error: null);
  }

  /// Places a live **Examination E-Pin** purchase via Bigisub Education API
  /// (`POST https://api.bigisub.ng/api/v2/bills/result-checker/purchase/`) and deducts
  /// the cost from the user's RESOLVA Wallet Balance.
  Future<({Order? order, String? error})> placeExamPinOrder({
    required ExamProduct product,
    required int quantity,
    String? pinCode,
  }) async {
    final normalizedQty =
        product.allowedQuantities.contains(quantity) ? quantity : 1;
    final total = product.price * normalizedQty;

    if (walletBalance.value < total) {
      final shortfall = (total - walletBalance.value).ceil();
      return (
        order: null,
        error:
            'Insufficient wallet balance. You need ₦$shortfall more in your wallet to purchase ${product.name} (x$normalizedQty).',
      );
    }

    final apiRes = await BigisubService.purchaseExamResultPins(
      product: product,
      quantity: normalizedQty,
      pinCode: pinCode,
    );

    if (!apiRes.isSuccess) {
      return (order: null, error: apiRes.message);
    }

    final now = DateTime.now();
    final orderId = apiRes.transactionId.isNotEmpty
        ? apiRes.transactionId
        : 'Edu-${now.millisecondsSinceEpoch.toString().substring(6)}';
    final txnRef = apiRes.reference.isNotEmpty
        ? apiRes.reference
        : 'TXN-${now.millisecondsSinceEpoch.toString().substring(6)}';

    walletBalance.value = (walletBalance.value - total).clamp(0.0, double.infinity);

    final newOrder = Order(
      id: orderId,
      productName: product.name,
      category: 'Examination E-Pins',
      date: now,
      amount: total,
      paymentStatus: OrderPaymentStatus.paid,
      fulfilmentStatus: OrderFulfilmentStatus.completed,
      details:
          '${product.provider} — ${product.name} (x$normalizedQty) • Ref: $txnRef',
      quantity: normalizedQty,
      recipientEmail:
          email.value.isNotEmpty ? email.value : 'customer@resolva.ng',
      pins: apiRes.pins,
      bigisubTranId: apiRes.transactionId,
      bigisubReference: apiRes.reference,
      unitPrice: product.price,
      deliveredCount: normalizedQty,
      deliveryPercentage: 100,
      statusNote: 'Result Checker PIN(s) delivered',
      canCancel: false,
      canRefill: false,
      canRefresh: false,
    );

    orders.insert(0, newOrder);
    filterOrders(selectedOrderFilter.value);

    transactions.insert(
      0,
      Transaction(
        reference: txnRef,
        description: '${product.name} (x$normalizedQty)',
        date: now,
        amount: total,
        paymentMethod: 'Wallet Balance',
        status: TransactionStatus.successful,
      ),
    );

    notifications.insert(
      0,
      AppNotification(
        id: 'NOTIF-${now.millisecondsSinceEpoch}',
        title: '${product.provider} E-PIN Delivered ($orderId)',
        message:
            'Your ${product.name} PIN(s) under reference $txnRef have been delivered to your Order & E-PIN Vault.',
        date: now,
        type: NotificationType.orderCompleted,
        isRead: false,
      ),
    );

    _saveLocalCache();

    AuthService.debitWalletOnSupabase(
      reference: txnRef,
      amount: total,
      description: '${product.name} (x$normalizedQty)',
      newBalance: walletBalance.value,
      creditedRefs: creditedReferences.toList(),
      recentTransactions: transactions.map(_transactionToJson).toList(),
    );

    AuthService.syncOrderToSupabase(
      orderCode: orderId,
      category: 'Examination E-Pins',
      productName: product.name,
      targetUrl: null,
      quantity: normalizedQty,
      amount: total,
      paymentMethod: 'Wallet Balance',
      status: 'completed',
      details: newOrder.details ?? product.name,
      pins: apiRes.pins,
      recentOrders: orders.map(_orderToJson).toList(),
    );

    if (Get.isRegistered<AdminController>() && email.value.isNotEmpty) {
      Get.find<AdminController>().recordUserPurchase(
        email: email.value,
        orderId: orderId,
        productName: product.name,
        category: 'Examination E-Pins',
        amount: total,
      );
    }

    return (order: newOrder, error: null);
  }

  /// Refreshes a Social Media Boosting order's delivery progress from Bigisub
  /// (`POST /api/v2/marketinghub/order/refresh/` + `GET /api/v2/marketinghub/order/receipt/`).
  Future<Order> refreshSocialOrderReceipt(Order order) async {
    final tranId = order.bigisubTranId ?? order.id;
    await BigisubService.refreshMarketingOrder(tranId);
    final receipt = await BigisubService.getMarketingOrderReceipt(tranId);

    Order updated = order;
    if (receipt != null) {
      final newFulfilment = switch (receipt.status.toLowerCase()) {
        'completed' => OrderFulfilmentStatus.completed,
        'cancelled' || 'failed' || 'refunded' => OrderFulfilmentStatus.cancelled,
        'pending' => OrderFulfilmentStatus.pending,
        _ => OrderFulfilmentStatus.processing,
      };
      updated = order.copyWith(
        fulfilmentStatus: newFulfilment,
        startCount: receipt.startCount,
        remains: receipt.remains,
        deliveredCount: receipt.deliveredCount,
        deliveryPercentage: receipt.deliveryPercentage,
        statusNote: receipt.statusNote,
        canCancel: receipt.canCancel,
        canRefill: receipt.canRefill,
        canRefresh: receipt.canRefresh,
      );
    } else {
      updated = order.copyWith(
        statusNote: 'Synced with Bigisub Marketing Hub',
      );
    }

    final idx = orders.indexWhere((o) => o.id == order.id);
    if (idx != -1) {
      orders[idx] = updated;
      filterOrders(selectedOrderFilter.value);
      _saveLocalCache();
    }
    return updated;
  }

  /// Requests a free refill for a Social Media Boosting order on Bigisub.
  Future<String> requestSocialOrderRefill(Order order) async {
    final tranId = order.bigisubTranId ?? order.id;
    final res = await BigisubService.requestMarketingOrderRefill(tranId);
    return res.message;
  }

  /// Cancels an active Social Media Boosting order on Bigisub and refunds any undelivered balance.
  Future<({bool ok, String message})> cancelSocialOrder(Order order) async {
    final tranId = order.bigisubTranId ?? order.id;
    final res = await BigisubService.cancelMarketingOrder(tranId);
    if (res.ok) {
      final refund = res.refundAmount ?? order.amount;
      if (refund > 0) {
        fundWallet(
          amount: refund,
          paymentMethod: 'Order Refund ($tranId)',
          reference: 'REFUND-$tranId-${DateTime.now().millisecondsSinceEpoch}',
        );
      }
      final idx = orders.indexWhere((o) => o.id == order.id);
      if (idx != -1) {
        orders[idx] = order.copyWith(
          fulfilmentStatus: OrderFulfilmentStatus.cancelled,
          statusNote: 'Cancelled & refunded',
          canCancel: false,
        );
        filterOrders(selectedOrderFilter.value);
        _saveLocalCache();
      }
    }
    return (ok: res.ok, message: res.message);
  }

  /// Legacy synchronous order placement helper.
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

    _saveLocalCache();
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
