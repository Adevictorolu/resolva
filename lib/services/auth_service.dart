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

  static Future<void> adminDeleteUser(String userId) =>
      _client.rpc('admin_delete_user', params: {'target': userId});

  /// Human-readable message for Supabase errors.
  static String describeError(Object e) {
    if (e is AuthException) return e.message;
    if (e is PostgrestException) return e.message;
    return e.toString();
  }
}
