import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/shared/app_navigation.dart';
import '../../widgets/shared/app_footer.dart';
import '../../widgets/shared/common_widgets.dart';

/// Authentication Screen supporting both Sign In and Sign Up tabs with demo pre-fill options.
class AuthScreen extends StatefulWidget {
  final Function(String) onNavigate;
  final bool initialRegister;

  const AuthScreen({
    super.key,
    required this.onNavigate,
    this.initialRegister = false,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final AuthController controller;
  final _loginFormKey = GlobalKey<FormState>();
  final _regFormKey = GlobalKey<FormState>();

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();

  late bool _isRegister;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AuthController>();
    _isRegister = widget.initialRegister;

    if (controller.loginEmail.value.isNotEmpty) {
      _loginEmailController.text = controller.loginEmail.value;
    }
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPhoneController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    super.dispose();
  }

  void _fillReturningDemoUser() {
    setState(() {
      _isRegister = false;
      controller.prepareDemoUser(isReturningUser: true);
      _loginEmailController.text = controller.loginEmail.value;
      _loginPasswordController.text = controller.loginPassword.value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Loaded Returning Demo User (Configured PIN: 123456)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _fillNewDemoUser() {
    setState(() {
      _isRegister = false;
      controller.prepareDemoUser(isReturningUser: false);
      _loginEmailController.text = controller.loginEmail.value;
      _loginPasswordController.text = controller.loginPassword.value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Loaded New Demo User (Requires Policy Acceptance & PIN Setup)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _fillAdminDemoUser() {
    setState(() {
      _isRegister = false;
      controller.prepareDemoUser(isReturningUser: true, isAdminUser: true);
      _loginEmailController.text = controller.loginEmail.value;
      _loginPasswordController.text = controller.loginPassword.value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Loaded Admin Account (PIN: 123456 • Opens Admin Dashboard)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAuthFeedback() {
    if (!mounted) return;
    final error = controller.authError.value;
    final info = controller.authInfo.value;
    if (error.isEmpty && info.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.isNotEmpty ? error : info),
        backgroundColor: error.isNotEmpty ? AppColors.error : AppColors.emeraldGreen,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _handleLogin() async {
    if (_loginFormKey.currentState!.validate()) {
      controller.loginEmail.value = _loginEmailController.text.trim();
      controller.loginPassword.value = _loginPasswordController.text;
      final ok = await controller.login();
      if (ok && mounted) {
        final nextRoute = controller.getNextAuthRoute();
        widget.onNavigate(nextRoute);
      } else {
        _showAuthFeedback();
      }
    }
  }

  void _handleRegister() async {
    if (_regFormKey.currentState!.validate()) {
      controller.regFullName.value = _regNameController.text.trim();
      controller.regEmail.value = _regEmailController.text.trim();
      controller.regPhone.value = _regPhoneController.text.trim();
      controller.regPassword.value = _regPasswordController.text;
      controller.regConfirmPassword.value = _regConfirmPasswordController.text;
      controller.regAcceptTerms.value = true;

      final ok = await controller.register();
      if (ok && mounted) {
        final nextRoute = controller.getNextAuthRoute();
        widget.onNavigate(nextRoute);
      } else {
        if (controller.authInfo.value.isNotEmpty && mounted) {
          // Email confirmation required: switch to Sign In with the email pre-filled.
          setState(() {
            _isRegister = false;
            _loginEmailController.text = controller.regEmail.value;
          });
        }
        _showAuthFeedback();
      }
    }
  }

  void _handleGoogle() async {
    await controller.signInWithGoogle();
    _showAuthFeedback();
  }

  Widget _buildGoogleButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Obx(
            () => OutlinedButton(
              onPressed: controller.googleLoading.value ? null : _handleGoogle,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.cardBorder),
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.primaryNavy,
              ),
              child: controller.googleLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset(
                            'assets/images/google_logo.png',
                            width: 22,
                            height: 22,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isRegister ? 'Sign up with Google' : 'Continue with Google',
                          style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.cardBorder)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or use your email',
                style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.cardBorder)),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobileView = isMobile(width);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: ResolvaDrawer(onNavigate: widget.onNavigate),
      body: Column(
        children: [
          ResolvaAppBar(currentIndex: -1, onNavigate: widget.onNavigate),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobileView ? 16 : 24,
                      vertical: isMobileView ? 24 : 64,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Container(
                          padding: EdgeInsets.all(isMobileView ? 20 : 36),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.cardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Logo
                              const ResolvaLogo(
                                size: 64,
                                useBoxedBadge: true,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _isRegister ? 'Create an Account' : 'Welcome Back',
                                style: GoogleFonts.montserrat(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isRegister
                                    ? 'Join thousands accessing exam PINs & digital services'
                                    : 'Sign in to access your orders, e-pins, and account',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Mode switcher tabs
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBackground,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() => _isRegister = false),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: !_isRegister ? AppColors.white : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: !_isRegister
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.05),
                                                      blurRadius: 4,
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Sign In',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 14,
                                              fontWeight: !_isRegister
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: !_isRegister
                                                  ? AppColors.royalBlue
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() => _isRegister = true),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: _isRegister ? AppColors.white : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: _isRegister
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.05),
                                                      blurRadius: 4,
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Register',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 14,
                                              fontWeight: _isRegister
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: _isRegister
                                                  ? AppColors.royalBlue
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Quick Fill Demo Options (demo mode only — hidden once Supabase is connected)
                              if (!controller.backendEnabled) Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Column(
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.flash_on_rounded, size: 16, color: AppColors.accentGold),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Demo Test Accounts',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primaryNavy,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: _fillNewDemoUser,
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              textStyle: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600),
                                            ),
                                            child: const Text('New User Flow'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: _fillReturningDemoUser,
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              textStyle: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600),
                                            ),
                                            child: const Text('Returning User (PIN)'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: _fillAdminDemoUser,
                                        icon: const Icon(Icons.admin_panel_settings_rounded, size: 15),
                                        label: const Text('Admin Dashboard Account (PIN: 123456)'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          textStyle: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!controller.backendEnabled) const SizedBox(height: 24),

                              // Google sign-in / sign-up
                              _buildGoogleButton(),

                              // Forms
                              if (!_isRegister) _buildLoginForm() else _buildRegisterForm(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  ResolvaFooter(onNavigate: widget.onNavigate),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email Address',
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'yourname@example.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 18),
          Text(
            'Password',
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Obx(
            () => TextFormField(
              controller: _loginPasswordController,
              obscureText: !controller.loginPasswordVisible.value,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.loginPasswordVisible.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: controller.toggleLoginPasswordVisibility,
                ),
              ),
              validator: (v) => v == null || v.length < 6 ? 'Password is too short' : null,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(
                    () => Checkbox(
                      value: controller.rememberMe.value,
                      onChanged: (v) => controller.rememberMe.value = v ?? false,
                      activeColor: AppColors.royalBlue,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Remember me',
                    style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => widget.onNavigate('/forgot-password'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot password?',
                  style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Obx(
              () => ElevatedButton(
                onPressed: controller.loginLoading.value ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: controller.loginLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Sign In to Account'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _regFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Full Name',
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _regNameController,
            decoration: const InputDecoration(
              hintText: 'John Doe',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Enter full name' : null,
          ),
          const SizedBox(height: 16),
          Text(
            'Email Address',
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _regEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'john@example.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 16),
          Text(
            'Phone Number (WhatsApp)',
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _regPhoneController,
            keyboardType: TextInputType.number,
            maxLength: 11,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            decoration: const InputDecoration(
              hintText: '08012345678',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
              counterText: '',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter phone number';
              if (v.length != 11) return 'Phone number must be 11 digits';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Password',
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Obx(
            () => TextFormField(
              controller: _regPasswordController,
              obscureText: !controller.regPasswordVisible.value,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.regPasswordVisible.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: controller.toggleRegPasswordVisibility,
                ),
              ),
              validator: (v) => v == null || v.length < 6 ? 'Password is too short' : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Confirm Password',
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Obx(
            () => TextFormField(
              controller: _regConfirmPasswordController,
              obscureText: !controller.regConfirmPasswordVisible.value,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.regConfirmPasswordVisible.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: controller.toggleRegConfirmPasswordVisibility,
                ),
              ),
              validator: (v) {
                if (v != _regPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 18),

          // Notice of policy acceptance on next step
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 18, color: AppColors.royalBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Terms of Service & Privacy Policy review will be requested upon account creation.',
                    style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: Obx(
              () => ElevatedButton(
                onPressed: controller.regLoading.value ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: controller.regLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Create Account'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
