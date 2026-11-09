import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/onboarding_controller.dart';
import '../../widgets/shared/common_widgets.dart';
import '../../widgets/shared/numeric_keypad.dart';

/// Step 2 of Security PIN setup: Re-enter and verify the 6-digit PIN.
class ConfirmPinScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const ConfirmPinScreen({super.key, required this.onNavigate});

  @override
  State<ConfirmPinScreen> createState() => _ConfirmPinScreenState();
}

class _ConfirmPinScreenState extends State<ConfirmPinScreen> {
  String _pin = '';
  String _errorMessage = '';

  void _onDigit(String d) {
    if (_pin.length < 6) {
      setState(() {
        _errorMessage = '';
        _pin += d;
      });
      if (_pin.length == 6) {
        _handleConfirm();
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _errorMessage = '';
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _onClear() {
    if (_pin.isNotEmpty) {
      setState(() {
        _errorMessage = '';
        _pin = '';
      });
    }
  }

  void _handleConfirm() async {
    final onboardingController = Get.find<OnboardingController>();
    final expected = onboardingController.tempCreatedPin;

    if (_pin.length != 6) return;

    if (_pin == expected) {
      // PIN Setup Successful!
      final authController = Get.find<AuthController>();
      try {
        await authController.setSecurityPin(_pin);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Could not save your PIN. Please try again.';
          _pin = '';
        });
        return;
      }
      if (!mounted) return;
      onboardingController.resetAll();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Security PIN successfully configured!'),
          backgroundColor: AppColors.emeraldGreen,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate to appropriate role destination
      final destination = authController.getNextAuthRoute();
      widget.onNavigate(destination);
    } else {
      // Mismatch
      setState(() {
        _errorMessage = 'PINs do not match. Please try again.';
        _pin = '';
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
                    // Brand Logo
                    const ResolvaLogo(
                      size: 60,
                      useBoxedBadge: true,
                    ),
                    const SizedBox(height: 20),

                    // Headings
                    Text(
                      'Confirm Your Security PIN',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: isMobile ? 22 : 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Re-enter your six-digit PIN to confirm it matches.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Six-digit masked indicators
                    PinIndicators(
                      length: _pin.length,
                      hasError: _errorMessage.isNotEmpty,
                    ),
                    const SizedBox(height: 12),

                    // Inline error text
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 18),

                    const SizedBox(height: 8),

                    // Numeric Keypad
                    NumericKeypad(
                      onDigitPressed: _onDigit,
                      onDeletePressed: _onDelete,
                      onClearPressed: _onClear,
                      onSubmitPressed: _handleConfirm,
                    ),
                    const SizedBox(height: 28),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _pin.length == 6 ? _handleConfirm : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.royalBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          disabledBackgroundColor: AppColors.cardBorder,
                        ),
                        child: Text(
                          'Confirm Security PIN',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Back / Change PIN option
                    TextButton(
                      onPressed: () => widget.onNavigate('/create-pin'),
                      child: Text(
                        'Change Original PIN',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
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
