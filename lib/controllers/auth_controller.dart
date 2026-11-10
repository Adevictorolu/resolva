import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent, AuthState;
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../data/models/admin_models.dart';
import '../services/auth_service.dart';
import 'admin_controller.dart';

/// Central authentication and session authorization controller.
///
/// Two modes:
/// * **Supabase mode** (when `SUPABASE_URL` / `SUPABASE_ANON_KEY` are provided at
///   build time): real email/password + Google sign-in, profiles & roles from
///   `public.profiles`, and a server-side hashed 6-digit security PIN.
/// * **Demo mode** (no keys): the original frontend-only demonstration flow.
class AuthController extends GetxController {
  /// Navigation hook registered by `main.dart` so async auth events
  /// (e.g. returning from Google sign-in) can route the user.
  static void Function(String route)? navigate;

  bool get backendEnabled => AuthService.isEnabled;

  // Login form state
  final loginEmail = ''.obs;
  final loginPassword = ''.obs;
  final rememberMe = false.obs;
  final loginLoading = false.obs;
  final loginPasswordVisible = false.obs;
  final googleLoading = false.obs;

  // Registration form state
  final regFullName = ''.obs;
  final regEmail = ''.obs;
  final regPhone = ''.obs;
  final regPassword = ''.obs;
  final regConfirmPassword = ''.obs;
  final regAcceptTerms = false.obs;
  final regLoading = false.obs;
  final regPasswordVisible = false.obs;
  final regConfirmPasswordVisible = false.obs;

  // Feedback for the UI (errors / info such as "check your email")
  final authError = ''.obs;
  final authInfo = ''.obs;

  // Authentication & session state
  final isLoggedIn = false.obs;
  final isSessionUnlocked = false.obs;
  final isAdmin = false.obs;
  final showRegistration = false.obs;

  // Legal policy acceptance tracking (versioned)
  final acceptedTermsVersion = ''.obs;
  final acceptedPrivacyVersion = ''.obs;

  // Security PIN setup (6 digits). In Supabase mode the PIN itself is never
  // kept on the client; only [pinConfigured] is tracked.
  final securityPin = ''.obs;
  final pinConfigured = false.obs;

  // Redirect destination after completing auth/onboarding (internal state, non-observable)
  String intendedRoute = '';

  // Registered user profile
  final userId = ''.obs;
  final userFullName = 'Demo User'.obs;
  final userEmail = 'demo@resolva.ng'.obs;
  final userAvatarUrl = ''.obs;

  StreamSubscription<AuthState>? _authSub;

  // Helper getters
  bool get hasAcceptedCurrentPolicies =>
      acceptedTermsVersion.value == AppConstants.termsVersion &&
      acceptedPrivacyVersion.value == AppConstants.privacyVersion;

  bool get hasConfiguredPin => backendEnabled
      ? pinConfigured.value
      : securityPin.value.isNotEmpty && securityPin.value.length == 6;

  bool get isFullyAuthorized =>
      isLoggedIn.value &&
      hasAcceptedCurrentPolicies &&
      hasConfiguredPin &&
      isSessionUnlocked.value;

  @override
  void onInit() {
    super.onInit();
    if (backendEnabled) {
      _authSub = AuthService.onAuthStateChange.listen(_onAuthStateChange);
    }
  }

  @override
  void onClose() {
    _authSub?.cancel();
    super.onClose();
  }

  // ──────────────────── SUPABASE SESSION HANDLING ────────────────────

  /// Restores a persisted Supabase session (called once at app start).
  Future<void> restoreSession() async {
    if (!backendEnabled || AuthService.currentSession == null) return;
    try {
      await _loadSessionFromBackend(recordLogin: false);
    } catch (e) {
      authError.value = AuthService.describeError(e);
    }
  }

  Future<void> _onAuthStateChange(AuthState state) async {
    switch (state.event) {
      case AuthChangeEvent.signedIn:
        // Fired after password login, sign-up with auto-confirm, and when
        // returning from Google OAuth. Only handle it if we aren't logged in yet.
        if (isLoggedIn.value || state.session == null) return;
        try {
          final ok = await _loadSessionFromBackend(recordLogin: true);
          if (ok) navigate?.call(getNextAuthRoute());
        } catch (e) {
          authError.value = AuthService.describeError(e);
        } finally {
          googleLoading.value = false;
        }
        break;
      case AuthChangeEvent.signedOut:
        if (isLoggedIn.value) {
          _clearSession();
          navigate?.call('/login');
        }
        break;
      default:
        break;
    }
  }

