import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/shared/app_navigation.dart';
import '../../widgets/shared/app_footer.dart';

/// Full Terms of Service screen.
class TermsOfServiceScreen extends StatelessWidget {
  final Function(String) onNavigate;

  const TermsOfServiceScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobileView = isMobile(width);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: ResolvaDrawer(onNavigate: onNavigate),
      body: Column(
        children: [
          ResolvaAppBar(currentIndex: -1, onNavigate: onNavigate),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(
                    title: 'Terms of Service',
                    version: AppConstants.termsVersion,
                    lastUpdated: 'October 20, 2026',
                    isMobile: isMobileView,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: isMobileView ? 32 : 48,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 860),
                        child: Container(
                          padding: EdgeInsets.all(isMobileView ? 24 : 40),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildNotice(),
                              const SizedBox(height: 32),
                              _buildLegalSection(
                                '1. Acceptance of Terms',
                                'By accessing or using RESOLVA services, you agree to be bound by these Terms of Service and all applicable Nigerian laws and regulations. If you do not agree with any of these terms, you are prohibited from using or accessing this site.',
                              ),
                              _buildLegalSection(
                                '2. Examination E-Pins & Digital Tokens',
                                'RESOLVA provides automated distribution of genuine examination scratch card pins and tokens (WAEC, NECO, NABTEB, JAMB). All delivered pins are generated through verified channels. Users agree that each scratch card token possesses a finite usage limit strictly determined by the examination body (e.g., up to 5 result checks). Once an authentic pin is issued and revealed, it is considered consumed.',
                              ),
                              _buildLegalSection(
                                '3. Social Media Services',
                                'Our social media promotion and engagement services are provided for marketing enhancement purposes. RESOLVA never requests account passwords. Users warrant that their submitted target profiles and post URLs comply with community standards and applicable platform terms. Delivery timelines are estimates and may vary based on platform algorithm updates.',
                              ),
                              _buildLegalSection(
                                '4. CAC Facilitation Services',
                                'Business registration facilitation is carried out through accredited Corporate Affairs Commission (CAC) filing agents. Clients are solely responsible for ensuring the accuracy and veracity of proprietor/director information and government identification documents supplied.',
                              ),
                              _buildLegalSection(
                                '5. Security PIN & Account Responsibility',
                                'Users are required to create and safeguard a six-digit Security PIN. You are solely responsible for all activities and transactions executed under your account credentials and PIN. Any unauthorized activity should be reported immediately to RESOLVA support.',
                              ),
                              _buildLegalSection(
                                '6. Refund & Cancellation Policy',
                                'Refunds are automatically issued if a digital token cannot be verified or delivered due to platform system failure within our guaranteed service level timeline. Services that have been successfully generated, delivered, or activated are non-refundable.',
                              ),
                              _buildLegalSection(
                                '7. Modifications to Agreement',
                                'RESOLVA reserves the right to revise these terms at any time. When terms are updated, users will be required to review and accept the latest version before accessing protected platform services.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  ResolvaFooter(onNavigate: onNavigate),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({
    required String title,
    required String version,
    required String lastUpdated,
    required bool isMobile,
  }) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryNavy,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 36 : 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: isMobile ? 28 : 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version $version • Effective Date: $lastUpdated',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.royalBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.royalBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Notice: This is a placeholder legal agreement for the RESOLVA frontend demonstration. Prior to production launch, these terms must be formally reviewed and ratified by qualified legal counsel.',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: AppColors.primaryNavy,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full Privacy Policy screen.
class PrivacyPolicyScreen extends StatelessWidget {
  final Function(String) onNavigate;

  const PrivacyPolicyScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobileView = isMobile(width);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: ResolvaDrawer(onNavigate: onNavigate),
      body: Column(
        children: [
          ResolvaAppBar(currentIndex: -1, onNavigate: onNavigate),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(
                    title: 'Privacy Policy',
                    version: AppConstants.privacyVersion,
                    lastUpdated: 'October 20, 2026',
                    isMobile: isMobileView,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: isMobileView ? 32 : 48,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 860),
                        child: Container(
                          padding: EdgeInsets.all(isMobileView ? 24 : 40),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildNotice(),
                              const SizedBox(height: 32),
                              _buildLegalSection(
                                '1. Information We Collect',
                                'We collect basic user profile information including your full name, email address, phone number (for WhatsApp token dispatch), and service destination URLs. We do not store or process debit card numbers or bank PINs on our servers; payments are processed securely through licensed payment gateways.',
                              ),
                              _buildLegalSection(
                                '2. Purpose of Data Processing',
                                'Your information is used strictly to fulfill purchase requests, deliver examination tokens, coordinate social media orders, dispatch important transaction receipts, and enable secure account recovery via Security PIN and email.',
                              ),
                              _buildLegalSection(
                                '3. Data Retention & Security Controls',
                                'We implement encryption and access controls to safeguard your transaction records and purchased tokens. You can request account deletion or data exports by contacting our dedicated support desk.',
                              ),
                              _buildLegalSection(
                                '4. Third-Party Sharing',
                                'RESOLVA does not sell or lease customer information to third-party advertisers. Information is only shared with accredited filing agents (for CAC registrations) or compliance authorities as strictly mandated by Nigerian jurisprudence.',
                              ),
                              _buildLegalSection(
                                '5. Cookies & Local Session Storage',
                                'Our web and mobile interfaces use local storage mechanisms to remember your authenticated session, legal agreement acceptances, and security PIN verification state across application sessions.',
                              ),
                              _buildLegalSection(
                                '6. Contact the Data Protection Officer',
                                'If you have inquiries regarding how your data is handled or wish to exercise your data rights, contact privacy@resolva.ng.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  ResolvaFooter(onNavigate: onNavigate),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({
    required String title,
    required String version,
    required String lastUpdated,
    required bool isMobile,
  }) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryNavy,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 36 : 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: isMobile ? 28 : 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version $version • Effective Date: $lastUpdated',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.emeraldGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.emeraldGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Notice: This placeholder privacy policy is provided for frontend demonstration. Real production deployment requires verified compliance with the Nigeria Data Protection Act (NDPA).',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: AppColors.primaryNavy,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
