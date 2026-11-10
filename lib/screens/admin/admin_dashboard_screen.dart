import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../data/models/admin_models.dart';
import '../../widgets/shared/app_navigation.dart';
import '../../widgets/shared/app_footer.dart';

/// RESOLVA Admin Dashboard Screen.
///
/// Features:
/// - Platform Analytics & Revenue Breakdown
/// - User Management (Add User, Remove User, Suspend/Activate, View User Info)
/// - User Session Tracking (When users log in & log out, online status)
/// - Last Purchase Inspector for each user
/// - Live User Activities & Audit Feed
class AdminDashboardScreen extends StatefulWidget {
  final Function(String) onNavigate;
  final int initialTab;

  const AdminDashboardScreen({
    super.key,
    required this.onNavigate,
    this.initialTab = 0,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final AdminController controller;
  late int _selectedTab;
  static final _currencyFormat = NumberFormat('#,##0', 'en_NG');
  static final _dateTimeFormat = DateFormat('MMM dd, yyyy • hh:mm a');
  static final _shortDateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    controller = Get.find<AdminController>();
    _selectedTab = widget.initialTab;
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
          ResolvaAppBar(currentIndex: 5, onNavigate: widget.onNavigate),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildAdminHeader(isMobileView),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppConstants.maxContentWidth + 48,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobileView ? 16 : 24,
                          vertical: 24,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 900) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildMobileNavTabs(),
                                  const SizedBox(height: 24),
                                  _buildActiveTab(isMobileView),
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 260,
                                  child: _buildDesktopSidebar(),
                                ),
                                const SizedBox(width: 28),
                                Expanded(
                                  child: _buildActiveTab(isMobileView),
                                ),
                              ],
                            );
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

  // ──────────────────── HEADER ────────────────────

  Widget _buildAdminHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 20 : 36,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxContentWidth + 48,
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: AppColors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentGold,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'ADMIN CONTROL CENTER',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryNavy,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  Obx(
                                    () => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.emeraldGreen.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppColors.emeraldGreen,
                                        ),
                                      ),
                                      child: Text(
                                        '${controller.onlineUsersCount} Online Now',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'RESOLVA Platform Administration',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Manage users, monitor login/logout sessions, inspect last purchases & platform analytics.',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddUserDialog(context),
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                        label: const Text('Add New User'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.brandBlue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 13,
                          ),
                          textStyle: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_rounded,
                              color: AppColors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentGold,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'ADMIN CONTROL CENTER',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryNavy,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Obx(
                                      () => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.emeraldGreen.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: AppColors.emeraldGreen,
                                          ),
                                        ),
                                        child: Text(
                                          '${controller.onlineUsersCount} Online Now',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'RESOLVA Platform Administration',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Manage users, monitor login/logout sessions, inspect last purchases & platform analytics.',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    color: AppColors.textSecondaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddUserDialog(context),
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: const Text('Add New User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.brandBlue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        textStyle: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ──────────────────── NAVIGATION ────────────────────

  Widget _buildMobileNavTabs() {
    final tabs = [
      {'icon': Icons.analytics_rounded, 'label': 'Analytics'},
      {'icon': Icons.people_alt_rounded, 'label': 'Users Management'},
      {'icon': Icons.history_rounded, 'label': 'Sessions & Activities'},
      {'icon': Icons.shopping_bag_rounded, 'label': 'Last Purchases'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _selectedTab == index;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(
                tab['icon'] as IconData,
                size: 16,
                color: isSelected ? AppColors.white : AppColors.textSecondary,
              ),
              label: Text(tab['label'] as String),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedTab = index);
              },
              selectedColor: AppColors.brandBlue,
              labelStyle: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.white : AppColors.textSecondary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    final navItems = [
      {
        'icon': Icons.analytics_rounded,
        'label': 'Analytics & Overview',
        'idx': 0,
      },
      {
        'icon': Icons.people_alt_rounded,
        'label': 'Users Directory',
        'idx': 1,
      },
      {
        'icon': Icons.history_edu_rounded,
        'label': 'Login/Logout & Activity',
        'idx': 2,
      },
      {
        'icon': Icons.shopping_bag_rounded,
        'label': 'Last Purchases Report',
        'idx': 3,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'ADMINISTRATION',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...navItems.map((item) {
            final isSelected = _selectedTab == item['idx'];
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                dense: true,
                selected: isSelected,
                selectedTileColor: AppColors.brandBlue.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                leading: Icon(
                  item['icon'] as IconData,
                  color: isSelected
                      ? AppColors.brandBlue
                      : AppColors.textSecondary,
                  size: 20,
                ),
                title: Text(
                  item['label'] as String,
                  style: GoogleFonts.montserrat(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.brandBlue
                        : AppColors.textPrimary,
                  ),
                ),
                onTap: () => setState(() => _selectedTab = item['idx'] as int),
              ),
            );
          }),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          ListTile(
            dense: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            leading: const Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: 20,
            ),
            title: Text(
              'Sign Out Admin',
              style: GoogleFonts.montserrat(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            onTap: () {
              final auth = Get.find<AuthController>();
              auth.logout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Admin logged out successfully.')),
              );
              widget.onNavigate('/');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTab(bool isMobile) {
    switch (_selectedTab) {
      case 0:
        return _buildAnalyticsTab(isMobile);
      case 1:
        return _buildUsersTab(isMobile);
      case 2:
        return _buildActivitiesTab(isMobile);
      case 3:
        return _buildLastPurchasesTab(isMobile);
      default:
        return _buildAnalyticsTab(isMobile);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 0: ANALYTICS & OVERVIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAnalyticsTab(bool isMobile) {
    return Obx(() {
      final revByCategory = controller.revenueByCategory;
      final examRev = revByCategory['Examination E-Pins'] ?? 0;
      final socialRev = revByCategory['Social Media Services'] ?? 0;
      final totalRev = controller.totalPlatformRevenue;
      final examShare = totalRev > 0 ? (examRev / totalRev) : 0.6;
      final socialShare = totalRev > 0 ? (socialRev / totalRev) : 0.4;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top KPI Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isVerySmall = constraints.maxWidth < 420;
              final isSmall = constraints.maxWidth < 700;
              final crossAxisCount = isVerySmall ? 1 : (isSmall ? 2 : 4);
              final aspectRatio = isVerySmall ? 2.3 : (isSmall ? 1.55 : 1.55);

              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: aspectRatio,
                children: [
                  _buildKpiCard(
                    label: 'Total Registered Users',
                    value: '${controller.totalUsersCount}',
                    sublabel: '${controller.activeUsersCount} Active • ${controller.suspendedUsersCount} Suspended',
                    icon: Icons.people_alt_rounded,
                    color: AppColors.brandBlue,
                    isSmall: isSmall,
                  ),
                  _buildKpiCard(
                    label: 'Active Sessions Now',
                    value: '${controller.onlineUsersCount} Online',
                    sublabel: '${controller.totalLoginsToday} logins • ${controller.totalLogoutsToday} logouts',
                    icon: Icons.wifi_tethering_rounded,
                    color: AppColors.emeraldGreen,
                    isSmall: isSmall,
                  ),
                  _buildKpiCard(
                    label: 'Total Platform Revenue',
                    value: '₦${_currencyFormat.format(totalRev)}',
                    sublabel: 'Avg ₦${_currencyFormat.format(controller.averageRevenuePerUser)} / user',
                    icon: Icons.payments_rounded,
                    color: AppColors.accentGold,
                    isSmall: isSmall,
                  ),
                  _buildKpiCard(
                    label: 'Completed Purchases',
                    value: '${controller.totalOrdersCount}',
                    sublabel: 'E-Pins & Social Orders',
                    icon: Icons.shopping_bag_rounded,
                    color: AppColors.primaryNavy,
                    isSmall: isSmall,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Analytics Breakdown Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 750;
              final revenueCard = _buildRevenueBreakdownCard(
                examRev: examRev,
                socialRev: socialRev,
                examShare: examShare,
                socialShare: socialShare,
              );
              final statusCard = _buildUserHealthBreakdownCard();

              if (!isWide) {
                return Column(
                  children: [
                    revenueCard,
                    const SizedBox(height: 20),
                    statusCard,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: revenueCard),
                  const SizedBox(width: 20),
                  Expanded(flex: 5, child: statusCard),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // Quick Preview: Recent User Sessions (Logins / Logouts) & Last Purchases
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Recent Logins & Purchases',
                style: GoogleFonts.montserrat(
                  fontSize: isMobile ? 15 : 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedTab = 2),
                child: const Text('View Full Activity Log →'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...controller.activityLogs
              .take(5)
              .map((log) => _buildActivityTile(log, isMobile)),
        ],
      );
    });
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required String sublabel,
    required IconData icon,
    required Color color,
    bool isSmall = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: isSmall ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: EdgeInsets.all(isSmall ? 5 : 7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: isSmall ? 15 : 17),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: isSmall ? 19 : 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
          Text(
            sublabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: isSmall ? 10 : 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdownCard({
    required double examRev,
    required double socialRev,
    required double examShare,
    required double socialShare,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Service Revenue Analytics',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Live Metrics',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Distribution of customer purchases across RESOLVA product lines',
            style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Exam E-Pins bar
          _buildAnalyticsBarRow(
            title: 'Examination E-Pins (WAEC, NECO, NABTEB)',
            amount: '₦${_currencyFormat.format(examRev)}',
            percent: examShare,
            color: AppColors.brandBlue,
          ),
          const SizedBox(height: 16),

          // Social Media bar
          _buildAnalyticsBarRow(
            title: 'Social Media Growth (IG, TikTok, YouTube, X)',
            amount: '₦${_currencyFormat.format(socialRev)}',
            percent: socialShare,
            color: AppColors.emeraldGreen,
          ),
          const SizedBox(height: 16),

          // CAC Waitlist bar
          _buildAnalyticsBarRow(
            title: 'CAC Business Registration (Pre-Launch Waitlist)',
            amount: 'Waitlist Active',
            percent: 0.18,
            color: AppColors.accentGold,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsBarRow({
    required String title,
    required String amount,
    required double percent,
    required Color color,
  }) {
    final clamped = percent.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amount,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 8,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildUserHealthBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Security & Session Status',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Real-time account compliance and session states',
            style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          _buildStatRow(
            icon: Icons.circle,
            iconColor: AppColors.emeraldGreen,
            label: 'Currently Logged In (Online)',
            value: '${controller.onlineUsersCount} Users',
          ),
          const Divider(height: 22),
          _buildStatRow(
            icon: Icons.verified_user_rounded,
            iconColor: AppColors.brandBlue,
            label: 'Active & PIN Configured',
            value: '${controller.activeUsersCount} Users',
          ),
          const Divider(height: 22),
          _buildStatRow(
            icon: Icons.pending_actions_rounded,
            iconColor: AppColors.warning,
            label: 'Pending PIN / Onboarding',
            value: '${controller.pendingUsersCount} Users',
          ),
          const Divider(height: 22),
          _buildStatRow(
            icon: Icons.block_rounded,
            iconColor: AppColors.error,
            label: 'Suspended Accounts',
            value: '${controller.suspendedUsersCount} Users',
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryNavy,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: USERS DIRECTORY (Add, Remove, Suspend, Inspect User Info)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildUsersTab(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile) ...[
          Text(
            'User Directory & Account Control',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add or remove users, inspect user information, login/logout timestamps, and last purchase.',
            style: GoogleFonts.montserrat(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddUserDialog(context),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text('Add User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _showAddUserDialog(context, defaultRole: UserRole.admin),
                  icon: const Icon(Icons.admin_panel_settings_rounded, size: 18),
                  label: const Text('Add Admin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Directory & Account Control',
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add or remove users & admins, inspect user information, login/logout timestamps, and last purchase.',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: controller.loadFromBackend,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Sync Users'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () =>
                    _showAddUserDialog(context, defaultRole: UserRole.admin),
                icon: const Icon(Icons.admin_panel_settings_rounded, size: 18),
                label: const Text('Add Admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _showAddUserDialog(context),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Add User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),

        // Search Bar
        TextField(
          onChanged: controller.searchUsers,
          decoration: InputDecoration(
            hintText: 'Search users by name, email, phone (11 digits), ID, or last purchase...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Status filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Obx(
            () => Row(
              children: [
                'All',
                'Online',
                'Active',
                'Pending',
                'Suspended',
                'Admins',
              ].map((filter) {
                final isSelected = controller.userStatusFilter.value == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) => controller.filterUsersByStatus(filter),
                    selectedColor: AppColors.brandBlue,
                    checkmarkColor: AppColors.white,
                    labelStyle: GoogleFonts.montserrat(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // User Cards List
        Obx(() {
          if (controller.filteredUsers.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.person_off_outlined,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No matching users found',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try clearing your search query or switching status filters.',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: controller.filteredUsers
                .map((u) => _buildUserManagementCard(u, isMobile))
                .toList(),
          );
        }),
      ],
    );
  }

  Widget _buildUserManagementCard(AdminUserRecord user, bool isMobile) {
    Color statusColor;
    String statusLabel;
    switch (user.status) {
      case UserStatus.active:
        statusColor = AppColors.emeraldGreen;
        statusLabel = 'Active';
        break;
      case UserStatus.suspended:
        statusColor = AppColors.error;
        statusLabel = 'Suspended';
        break;
      case UserStatus.pendingOnboarding:
        statusColor = AppColors.warning;
        statusLabel = 'Pending PIN';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Avatar, Name, Badges, Action Buttons
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: isMobile ? double.infinity : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.brandBlue.withValues(alpha: 0.12),
                          child: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName
                                    .trim()
                                    .split(' ')
                                    .take(2)
                                    .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
                                    .join()
                                : 'U',
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandBlue,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color: user.isCurrentlyOnline
                                  ? AppColors.emeraldGreen
                                  : AppColors.textTertiary,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                user.fullName,
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  user.id,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              if (user.role == UserRole.admin)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentGold.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    'ADMIN',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.accentGold,
                                    ),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${user.email}  •  ${user.phone}',
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
              ),

              // Action buttons: Inspect, Make/Remove Admin, Suspend/Activate, Remove
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showUserDetailsModal(context, user),
                    icon: const Icon(Icons.badge_outlined, size: 16),
                    label: const Text('User Info'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      final becomingAdmin = user.role != UserRole.admin;
                      controller.toggleUserRole(user.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            becomingAdmin
                                ? '${user.fullName} promoted to Administrator.'
                                : '${user.fullName} changed to Customer role.',
                          ),
                          backgroundColor: becomingAdmin
                              ? AppColors.emeraldGreen
                              : AppColors.primaryNavy,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: Icon(
                      user.role == UserRole.admin
                          ? Icons.shield_rounded
                          : Icons.admin_panel_settings_outlined,
                      size: 16,
                      color: AppColors.accentGold,
                    ),
                    label: Text(
                      user.role == UserRole.admin ? 'Remove Admin' : 'Make Admin',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryNavy,
                      side: BorderSide(
                        color: AppColors.accentGold.withValues(alpha: 0.7),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      controller.toggleUserStatus(user.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            user.status == UserStatus.suspended
                                ? '${user.fullName} reactivated.'
                                : '${user.fullName} suspended.',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: Icon(
                      user.status == UserStatus.suspended
                          ? Icons.check_circle_outline_rounded
                          : Icons.pause_circle_outline_rounded,
                      size: 16,
                      color: user.status == UserStatus.suspended
                          ? AppColors.emeraldGreen
                          : AppColors.warning,
                    ),
                    label: Text(
                      user.status == UserStatus.suspended ? 'Activate' : 'Suspend',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: user.status == UserStatus.suspended
                          ? AppColors.emeraldGreen
                          : AppColors.warning,
                      side: BorderSide(
                        color: (user.status == UserStatus.suspended
                                ? AppColors.emeraldGreen
                                : AppColors.warning)
                            .withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _confirmRemoveUser(context, user),
                    icon: const Icon(
                      Icons.person_remove_outlined,
                      size: 16,
                      color: AppColors.error,
                    ),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Bottom Metadata Grid: Login Time, Logout Time, Total Spent, Last Purchase
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _buildUserMetaItem(
                icon: Icons.login_rounded,
                iconColor: AppColors.emeraldGreen,
                label: 'Last Login',
                value: user.lastLoginAt != null
                    ? _dateTimeFormat.format(user.lastLoginAt!)
                    : 'Never logged in',
                isMobile: isMobile,
              ),
              _buildUserMetaItem(
                icon: Icons.logout_rounded,
                iconColor: AppColors.textSecondary,
                label: 'Last Logout',
                value: user.isCurrentlyOnline
                    ? 'Active Session (Online Now)'
                    : (user.lastLogoutAt != null
                        ? _dateTimeFormat.format(user.lastLogoutAt!)
                        : 'No logout recorded'),
                isMobile: isMobile,
              ),
              _buildUserMetaItem(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.brandBlue,
                label: 'Total Spent (${user.totalOrders} orders)',
                value: '₦${_currencyFormat.format(user.totalSpent)}',
                isMobile: isMobile,
              ),
              _buildUserMetaItem(
                icon: Icons.shopping_cart_checkout_rounded,
                iconColor: AppColors.accentGold,
                label: 'Last Purchase',
                value: user.lastPurchase != null
                    ? '${user.lastPurchase!.productName} — ₦${_currencyFormat.format(user.lastPurchase!.amount)} (${_shortDateFormat.format(user.lastPurchase!.date)})'
                    : 'No purchases yet',
                isMobile: isMobile,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserMetaItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isMobile = false,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isMobile ? double.infinity : 380,
      ),
      child: Row(
        mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text.rich(
              TextSpan(
                style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textSecondary),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: value,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: SESSIONS & ACTIVITIES (When user logs in/out & all user actions)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActivitiesTab(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Activity & Login/Logout Session Logs',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Real-time audit trail showing when users log in, log out, verify PINs, and complete purchases.',
          style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // Search
        TextField(
          onChanged: controller.searchActivities,
          decoration: InputDecoration(
            hintText: 'Search activity log by user name, email, or action...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Obx(
            () => Row(
              children: [
                'All',
                'Logins',
                'Logouts',
                'Purchases',
                'Account Changes',
              ].map((filter) {
                final isSelected = controller.activityFilter.value == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) => controller.filterActivities(filter),
                    selectedColor: AppColors.brandBlue,
                    checkmarkColor: AppColors.white,
                    labelStyle: GoogleFonts.montserrat(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),

        Obx(() {
          if (controller.filteredActivityLogs.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Center(
                child: Text(
                  'No activity logs match your filter.',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }

          return Column(
            children: controller.filteredActivityLogs
                .map((log) => _buildActivityTile(log, isMobile))
                .toList(),
          );
        }),
      ],
    );
  }

  Widget _buildActivityTile(UserActivityLog log, bool isMobile) {
    IconData icon;
    Color color;
    String badgeLabel;

    switch (log.type) {
      case ActivityType.login:
      case ActivityType.pinVerified:
        icon = Icons.login_rounded;
        color = AppColors.emeraldGreen;
        badgeLabel = 'LOGIN';
        break;
      case ActivityType.logout:
        icon = Icons.logout_rounded;
        color = AppColors.textSecondary;
        badgeLabel = 'LOGOUT';
        break;
      case ActivityType.purchase:
        icon = Icons.shopping_bag_rounded;
        color = AppColors.brandBlue;
        badgeLabel = 'PURCHASE';
        break;
      case ActivityType.accountCreated:
        icon = Icons.person_add_alt_1_rounded;
        color = AppColors.accentGold;
        badgeLabel = 'NEW USER';
        break;
      case ActivityType.accountRemoved:
        icon = Icons.person_remove_rounded;
        color = AppColors.error;
        badgeLabel = 'REMOVED';
        break;
      case ActivityType.statusChanged:
        icon = Icons.manage_accounts_rounded;
        color = AppColors.warning;
        badgeLabel = 'STATUS';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        badgeLabel,
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                    Text(
                      log.userName,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    Text(
                      '(${log.userEmail})',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  log.description,
                  style: GoogleFonts.montserrat(
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Text(
                      _dateTimeFormat.format(log.timestamp),
                      style: GoogleFonts.montserrat(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '•  ${log.ipOrDevice}',
                      style: GoogleFonts.montserrat(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (log.amount != null) ...[
            const SizedBox(width: 8),
            Text(
              '₦${_currencyFormat.format(log.amount)}',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.brandBlue,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3: LAST PURCHASES REPORT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLastPurchasesTab(bool isMobile) {
    return Obx(() {
      final usersWithPurchases = controller.users
          .where((u) => u.lastPurchase != null)
          .toList()
        ..sort((a, b) =>
            b.lastPurchase!.date.compareTo(a.lastPurchase!.date));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last Purchase by User',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track the most recent examination e-pin or social media order placed by each customer.',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          ...usersWithPurchases.map((user) {
            final lp = user.lastPurchase!;
            final isExam = lp.category == 'Examination E-Pins';
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: isMobile ? double.infinity : null,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (isExam
                                    ? AppColors.brandBlue
                                    : AppColors.emeraldGreen)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isExam
                                ? Icons.school_rounded
                                : Icons.trending_up_rounded,
                            color: isExam
                                ? AppColors.brandBlue
                                : AppColors.emeraldGreen,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lp.productName,
                                style: GoogleFonts.montserrat(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Purchased by ${user.fullName} (${user.email})',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Order ${lp.orderId}  •  ${_dateTimeFormat.format(lp.date)}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 11.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: isMobile ? double.infinity : null,
                    child: isMobile
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₦${_currencyFormat.format(lp.amount)}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brandBlue,
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    _showUserDetailsModal(context, user),
                                child: const Text('Inspect Customer →'),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₦${_currencyFormat.format(lp.amount)}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brandBlue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed: () =>
                                    _showUserDetailsModal(context, user),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Inspect Customer →'),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            );
          }),
        ],
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIALOGS: ADD USER, REMOVE USER, INSPECT USER DETAILS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showAddUserDialog(
    BuildContext context, {
    UserRole defaultRole = UserRole.customer,
  }) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    UserRole selectedRole = defaultRole;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedRole == UserRole.admin
                              ? 'Add Administrator'
                              : 'Add New User',
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedRole == UserRole.admin
                          ? 'Grant administrator privileges to an email address so they can oversee the system.'
                          : 'Create a new customer or administrator profile directly.',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Full Name',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Ngozi Nwosu',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Enter full name' : null,
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'Email Address',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'ngozi@example.com',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                      validator: (v) => v == null || !v.contains('@')
                          ? 'Enter a valid email'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'Phone Number (11 digits)',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: phoneCtrl,
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
                        if (v.length != 11) {
                          return 'Phone number must be 11 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'Account Role',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<UserRole>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Icons.shield_outlined,
                          size: 20,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: UserRole.customer,
                          child: Text('Customer Account'),
                        ),
                        DropdownMenuItem(
                          value: UserRole.admin,
                          child: Text('Administrator'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedRole = val);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            final added = controller.addUser(
                              fullName: nameCtrl.text,
                              email: emailCtrl.text,
                              phone: phoneCtrl.text,
                              role: selectedRole,
                            );
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  selectedRole == UserRole.admin
                                      ? 'Added Administrator ${added.fullName} (${added.email})'
                                      : 'Added user ${added.fullName} (${added.id})',
                                ),
                                backgroundColor: AppColors.emeraldGreen,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedRole == UserRole.admin
                              ? AppColors.primaryNavy
                              : AppColors.brandBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          selectedRole == UserRole.admin
                              ? 'Add Administrator'
                              : 'Create User Account',
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

  void _confirmRemoveUser(BuildContext context, AdminUserRecord user) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_remove_rounded,
                    color: AppColors.error,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Remove User Account?',
                  style: GoogleFonts.montserrat(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to permanently remove ${user.fullName} (${user.email}) from RESOLVA?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          controller.removeUser(user.id);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Removed ${user.fullName} (${user.id})',
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('Remove User'),
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

  void _showUserDetailsModal(BuildContext context, AdminUserRecord user) {
    final userLogs = controller.activityLogs
        .where((a) =>
            a.userId == user.id ||
            a.userEmail.toLowerCase() == user.email.toLowerCase())
        .take(5)
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'User Profile & Session Dossier',
                      style: GoogleFonts.montserrat(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                // Core user information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      _dossierRow('User ID', user.id),
                      const SizedBox(height: 8),
                      _dossierRow('Full Name', user.fullName),
                      const SizedBox(height: 8),
                      _dossierRow('Email Address', user.email),
                      const SizedBox(height: 8),
                      _dossierRow('WhatsApp Phone', user.phone),
                      const SizedBox(height: 8),
                      _dossierRow(
                        'Role',
                        user.role == UserRole.admin
                            ? 'Administrator'
                            : 'Customer',
                      ),
                      const SizedBox(height: 8),
                      _dossierRow(
                        'Joined Date',
                        _dateTimeFormat.format(user.joinedAt),
                      ),
                      const SizedBox(height: 8),
                      _dossierRow(
                        'Security PIN Status',
                        user.hasPinConfigured
                            ? 'Configured (6-Digit PIN Active)'
                            : 'Not Configured',
                      ),
                      const SizedBox(height: 8),
                      _dossierRow(
                        'Last Login',
                        user.lastLoginAt != null
                            ? _dateTimeFormat.format(user.lastLoginAt!)
                            : 'Never',
                      ),
                      const SizedBox(height: 8),
                      _dossierRow(
                        'Last Logout',
                        user.isCurrentlyOnline
                            ? 'Currently Online'
                            : (user.lastLogoutAt != null
                                ? _dateTimeFormat.format(user.lastLogoutAt!)
                                : 'None'),
                      ),
                      const SizedBox(height: 8),
                      _dossierRow(
                        'Lifetime Spend',
                        '₦${_currencyFormat.format(user.totalSpent)} (${user.totalOrders} orders)',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Last Purchase Box
                Text(
                  'Last Purchase Details',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 8),
                if (user.lastPurchase != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.brandBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.lastPurchase!.productName,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Order ID: ${user.lastPurchase!.orderId} • Category: ${user.lastPurchase!.category}',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Amount: ₦${_currencyFormat.format(user.lastPurchase!.amount)} • Date: ${_dateTimeFormat.format(user.lastPurchase!.date)}',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandBlue,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'This user has not completed any purchases yet.',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),

                if (userLogs.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Recent Session & Activity History',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...userLogs.map(
                    (l) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_right_rounded,
                            size: 18,
                            color: AppColors.brandBlue,
                          ),
                          Expanded(
                            child: Text(
                              '${l.description} (${_dateTimeFormat.format(l.timestamp)})',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dossierRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.montserrat(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
        ),
      ],
    );
  }
}

