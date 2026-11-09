import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/onboarding_controller.dart';

/// Demonstration PIN Recovery screen.
///
/// Simulates secure identity verification via one-time recovery code before allowing
/// the user to reset their Security PIN.
class ForgotPinScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const ForgotPinScreen({super.key, required this.onNavigate});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  late final AuthController authController;
  late final OnboardingController onboardingController;
  final _codeController = TextEditingController();
  bool _codeSent = false;
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
    _codeController.dispose();
    super.dispose();
  }

  void _sendRecoveryCode() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      _isLoading = false;
      _codeSent = true;
      _errorText = '';
      _codeController.text = onboardingController.demoRecoveryCode; // Convenience auto-fill for demo
    });
  }

  void _verifyRecoveryCode() async {
    final entered = _codeController.text.trim();
    if (entered != onboardingController.demoRecoveryCode) {
      setState(() {
        _errorText = 'Invalid recovery code. Please check and retry.';
      });
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);

    // Identity verified! Reset PIN and redirect to Create Security PIN step
    await authController.resetPinForDemo();
    onboardingController.resetAll();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Identity verified. Please create your new Security PIN.'),
        backgroundColor: AppColors.emeraldGreen,
      ),
    );

    widget.onNavigate('/create-pin');
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Icon
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
                        'Reset Security PIN',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 22 : 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Verify your registered email address to safely reset your six-digit PIN.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 20),

                    // Registered email display
                    Text(
                      'Registered Email Destination',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
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
                          const Icon(Icons.email_outlined, size: 20, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Obx(
                              () => Text(
                                authController.userEmail.value.isNotEmpty
                                    ? authController.userEmail.value
                                    : 'demo@resolva.ng',
                                style: GoogleFonts.inter(
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
                    const SizedBox(height: 20),

                    if (!_codeSent) ...[
                      // Action to send demo code
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendRecoveryCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.royalBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Send Recovery Code'),
                        ),
                      ),
                    ] else ...[
                      // Demo Notice with Code
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.mark_email_read_outlined,
                                color: AppColors.emeraldGreen, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Demo Code sent! Your verification code is: ${onboardingController.demoRecoveryCode}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Enter 6-Digit Recovery Code',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          hintText: '849201',
                          prefixIcon: Icon(Icons.pin_outlined, size: 20),
                          counterText: '',
                        ),
                      ),
                      if (_errorText.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          _errorText,
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.error),
                        ),
                      ],
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyRecoveryCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.royalBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Verify Code and Set New PIN'),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => widget.onNavigate('/verify-pin'),
                        child: Text(
                          'Back to PIN Entry',
                          style: GoogleFonts.inter(
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