  /// Loads profile, role, policy and PIN state for the current Supabase user.
  /// Returns false (and signs out) if the account is suspended.
  Future<bool> _loadSessionFromBackend({required bool recordLogin}) async {
    UserProfile? profile;
    try {
      profile = await AuthService.fetchMyProfile();
    } catch (_) {
      profile = null;
    }

    if (profile != null && profile.isSuspended) {
      authError.value = 'This account has been suspended. Please contact support.';
      await AuthService.signOut();
      return false;
    }

    bool hasPin = false;
    try {
      hasPin = await AuthService.hasSecurityPin();
    } catch (_) {
      hasPin = false;
    }

    final supaUser = AuthService.currentUser;
    final meta = supaUser?.userMetadata ?? const <String, dynamic>{};
    final email = (profile?.email.isNotEmpty == true
            ? profile!.email
            : supaUser?.email ?? '')
        .trim();
    final fullName = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : (meta['full_name'] as String?) ??
            (meta['name'] as String?) ??
            (email.isNotEmpty ? email.split('@').first : 'User');
    final avatar = profile?.avatarUrl ??
        (meta['avatar_url'] as String?) ??
        (meta['picture'] as String?) ??
        '';
    final isPrimaryAdmin =
        email.toLowerCase() == SupabaseConfig.primaryAdminEmail.toLowerCase();

    userId.value = profile?.id ?? supaUser?.id ?? '';
    userEmail.value = email;
    userFullName.value = fullName;
    userAvatarUrl.value = avatar;
    isAdmin.value = (profile?.isAdmin ?? false) || isPrimaryAdmin;
    acceptedTermsVersion.value = profile?.acceptedTermsVersion ?? '';
    acceptedPrivacyVersion.value = profile?.acceptedPrivacyVersion ?? '';
    pinConfigured.value = hasPin;
    securityPin.value = '';
    isSessionUnlocked.value = false;
    isLoggedIn.value = true;
    authError.value = '';

    if (recordLogin) {
      unawaited(AuthService.recordLogin().catchError((_) {}));
    }
    if (Get.isRegistered<AdminController>()) {
      final adminCtrl = Get.find<AdminController>();
      adminCtrl.recordUserLogin(
        email: userEmail.value,
        fullName: userFullName.value,
        role: isAdmin.value ? UserRole.admin : UserRole.customer,
      );
      if (isAdmin.value) {
        unawaited(adminCtrl.loadFromBackend());
      }
    }
    return true;
  }

  void _clearSession() {
    isLoggedIn.value = false;
    isSessionUnlocked.value = false;
    isAdmin.value = false;
    pinConfigured.value = false;
    securityPin.value = '';
    acceptedTermsVersion.value = '';
    acceptedPrivacyVersion.value = '';
    userId.value = '';
    userAvatarUrl.value = '';
    intendedRoute = '';
    loginPassword.value = '';
  }

  /// Returns the next route the user should visit based on their onboarding state.
  String getNextAuthRoute() {
    if (!isLoggedIn.value) {
      return '/login';
    }
    if (!hasAcceptedCurrentPolicies) {
      return '/policy-acceptance';
    }
    if (!hasConfiguredPin) {
      return '/create-pin';
    }
    if (!isSessionUnlocked.value) {
      return '/verify-pin';
    }
    if (isAdmin.value) {
      intendedRoute = '';
      return '/admin';
    }
    if (intendedRoute == '/admin') {
      intendedRoute = '';
    }
    final target = intendedRoute.isNotEmpty ? intendedRoute : '/dashboard';
    intendedRoute = '';
    return target;
  }

  void toggleAuthForm() {
    showRegistration.value = !showRegistration.value;
  }

  void toggleLoginPasswordVisibility() {
    loginPasswordVisible.value = !loginPasswordVisible.value;
  }

  void toggleRegPasswordVisibility() {
    regPasswordVisible.value = !regPasswordVisible.value;
  }

  void toggleRegConfirmPasswordVisibility() {
    regConfirmPasswordVisible.value = !regConfirmPasswordVisible.value;
  }

