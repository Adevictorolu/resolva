import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/shared/common_widgets.dart';

/// Mandatory Terms of Service & Privacy Policy acceptance screen.
///
/// Triggered immediately after login/registration if the user has not accepted
/// the current policy versions.
class PolicyAcceptanceScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const PolicyAcceptanceScreen({super.key, required this.onNavigate});

  @override
  State<PolicyAcceptanceScreen> createState() => _PolicyAcceptanceScreenState();
}

class _PolicyAcceptanceScreenState extends State<PolicyAcceptanceScreen> {
  late final AuthController authController;
  bool _isAgreed = false; // Must NOT be preselected
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    authController = Get.find<AuthController>();
  }

  void _handleAccept() async {
    if (!_isAgreed) return;

    setState(() => _isSubmitting = true);
    try {
      await authController.acceptPolicies();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your acceptance. Please try again.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // Continue to next onboarding step (Create PIN) or target
    widget.onNavigate(authController.getNextAuthRoute());
  }

  void _handleDecline() {
    authController.logout();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Access declined. You must accept our terms to access RESOLVA services.'),
        backgroundColor: AppColors.primaryNavy,
      ),
    );
    widget.onNavigate('/login');
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Terms of Service (v${AppConstants.termsVersion})',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _dialogParagraph(
                            '1. Agreement to Terms',
                            'By using RESOLVA, you agree to comply with all applicable laws and standards. All digital tokens and exam pins issued are genuine and authenticated through appropriate issuing bodies.',
                          ),
                          _dialogParagraph(
                            '2. Pin Delivery & Redemptions',
                            'Pintokens have finite usage limits set by the exam boards. Once an authentic pin is issued and revealed, it is considered consumed and delivered.',
                          ),
                          _dialogParagraph(
                            '3. User Security Obligation',
                            'You agree to create and protect a confidential 6-digit Security PIN to safeguard your account and service operations.',
                          ),
                          _dialogParagraph(
                            '4. Refund Assurances',
                            'Unfulfilled tokens or system delivery errors are covered by our 100% money-back guarantee within the guaranteed SLA period.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('I Understand'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Privacy Policy (v${AppConstants.privacyVersion})',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _dialogParagraph(
                            '1. Data We Process',
                            'We securely store your contact details to deliver purchased result-checking pins, order receipts, and social media fulfillment updates.',
                          ),
                          _dialogParagraph(
                            '2. Payment Security',
                            'We do not store your debit card details or banking PINs. All financial interactions are routed through licensed, PCI-DSS compliant Nigerian payment processors.',
                          ),
                          _dialogParagraph(
                            '3. Session Protection',
                            'Local state is maintained to authenticate your device session, verify legal compliance, and validate your Security PIN.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('I Understand'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogParagraph(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
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
              horizontal: isMobile ? 16 : 24,
              vertical: isMobile ? 20 : 48,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Container(
                padding: EdgeInsets.all(isMobile ? 18 : 40),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Logo & Welcome
                    Center(
                      child: Column(
                        children: [
                          const ResolvaLogo(
                            size: 64,
                            useBoxedBadge: true,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Welcome to RESOLVA',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: isMobile ? 22 : 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Before accessing our services, please review and accept our customer agreements.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 24),

                    // Terms of Service card
                    _buildAgreementCard(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      version: 'v${AppConstants.termsVersion}',
                      desc:
                          'Governs the purchase of examination e-pins, social media visibility services, and business registration facilitation.',
                      buttonLabel: 'Read Full Terms',
                      onRead: _showTermsDialog,
                    ),
                    const SizedBox(height: 16),

                    // Privacy Policy card
                    _buildAgreementCard(
                      icon: Icons.security_outlined,
                      title: 'Privacy Policy',
                      version: 'v${AppConstants.privacyVersion}',
                      desc:
                          'Explains how we collect, store, and safeguard your account profile, delivery emails, and transaction history.',
                      buttonLabel: 'Read Full Privacy Policy',
                      onRead: _showPrivacyDialog,
                    ),
                    const SizedBox(height: 24),

                    // Checkbox agreement (NOT preselected)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isAgreed
                            ? AppColors.royalBlue.withValues(alpha: 0.05)
                            : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isAgreed
                              ? AppColors.royalBlue.withValues(alpha: 0.3)
                              : AppColors.cardBorder,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _isAgreed,
                            activeColor: AppColors.royalBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setState(() => _isAgreed = val ?? false);
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isAgreed = !_isAgreed),
                              child: Text(
                                'I have reviewed and agree to the RESOLVA Terms of Service (v${AppConstants.termsVersion}) and Privacy Policy (v${AppConstants.privacyVersion}).',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isAgreed && !_isSubmitting ? _handleAccept : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.royalBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          disabledBackgroundColor: AppColors.cardBorder,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Accept and Continue',
                                style: GoogleFonts.montserrat(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Decline & Logout option
                    Center(
                      child: TextButton(
                        onPressed: _handleDecline,
                        child: Text(
                          'Decline and Logout',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
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

  Widget _buildAgreementCard({
    required IconData icon,
    required String title,
    required String version,
    required String desc,
    required String buttonLabel,
    required VoidCallback onRead,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.royalBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.royalBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            version,
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.royalBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: onRead,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        buttonLabel,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.royalBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
