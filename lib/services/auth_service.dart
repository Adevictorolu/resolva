import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';

/// Profile row stored in `public.profiles` (see supabase/migrations).
class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String? avatarUrl;
  final String role; // 'customer' | 'admin'
  final String status; // 'active' | 'suspended' | 'pendingOnboarding'
  final String acceptedTermsVersion;
  final String acceptedPrivacyVersion;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.avatarUrl,
    required this.role,
    required this.status,
    required this.acceptedTermsVersion,
    required this.acceptedPrivacyVersion,
    required this.createdAt,
    required this.lastLoginAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isSuspended => status == 'suspended';

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        id: m['id'] as String,
        email: (m['email'] ?? '') as String,
        fullName: (m['full_name'] ?? '') as String,
        phone: (m['phone'] ?? '') as String,
        avatarUrl: m['avatar_url'] as String?,
        role: (m['role'] ?? 'customer') as String,
        status: (m['status'] ?? 'pendingOnboarding') as String,
        acceptedTermsVersion: (m['accepted_terms_version'] ?? '') as String,
        acceptedPrivacyVersion: (m['accepted_privacy_version'] ?? '') as String,
        createdAt: DateTime.tryParse('${m['created_at']}') ?? DateTime.now(),
        lastLoginAt: m['last_login_at'] == null
            ? null
            : DateTime.tryParse('${m['last_login_at']}'),
      );
}

/// Thin wrapper around Supabase Auth + the RESOLVA profile / PIN RPCs.
class AuthService {
  AuthService._();

  static const _profileColumns =
      'id, email, full_name, phone, avatar_url, role, status, '
      'accepted_terms_version, accepted_privacy_version, created_at, last_login_at';

  static bool get isEnabled => SupabaseConfig.isConfigured;

  static Future<void> initialize() async {
    if (!isEnabled) return;
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  }

  static SupabaseClient get _client => Supabase.instance.client;

  static Session? get currentSession => isEnabled ? _client.auth.currentSession : null;
  static User? get currentUser => isEnabled ? _client.auth.currentUser : null;

