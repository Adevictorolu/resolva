import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/shared/app_navigation.dart';
import '../../widgets/shared/common_widgets.dart';

/// Modern Authentication Dialog Screen supporting Sign In, Sign Up, and Google OAuth.
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
  bool _googleHovered = false;

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

  void _showAuthFeedback() {
    if (!mounted) return;
    final error = controller.authError.value;
    final info = controller.authInfo.value;
    if (error.isEmpty && info.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.isNotEmpty ? error : info),
        backgroundColor:
            error.isNotEmpty ? AppColors.error : AppColors.emeraldGreen,
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
        MouseRegion(
          onEnter: (_) => setState(() => _googleHovered = true),
          onExit: (_) => setState(() => _googleHovered = false),
          child: Obx(
            () => GestureDetector(
              onTap: controller.googleLoading.value ? null : _handleGoogle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                decoration: BoxDecoration(
                  color: _googleHovered
                      ? AppColors.surfaceLight
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _googleHovered
                        ? AppColors.royalBlue.withValues(alpha: 0.45)
                        : AppColors.cardBorder,
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _googleHovered
                          ? AppColors.royalBlue.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: _googleHovered ? 16 : 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: controller.googleLoading.value
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/google_logo.png',
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isRegister
                                ? 'Continue with Google'
                                : 'Continue with Google',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.cardBorder)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'or continue with email',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.cardBorder)),
          ],
        ),
        const SizedBox(height: 22),
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
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobileView ? 16 : 24,
                  vertical: isMobileView ? 20 : 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.cardBorder,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryNavy.withValues(alpha: 0.07),
                          blurRadius: 32,
                          offset: const Offset(0, 14),
                        ),
                        BoxShadow(
                          color: AppColors.royalBlue.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Subtle top accent gradient bar
                          Container(
                            height: 5,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.royalBlue,
                                  AppColors.electricBlue,
                                  AppColors.emeraldGreen,
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              isMobileView ? 22 : 36,
                              isMobileView ? 26 : 34,
                              isMobileView ? 22 : 36,
                              isMobileView ? 26 : 36,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const ResolvaLogo(
                                  size: 56,
                                  useBoxedBadge: true,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _isRegister ? 'Create Your Account' : 'Welcome Back',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryNavy,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _isRegister
                                      ? 'Get instant access to examination e-pins & digital services'
                                      : 'Sign in to manage your orders, wallet & e-pins',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Modern Pill Mode Switcher
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBackground,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() => _isRegister = false),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 180),
                                            padding: const EdgeInsets.symmetric(vertical: 11),
                                            decoration: BoxDecoration(
                                              color: !_isRegister
                                                  ? AppColors.white
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(999),
                                              boxShadow: !_isRegister
                                                  ? [
                                                      BoxShadow(
                                                        color: Colors.black.withValues(alpha: 0.06),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Sign In',
                                              style: GoogleFonts.montserrat(
                                                fontSize: 13.5,
                                                fontWeight: !_isRegister
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
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
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 180),
                                            padding: const EdgeInsets.symmetric(vertical: 11),
                                            decoration: BoxDecoration(
                                              color: _isRegister
                                                  ? AppColors.white
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(999),
                                              boxShadow: _isRegister
                                                  ? [
                                                      BoxShadow(
                                                        color: Colors.black.withValues(alpha: 0.06),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Create Account',
                                              style: GoogleFonts.montserrat(
                                                fontSize: 13.5,
                                                fontWeight: _isRegister
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
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
                                const SizedBox(height: 24),

                                // Google OAuth Button
                                _buildGoogleButton(),

                                // Active Form
                                if (!_isRegister)
                                  _buildLoginForm()
                                else
                                  _buildRegisterForm(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'adebayo.oluwaseun@gmail.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: (v) =>
                v == null || !v.contains('@') ? 'Enter a valid email address' : null,
          ),
          const SizedBox(height: 18),
          Text(
            'Password',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => TextFormField(
              controller: _loginPasswordController,
              obscureText: !controller.loginPasswordVisible.value,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
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
              validator: (v) =>
                  v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
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
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
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
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sign In to Account',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
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
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _regNameController,
            decoration: const InputDecoration(
              hintText: 'Adebayo Oluwaseun',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter your full name' : null,
          ),
          const SizedBox(height: 16),
          Text(
            'Email Address',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _regEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'adebayo.oluwaseun@gmail.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: (v) =>
                v == null || !v.contains('@') ? 'Enter a valid email address' : null,
          ),
          const SizedBox(height: 16),
          Text(
            'Phone Number (WhatsApp)',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryNavy,
            ),
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
              hintText: '08034567890',
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
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => TextFormField(
              controller: _regPasswordController,
              obscureText: !controller.regPasswordVisible.value,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
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
              validator: (v) =>
                  v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Confirm Password',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => TextFormField(
              controller: _regConfirmPasswordController,
              obscureText: !controller.regConfirmPasswordVisible.value,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Obx(
              () => ElevatedButton(
                onPressed: controller.regLoading.value ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Create Account',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
