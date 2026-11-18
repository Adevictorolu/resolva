import 'package:get/get.dart';
import '../core/config/bigisub_config.dart';
import '../core/config/supabase_config.dart';
import '../data/models/admin_models.dart';
import '../data/mock/mock_data.dart';
import '../services/auth_service.dart';
import '../services/bigisub_service.dart';
import '../services/pricing_service.dart';
import 'exam_controller.dart';
import 'social_controller.dart';

/// Controller managing the RESOLVA Admin Dashboard:
/// - Adding & removing users and administrators
/// - Setting global & per-service pricing (percentage `%` or fixed/per-unit `₦`)
/// - Toggling user status (Active / Suspended)
/// - Viewing user information & last purchase details
/// - Tracking user login/logout sessions & live activities
/// - Platform analytics & revenue breakdowns
class AdminController extends GetxController {
  final users = <AdminUserRecord>[].obs;
  final filteredUsers = <AdminUserRecord>[].obs;
  final activityLogs = <UserActivityLog>[].obs;
  final filteredActivityLogs = <UserActivityLog>[].obs;

  // Filters & search
  final userSearchQuery = ''.obs;
  final userStatusFilter = 'All'.obs; // All, Active, Online, Suspended, Pending, Admins
  final activityFilter = 'All'.obs; // All, Logins, Logouts, Purchases, Account Changes
  final activitySearchQuery = ''.obs;

  // Service Pricing Management filters
  final pricingSearchQuery = ''.obs;
  final pricingPlatformFilter = 'all'.obs;
  final pricingRegionFilter = 'all'.obs;
  final showCustomOverridesOnly = false.obs;

  // Selected user for detailed profile modal/drawer
  final selectedUser = Rxn<AdminUserRecord>();

  int _nextUserCounter = 1009;
  int _nextLogCounter = 9013;

  @override
  void onInit() {
    super.onInit();
    PricingService.initialize();
    if (AuthService.isEnabled) {
      loadFromBackend();
    } else {
      users.assignAll(mockAdminUsers);
      filteredUsers.assignAll(mockAdminUsers);
      activityLogs.assignAll(mockAdminActivityLogs);
      filteredActivityLogs.assignAll(mockAdminActivityLogs);
    }
  }

  // ──────────────────── SUPABASE BACKEND ────────────────────

  final isLoadingUsers = false.obs;
  final backendError = ''.obs;

  /// Loads every profile from Supabase (admins only; enforced by RLS) and merges
  /// any invited administrator emails from `PricingService.config.value.adminEmails`.
  Future<void> loadFromBackend() async {
    if (!AuthService.isEnabled) return;
    isLoadingUsers.value = true;
    backendError.value = '';
    try {
      final profiles = await AuthService.adminListProfiles();
      final backendRecords = profiles.map(_recordFromProfile).toList();

      // Ensure any invited admin emails that haven't signed up yet are also visible
      for (final adminEmail in PricingService.config.value.adminEmails) {
        final exists = backendRecords.any(
          (u) => u.email.toLowerCase() == adminEmail.toLowerCase(),
        );
        if (!exists) {
          backendRecords.insert(
            0,
            AdminUserRecord(
              id: 'ADM-${adminEmail.hashCode.abs().toString().substring(0, 4)}',
              fullName: '${adminEmail.split('@').first} (Admin)',
              email: adminEmail,
              phone: 'Invited Admin',
              role: UserRole.admin,
              status: UserStatus.active,
              joinedAt: DateTime.now(),
              hasPinConfigured: true,
              hasAcceptedPolicies: true,
            ),
          );
        }
      }

      users.assignAll(backendRecords);
      _applyUserFilters();
    } catch (e) {
      backendError.value = AuthService.describeError(e);
    } finally {
      isLoadingUsers.value = false;
    }
  }

