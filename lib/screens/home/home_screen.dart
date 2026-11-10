import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/shared/app_navigation.dart';
import '../../widgets/shared/app_footer.dart';
import '../../widgets/shared/common_widgets.dart';
import 'package:google_fonts/google_fonts.dart';

/// RESOLVA Homepage — hero, services, how it works, why choose us, FAQ, CTA.
class HomeScreen extends StatelessWidget {
  final Function(String) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  static final GlobalKey servicesKey = GlobalKey();
  static final GlobalKey howItWorksKey = GlobalKey();

  static void scrollToSection(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobileView = isMobile(width);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: ResolvaDrawer(onNavigate: onNavigate),
      body: Column(
        children: [
          ResolvaAppBar(currentIndex: 0, onNavigate: onNavigate),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _HeroSection(onNavigate: onNavigate, isMobile: isMobileView),
                  Container(
                    key: servicesKey,
                    child: _ServicesSection(
                      onNavigate: onNavigate,
                      isMobile: isMobileView,
                    ),
                  ),
                  Container(
                    key: howItWorksKey,
                    child: _HowItWorksSection(isMobile: isMobileView),
                  ),
                  _WhyChooseSection(isMobile: isMobileView),
                  _FaqPreviewSection(isMobile: isMobileView),
                  _CtaSection(onNavigate: onNavigate, isMobile: isMobileView),
                  ResolvaFooter(onNavigate: onNavigate),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────── HERO ────────────────────

class _HeroSection extends StatelessWidget {
  final Function(String) onNavigate;
  final bool isMobile;

  const _HeroSection({required this.onNavigate, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth + 48),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: isMobile ? 48 : 80,
            ),
            child: isMobile ? _buildMobileHero() : _buildDesktopHero(),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHero() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: _buildHeroContent(),
        ),
        const SizedBox(width: 48),
        Expanded(
          flex: 4,
          child: _buildHeroVisual(),
        ),
      ],
    );
  }

  Widget _buildMobileHero() {
    return Column(
      children: [
        _buildHeroContent(),
        const SizedBox(height: 40),
        _buildHeroVisual(),
      ],
    );
  }

  Widget _buildHeroContent() {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.emeraldGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Digital Services Platform',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Everything You Need.\nAll in One Place.',
          style: GoogleFonts.montserrat(
            fontSize: isMobile ? 36 : 52,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
            height: 1.1,
            letterSpacing: -1.5,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 20),
        Text(
          'Get your examination e-pins, explore social media growth services, and discover convenient digital solutions with RESOLVA.',
          style: GoogleFonts.montserrat(
            fontSize: isMobile ? 15 : 17,
            color: AppColors.white.withValues(alpha: 0.8),
            height: 1.6,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () => onNavigate('/#services'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.primaryNavy,
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.2),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 28,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Explore Services', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
            OutlinedButton(
              onPressed: () => onNavigate('/register'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: BorderSide(color: AppColors.white.withValues(alpha: 0.45), width: 1.5),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 28,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Get Started', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    const Icon(Icons.rocket_launch_rounded, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroVisual() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          _buildMiniServiceCard(
            Icons.school_rounded,
            'Examination E-Pins',
            'WAEC • NECO • NABTEB • JAMB',
            AppColors.royalBlue,
            const [
              'assets/images/waec_logo.png',
              'assets/images/neco_logo.png',
              'assets/images/nabteb_logo.png',
              'assets/images/jamb_logo.png',
            ],
          ),
          const SizedBox(height: 12),
          _buildMiniServiceCard(
            Icons.trending_up_rounded,
            'Social Media Services',
            'Instagram • TikTok • YouTube • X',
            AppColors.emeraldGreen,
            const [
              'assets/images/instagram_logo.png',
              'assets/images/tiktok_logo.png',
              'assets/images/youtube_logo.png',
              'assets/images/x_logo.png',
            ],
          ),
          const SizedBox(height: 12),
          _buildMiniServiceCard(
            Icons.domain_verification_rounded,
            'CAC Registration',
            'Coming Soon',
            AppColors.warning,
            const [],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniServiceCard(
    IconData icon,
    String title,
    String sub,
    Color color,
    List<String> logoAssets,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: AppColors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          if (logoAssets.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: logoAssets.take(3).map((asset) {
                return Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(asset, fit: BoxFit.contain),
                  ),
                );
              }).toList(),
            )
          else
            Icon(Icons.chevron_right_rounded, color: AppColors.white.withValues(alpha: 0.4), size: 20),
        ],
      ),
    );
  }
}

