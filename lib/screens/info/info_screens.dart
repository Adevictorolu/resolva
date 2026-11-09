import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/shared/app_navigation.dart';
import '../../widgets/shared/app_footer.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ABOUT US SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class AboutScreen extends StatelessWidget {
  final Function(String) onNavigate;

  const AboutScreen({super.key, required this.onNavigate});

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
                  _buildAboutHero(isMobileView),
                  _buildAboutMission(isMobileView),
                  _buildAboutPillars(isMobileView),
                  _buildAboutMetrics(isMobileView),
                  ResolvaFooter(onNavigate: onNavigate),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutHero(bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isMobile ? 48 : 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  'ABOUT RESOLVA',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentGold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Powering Digital Services & Enterprise in Nigeria',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: isMobile ? 30 : 44,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'RESOLVA is a premier digital utility platform built to eliminate the stress of acquiring essential credentials, scaling digital visibility, and legitimizing Nigerian businesses.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: AppColors.textSecondaryDark,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutMission(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 48 : 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 800;
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OUR MISSION',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.royalBlue,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Democratizing access to essential digital solutions with transparency & speed',
                          style: GoogleFonts.montserrat(
                            fontSize: isMobile ? 24 : 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryNavy,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'From students needing instant WAEC and JAMB examination pins at midnight, to content creators and entrepreneurs scaling social reach, and founders seeking friction-free corporate registration, RESOLVA serves as your dependable technological backbone.',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isWide) ...[
                    const SizedBox(width: 48),
                    Container(
                      width: 320,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.verified_rounded, size: 48, color: AppColors.accentGold),
                          const SizedBox(height: 20),
                          Text(
                            'Trusted by Over 50,000 Users',
                            style: GoogleFonts.montserrat(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '99.98% successful automated token deliveries across Nigeria and the diaspora.',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAboutPillars(bool isMobile) {
    final pillars = [
      {
        'icon': Icons.bolt_rounded,
        'title': 'Instant Automated Delivery',
        'desc': 'Zero human delays. Examination tokens and social campaigns are triggered immediately upon payment confirmation.',
      },
      {
        'icon': Icons.verified_user_rounded,
        'title': '100% Genuine Credentials',
        'desc': 'All e-pins are directly sourced through verified examination board conduits, guaranteeing valid checker pins.',
      },
      {
        'icon': Icons.support_agent_rounded,
        'title': 'Human 24/7 Support',
        'desc': 'Our customer care agents in Lagos and Abuja are available around the clock via live WhatsApp and email.',
      },
    ];

    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 48 : 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
          child: Column(
            children: [
              Text(
                'Our Core Pillars',
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
                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: pillars
                              .map((p) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: _buildPillarCard(p),
                                    ),
                                  ))
                              .toList(),
                        )
                      : Column(
                          children: pillars
                              .map((p) => Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: _buildPillarCard(p),
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

  Widget _buildPillarCard(Map<String, dynamic> p) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(p['icon'] as IconData, color: AppColors.royalBlue, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            p['title'] as String,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            p['desc'] as String,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutMetrics(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 48 : 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
          child: Container(
            padding: EdgeInsets.all(isMobile ? 24 : 48),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(
                  'Ready to experience seamless digital services?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 24 : 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Join thousands of satisfied students, schools, and brands today.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => onNavigate('/exam-pins'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                    foregroundColor: AppColors.primaryNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                    textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  child: const Text('Get Started Now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONTACT US SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class ContactScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const ContactScreen({super.key, required this.onNavigate});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'Exam PIN Issue';
  bool _isSent = false;
  bool _isLoading = false;

  final _categories = [
    'Exam PIN Issue',
    'Social Media Order Status',
    'CAC Registration Inquiry',
    'Payment or Billing',
    'Partnership / Bulk Order',
    'Other Inquiries',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _isLoading = false;
        _isSent = true;
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
          ResolvaAppBar(currentIndex: -1, onNavigate: widget.onNavigate),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildContactHero(isMobileView),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: isMobileView ? 36 : 64,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 800) {
                              return Column(
                                children: [
                                  _buildContactChannels(),
                                  const SizedBox(height: 36),
                                  _buildMessageForm(isMobileView),
                                ],
                              );
                            } else {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 4, child: _buildContactChannels()),
                                  const SizedBox(width: 48),
                                  Expanded(flex: 6, child: _buildMessageForm(isMobileView)),
                                ],
                              );
                            }
                          },
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

  Widget _buildContactHero(bool isMobile) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryNavy,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 36 : 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Text(
                'We are Here to Help',
                style: GoogleFonts.montserrat(
                  fontSize: isMobile ? 28 : 38,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Reach out to our support team for any inquiries, bulk purchases, or order assistance. Average response time is under 15 minutes.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactChannels() {
    final channels = [
      {
        'icon': Icons.chat_bubble_rounded,
        'title': 'WhatsApp Support',
        'desc': 'Instant replies & PIN troubleshooting',
        'val': '+234 812 345 6789',
        'color': AppColors.emeraldGreen,
      },
      {
        'icon': Icons.email_rounded,
        'title': 'Email Desk',
        'desc': 'For official & enterprise inquiries',
        'val': 'support@resolva.ng',
        'color': AppColors.royalBlue,
      },
      {
        'icon': Icons.phone_rounded,
        'title': 'Phone Hotline',
        'desc': 'Mon - Sat (8:00 AM - 9:00 PM)',
        'val': '+234 700-RESOLVA',
        'color': AppColors.accentGold,
      },
      {
        'icon': Icons.location_on_rounded,
        'title': 'Headquarters',
        'desc': 'Victoria Island, Lagos, Nigeria',
        'val': 'Plot 12, Adeola Odeku St',
        'color': AppColors.textPrimary,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Direct Channels',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 20),
        ...channels.map(
          (c) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (c['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(c['icon'] as IconData, color: c['color'] as Color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c['title'] as String,
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c['desc'] as String,
                        style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c['val'] as String,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.royalBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageForm(bool isMobile) {
    if (_isSent) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.emeraldGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.emeraldGreen,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Message Sent Successfully!',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thank you ${_nameController.text.isNotEmpty ? _nameController.text : "user"}. An agent has been assigned to your ticket and will reply to ${_emailController.text} promptly.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _isSent = false;
                  _subjectController.clear();
                  _messageController.clear();
                });
              },
              child: const Text('Send Another Message'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 36),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send Us a Message',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fill out the form below and we will get back to you in no time.',
              style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 20),

            // Name
            Text(
              'Your Name',
              style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Samuel Okafor',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 16),

            // Email
            Text(
              'Email Address',
              style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'samuel@example.com',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
              validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 16),

            // Category
            Text(
              'Inquiry Category',
              style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_outlined, size: 20),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          c,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(fontSize: 14),
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedCategory = v);
              },
            ),
            const SizedBox(height: 16),

            // Subject
            Text(
              'Subject',
              style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                hintText: 'Brief summary of issue or question',
                prefixIcon: Icon(Icons.subject_outlined, size: 20),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Please provide a subject' : null,
            ),
            const SizedBox(height: 16),

            // Message
            Text(
              'Detailed Message',
              style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Include order reference ID if applicable...',
              ),
              validator: (v) => v == null || v.isEmpty ? 'Please enter your message' : null,
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendMessage,
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
                    : const Text('Send Support Message'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FAQ SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class FaqScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const FaqScreen({super.key, required this.onNavigate});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<Map<String, String>> _allFaqs = [
    {
      'cat': 'Exam PINs',
      'q': 'How quickly will I receive my WAEC or JAMB PIN?',
      'a': 'Immediately. Our system is fully automated. As soon as your payment is processed, the examination PIN and serial number will display directly on your screen and will also be emailed to your inbox within seconds.',
    },
    {
      'cat': 'Exam PINs',
      'q': 'How many times can I use a WAEC scratch card PIN to check results?',
      'a': 'According to WAEC guidelines, an authentic result checker PIN can be used up to 5 times for a single candidate examination number.',
    },
    {
      'cat': 'Exam PINs',
      'q': 'What happens if my generated PIN shows invalid on the exam portal?',
      'a': 'Every token issued by RESOLVA is 100% verified. If you ever face an error, it is typically due to a typographical mistake on candidate examination numbers. If the issue persists, our support team will verify and replace it immediately.',
    },
    {
      'cat': 'Social Media',
      'q': 'Is my account password required for social media engagement services?',
      'a': 'NEVER. We will never ask for your account password or sensitive login details. All we require is your public profile link or post URL. Your account security is guaranteed.',
    },
    {
      'cat': 'Social Media',
      'q': 'How soon does social media delivery begin after ordering?',
      'a': 'Orders start processing within 5 to 30 minutes of payment. Larger packages are delivered gradually and organically over 24 to 48 hours to maintain safe and authentic account growth.',
    },
    {
      'cat': 'CAC Registration',
      'q': 'When is CAC business registration launching on RESOLVA?',
      'a': 'CAC services are launching in Q2 2025. You can join our Early Bird waitlist today to receive 15% discount on your first incorporation filing and gain priority support.',
    },
    {
      'cat': 'Payments',
      'q': 'What payment methods do you support?',
      'a': 'We accept all Nigerian bank debit cards (Mastercard, Visa, Verve), direct bank transfers, USSD codes, and virtual account transfers.',
    },
    {
      'cat': 'Payments',
      'q': 'Can I get a refund if I experience an unresolvable issue?',
      'a': 'Yes. We have a 100% money-back guarantee for failed transactions that cannot be fulfilled within our service level agreement.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobileView = isMobile(width);

    final filteredFaqs = _allFaqs.where((f) {
      final matchesCategory = _selectedCategory == 'All' || f['cat'] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          f['q']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          f['a']!.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

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
                  _buildFaqHero(isMobileView),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: isMobileView ? 36 : 60,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Column(
                          children: [
                            // Search box
                            TextField(
                              onChanged: (v) => setState(() => _searchQuery = v),
                              decoration: InputDecoration(
                                hintText: 'Search frequently asked questions...',
                                prefixIcon: const Icon(Icons.search, size: 22),
                                filled: true,
                                fillColor: AppColors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppColors.cardBorder),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Categories
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: ['All', 'Exam PINs', 'Social Media', 'CAC Registration', 'Payments']
                                    .map((cat) {
                                  final isSelected = _selectedCategory == cat;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(cat),
                                      selected: isSelected,
                                      onSelected: (val) {
                                        if (val) setState(() => _selectedCategory = cat);
                                      },
                                      selectedColor: AppColors.royalBlue,
                                      labelStyle: GoogleFonts.montserrat(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        color: isSelected ? AppColors.white : AppColors.textSecondary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // FAQ list
                            if (filteredFaqs.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(48),
                                alignment: Alignment.center,
                                child: Text(
                                  'No answers found matching your query.',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            else
                              ...filteredFaqs.map(
                                (item) => Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(14),
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
                          ],
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

  Widget _buildFaqHero(bool isMobile) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryNavy,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 36 : 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Text(
                'Help & Frequently Asked Questions',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: isMobile ? 26 : 38,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Find immediate answers to everything about result tokens, social visibility, payments, and business incorporation.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
