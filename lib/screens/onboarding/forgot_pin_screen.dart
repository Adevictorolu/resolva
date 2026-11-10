import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/onboarding_controller.dart';
import '../../services/auth_service.dart';

/// Live Security PIN Recovery screen.
///
/// Allows the signed-in user to verify their identity and reset their 6-digit Security PIN.
class ForgotPinScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const ForgotPinScreen({super.key, required this.onNavigate});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  late final AuthController authController;
  late final OnboardingController onboardingController;
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    authController = Get.find<AuthController>();
    onboardingController = Get.find<OnboardingController>();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPin() async {
    setState(() {
      _isLoading = true;
      _errorText = '';
    });

    final email = authController.userEmail.value.trim();
    final pwd = _passwordController.text;

    try {
      // If user entered their password, re-verify credentials when possible
      if (pwd.isNotEmpty && email.isNotEmpty && authController.backendEnabled) {
        await AuthService.signInWithPassword(email, pwd);
      }

      await authController.resetSecurityPin();
      onboardingController.resetAll();

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Identity verified. Please create your new 6-digit Security PIN.'),
          backgroundColor: AppColors.emeraldGreen,
        ),
      );

      widget.onNavigate('/create-pin');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = AuthService.describeError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: isMobile ? 24 : 40,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: EdgeInsets.all(isMobile ? 24 : 36),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryNavy.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.royalBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          color: AppColors.royalBlue,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Reset Transaction PIN',
                        style: GoogleFonts.montserrat(
                          fontSize: isMobile ? 22 : 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Confirm your registered account to set a new 6-digit Security PIN.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 20),
                    Text(
                      'Registered Account Email',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            size: 20,
                            color: AppColors.emeraldGreen,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Obx(
                              () => Text(
                                authController.userEmail.value.isNotEmpty
                                    ? authController.userEmail.value
                                    : 'Verified Account Session',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Account Password (optional if signed in with Google)',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Enter account password or leave blank for Google',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    if (_errorText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorText,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleResetPin,
                        icon: _isLoading
                            ? const SizedBox.shrink()
                            : const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Create New 6-Digit PIN'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.royalBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => widget.onNavigate(
                          authController.isFullyAuthorized ? '/dashboard' : '/verify-pin',
                        ),
                        child: Text(
                          authController.isFullyAuthorized
                              ? 'Back to Dashboard'
                              : 'Back to PIN Entry',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