  /// Sets up credentials for demonstration testing (demo mode only).
  /// If [isReturningUser] is true, configures terms acceptance and existing PIN '123456'.
  /// If [isAdminUser] is true, configures an Administrator account with PIN '123456'.
  void prepareDemoUser({
    required bool isReturningUser,
    bool isAdminUser = false,
  }) {
    isAdmin.value = isAdminUser;

    if (isAdminUser) {
      loginEmail.value = 'admin@resolva.ng';
      loginPassword.value = 'AdminResolva2026!';
      userFullName.value = 'Ibrahim Musa (Admin)';
      userEmail.value = 'admin@resolva.ng';
      acceptedTermsVersion.value = AppConstants.termsVersion;
      acceptedPrivacyVersion.value = AppConstants.privacyVersion;
      securityPin.value = '123456';
      isSessionUnlocked.value = false;
      intendedRoute = '/admin';
      return;
    }

    loginEmail.value = 'demo@resolva.ng';
    loginPassword.value = 'ResolvaPass2025!';
    userFullName.value = 'Demo User';
    userEmail.value = 'demo@resolva.ng';

    if (isReturningUser) {
      acceptedTermsVersion.value = AppConstants.termsVersion;
      acceptedPrivacyVersion.value = AppConstants.privacyVersion;
      securityPin.value = '123456';
      isSessionUnlocked.value = false;
    } else {
      acceptedTermsVersion.value = '';
      acceptedPrivacyVersion.value = '';
      securityPin.value = '';
      isSessionUnlocked.value = false;
    }
  }

  // ──────────────────── SIGN IN ────────────────────