// ──────────────────── SERVICES ────────────────────

class _ServicesSection extends StatelessWidget {
  final Function(String) onNavigate;
  final bool isMobile;

  const _ServicesSection({required this.onNavigate, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      width: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth + 48),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: isMobile ? 48 : 80,
            ),
            child: Column(
              children: [
                const SectionHeading(
                  title: 'Our Services',
                  subtitle: 'Explore the digital products and services available on RESOLVA.',
                ),
                const SizedBox(height: 48),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 700) {
                      return Column(
                        children: _buildCards(),
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildCards()
                          .map((c) => Expanded(child: c))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCards() {
    return [
      Padding(
        padding: const EdgeInsets.all(8),
        child: ServiceCard(
          icon: Icons.school_rounded,
          iconColor: AppColors.royalBlue,
          title: 'Examination E-Pins',
          description: 'Find examination pins and result-checking scratch cards for your academic needs.',
          tags: const ['WAEC', 'NECO', 'NABTEB', 'JAMB'],
          tagLogos: const {
            'WAEC': 'assets/images/waec_logo.png',
            'NECO': 'assets/images/neco_logo.png',
            'NABTEB': 'assets/images/nabteb_logo.png',
            'JAMB': 'assets/images/jamb_logo.png',
          },
          buttonText: 'Explore E-Pins',
          onTap: () => onNavigate('/exam-pins'),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8),
        child: ServiceCard(
          icon: Icons.trending_up_rounded,
          iconColor: AppColors.emeraldGreen,
          title: 'Social Media Services',
          description: 'Explore high-retention engagement services for creators, brands, and businesses.',
          tags: const ['Instagram', 'TikTok', 'Facebook', 'YouTube', 'X'],
          tagLogos: const {
            'Instagram': 'assets/images/instagram_logo.png',
            'TikTok': 'assets/images/tiktok_logo.png',
            'Facebook': 'assets/images/facebook_logo.png',
            'YouTube': 'assets/images/youtube_logo.png',
            'X': 'assets/images/x_logo.png',
          },
          buttonText: 'Explore Services',
          onTap: () => onNavigate('/social-media'),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8),
        child: ServiceCard(
          icon: Icons.domain_verification_rounded,
          iconColor: AppColors.warning,
          title: 'CAC Registration',
          description: 'Business registration services are coming soon to RESOLVA.',
          tags: const ['Business Name', 'Limited Company'],
          buttonText: 'Coming Soon',
          isComingSoon: true,
        ),
      ),
    ];
  }
}

// ──────────────────── HOW IT WORKS ────────────────────

class _HowItWorksSection extends StatelessWidget {
  final bool isMobile;

  const _HowItWorksSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepData(Icons.search_rounded, 'Browse Services', 'Explore our examination e-pins, social media services, and upcoming offerings.'),
      _StepData(Icons.shopping_cart_rounded, 'Place Your Order', 'Select the product or service you need and complete the order form.'),
      _StepData(Icons.payment_rounded, 'Make Payment', 'Pay securely using your preferred payment method.'),
      _StepData(Icons.check_circle_rounded, 'Get Delivered', 'Receive your e-pin or service delivery directly to your dashboard.'),
    ];

    return Container(
      color: AppColors.background,
      width: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth + 48),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: isMobile ? 48 : 80,
            ),
            child: Column(
              children: [
                const SectionHeading(
                  title: 'How It Works',
                  subtitle: 'Get started with RESOLVA in four simple steps.',
                ),
                const SizedBox(height: 48),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 700) {
                      return Column(
                        children: steps.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildStep(e.key + 1, e.value),
                        )).toList(),
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: steps.asMap().entries.map((e) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildStep(e.key + 1, e.value),
                        ),
                      )).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int number, _StepData step) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              '$number',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Icon(step.icon, size: 28, color: AppColors.royalBlue),
        const SizedBox(height: 12),
        Text(
          step.title,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          step.description,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StepData {
  final IconData icon;
  final String title;
  final String description;
  const _StepData(this.icon, this.title, this.description);
}

// ──────────────────── WHY CHOOSE ────────────────────

class _WhyChooseSection extends StatelessWidget {
  final bool isMobile;

  const _WhyChooseSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final reasons = [
      _ReasonData(Icons.verified_rounded, 'Trusted Products', 'All examination e-pins are sourced from authorised channels.'),
      _ReasonData(Icons.flash_on_rounded, 'Instant Delivery', 'Receive your products quickly after payment confirmation.'),
      _ReasonData(Icons.support_agent_rounded, 'Customer Support', 'Get help whenever you need it from our support team.'),
      _ReasonData(Icons.lock_rounded, 'Secure Platform', 'Your information and transactions are handled securely.'),
      _ReasonData(Icons.devices_rounded, 'Access Anywhere', 'Use RESOLVA on your phone, tablet, or computer.'),
      _ReasonData(Icons.price_check_rounded, 'Competitive Pricing', 'Get fair, transparent pricing across all services.'),
    ];

    return Container(
      color: AppColors.white,
      width: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth + 48),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: isMobile ? 48 : 80,
            ),
            child: Column(
              children: [
                const SectionHeading(
                  title: 'Why Choose RESOLVA?',
                  subtitle: 'A platform built around convenience, trust, and quality.',
                ),
                const SizedBox(height: 48),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossCount = constraints.maxWidth < 600 ? 1 : (constraints.maxWidth < 900 ? 2 : 3);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        mainAxisExtent: crossCount == 1 ? 165 : 190,
                      ),
                      itemCount: reasons.length,
                      itemBuilder: (context, index) => _buildReasonCard(reasons[index]),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReasonCard(_ReasonData reason) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(reason.icon, color: AppColors.royalBlue, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            reason.title,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              reason.description,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonData {
  final IconData icon;
  final String title;
  final String description;
  const _ReasonData(this.icon, this.title, this.description);
}

// ──────────────────── FAQ PREVIEW ────────────────────

class _FaqPreviewSection extends StatelessWidget {
  final bool isMobile;

  const _FaqPreviewSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      ('How do I purchase an examination e-pin?',
       'Browse our Examination E-Pins section, select the product you need, choose the quantity, and proceed to checkout.'),
      ('How long does delivery take for social media services?',
       'Delivery times vary by service. Most services begin within a few hours, with full delivery ranging from hours to several days.'),
      ('What payment methods are accepted?',
       'RESOLVA will support bank transfers and card payments. Payment options will be available at checkout once payment integration is complete.'),
      ('Is it safe to use social media engagement services?',
       'We use methods designed to appear natural. However, please review the terms of service for each social media platform.'),
    ];

    return Container(
      color: AppColors.background,
      width: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: isMobile ? 48 : 80,
            ),
            child: Column(
              children: [
                const SectionHeading(
                  title: 'Frequently Asked Questions',
                  subtitle: 'Quick answers to common questions about RESOLVA.',
                ),
                const SizedBox(height: 40),
                ...faqs.map((faq) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        title: Text(
                          faq.$1,
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        children: [
                          Text(
                            faq.$2,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────── CTA ────────────────────

class _CtaSection extends StatelessWidget {
  final Function(String) onNavigate;
  final bool isMobile;

  const _CtaSection({required this.onNavigate, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      width: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth + 48),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: isMobile ? 48 : 80,
            ),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 32 : 56),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Text(
                    'Ready to Get Started?',
                    style: GoogleFonts.montserrat(
                      fontSize: isMobile ? 28 : 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Join RESOLVA and access examination e-pins, social media services, and more from one convenient platform.',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: AppColors.white.withValues(alpha: 0.8),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => onNavigate('/register'),
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                        label: Text('Create Account', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.primaryNavy,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => onNavigate('/#services'),
                        icon: const Icon(Icons.explore_rounded, size: 18),
                        label: Text('Browse Services', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.white,
                          side: BorderSide(color: AppColors.white.withValues(alpha: 0.45)),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