  static Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// URL Supabase should send users back to after Google sign-in / email links.
  static String? get redirectUrl {
    if (SupabaseConfig.redirectUrl.isNotEmpty) return SupabaseConfig.redirectUrl;
    if (!kIsWeb) return null;
    // Current page without query/fragment, e.g. https://user.github.io/resolva/
    final base = Uri.base;
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: base.path,
    ).toString();
  }

  // ──────────────── Sign in / sign up ────────────────

  static Future<AuthResponse> signInWithPassword(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: redirectUrl,
      data: {'full_name': fullName, 'phone': phone},
    );
  }

  /// Starts the Google OAuth flow. On web this redirects the whole page to
  /// Google and comes back to [redirectUrl]; the session is then picked up
  /// automatically and emitted on [onAuthStateChange].
  static Future<bool> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
      queryParams: const {'prompt': 'select_account'},
    );
  }

  static Future<void> sendPasswordReset(String email) {
    return _client.auth.resetPasswordForEmail(email, redirectTo: redirectUrl);
  }

  static Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  static Future<void> signOut() => _client.auth.signOut();

  // ──────────────── Profile ────────────────

  static Future<UserProfile?> fetchMyProfile() async {
    final user = currentUser;
    if (user == null) return null;
    final row = await _client
        .from('profiles')
        .select(_profileColumns)
        .eq('id', user.id)
        .maybeSingle();
    return row == null ? null : UserProfile.fromMap(row);
  }

  static Future<void> acceptPolicies(String termsVersion, String privacyVersion) async {
    final user = currentUser;
    if (user == null) return;
    await _client.from('profiles').update({
      'accepted_terms_version': termsVersion,
      'accepted_privacy_version': privacyVersion,
    }).eq('id', user.id);
  }

  static Future<void> updateMyProfile({
    required String fullName,
    required String phone,
  }) async {
    final user = currentUser;
    if (user == null) return;
    await _client.from('profiles').update({
      'full_name': fullName.trim(),
      'phone': phone.trim(),
    }).eq('id', user.id);
    try {
      await _client.auth.updateUser(
        UserAttributes(data: {'full_name': fullName.trim(), 'phone': phone.trim()}),
      );
    } catch (_) {}
  }

  static Future<void> recordLogin() => _client.rpc('record_login');

  // ──────────────── Security PIN ────────────────

  static Future<bool> hasSecurityPin() async =>
      (await _client.rpc('has_security_pin')) == true;

  static Future<void> setSecurityPin(String pin) =>
      _client.rpc('set_security_pin', params: {'pin': pin});

  static Future<bool> verifySecurityPin(String pin) async =>
      (await _client.rpc('verify_security_pin', params: {'pin': pin})) == true;

  static Future<void> resetSecurityPin() => _client.rpc('reset_security_pin');

  // ──────────────── Admin ────────────────

  static Future<List<UserProfile>> adminListProfiles() async {
    final rows = await _client
        .from('profiles')
        .select(_profileColumns)
        .order('created_at', ascending: false);
    return rows.map(UserProfile.fromMap).toList();
  }

  static Future<void> adminSetUserStatus(String userId, String status) =>
      _client.rpc('admin_set_user_status', params: {'target': userId, 'new_status': status});

  static Future<void> adminSetUserRole(String userId, String role) =>
      _client.rpc('admin_set_user_role', params: {'target': userId, 'new_role': role});

  static Future<void> adminAddAdminEmail(String email) =>
      _client.rpc('admin_add_admin_email', params: {'admin_email': email});

  static Future<void> adminDeleteUser(String userId) =>
      _client.rpc('admin_delete_user', params: {'target': userId});

  /// Stores or updates a gateway secret (`bigisub` or `paystack`) inside
  /// Supabase Vault (`vault.secrets`) and `public.payment_gateway_configs`.
  static Future<void> adminSaveGatewaySecret({
    required String provider,
    String publicKey = '',
    required String secretKey,
  }) async {
    if (!isEnabled) return;
    await _client.rpc(
      'admin_save_gateway_secret',
      params: {
        'p_provider': provider.trim().toLowerCase(),
        'p_public_key': publicKey.trim(),
        'p_secret_key': secretKey.trim(),
      },
    );
  }

  // ──────────────── Wallet & Paystack Cloud Sync ────────────────

  static bool _walletRpcsAvailable = true;

  /// Fetches the user's wallet balance from `public.profiles` (via RPC) and/or
  /// `auth.users.user_metadata` so the balance persists across devices and refreshes.
  static Future<double?> fetchCloudWalletBalance() async {
    if (!isEnabled) return null;
    final user = currentUser;
    if (user == null) return null;

    double? rpcBalance;
    if (_walletRpcsAvailable) {
      try {
        final res = await _client
            .rpc('get_my_wallet_balance')
            .timeout(const Duration(seconds: 4));
        if (res is num) {
          rpcBalance = res.toDouble();
        } else if (res != null) {
          rpcBalance = double.tryParse(res.toString());
        }
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST202' || e.code == '42883') {
          _walletRpcsAvailable = false;
        }
      } catch (_) {}
    }

    final meta = user.userMetadata ?? const <String, dynamic>{};
    final metaBalRaw = meta['resolva_wallet_balance'];
    double? metaBalance;
    if (metaBalRaw is num) {
      metaBalance = metaBalRaw.toDouble();
    } else if (metaBalRaw != null) {
      metaBalance = double.tryParse(metaBalRaw.toString());
    }

    if (rpcBalance != null && metaBalance != null) {
      return rpcBalance > metaBalance ? rpcBalance : metaBalance;
    }
    return rpcBalance ?? metaBalance;
  }

  /// Fetches raw metadata map from `auth.users` for wallet transactions/references.
  static Map<String, dynamic> getCurrentUserMetadata() {
    if (!isEnabled) return const {};
    return currentUser?.userMetadata ?? const {};
  }

  /// Credits the user's wallet in Supabase (`credit_wallet_paystack` RPC + `user_metadata`).
  static Future<double?> creditWalletOnSupabase({
    required String reference,
    required double amount,
    required String paymentMethod,
    required String channel,
    required double newBalance,
    required List<String> creditedRefs,
    required List<Map<String, dynamic>> recentTransactions,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (!isEnabled || currentUser == null) return newBalance;

    double effectiveBalance = newBalance;

    // 1. Try SQL RPC on public.profiles + public.wallet_transactions if available
    if (_walletRpcsAvailable) {
      try {
        final rpcRes = await _client
            .rpc(
              'credit_wallet_paystack',
              params: {
                'p_reference': reference,
                'p_amount': amount,
                'p_payment_method': paymentMethod,
                'p_channel': channel,
                'p_metadata': metadata,
              },
            )
            .timeout(const Duration(seconds: 4));
        if (rpcRes is num) {
          effectiveBalance = rpcRes.toDouble();
        }
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST202' || e.code == '42883') {
          _walletRpcsAvailable = false;
        }
      } catch (_) {}
    }

    // 2. Always persist to Supabase Auth user_metadata so balance is saved in cloud immediately
    try {
      await _client.auth.updateUser(
        UserAttributes(
          data: {
            'resolva_wallet_balance': effectiveBalance,
            'resolva_credited_refs': creditedRefs.take(100).toList(),
            'resolva_transactions': recentTransactions.take(40).toList(),
          },
        ),
      );
    } catch (_) {}

    return effectiveBalance;
  }

  /// Debits the user's wallet in Supabase (`debit_wallet_for_order` RPC + `user_metadata`).
  static Future<void> debitWalletOnSupabase({
    required String reference,
    required double amount,
    required String description,
    required double newBalance,
    required List<String> creditedRefs,
    required List<Map<String, dynamic>> recentTransactions,
  }) async {
    if (!isEnabled || currentUser == null) return;

    if (_walletRpcsAvailable) {
      try {
        await _client
            .rpc(
              'debit_wallet_for_order',
              params: {
                'p_reference': reference,
                'p_amount': amount,
                'p_description': description,
              },
            )
            .timeout(const Duration(seconds: 4));
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST202' || e.code == '42883') {
          _walletRpcsAvailable = false;
        }
      } catch (_) {}
    }

    try {
      await _client.auth.updateUser(
        UserAttributes(
          data: {
            'resolva_wallet_balance': newBalance,
            'resolva_credited_refs': creditedRefs.take(100).toList(),
            'resolva_transactions': recentTransactions.take(40).toList(),
          },
        ),
      );
    } catch (_) {}
  }

  /// Records a Social Media Boosting or Other Services order in Supabase
  /// (`create_service_order` RPC + `auth.users.user_metadata`).
  static Future<void> syncOrderToSupabase({
    required String orderCode,
    required String category,
    required String productName,
    String? targetUrl,
    required int quantity,
    required double amount,
    required String paymentMethod,
    required String status,
    required String details,
    List<String>? pins,
    required List<Map<String, dynamic>> recentOrders,
  }) async {
    if (!isEnabled || currentUser == null) return;

    if (_walletRpcsAvailable) {
      try {
        await _client
            .rpc(
              'create_service_order',
              params: {
                'p_order_code': orderCode,
                'p_category': category,
                'p_product_name': productName,
                'p_target_url': targetUrl,
                'p_quantity': quantity,
                'p_amount': amount,
                'p_payment_method': paymentMethod,
                'p_status': status,
                'p_details': details,
                'p_pins': pins,
              },
            )
            .timeout(const Duration(seconds: 4));
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST202' || e.code == '42883') {
          _walletRpcsAvailable = false;
        }
      } catch (_) {}
    }

    try {
      await _client.auth.updateUser(
        UserAttributes(
          data: {
            'resolva_orders': recentOrders.take(40).toList(),
          },
        ),
      );
    } catch (_) {}
  }

  /// Logs an outbound email notification to Supabase `public.email_notifications` table.
  static Future<void> logEmailNotification({
    required String recipientEmail,
    required String recipientName,
    required String subject,
    required String htmlContent,
    required String templateType,
  }) async {
    if (!isEnabled) return;
    try {
      await _client.from('email_notifications').insert({
        'user_id': currentUser?.id,
        'recipient_email': recipientEmail.trim().toLowerCase(),
        'recipient_name': recipientName.trim(),
        'subject': subject,
        'template_type': templateType,
        'html_content': htmlContent,
        'status': 'sent',
      }).timeout(const Duration(seconds: 4));
    } catch (_) {
      // Non-blocking table insert
    }
  }

  /// Human-readable message for Supabase errors.
  static String describeError(Object e) {
    if (e is AuthException) return e.message;
    if (e is PostgrestException) return e.message;
    return e.toString();
  }
}