  AdminUserRecord _recordFromProfile(UserProfile p) {
    final normalizedEmail = p.email.trim().toLowerCase();
    final isListedAdmin =
        PricingService.config.value.adminEmails.contains(normalizedEmail) ||
        normalizedEmail == SupabaseConfig.primaryAdminEmail.toLowerCase();
    return AdminUserRecord(
      id: p.id,
      fullName: p.fullName.isNotEmpty ? p.fullName : p.email.split('@').first,
      email: p.email,
      phone: p.phone.isNotEmpty ? p.phone : 'Not provided',
      role: (p.isAdmin || isListedAdmin) ? UserRole.admin : UserRole.customer,
      status: switch (p.status) {
        'active' => UserStatus.active,
        'suspended' => UserStatus.suspended,
        _ => UserStatus.pendingOnboarding,
      },
      joinedAt: p.createdAt,
      lastLoginAt: p.lastLoginAt,
      hasPinConfigured: p.status != 'pendingOnboarding',
      hasAcceptedPolicies: p.acceptedTermsVersion.isNotEmpty,
    );
  }

  List<AdminUserRecord> get adminUsers =>
      users.where((u) => u.role == UserRole.admin).toList();

  // ──────────────────── ANALYTICS GETTERS ────────────────────

  int get totalUsersCount => users.length;

  int get activeUsersCount =>
      users.where((u) => u.status == UserStatus.active).length;

  int get onlineUsersCount =>
      users.where((u) => u.isCurrentlyOnline).length;

  int get suspendedUsersCount =>
      users.where((u) => u.status == UserStatus.suspended).length;

  int get pendingUsersCount =>
      users.where((u) => u.status == UserStatus.pendingOnboarding).length;

  int get totalOrdersCount =>
      users.fold(0, (sum, u) => sum + u.totalOrders);

  double get totalPlatformRevenue =>
      users.fold(0.0, (sum, u) => sum + u.totalSpent);

  double get averageRevenuePerUser =>
      users.isEmpty ? 0 : totalPlatformRevenue / users.length;

  int get totalLoginsToday => activityLogs
      .where((a) => a.type == ActivityType.login)
      .length;

  int get totalLogoutsToday => activityLogs
      .where((a) => a.type == ActivityType.logout)
      .length;

  /// Revenue breakdown by category for analytics visualization
  Map<String, double> get revenueByCategory {
    double examRevenue = 0;
    double socialRevenue = 0;
    for (final u in users) {
      if (u.lastPurchase != null) {
        if (u.lastPurchase!.category == 'Examination E-Pins') {
          examRevenue += u.totalSpent * 0.65;
          socialRevenue += u.totalSpent * 0.35;
        } else {
          socialRevenue += u.totalSpent * 0.65;
          examRevenue += u.totalSpent * 0.35;
        }
      }
    }
    return {
      'Social Media Boosting': socialRevenue,
      'Other Services (Exam E-Pins)': examRevenue,
    };
  }

  // ──────────────────── USER FILTERING ────────────────────

  void searchUsers(String query) {
    userSearchQuery.value = query;
    _applyUserFilters();
  }

  void filterUsersByStatus(String status) {
    userStatusFilter.value = status;
    _applyUserFilters();
  }

  void _applyUserFilters() {
    var list = users.toList();

    switch (userStatusFilter.value) {
      case 'Active':
        list = list.where((u) => u.status == UserStatus.active).toList();
        break;
      case 'Online':
        list = list.where((u) => u.isCurrentlyOnline).toList();
        break;
      case 'Suspended':
        list = list.where((u) => u.status == UserStatus.suspended).toList();
        break;
      case 'Pending':
        list = list.where((u) => u.status == UserStatus.pendingOnboarding).toList();
        break;
      case 'Admins':
        list = list.where((u) => u.role == UserRole.admin).toList();
        break;
    }

    if (userSearchQuery.value.isNotEmpty) {
      final q = userSearchQuery.value.toLowerCase();
      list = list
          .where((u) =>
              u.fullName.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.phone.toLowerCase().contains(q) ||
              u.id.toLowerCase().contains(q) ||
              (u.lastPurchase?.productName.toLowerCase().contains(q) ?? false))
          .toList();
    }

    filteredUsers.assignAll(list);
  }

  // ──────────────────── ACTIVITY FILTERING ────────────────────

  void filterActivities(String filter) {
    activityFilter.value = filter;
    _applyActivityFilters();
  }

  void searchActivities(String query) {
    activitySearchQuery.value = query;
    _applyActivityFilters();
  }

