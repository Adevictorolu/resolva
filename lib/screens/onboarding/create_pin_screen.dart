import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../controllers/onboarding_controller.dart';
import '../../widgets/shared/common_widgets.dart';
import '../../widgets/shared/numeric_keypad.dart';

/// Step 1 of Security PIN setup: Enter the initial 6-digit PIN.
class CreatePinScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const CreatePinScreen({super.key, required this.onNavigate});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  String _pin = '';

  void _onDigit(String d) {
    if (_pin.length < 6) {
      setState(() => _pin += d);
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  void _onClear() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = '');
    }
  }

  void _handleContinue() {
    if (_pin.length == 6) {
      final onboardingController = Get.find<OnboardingController>();
      onboardingController.tempCreatedPin = _pin;
      widget.onNavigate('/confirm-pin');
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
                      'Create Your Security PIN',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: isMobile ? 22 : 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a secure PIN to protect access to your RESOLVA services.',
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
                      hasError: false,
                    ),
                    const SizedBox(height: 28),

                    // Numeric Keypad
                    NumericKeypad(
                      onDigitPressed: _onDigit,
                      onDeletePressed: _onDelete,
                      onClearPressed: _onClear,
                      onSubmitPressed: _handleContinue,
                    ),
                    const SizedBox(height: 28),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _pin.length == 6 ? _handleContinue : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.royalBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          disabledBackgroundColor: AppColors.cardBorder,
                        ),
                        child: Text(
                          'Continue',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
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
