import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../data/models/order.dart';
import '../../widgets/shared/app_navigation.dart';
import '../../widgets/shared/common_widgets.dart';

/// Live Customer Dashboard & Account Management Screen.
class DashboardScreen extends StatefulWidget {
  final Function(String) onNavigate;
  final int initialTab;

  const DashboardScreen({
    super.key,
    required this.onNavigate,
    this.initialTab = 0,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardController controller;
  late final AuthController authController;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  Worker? _profileWorker;

  static final _currencyFormat = NumberFormat('#,##0', 'en_NG');
  static final _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    controller = Get.find<DashboardController>();
    authController = Get.find<AuthController>();
    controller.setTab(widget.initialTab);

    _nameController = TextEditingController(text: controller.fullName.value);
    _emailController = TextEditingController(text: controller.email.value);
    _phoneController = TextEditingController(text: controller.phone.value);

    _profileWorker = everAll(
      [controller.fullName, controller.email, controller.phone],
      (_) {
        if (_nameController.text != controller.fullName.value) {
          _nameController.text = controller.fullName.value;
        }
        if (_emailController.text != controller.email.value) {
          _emailController.text = controller.email.value;
        }
        if (_phoneController.text != controller.phone.value) {
          _phoneController.text = controller.phone.value;
        }
      },
    );
  }

  @override
  void dispose() {
    _profileWorker?.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
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
          ResolvaAppBar(currentIndex: 4, onNavigate: widget.onNavigate),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(isMobileView),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppConstants.maxContentWidth + 48,
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isMobileView ? 16 : 24,
                          24,
                          isMobileView ? 16 : 24,
                          48,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 900) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildMobileTabs(),
                                  const SizedBox(height: 24),
                                  Obx(() => _buildActiveTabContent(isMobileView)),
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 268,
                                  child: _buildSidebarMenu(),
                                ),
                                const SizedBox(width: 28),
                                Expanded(
                                  child: Obx(
                                    () => _buildActiveTabContent(isMobileView),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
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

  // ──────────────────── HEADER ────────────────────

  Widget _buildHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 24 : 36,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxContentWidth + 48,
          ),
          child: Obx(() {
            final name = controller.fullName.value.isNotEmpty
                ? controller.fullName.value
                : 'Member';
            final email = controller.email.value;
            final avatar = controller.avatarUrl.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // User Avatar (Network image or dynamic initials)
                    Stack(
                      children: [
                        Container(
                          width: isMobile ? 54 : 64,
                          height: isMobile ? 54 : 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.royalBlue, AppColors.electricBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.4),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: avatar.isNotEmpty
                                ? Image.network(
                                    avatar,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Center(
                                      child: Text(
                                        controller.userInitials,
                                        style: GoogleFonts.montserrat(
                                          fontSize: isMobile ? 18 : 22,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      controller.userInitials,
                                      style: GoogleFonts.montserrat(
                                        fontSize: isMobile ? 18 : 22,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.emeraldGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primaryNavy, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, $name',
                            style: GoogleFonts.montserrat(
                              fontSize: isMobile ? 20 : 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (email.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.white.withValues(alpha: 0.18),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.alternate_email_rounded,
                                    size: 13,
                                    color: AppColors.emeraldGreen,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      email,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.white.withValues(alpha: 0.92),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!isMobile) ...[
                      OutlinedButton.icon(
                        onPressed: () => _showFundWalletDialog(context),
                        icon: const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 18,
                          color: AppColors.white,
                        ),
                        label: const Text('Fund Wallet'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.white,
                          side: BorderSide(
                            color: AppColors.white.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          textStyle: GoogleFonts.montserrat(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showNewOrderModal(context),
                        icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                        label: const Text('New Order'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emeraldGreen,
                          foregroundColor: AppColors.white,
                          elevation: 4,
                          shadowColor: AppColors.emeraldGreen.withValues(alpha: 0.4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          textStyle: GoogleFonts.montserrat(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (isMobile) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showFundWalletDialog(context),
                          icon: const Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 17,
                            color: AppColors.white,
                          ),
                          label: const Text('Fund Wallet'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.white,
                            side: BorderSide(
                              color: AppColors.white.withValues(alpha: 0.4),
                              width: 1.4,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            textStyle: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showNewOrderModal(context),
                          icon: const Icon(Icons.rocket_launch_rounded, size: 17),
                          label: const Text('New Order'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.emeraldGreen,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            textStyle: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          }),
        ),
      ),
    );
  }

  // ──────────────────── SIDEBAR & MOBILE TABS ────────────────────

  Widget _buildSidebarMenu() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                'ACCOUNT MENU',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            _sidebarItem(0, Icons.space_dashboard_rounded, 'Dashboard Overview'),
            _sidebarItem(
              1,
              Icons.local_mall_rounded,
              'My Orders',
              badge: controller.pendingOrders > 0
                  ? '${controller.pendingOrders}'
                  : null,
            ),
            _sidebarItem(
              2,
              Icons.account_balance_wallet_rounded,
              'Wallet & Invoices',
            ),
            _sidebarItem(
              3,
              Icons.notifications_active_rounded,
              'Notifications',
              badge: controller.unreadNotifications > 0
                  ? '${controller.unreadNotifications}'
                  : null,
              badgeColor: AppColors.error,
            ),
            _sidebarItem(4, Icons.manage_accounts_rounded, 'Account Settings'),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showFundWalletDialog(context),
                icon: const Icon(Icons.add_card_rounded, size: 17),
                label: const Text('Fund Wallet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                authController.logout();
                widget.onNavigate('/');
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      size: 20,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Sign Out',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebarItem(
    int index,
    IconData icon,
    String title, {
    String? badge,
    Color? badgeColor,
  }) {
    final isSelected = controller.activeTab.value == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => controller.setTab(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.royalBlue.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppColors.royalBlue
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.royalBlue
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor ?? AppColors.royalBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTabs() {
    final tabs = [
      (0, Icons.space_dashboard_rounded, 'Dashboard Overview'),
      (1, Icons.local_mall_rounded, 'Orders'),
      (2, Icons.account_balance_wallet_rounded, 'Wallet & Invoices'),
      (3, Icons.notifications_active_rounded, 'Alerts'),
      (4, Icons.manage_accounts_rounded, 'Settings'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Obx(
        () => Row(
          children: tabs.map((t) {
            final isSelected = controller.activeTab.value == t.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(
                  t.$2,
                  size: 16,
                  color: isSelected
                      ? AppColors.white
                      : AppColors.textSecondary,
                ),
                label: Text(t.$3),
                selected: isSelected,
                onSelected: (_) => controller.setTab(t.$1),
                selectedColor: AppColors.royalBlue,
                backgroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                labelStyle: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.white : AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ──────────────────── CONTENT ROUTER ────────────────────

  Widget _buildActiveTabContent(bool isMobile) {
    switch (controller.activeTab.value) {
      case 0:
        return _buildOverviewTab(isMobile);
      case 1:
        return _buildOrdersTab(isMobile);
      case 2:
        return _buildTransactionsTab(isMobile);
      case 3:
        return _buildNotificationsTab(isMobile);
      case 4:
        return _buildSettingsTab(isMobile);
      default:
        return _buildOverviewTab(isMobile);
    }
  }

  // ──────────────────── TAB 0: OVERVIEW ────────────────────

  Widget _buildOverviewTab(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wallet Balance Banner Card
        _buildWalletBannerCard(isMobile),
        const SizedBox(height: 24),

        // Summary Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 600;
            final cards = [
              _buildMetricCard(
                'Total Orders',
                '${controller.totalOrders}',
                Icons.local_mall_rounded,
                AppColors.royalBlue,
              ),
              _buildMetricCard(
                'Completed',
                '${controller.completedOrders}',
                Icons.verified_rounded,
                AppColors.emeraldGreen,
              ),
              _buildMetricCard(
                'In Progress',
                '${controller.pendingOrders}',
                Icons.timelapse_rounded,
                AppColors.warning,
              ),
              _buildMetricCard(
                'Total Spent',
                '₦${_currencyFormat.format(controller.totalSpent)}',
                Icons.payments_rounded,
                AppColors.primaryNavy,
              ),
            ];

            if (isSmall) {
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: cards,
              );
            }
            return Row(
              children: cards
                  .map(
                    (c) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: c,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 32),

        // Quick Actions
        Text(
          'Quick Service Shortcuts',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final actions = [
              _buildQuickActionCard(
                'Buy Exam E-PIN',
                'WAEC • NECO • NABTEB • JAMB',
                Icons.school_rounded,
                AppColors.royalBlue,
                () => widget.onNavigate('/exam-pins'),
                logos: const [
                  'assets/images/waec_logo.png',
                  'assets/images/neco_logo.png',
                  'assets/images/nabteb_logo.png',
                ],
              ),
              _buildQuickActionCard(
                'Boost Social Media',
                'Instagram • TikTok • YouTube • X',
                Icons.trending_up_rounded,
                AppColors.emeraldGreen,
                () => widget.onNavigate('/social-media'),
                logos: const [
                  'assets/images/instagram_logo.png',
                  'assets/images/tiktok_logo.png',
                  'assets/images/youtube_logo.png',
                ],
              ),
              _buildQuickActionCard(
                'CAC Registration',
                'Business Name & Company Incorporation',
                Icons.domain_verification_rounded,
                AppColors.accentGold,
                () => widget.onNavigate('/cac'),
              ),
            ];

            if (constraints.maxWidth < 680) {
              return Column(
                children: actions
                    .map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: a,
                      ),
                    )
                    .toList(),
              );
            }
            return Row(
              children: actions
                  .map(
                    (a) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: a,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 32),

        // Recent Orders Preview
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recent Orders',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
            ),
            if (controller.orders.isNotEmpty)
              TextButton.icon(
                onPressed: () => controller.setTab(1),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (controller.orders.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_mall_outlined,
                    color: AppColors.royalBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'No orders placed yet',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Purchase an Examination E-Pin or Social Media service to see your order activity here.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () => _showNewOrderModal(context),
                  icon: const Icon(Icons.rocket_launch_rounded, size: 17),
                  label: const Text('Place First Order'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...controller.orders
              .take(4)
              .map((order) => _buildOrderCard(order, isMobile)),
      ],
    );
  }

  Widget _buildWalletBannerCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryNavy, AppColors.royalBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Obx(
        () => Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 18,
                      color: AppColors.emeraldGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AVAILABLE WALLET BALANCE',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white.withValues(alpha: 0.75),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '₦${_currencyFormat.format(controller.walletBalance.value)}',
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 28 : 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showFundWalletDialog(context),
                  icon: const Icon(Icons.add_card_rounded, size: 18),
                  label: const Text('Fund Wallet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldGreen,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: GoogleFonts.montserrat(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => controller.setTab(2),
                  icon: const Icon(
                    Icons.receipt_long_rounded,
                    size: 18,
                    color: AppColors.white,
                  ),
                  label: const Text('Invoices'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    side: BorderSide(
                      color: AppColors.white.withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: GoogleFonts.montserrat(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    List<String> logos = const [],
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
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
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (logos.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: logos.take(2).map((l) {
                  return Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipOval(child: Image.asset(l, fit: BoxFit.contain)),
                  );
                }).toList(),
              )
            else
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }

  // ──────────────────── TAB 1: ORDERS ────────────────────

  Widget _buildOrdersTab(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order History & E-PIN Vault',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track your orders and copy purchased examination scratch card PINs.',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (!isMobile)
              ElevatedButton.icon(
                onPressed: () => _showNewOrderModal(context),
                icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                label: const Text('New Order'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: controller.orderFilters.map((f) {
              final isSelected = controller.selectedOrderFilter.value == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f),
                  selected: isSelected,
                  onSelected: (_) => controller.filterOrders(f),
                  selectedColor: AppColors.royalBlue.withValues(alpha: 0.12),
                  checkmarkColor: AppColors.royalBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  labelStyle: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.royalBlue
                        : AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        if (controller.filteredOrders.isEmpty)
          const EmptyState(
            icon: Icons.inbox_rounded,
            title: 'No orders found',
            subtitle: 'Place a new order to see your purchases and e-pins here.',
          )
        else
          ...controller.filteredOrders.map(
            (order) => _buildOrderCard(order, isMobile, showDetails: true),
          ),
      ],
    );
  }

  Widget _buildOrderCard(
    Order order,
    bool isMobile, {
    bool showDetails = false,
  }) {
    final isExam = order.category.contains('Exam');
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isExam ? AppColors.royalBlue : AppColors.emeraldGreen)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isExam ? Icons.school_rounded : Icons.trending_up_rounded,
                  color: isExam ? AppColors.royalBlue : AppColors.emeraldGreen,
                  size: 22,
                ),
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
                        Text(
                          order.productName,
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        _buildFulfilmentBadge(order.fulfilmentStatus),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.id} • ${_dateFormat.format(order.date)} • Qty: ${order.quantity}',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₦${_currencyFormat.format(order.amount)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildPaymentBadge(order.paymentStatus),
                ],
              ),
            ],
          ),
          if (showDetails && order.details != null) ...[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.details!,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (order.fulfilmentStatus == OrderFulfilmentStatus.completed &&
                    isExam)
                  TextButton.icon(
                    onPressed: () {
                      final pinText = (order.pins != null && order.pins!.isNotEmpty)
                          ? order.pins!.first
                          : order.details!;
                      Clipboard.setData(ClipboardData(text: pinText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('E-PIN copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 15),
                    label: const Text('Copy PIN'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFulfilmentBadge(OrderFulfilmentStatus status) {
    switch (status) {
      case OrderFulfilmentStatus.completed:
        return StatusBadge.completed();
      case OrderFulfilmentStatus.processing:
        return StatusBadge.processing();
      case OrderFulfilmentStatus.pending:
        return StatusBadge.pending();
      case OrderFulfilmentStatus.cancelled:
        return StatusBadge.cancelled();
    }
  }

  Widget _buildPaymentBadge(OrderPaymentStatus status) {
    switch (status) {
      case OrderPaymentStatus.paid:
        return StatusBadge.paid();
      case OrderPaymentStatus.pending:
        return StatusBadge.pending();
      case OrderPaymentStatus.failed:
        return StatusBadge.failed();
    }
  }

  // ──────────────────── TAB 2: WALLET & INVOICES ────────────────────

  Widget _buildTransactionsTab(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWalletBannerCard(isMobile),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallet & Payment Invoices',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete history of wallet top-ups and service payments.',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (!isMobile)
              ElevatedButton.icon(
                onPressed: () => _showFundWalletDialog(context),
                icon: const Icon(Icons.add_card_rounded, size: 17),
                label: const Text('Fund Wallet'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (controller.transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.emeraldGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'No wallet transactions yet',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Fund your wallet to enjoy instant checkout on Examination E-Pins and Social Media orders.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () => _showFundWalletDialog(context),
                  icon: const Icon(Icons.add_card_rounded, size: 18),
                  label: const Text('Fund Wallet Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.transactions.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final tx = controller.transactions[index];
                final isTopUp = tx.description.toLowerCase().contains('top-up');
                final statusColor = switch (tx.status) {
                  TransactionStatus.successful => AppColors.emeraldGreen,
                  TransactionStatus.pending => AppColors.warning,
                  TransactionStatus.failed => AppColors.error,
                };
                return Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isTopUp
                              ? Icons.add_card_rounded
                              : Icons.receipt_long_rounded,
                          color: statusColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.description,
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${tx.reference} • ${tx.paymentMethod} • ${_dateFormat.format(tx.date)}',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isTopUp ? "+" : "-"}₦${_currencyFormat.format(tx.amount)}',
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isTopUp
                                  ? AppColors.emeraldGreen
                                  : AppColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tx.status.name.toUpperCase(),
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ──────────────────── TAB 3: NOTIFICATIONS ────────────────────

  Widget _buildNotificationsTab(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real-time updates on your orders, wallet funding, and account security.',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (controller.unreadNotifications > 0)
              TextButton.icon(
                onPressed: controller.markAllNotificationsRead,
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: const Text('Mark all read'),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (controller.notifications.isEmpty)
          const EmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'No notifications yet',
            subtitle: 'Order confirmations and wallet alerts will appear here.',
          )
        else
          ...controller.notifications.map((n) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: n.isRead
                    ? AppColors.white
                    : AppColors.royalBlue.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: n.isRead
                      ? AppColors.cardBorder
                      : AppColors.royalBlue.withValues(alpha: 0.3),
                ),
              ),
              child: InkWell(
                onTap: () => controller.markNotificationRead(n.id),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.royalBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        n.type == NotificationType.payment
                            ? Icons.account_balance_wallet_rounded
                            : Icons.notifications_active_rounded,
                        size: 18,
                        color: AppColors.royalBlue,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  n.title,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                              ),
                              if (!n.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.royalBlue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            n.message,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _dateFormat.format(n.date),
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ──────────────────── TAB 4: ACCOUNT SETTINGS ────────────────────

  Widget _buildSettingsTab(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Information',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Update your personal details and contact information.',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Full Name',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
              hintText: 'Adebayo Oluwaseun',
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Email Address',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            readOnly: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.email_outlined, size: 20),
              suffixIcon: Tooltip(
                message: 'Verified account email',
                child: Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: AppColors.emeraldGreen,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Phone Number (WhatsApp)',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 15,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
              hintText: '08034567890',
              counterText: '',
            ),
          ),
          const SizedBox(height: 24),
          Obx(
            () => ElevatedButton.icon(
              onPressed: controller.isSavingProfile.value
                  ? null
                  : () async {
                      final ok = await controller.updateProfile(
                        name: _nameController.text,
                        emailAddr: _emailController.text,
                        phoneNum: _phoneController.text,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Profile updated successfully!'
                                : (authController.authError.value.isNotEmpty
                                    ? authController.authError.value
                                    : 'Could not update profile'),
                          ),
                          backgroundColor: ok
                              ? AppColors.emeraldGreen
                              : AppColors.error,
                        ),
                      );
                    },
              icon: controller.isSavingProfile.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Save Profile Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          Text(
            'Security & Access Control',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Manage your 6-digit Transaction PIN and account password.',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          // Reset Transaction PIN Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.royalBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.dialpad_rounded,
                        color: AppColors.royalBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '6-Digit Transaction PIN',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        Text(
                          'Active & protecting your account session',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => widget.onNavigate('/forgot-pin'),
                  icon: const Icon(Icons.pin_outlined, size: 17),
                  label: const Text('Reset PIN'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Reset Account Password Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: AppColors.emeraldGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Password',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        Text(
                          'Change your sign-in password anytime',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => _showResetPasswordDialog(context),
                  icon: const Icon(Icons.password_rounded, size: 17),
                  label: const Text('Reset Password'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.emeraldGreen,
                    side: const BorderSide(color: AppColors.emeraldGreen, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
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

  // ──────────────────── MODALS: FUND WALLET, NEW ORDER, RESET PASSWORD ────────────────────

  void _showFundWalletDialog(BuildContext context) {
    final amountController = TextEditingController(text: '5000');
    String selectedMethod = 'Bank Transfer';
    final presets = [2000, 5000, 10000, 25000];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: AppColors.emeraldGreen,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Fund Your Wallet',
                            style: GoogleFonts.montserrat(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Select Preset Amount',
                    style: GoogleFonts.montserrat(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presets.map((amt) {
                      final isPicked = amountController.text == '$amt';
                      return ChoiceChip(
                        label: Text('₦${_currencyFormat.format(amt)}'),
                        selected: isPicked,
                        onSelected: (_) {
                          setModalState(() {
                            amountController.text = '$amt';
                          });
                        },
                        selectedColor: AppColors.royalBlue.withValues(alpha: 0.14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        labelStyle: GoogleFonts.montserrat(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isPicked
                              ? AppColors.royalBlue
                              : AppColors.primaryNavy,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Amount (₦)',
                    style: GoogleFonts.montserrat(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.payments_outlined, size: 20),
                      hintText: 'Enter amount in Naira',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Payment Channel',
                    style: GoogleFonts.montserrat(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Bank Transfer', 'Debit Card', 'USSD'].map((m) {
                      final active = selectedMethod == m;
                      return ChoiceChip(
                        label: Text(m),
                        selected: active,
                        onSelected: (_) => setModalState(() => selectedMethod = m),
                        selectedColor: AppColors.emeraldGreen.withValues(alpha: 0.14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        labelStyle: GoogleFonts.montserrat(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: active
                              ? AppColors.emeraldGreen
                              : AppColors.primaryNavy,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final amount = double.tryParse(amountController.text.trim()) ?? 0;
                        if (amount < 100) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Minimum wallet top-up is ₦100'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        controller.fundWallet(
                          amount: amount,
                          paymentMethod: selectedMethod,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Wallet funded with ₦${_currencyFormat.format(amount)} via $selectedMethod!',
                            ),
                            backgroundColor: AppColors.emeraldGreen,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text('Fund Wallet Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emeraldGreen,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
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
    );
  }

  void _showNewOrderModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Start a New Order',
                      style: GoogleFonts.montserrat(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose the service category you would like to order.',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                _buildQuickActionCard(
                  'Examination E-Pins',
                  'WAEC, NECO, NABTEB & JAMB Scratch Cards',
                  Icons.school_rounded,
                  AppColors.royalBlue,
                  () {
                    Navigator.pop(ctx);
                    widget.onNavigate('/exam-pins');
                  },
                  logos: const [
                    'assets/images/waec_logo.png',
                    'assets/images/neco_logo.png',
                  ],
                ),
                const SizedBox(height: 12),
                _buildQuickActionCard(
                  'Social Media Services',
                  'Instagram, TikTok, YouTube, X & Facebook',
                  Icons.trending_up_rounded,
                  AppColors.emeraldGreen,
                  () {
                    Navigator.pop(ctx);
                    widget.onNavigate('/social-media');
                  },
                  logos: const [
                    'assets/images/instagram_logo.png',
                    'assets/images/tiktok_logo.png',
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context) {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscure = true;
    bool saving = false;
    String errorMsg = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reset Account Password',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter a new password for your RESOLVA account.',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: newPassCtrl,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setModalState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: confirmPassCtrl,
                    obscureText: obscure,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                    ),
                  ),
                  if (errorMsg.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMsg,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              final p1 = newPassCtrl.text;
                              final p2 = confirmPassCtrl.text;
                              if (p1.length < 6) {
                                setModalState(() {
                                  errorMsg = 'Password must be at least 6 characters.';
                                });
                                return;
                              }
                              if (p1 != p2) {
                                setModalState(() {
                                  errorMsg = 'Passwords do not match.';
                                });
                                return;
                              }
                              setModalState(() {
                                saving = true;
                                errorMsg = '';
                              });
                              final ok = await authController.updateAccountPassword(p1);
                              if (!ctx.mounted) return;
                              setModalState(() => saving = false);
                              if (ok) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Password updated successfully!'),
                                    backgroundColor: AppColors.emeraldGreen,
                                  ),
                                );
                              } else {
                                setModalState(() {
                                  errorMsg = authController.authError.value;
                                });
                              }
                            },
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: Text(saving ? 'Updating...' : 'Update Password'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.royalBlue,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
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
    );
  }
}