  void _applyActivityFilters() {
    var list = activityLogs.toList();

    switch (activityFilter.value) {
      case 'Logins':
        list = list
            .where((a) =>
                a.type == ActivityType.login ||
                a.type == ActivityType.pinVerified)
            .toList();
        break;
      case 'Logouts':
        list = list.where((a) => a.type == ActivityType.logout).toList();
        break;
      case 'Purchases':
        list = list.where((a) => a.type == ActivityType.purchase).toList();
        break;
      case 'Account Changes':
        list = list
            .where((a) =>
                a.type == ActivityType.accountCreated ||
                a.type == ActivityType.accountRemoved ||
                a.type == ActivityType.statusChanged)
            .toList();
        break;
    }

    if (activitySearchQuery.value.isNotEmpty) {
      final q = activitySearchQuery.value.toLowerCase();
      list = list
          .where((a) =>
              a.userName.toLowerCase().contains(q) ||
              a.userEmail.toLowerCase().contains(q) ||
              a.description.toLowerCase().contains(q) ||
              a.userId.toLowerCase().contains(q))
          .toList();
    }

    filteredActivityLogs.assignAll(list);
  }

  // ──────────────────── USER MANAGEMENT ACTIONS ────────────────────

  /// Adds a new user from the Admin Dashboard or Registration flow.
  /// If [role] is [UserRole.admin], also adds their email to `public.admin_emails`
  /// and promotes any existing profile in Supabase.
  AdminUserRecord addUser({
    required String fullName,
    required String email,
    required String phone,
    UserRole role = UserRole.customer,
    UserStatus status = UserStatus.active,
    bool hasPinConfigured = true,
  }) {
    final normalizedEmail = email.trim();
    final existingIdx = users.indexWhere(
      (u) => u.email.toLowerCase() == normalizedEmail.toLowerCase(),
    );

    if (existingIdx != -1) {
      final existing = users[existingIdx];
      final updated = existing.copyWith(
        fullName: fullName.trim().isNotEmpty ? fullName.trim() : existing.fullName,
        phone: phone.trim().isNotEmpty ? phone.trim() : existing.phone,
        role: role,
      );
      users[existingIdx] = updated;
      _applyUserFilters();

      if (AuthService.isEnabled && role == UserRole.admin) {
        AuthService.adminAddAdminEmail(normalizedEmail).then((_) {
          loadFromBackend();
        }).catchError((Object e) {
          backendError.value = AuthService.describeError(e);
        });
      }

      recordActivity(
        userId: updated.id,
        userName: updated.fullName,
        userEmail: updated.email,
        type: ActivityType.statusChanged,
        description:
            'Updated role to ${role == UserRole.admin ? "Administrator" : "Customer"}',
      );
      return updated;
    }

    final now = DateTime.now();
    final newUser = AdminUserRecord(
      id: 'USR-${_nextUserCounter++}',
      fullName: fullName.trim(),
      email: normalizedEmail,
      phone: phone.trim(),
      role: role,
      status: status,
      joinedAt: now,
      lastLoginAt: null,
      lastLogoutAt: null,
      isCurrentlyOnline: false,
      totalOrders: 0,
      totalSpent: 0,
      hasPinConfigured: hasPinConfigured,
      hasAcceptedPolicies: true,
      lastPurchase: null,
    );

    users.insert(0, newUser);
    _applyUserFilters();

    if (AuthService.isEnabled && role == UserRole.admin) {
      AuthService.adminAddAdminEmail(normalizedEmail).catchError((Object e) {
        backendError.value = AuthService.describeError(e);
      });
    }

    recordActivity(
      userId: newUser.id,
      userName: newUser.fullName,
      userEmail: newUser.email,
      type: ActivityType.accountCreated,
      description:
          'Account created (${role == UserRole.admin ? "Administrator" : "Customer"})',
    );

    return newUser;
  }