  /// Signs in with email & password (Supabase) or simulates it (demo mode).
  Future<bool> login() async {
    if (loginEmail.value.isEmpty || loginPassword.value.isEmpty) return false;
    authError.value = '';
    authInfo.value = '';

    if (backendEnabled) {
      loginLoading.value = true;
      try {
        await AuthService.signInWithPassword(
          loginEmail.value.trim(),
          loginPassword.value,
        );
        return await _loadSessionFromBackend(recordLogin: true);
      } catch (e) {
        authError.value = AuthService.describeError(e);
        return false;
      } finally {
        loginPassword.value = '';
        loginLoading.value = false;
      }
    }

    loginLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 600));
    loginLoading.value = false;
    isLoggedIn.value = true;
    isSessionUnlocked.value = false; // session requires PIN verification if returning
    userEmail.value = loginEmail.value;

    // Automatically recognize admin email addresses
    if (userEmail.value.toLowerCase().contains('admin') ||
        userEmail.value.toLowerCase() == 'ibrahim.musa@resolva.ng') {
      isAdmin.value = true;
      userFullName.value = 'Ibrahim Musa (Admin)';
      if (acceptedTermsVersion.value.isEmpty) {
        acceptedTermsVersion.value = AppConstants.termsVersion;
        acceptedPrivacyVersion.value = AppConstants.privacyVersion;
      }
      if (securityPin.value.isEmpty) {
        securityPin.value = '123456';
      }
    }

    if (Get.isRegistered<AdminController>()) {
      Get.find<AdminController>().recordUserLogin(
        email: userEmail.value,
        fullName: userFullName.value,
        role: isAdmin.value ? UserRole.admin : UserRole.customer,
      );
    }

    return true;
  }

  /// Starts "Continue with Google". On web the page redirects to Google and
  /// the session is completed in [_onAuthStateChange] when the user returns.
  Future<void> signInWithGoogle() async {
    authError.value = '';
    authInfo.value = '';
    if (!backendEnabled) {
      authError.value =
          'Google sign-in is not configured yet. Connect Supabase to enable it.';
      return;
    }
    googleLoading.value = true;
    try {
      await AuthService.signInWithGoogle();
    } catch (e) {
      authError.value = AuthService.describeError(e);
      googleLoading.value = false;
    }
  }

  /// Sends a password reset email (Supabase mode).
  Future<bool> sendPasswordReset(String email) async {
    if (!backendEnabled) return true;
    try {
      await AuthService.sendPasswordReset(email.trim());
      return true;
    } catch (e) {
      authError.value = AuthService.describeError(e);
      return false;
    }
  }

  // ──────────────────── SIGN UP ────────────────────

  /// Registers a new account (Supabase) or simulates it (demo mode).
  ///
  /// In Supabase mode, if email confirmation is enabled the user is not
  /// signed in yet: this returns false and sets [authInfo].
  Future<bool> register() async {
    if (regFullName.value.isEmpty ||
        regEmail.value.isEmpty ||
        regPhone.value.isEmpty ||
        regPassword.value.isEmpty ||
        regPassword.value != regConfirmPassword.value ||
        !regAcceptTerms.value) {
      return false;
    }
    authError.value = '';
    authInfo.value = '';

    if (backendEnabled) {
      regLoading.value = true;
      try {
        final res = await AuthService.signUp(
          email: regEmail.value.trim(),
          password: regPassword.value,
          fullName: regFullName.value.trim(),
          phone: regPhone.value.trim(),
        );
        if (res.session == null) {
          authInfo.value =
              'Account created! Check ${regEmail.value.trim()} for a confirmation link, then sign in.';
          return false;
        }
        return await _loadSessionFromBackend(recordLogin: true);
      } catch (e) {
        authError.value = AuthService.describeError(e);
        return false;
      } finally {
        regPassword.value = '';
        regConfirmPassword.value = '';
        regLoading.value = false;
      }
    }

    regLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 600));
    regLoading.value = false;
    isLoggedIn.value = true;
    isSessionUnlocked.value = false;
    isAdmin.value = false;
    userFullName.value = regFullName.value;
    userEmail.value = regEmail.value;

    // A newly registered user has not completed policy acceptance or PIN setup
    acceptedTermsVersion.value = '';
    acceptedPrivacyVersion.value = '';
    securityPin.value = '';

    if (Get.isRegistered<AdminController>()) {
      Get.find<AdminController>().addUser(
        fullName: regFullName.value,
        email: regEmail.value,
        phone: regPhone.value,
        role: UserRole.customer,
        status: UserStatus.pendingOnboarding,
        hasPinConfigured: false,
      );
    }

    return true;
  }

  // ──────────────────── ONBOARDING ────────────────────

  /// Marks terms and privacy policy as accepted for the current versions.
  Future<void> acceptPolicies() async {
    if (backendEnabled) {
      try {
        await AuthService.acceptPolicies(
          AppConstants.termsVersion,
          AppConstants.privacyVersion,
        );
      } catch (_) {}
    }
    acceptedTermsVersion.value = AppConstants.termsVersion;
    acceptedPrivacyVersion.value = AppConstants.privacyVersion;
  }

  /// Configures a new 6-digit security PIN and unlocks the active session.
  Future<void> setSecurityPin(String pin) async {
    if (pin.length != 6) return;
    if (backendEnabled) {
      try {
        await AuthService.setSecurityPin(pin);
      } catch (_) {
        securityPin.value = pin;
      }
      pinConfigured.value = true;
    } else {
      securityPin.value = pin;
    }
    isSessionUnlocked.value = true;
  }

  /// Verifies the entered PIN (server-side in Supabase mode).
  Future<bool> verifyPin(String enteredPin) async {
    bool valid;
    if (backendEnabled) {
      try {
        valid = await AuthService.verifySecurityPin(enteredPin);
      } catch (_) {
        valid = securityPin.value.isNotEmpty && enteredPin == securityPin.value;
      }
    } else {
      valid = enteredPin == securityPin.value;
    }
    if (valid) {
      isSessionUnlocked.value = true;
    }
    return valid;
  }

  /// Resets the user's PIN during forgot-pin recovery.
  Future<void> resetPinForDemo() async {
    if (backendEnabled) {
      try {
        await AuthService.resetSecurityPin();
      } catch (_) {}
      pinConfigured.value = false;
    }
    securityPin.value = '';
    isSessionUnlocked.value = false;
  }

  /// Standard logout: clears active session and authentication.
  /// In demo mode the stored PIN and policy acceptance are preserved for the
  /// returning-user demonstration flow.
  void logout() {
    if (isLoggedIn.value && Get.isRegistered<AdminController>()) {
      Get.find<AdminController>().recordUserLogout(email: userEmail.value);
    }
    if (backendEnabled) {
      _clearSession();
      AuthService.signOut().catchError((_) {});
      return;
    }
    isLoggedIn.value = false;
    isSessionUnlocked.value = false;
    isAdmin.value = false;
    intendedRoute = '';
    loginPassword.value = '';
  }
}
