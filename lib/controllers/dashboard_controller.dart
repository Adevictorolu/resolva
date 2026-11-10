import 'dart:math';
import 'package:get/get.dart';
import '../data/models/order.dart';
import 'admin_controller.dart';
import 'auth_controller.dart';

/// Controller for the live Customer Dashboard, Wallet, Orders, Notifications & Settings.
class DashboardController extends GetxController {
  final orders = <Order>[].obs;
  final filteredOrders = <Order>[].obs;
  final transactions = <Transaction>[].obs;
  final notifications = <AppNotification>[].obs;
  final selectedOrderFilter = 'All'.obs;
  final activeTab = 0.obs; // 0: Overview, 1: Orders, 2: Wallet & Invoices, 3: Notifications, 4: Settings

  // Wallet balance (in NGN)
  final walletBalance = 0.0.obs;

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
          _ensureWelcomeNotification();
        } else {
          orders.clear();
          filteredOrders.clear();
          transactions.clear();
          notifications.clear();
          walletBalance.value = 0.0;
        }
      });
    }
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

  void _ensureWelcomeNotification() {
    if (notifications.isNotEmpty) return;
    final displayName = fullName.value.isNotEmpty ? fullName.value : 'there';
    notifications.add(
      AppNotification(
        id: 'NOTIF-WELCOME',
        title: 'Welcome to RESOLVA, $displayName!',
        message:
            'Your account is active. Fund your wallet or place your first order for Examination E-Pins and Social Media services.',
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

  /// Credits the customer's wallet and records a transaction + notification.
  void fundWallet({
    required double amount,
    required String paymentMethod,
  }) {
    if (amount <= 0) return;
    walletBalance.value += amount;
    final now = DateTime.now();
    final ref = 'TXN-${now.millisecondsSinceEpoch.toString().substring(6)}';

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
    final orderId =
        'ORD-${now.year}-${(1000 + rng.nextInt(9000))}';
    final txnRef = 'TXN-${now.millisecondsSinceEpoch.toString().substring(6)}';

    if (paymentMethod == 'Wallet Balance' && walletBalance.value >= amount) {
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
      recipientEmail: email.value.isNotEmpty ? email.value : 'customer@resolva.ng',
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