  /// Promotes a Customer to Administrator or demotes an Administrator to Customer.
  void toggleUserRole(String userId) {
    final index = users.indexWhere((u) => u.id == userId);
    if (index == -1) return;

    final current = users[index];
    final nextRole =
        current.role == UserRole.admin ? UserRole.customer : UserRole.admin;
    final updated = current.copyWith(role: nextRole);

    users[index] = updated;
    if (selectedUser.value?.id == userId) {
      selectedUser.value = updated;
    }
    _applyUserFilters();

    if (AuthService.isEnabled) {
      AuthService.adminSetUserRole(userId, nextRole.name).catchError((Object e) {
        backendError.value = AuthService.describeError(e);
        loadFromBackend();
      });
    }

    recordActivity(
      userId: updated.id,
      userName: updated.fullName,
      userEmail: updated.email,
      type: ActivityType.statusChanged,
      description: nextRole == UserRole.admin
          ? 'Promoted to Administrator by Admin'
          : 'Changed to Customer role by Admin',
    );
  }

  /// Removes a user by ID from the platform.
  void removeUser(String userId) {
    final index = users.indexWhere((u) => u.id == userId);
    if (index == -1) return;

    final removed = users.removeAt(index);
    if (selectedUser.value?.id == userId) {
      selectedUser.value = null;
    }
    _applyUserFilters();

    if (AuthService.isEnabled) {
      AuthService.adminDeleteUser(userId).catchError((Object e) {
        backendError.value = AuthService.describeError(e);
        loadFromBackend();
      });
    }

    recordActivity(
      userId: removed.id,
      userName: removed.fullName,
      userEmail: removed.email,
      type: ActivityType.accountRemoved,
      description: 'User account removed by Administrator',
    );
  }

  /// Toggles a user's status between Active and Suspended.
  void toggleUserStatus(String userId) {
    final index = users.indexWhere((u) => u.id == userId);
    if (index == -1) return;

    final current = users[index];
    final nextStatus = current.status == UserStatus.suspended
        ? UserStatus.active
        : UserStatus.suspended;

    final updated = current.copyWith(
      status: nextStatus,
      isCurrentlyOnline:
          nextStatus == UserStatus.suspended ? false : current.isCurrentlyOnline,
    );

    users[index] = updated;
    if (selectedUser.value?.id == userId) {
      selectedUser.value = updated;
    }
    _applyUserFilters();

    if (AuthService.isEnabled) {
      AuthService.adminSetUserStatus(userId, nextStatus.name).catchError((Object e) {
        backendError.value = AuthService.describeError(e);
        loadFromBackend();
      });
    }

    recordActivity(
      userId: updated.id,
      userName: updated.fullName,
      userEmail: updated.email,
      type: ActivityType.statusChanged,
      description: nextStatus == UserStatus.suspended
          ? 'Account suspended by Administrator'
          : 'Account reactivated by Administrator',
    );
  }

  // ──────────────────── LIVE SESSION & ACTIVITY HOOKS ────────────────────

  /// Records a live login event when a user signs in.
  void recordUserLogin({
    required String email,
    required String fullName,
    UserRole role = UserRole.customer,
  }) {
    final now = DateTime.now();
    final idx = users.indexWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );

    String userId;
    String name = fullName;

    if (idx != -1) {
      final existing = users[idx];
      name = existing.fullName;
      userId = existing.id;
      users[idx] = existing.copyWith(
        lastLoginAt: now,
        isCurrentlyOnline: true,
      );
    } else {
      userId = 'USR-${_nextUserCounter++}';
      final created = AdminUserRecord(
        id: userId,
        fullName: fullName.isNotEmpty ? fullName : email.split('@').first,
        email: email,
        phone: '08012345678',
        role: role,
        status: UserStatus.active,
        joinedAt: now,
        lastLoginAt: now,
        isCurrentlyOnline: true,
      );
      users.insert(0, created);
    }

