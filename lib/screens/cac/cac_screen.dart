import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/shared/app_navigation.dart';

/// CAC Business Registration landing and waitlist pre-registration screen.
class CacScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const CacScreen({super.key, required this.onNavigate});

  @override
  State<CacScreen> createState() => _CacScreenState();
}

class _CacScreenState extends State<CacScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessNameController = TextEditingController();
  String _selectedEntityType = 'Business Name (Sole Proprietor / Enterprise)';
  bool _isSubmitted = false;
  bool _isLoading = false;

  final List<String> _entityTypes = [
    'Business Name (Sole Proprietor / Enterprise)',
    'Private Limited Company (LTD)',
    'Incorporated Trustees (NGO / Church / Association)',
    'Limited by Guarantee (LTD/GTE)',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  void _submitWaitlist() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 900));
      setState(() {
        _isLoading = false;
        _isSubmitted = true;
      });
    }
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
          ResolvaAppBar(currentIndex: 3, onNavigate: widget.onNavigate),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHero(isMobileView),
                  _buildStatsBar(isMobileView),
                  _buildServicePackages(isMobileView),
                  _buildProcessRoadmap(isMobileView),
                  _buildFeaturesGrid(isMobileView),
                  _buildWaitlistSection(isMobileView),
                  _buildCacFaq(isMobileView),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: isMobile ? 48 : 80,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Coming Soon Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: AppColors.accentGold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accentGold,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'UPCOMING SERVICE • LAUNCHING SOON',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            color: AppColors.accentGold,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'CAC Business Registration\nMade Fast, Legitimate & Effortless',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 32 : 46,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    height: 1.15,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 20),

                // Subtitle
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Text(
                    'Legitimize your enterprise with accredited CAC agents. From business name reservation to tax identification number (TIN) and digital incorporation certificates, RESOLVA is bringing business incorporation directly to your screen.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: isMobile ? 15 : 17,
                      color: AppColors.textSecondaryDark,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Hero CTA
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Scroll down to waitlist or trigger registration
                        Scrollable.ensureVisible(
                          _formKey.currentContext ?? context,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                        );
                      },
                      icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                      label: const Text('Join the Early Bird Waitlist'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGold,
                        foregroundColor: AppColors.primaryNavy,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                        textStyle: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => widget.onNavigate('/exam-pins'),
                      icon: const Icon(Icons.explore_outlined, size: 18, color: AppColors.white),
                      label: const Text('Explore Active Services'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(bool isMobile) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryNavy,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: isMobile
                ? Column(
                    children: [
                      _buildStatItem('100% Accredited', 'Certified CAC filing agents'),
                      const Divider(color: Colors.white12, height: 32),
                      _buildStatItem('3-7 Days', 'Average turnaround timeline'),
                      const Divider(color: Colors.white12, height: 32),
                      _buildStatItem('Zero Hidden Fees', 'Transparent government & filing tariffs'),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildStatItem('100% Accredited', 'Certified CAC filing agents'),
                      ),
                      Container(height: 40, width: 1, color: Colors.white12),
                      Expanded(
                        child: _buildStatItem('3-7 Days', 'Average turnaround timeline'),
                      ),
                      Container(height: 40, width: 1, color: Colors.white12),
                      Expanded(
                        child: _buildStatItem('Zero Hidden Fees', 'Transparent government & filing tariffs'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String subtitle) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.accentGold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: AppColors.textSecondaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildServicePackages(bool isMobile) {
    final packages = [
      {
        'title': 'Business Name Registration',
        'badge': 'Most Popular For Sole Traders',
        'price': 'Estimated ₦25,000 - ₦30,000',
        'duration': '3 - 5 Working Days',
        'desc': 'Ideal for freelancers, small retail shops, artisans, and sole proprietors starting out.',
        'features': [
          'Name availability search & reservation',
          'CAC Business Name Certificate',
          'Status Report documentation',
          'Tax Identification Number (TIN)',
          'Bank account ready package',
        ],
        'isHighlight': true,
      },
      {
        'title': 'Company Registration (LTD)',
        'badge': 'For Startups & Enterprises',
        'price': 'Estimated ₦60,000 - ₦75,000',
        'duration': '5 - 7 Working Days',
        'desc': 'Full corporate limited liability structure suitable for high-growth ventures and partnerships.',
        'features': [
          'Name search & 60-day reservation',
          'Certificate of Incorporation (RC Number)',
          'MEMART (Memorandum & Articles)',
          'Status Report with Director details',
          'Automatic FIRS Company TIN',
        ],
        'isHighlight': false,
      },
      {
        'title': 'Incorporated Trustees (NGO)',
        'badge': 'For Foundations & Non-Profits',
        'price': 'Estimated ₦120,000 - ₦150,000',
        'duration': '14 - 21 Working Days',
        'desc': 'For churches, mosques, charities, community associations, and social initiatives.',
        'features': [
          'Pre-approval & Newspaper publications',
          'Constitution drafting assistance',
          'CAC Certificate of Incorporation',
          'Trustees Status Report',
          'Official Board clearance',
        ],
        'isHighlight': false,
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isMobile ? 48 : 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
          child: Column(
            children: [
              Text(
                'Anticipated Packages & Tariffs',
                style: GoogleFonts.montserrat(
                  fontSize: isMobile ? 26 : 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Straightforward all-inclusive packages with zero surprise fees when we launch.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),

              // Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 900) {
                    return Column(
                      children: packages
                          .map((pkg) => Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: _buildPackageCard(pkg, true),
                              ))
                          .toList(),
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: packages
                        .map((pkg) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: _buildPackageCard(pkg, false),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> pkg, bool isMobile) {
    final isHighlight = pkg['isHighlight'] as bool;
    final features = pkg['features'] as List<String>;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight ? AppColors.royalBlue : AppColors.cardBorder,
          width: isHighlight ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlight
                ? AppColors.royalBlue.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isHighlight)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.royalBlue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Text(
                'RECOMMENDED FOR MOST BUSINESSES',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pkg['title'] as String,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pkg['desc'] as String,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  pkg['price'] as String,
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isHighlight ? AppColors.royalBlue : AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        pkg['duration'] as String,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'What will be included:',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: AppColors.emeraldGreen,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessRoadmap(bool isMobile) {
    final steps = [
      {
        'step': '01',
        'title': 'Name Availability',
        'desc': 'Choose your preferred business names. We conduct searches on the CAC portal and reserve your best pick.',
      },
      {
        'step': '02',
        'title': 'Submit Requirements',
        'desc': 'Provide your valid ID (NIN/Voter Card), passport photograph, business address, and partner/director details.',
      },
      {
        'step': '03',
        'title': 'Filing & Processing',
        'desc': 'Accredited CAC legal agents file your incorporation documents directly through the corporate commission.',
      },
      {
        'step': '04',
        'title': 'Digital Delivery',
        'desc': 'Receive your authentic CAC Certificate, Status Report, and TIN delivered right to your dashboard and email.',
      },
    ];

    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isMobile ? 48 : 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
          child: Column(
            children: [
              Text(
                'How It Will Work',
                style: GoogleFonts.montserrat(
                  fontSize: isMobile ? 26 : 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Four seamless steps from conception to an officially registered corporate identity.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 800) {
                    return Column(
                      children: steps
                          .map((s) => Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: _buildStepItem(s),
                              ))
                          .toList(),
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: steps
                        .map((s) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: _buildStepItem(s),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(Map<String, String> s) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              s['step']!,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.royalBlue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            s['title']!,
            style: GoogleFonts.montserrat(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s['desc']!,
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

  Widget _buildFeaturesGrid(bool isMobile) {
    final features = [
      {
        'icon': Icons.verified_user_rounded,
        'title': 'Accredited Legal Experts',
        'desc': 'Your documents are vetted and filed by licensed corporate lawyers and CAC-certified professionals.',
      },
      {
        'icon': Icons.speed_rounded,
        'title': 'Express Processing Track',
        'desc': 'Avoid long physical queues at registry offices. Everything is tracked digitally with real-time status updates.',
      },
      {
        'icon': Icons.receipt_long_rounded,
        'title': 'Tax ID (TIN) Auto-Issuance',
        'desc': 'Every company incorporation comes bundled with an official Joint Tax Board / FIRS corporate TIN.',
      },
      {
        'icon': Icons.security_rounded,
        'title': 'Bank-Compliant Verification',
        'desc': 'All produced certificates and documents come with official CAC QR codes ready for tier-3 corporate bank accounts.',
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isMobile ? 48 : 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
          child: Column(
            children: [
              Text(
                'Why Choose RESOLVA for CAC?',
                style: GoogleFonts.montserrat(
                  fontSize: isMobile ? 26 : 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 48),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 768;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 2 : 1,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: isWide ? 2.3 : 1.7,
                    ),
                    itemCount: features.length,
                    itemBuilder: (context, index) {
                      final f = features[index];
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.royalBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                f['icon'] as IconData,
                                color: AppColors.royalBlue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    f['title'] as String,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    f['desc'] as String,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaitlistSection(bool isMobile) {
    return Container(
      key: _formKey,
      width: double.infinity,
      color: AppColors.white,
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isMobile ? 48 : 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Container(
            padding: EdgeInsets.all(isMobile ? 24 : 40),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFAFBFC), Color(0xFFF1F5F9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: _isSubmitted ? _buildSuccessCard() : _buildForm(isMobile),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(bool isMobile) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  color: AppColors.royalBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Join the Early Access Waitlist',
                      style: GoogleFonts.montserrat(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    Text(
                      'Get 15% discount coupon on your first registration when we launch.',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 24),

          // Full Name
          Text(
            'Your Full Name',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'e.g. Adebayo Johnson',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 18),

          // Email & Phone
          if (isMobile) ...[
            Text(
              'Email Address',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'adebayo@example.com',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
              validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 18),
            Text(
              'Phone Number (WhatsApp)',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
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
                if (v == null || v.isEmpty) return 'Enter your phone number';
                if (v.length != 11) return 'Phone number must be 11 digits';
                return null;
              },
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email Address',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'adebayo@example.com',
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                        ),
                        validator: (v) =>
                            v == null || !v.contains('@') ? 'Enter a valid email' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phone Number (WhatsApp)',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
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
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),

          // Target Entity Type
          Text(
            'Preferred Registration Type',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedEntityType,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.business_outlined, size: 20),
            ),
            items: _entityTypes
                .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t, style: GoogleFonts.montserrat(fontSize: 14)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedEntityType = v);
            },
          ),
          const SizedBox(height: 18),

          // Business Name Idea
          Text(
            'Proposed Business Name Idea (Optional)',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _businessNameController,
            decoration: const InputDecoration(
              hintText: 'e.g. Apex Global Logistics',
              prefixIcon: Icon(Icons.lightbulb_outline, size: 20),
            ),
          ),
          const SizedBox(height: 28),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitWaitlist,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                padding: const EdgeInsets.symmetric(vertical: 18),
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
                  : Text(
                      'Join Launch Waitlist Now',
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'No spam guaranteed. We will only notify you when CAC service registrations open.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.emeraldGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.check_circle_rounded,
              color: AppColors.emeraldGreen,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'You are on the Early Access List!',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Thank you ${_nameController.text.isNotEmpty ? _nameController.text : "valued user"}! We have reserved your spot for $_selectedEntityType. As soon as the CAC onboarding portal goes live, you will receive priority support and your 15% discount token.',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _isSubmitted = false;
                  _nameController.clear();
                  _emailController.clear();
                  _phoneController.clear();
                  _businessNameController.clear();
                });
              },
              child: const Text('Register Another Business'),
            ),
            ElevatedButton(
              onPressed: () => widget.onNavigate('/exam-pins'),
              child: const Text('Explore E-Pins'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCacFaq(bool isMobile) {
    final faqs = [
      {
        'q': 'What is the difference between Business Name and Limited Liability Company (LTD)?',
        'a': 'A Business Name is a sole proprietorship or partnership where the business and owner are legally viewed as one entity. A Limited Liability Company (LTD) is a distinct corporate entity where shareholders’ liabilities are strictly limited to their shares, creating higher credibility for corporate contracts and funding.'
      },
      {
        'q': 'What documents are required for CAC registration?',
        'a': 'You will need a valid government-issued ID card (National Identity Number/NIN slip, International Passport, or Voter Card), your official passport photograph, signature specimen, registered office address, and details of proprietors or directors.'
      },
      {
        'q': 'How long does business registration take on RESOLVA?',
        'a': 'Business Name registrations typically take 3 to 5 business days upon submission. Private Limited Companies take 5 to 7 business days, while NGOs take 14 to 21 business days due to mandatory newspaper publication requirements.'
      },
      {
        'q': 'Will I get an official Tax Identification Number (TIN)?',
        'a': 'Yes! All corporate entities registered via accredited channels automatically receive an official TIN linked directly to the Joint Tax Board (JTB) and Federal Inland Revenue Service (FIRS).'
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isMobile ? 48 : 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
          child: Column(
            children: [
              Text(
                'Frequently Asked Questions',
                style: GoogleFonts.montserrat(
                  fontSize: isMobile ? 26 : 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 36),
              ...faqs.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: ExpansionTile(
                      shape: const Border(),
                      title: Text(
                        item['q']!,
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Text(
                            item['a']!,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