    _applyUserFilters();
    recordActivity(
      userId: userId,
      userName: name,
      userEmail: email,
      type: ActivityType.login,
      description: 'User logged in to RESOLVA session',
    );
  }

  /// Records a live logout event when a user signs out.
  void recordUserLogout({required String email}) {
    final now = DateTime.now();
    final idx = users.indexWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );

    if (idx != -1) {
      final existing = users[idx];
      users[idx] = existing.copyWith(
        lastLogoutAt: now,
        isCurrentlyOnline: false,
      );
      _applyUserFilters();

      recordActivity(
        userId: existing.id,
        userName: existing.fullName,
        userEmail: existing.email,
        type: ActivityType.logout,
        description: 'User logged out of RESOLVA session',
      );
    }
  }

  /// Records a live purchase event for a customer.
  void recordUserPurchase({
    required String email,
    required String orderId,
    required String productName,
    required String category,
    required double amount,
  }) {
    final now = DateTime.now();
    final idx = users.indexWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );

    if (idx != -1) {
      final existing = users[idx];
      users[idx] = existing.copyWith(
        totalOrders: existing.totalOrders + 1,
        totalSpent: existing.totalSpent + amount,
        lastPurchase: LastPurchaseInfo(
          orderId: orderId,
          productName: productName,
          category: category,
          amount: amount,
          date: now,
        ),
      );
      _applyUserFilters();

      recordActivity(
        userId: existing.id,
        userName: existing.fullName,
        userEmail: existing.email,
        type: ActivityType.purchase,
        description: 'Purchased $productName ($orderId)',
        amount: amount,
      );
    }
  }

  /// Appends an entry to the activity log.
  void recordActivity({
    required String userId,
    required String userName,
    required String userEmail,
    required ActivityType type,
    required String description,
    double? amount,
  }) {
    final log = UserActivityLog(
      id: 'ACT-${_nextLogCounter++}',
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      type: type,
      description: description,
      timestamp: DateTime.now(),
      ipOrDevice: 'Web Session • Active Device',
      amount: amount,
    );
    activityLogs.insert(0, log);
    _applyActivityFilters();
  }

  // ──────────────────── ADMIN INVITATION & TEAM MANAGEMENT ────────────────────

  /// Adds a new administrator by email. This updates `PricingService.config`
  /// and `public.admin_emails` so the new admin can log in and oversee the dashboard.
  Future<void> inviteAdmin({
    required String email,
    String? fullName,
    String? phone,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) return;

    final currentAdmins =
        List<String>.from(PricingService.config.value.adminEmails);
    if (!currentAdmins.contains(cleanEmail)) {
      currentAdmins.add(cleanEmail);
      await PricingService.saveConfig(
        PricingService.config.value.copyWith(adminEmails: currentAdmins),
      );
    }

    addUser(
      fullName: (fullName != null && fullName.trim().isNotEmpty)
          ? fullName.trim()
          : cleanEmail.split('@').first,
      email: cleanEmail,
      phone: (phone != null && phone.trim().isNotEmpty) ? phone.trim() : 'Admin Team',
      role: UserRole.admin,
      status: UserStatus.active,
    );

    recordActivity(
      userId: 'ADM-${cleanEmail.hashCode.abs().toString().substring(0, 4)}',
      userName: fullName ?? cleanEmail.split('@').first,
      userEmail: cleanEmail,
      type: ActivityType.statusChanged,
      description: 'Added as Administrator by Primary Admin',
    );
  }

  /// Revokes administrator privileges from an email address (primary admin cannot be removed).
  Future<void> revokeAdmin(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail == SupabaseConfig.primaryAdminEmail.toLowerCase()) return;

    final currentAdmins =
        List<String>.from(PricingService.config.value.adminEmails);
    currentAdmins.remove(cleanEmail);
    await PricingService.saveConfig(
      PricingService.config.value.copyWith(adminEmails: currentAdmins),
    );

    final idx = users.indexWhere((u) => u.email.toLowerCase() == cleanEmail);
    if (idx != -1) {
      users[idx] = users[idx].copyWith(role: UserRole.customer);
      _applyUserFilters();
    }

    if (AuthService.isEnabled) {
      try {
        final profile = users.firstWhereOrNull((u) => u.email.toLowerCase() == cleanEmail);
        if (profile != null) {
          await AuthService.adminSetUserRole(profile.id, 'customer');
        }
      } catch (_) {}
    }

    recordActivity(
      userId: 'REV-${cleanEmail.hashCode.abs().toString().substring(0, 4)}',
      userName: cleanEmail,
      userEmail: cleanEmail,
      type: ActivityType.statusChanged,
      description: 'Administrator privileges revoked',
    );
  }

  // ──────────────────── PRICING & MARGINS MANAGEMENT ────────────────────

  PlatformPricingConfig get currentPricing => PricingService.config.value;

  /// Updates global pricing markup rules (percentage `%` or fixed `₦`) and
  /// broadcasts the changes immediately to all users' views.
  Future<void> updateGlobalPricing({
    PriceRuleMode? socialMode,
    double? socialValue,
    double? globalRegionPct,
    double? nigeriaRegionPct,
    double? ghanaRegionPct,
    PriceRuleMode? examMode,
    double? examValue,
  }) async {
    final updated = currentPricing.copyWith(
      socialGlobalMode: socialMode,
      socialGlobalValue: socialValue,
      globalRegionPercent: globalRegionPct,
      nigeriaRegionPercent: nigeriaRegionPct,
      ghanaRegionPercent: ghanaRegionPct,
      examGlobalMode: examMode,
      examGlobalValue: examValue,
    );

    await PricingService.saveConfig(updated);
    _refreshControllers();

    recordActivity(
      userId: 'PRICING-GLOBAL',
      userName: 'Administrator',
      userEmail: 'admin@resolva.ng',
      type: ActivityType.statusChanged,
      description: 'Updated global service pricing rules',
    );
  }

  /// Sets an exact price or markup for a specific service (by service id).
  Future<void> setServicePriceOverride({
    required String serviceId,
    required PriceRuleMode mode,
    required double value,
  }) async {
    final currentOverrides =
        Map<String, ServicePriceOverride>.from(currentPricing.overrides);
    currentOverrides[serviceId] = ServicePriceOverride(
      serviceId: serviceId,
      mode: mode,
      value: value,
      updatedAt: DateTime.now(),
    );

    final updated = currentPricing.copyWith(overrides: currentOverrides);
    await PricingService.saveConfig(updated);
    _refreshControllers();

    recordActivity(
      userId: 'PRICING-OVERRIDE',
      userName: 'Administrator',
      userEmail: 'admin@resolva.ng',
      type: ActivityType.statusChanged,
      description: 'Updated price override for service $serviceId',
    );
  }

  /// Removes a custom price override from a specific service.
  Future<void> removeServicePriceOverride(String serviceId) async {
    final currentOverrides =
        Map<String, ServicePriceOverride>.from(currentPricing.overrides);
    currentOverrides.remove(serviceId);

    final updated = currentPricing.copyWith(overrides: currentOverrides);
    await PricingService.saveConfig(updated);
    _refreshControllers();
  }

  /// Resets all per-service custom overrides back to global rules.
  Future<void> resetAllOverrides() async {
    final updated = currentPricing.copyWith(overrides: const {});
    await PricingService.saveConfig(updated);
    _refreshControllers();
  }

  void _refreshControllers() {
    if (Get.isRegistered<SocialController>()) {
      Get.find<SocialController>().applyPricingRules();
    }
    if (Get.isRegistered<ExamController>()) {
      Get.find<ExamController>().applyPricingRules();
    }
  }

  /// Safely saves or rotates sensitive API keys (`paystack` or `bigisub`) inside
  /// Supabase Vault (`vault.secrets`) & `public.payment_gateway_configs`.
  Future<void> saveGatewaySecretToSupabase({
    required String provider,
    String publicKey = '',
    required String secretKey,
  }) async {
    if (secretKey.trim().isEmpty) return;

    if (provider.toLowerCase() == 'bigisub') {
      BigisubConfig.setRuntimeToken(secretKey.trim());
      BigisubService.resetProxyFlags();
    }

    if (AuthService.isEnabled) {
      await AuthService.adminSaveGatewaySecret(
        provider: provider,
        publicKey: publicKey,
        secretKey: secretKey,
      );
    }

    recordActivity(
      userId: 'VAULT-${provider.toUpperCase()}',
      userName: 'Administrator',
      userEmail: 'admin@resolva.ng',
      type: ActivityType.statusChanged,
      description:
          'Updated $provider secret in Supabase Vault (Zero GitHub Exposure)',
    );
  }
}

