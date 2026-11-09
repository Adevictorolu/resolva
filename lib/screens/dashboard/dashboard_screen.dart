import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../data/models/order.dart';
import '../../widgets/shared/app_navigation.dart';
import '../../widgets/shared/app_footer.dart';

/// Customer Dashboard and Orders management screen.
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
  late int _selectedTab;
  static final _currencyFormat = NumberFormat('#,##0', 'en_NG');
  static final _dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

  @override
  void initState() {
    super.initState();
    controller = Get.find<DashboardController>();
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
          ResolvaAppBar(currentIndex: -1, onNavigate: widget.onNavigate),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(isMobileView),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobileView ? 16 : 24,
                          vertical: 24,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 850) {
                              // Mobile layout: Tab Bar on top + Content below
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildMobileNavTabs(),
                                  const SizedBox(height: 24),
                                  _buildTabContent(isMobileView),
                                ],
                              );
                            } else {
                              // Desktop layout: Sidebar + Content
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 250,
                                    child: _buildDesktopSidebar(),
                                  ),
                                  const SizedBox(width: 32),
                                  Expanded(
                                    child: _buildTabContent(isMobileView),
                                  ),
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

  Widget _buildHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryNavy,
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isMobile ? 24 : 36,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
          child: Row(
            children: [
              Container(
                width: isMobile ? 48 : 56,
                height: isMobile ? 48 : 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Center(
                  child: Text(
                    'DU',
                    style: GoogleFonts.montserrat(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => Text(
                        'Welcome back, ${controller.fullName.value}',
                        style: GoogleFonts.montserrat(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Obx(
                      () => Text(
                        controller.email.value,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile) ...[
                ElevatedButton.icon(
                  onPressed: () => widget.onNavigate('/exam-pins'),
                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                  label: const Text('New Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNavTabs() {
    final tabs = [
      {'icon': Icons.dashboard_rounded, 'label': 'Overview'},
      {'icon': Icons.receipt_long_rounded, 'label': 'Orders'},
      {'icon': Icons.account_balance_wallet_rounded, 'label': 'Transactions'},
      {'icon': Icons.notifications_rounded, 'label': 'Alerts'},
      {'icon': Icons.person_rounded, 'label': 'Profile'},
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
    );
  }

  Widget _buildDesktopSidebar() {
    final navItems = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard Overview', 'idx': 0},
      {'icon': Icons.receipt_long_rounded, 'label': 'Order History', 'idx': 1},
      {'icon': Icons.account_balance_wallet_rounded, 'label': 'Wallet & Invoices', 'idx': 2},
      {'icon': Icons.notifications_rounded, 'label': 'Notifications', 'idx': 3},
      {'icon': Icons.manage_accounts_rounded, 'label': 'Account Settings', 'idx': 4},
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
              'ACCOUNT MENU',
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
                selectedTileColor: AppColors.royalBlue.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                leading: Icon(
                  item['icon'] as IconData,
                  color: isSelected ? AppColors.royalBlue : AppColors.textSecondary,
                  size: 20,
                ),
                title: Text(
                  item['label'] as String,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.royalBlue : AppColors.textPrimary,
                  ),
                ),
                onTap: () => setState(() => _selectedTab = item['idx'] as int),
              ),
            );
          }),
          const SizedBox(height: 8),
          ListTile(
            dense: true,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: const Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: 20,
            ),
            title: Text(
              'Sign Out',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            onTap: () {
              final auth = Get.find<AuthController>();
              auth.logout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully.')),
              );
              widget.onNavigate('/');
            },
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 16),
          // Need Help Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.support_agent_rounded, size: 20, color: AppColors.royalBlue),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Direct Support',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Have inquiries with a PIN or service delivery?',
                  style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => widget.onNavigate('/contact'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Contact Support'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(bool isMobile) {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab(isMobile);
      case 1:
        return _buildOrdersTab(isMobile);
      case 2:
        return _buildTransactionsTab(isMobile);
      case 3:
        return _buildNotificationsTab(isMobile);
      case 4:
        return _buildProfileTab(isMobile);
      default:
        return _buildOverviewTab(isMobile);
    }
  }

  // ──────────────────── TAB 0: OVERVIEW ────────────────────

  Widget _buildOverviewTab(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metrics Row
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 600;
            return GridView.count(
              crossAxisCount: isSmall ? 2 : 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isSmall ? 1.4 : 1.6,
              children: [
                _buildMetricCard(
                  'Total Spent',
                  '₦${_currencyFormat.format(controller.totalSpent)}',
                  Icons.account_balance_wallet_rounded,
                  AppColors.royalBlue,
                ),
                _buildMetricCard(
                  'Total Orders',
                  '${controller.totalOrders}',
                  Icons.receipt_rounded,
                  AppColors.accentGold,
                ),
                _buildMetricCard(
                  'Completed',
                  '${controller.completedOrders}',
                  Icons.check_circle_rounded,
                  AppColors.emeraldGreen,
                ),
                _buildMetricCard(
                  'Pending Action',
                  '${controller.pendingOrders}',
                  Icons.hourglass_top_rounded,
                  AppColors.warning,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),

        // Recent Orders Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Orders',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryNavy,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedTab = 1),
              child: const Text('View All Orders →'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Recent Orders List
        Obx(() {
          final recent = controller.orders.take(5).toList();
          return Column(
            children: recent.map((o) => _buildOrderCard(o, isMobile)).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────── TAB 1: ORDERS ────────────────────

  Widget _buildOrdersTab(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Orders',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 16),

        // Search & Filter
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: controller.searchOrders,
                decoration: InputDecoration(
                  hintText: 'Search by Order ID, exam name, service...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Status filter tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Obx(
            () => Row(
              children: ['All', 'Completed', 'Processing', 'Pending'].map((filter) {
                final isSelected = controller.orderFilter.value == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) => controller.filterOrders(filter),
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
        ),
        const SizedBox(height: 24),

        // Orders List
        Obx(() {
          if (controller.filteredOrders.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(48),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No orders found',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Try adjusting your filter or search keywords.',
                    style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: controller.filteredOrders.map((o) => _buildOrderCard(o, isMobile)).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildOrderCard(Order o, bool isMobile) {
    Color statusColor;
    String statusText;
    switch (o.fulfilmentStatus) {
      case OrderFulfilmentStatus.completed:
        statusColor = AppColors.emeraldGreen;
        statusText = 'Completed';
        break;
      case OrderFulfilmentStatus.processing:
        statusColor = AppColors.royalBlue;
        statusText = 'Processing';
        break;
      case OrderFulfilmentStatus.pending:
        statusColor = AppColors.warning;
        statusText = 'Pending';
        break;
      default:
        statusColor = AppColors.error;
        statusText = 'Failed';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      o.id,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    o.category,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            o.productName,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '₦${_currencyFormat.format(o.amount)}',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.royalBlue,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '•  Qty: ${o.quantity}',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                _dateFormat.format(o.createdAt),
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showOrderDetailsDialog(o),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('View Details'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOrderDetailsDialog(Order o) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
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
                        'Order Details',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailRow('Order Reference', o.id),
                        const SizedBox(height: 8),
                        _detailRow('Item Purchased', o.productName),
                        const SizedBox(height: 8),
                        _detailRow('Service Category', o.category),
                        const SizedBox(height: 8),
                        _detailRow('Quantity', '${o.quantity}'),
                        const SizedBox(height: 8),
                        _detailRow('Total Amount', '₦${_currencyFormat.format(o.amount)}'),
                        const SizedBox(height: 8),
                        _detailRow('Order Date', _dateFormat.format(o.createdAt)),
                        const SizedBox(height: 8),
                        _detailRow('Recipient Email', o.recipientEmail),
                        if (o.targetUrl != null && o.targetUrl!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _detailRow('Target Profile / URL', o.targetUrl!),
                        ],
                      ],
                    ),
                  ),

                  // If exam pins available, display PIN cards with copy button
                  if (o.pins != null && o.pins!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Your Generated Examination PIN(s)',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...o.pins!.map((p) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.royalBlue.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.vpn_key_rounded, size: 18, color: AppColors.royalBlue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  p,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryNavy,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.royalBlue),
                                tooltip: 'Copy PIN',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: p));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Examination PIN copied to clipboard!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        )),
                  ],

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────── TAB 2: TRANSACTIONS ────────────────────

  Widget _buildTransactionsTab(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transactions & Billing',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          final txs = controller.transactions;
          return Column(
            children: txs.map((tx) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_outward_rounded,
                        color: AppColors.emeraldGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.description,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${tx.reference} • ${_dateFormat.format(tx.date)}',
                            style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '-₦${_currencyFormat.format(tx.amount)}',
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  // ──────────────────── TAB 3: NOTIFICATIONS ────────────────────

  Widget _buildNotificationsTab(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Notification Center',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryNavy,
              ),
            ),
            TextButton(
              onPressed: controller.markAllNotificationsRead,
              child: const Text('Mark all as read'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          final notifs = controller.notifications;
          return Column(
            children: notifs.map((n) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: n.isRead ? AppColors.white : AppColors.royalBlue.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: n.isRead ? AppColors.cardBorder : AppColors.royalBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.royalBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: AppColors.royalBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.title,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w700,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            n.message,
                            style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _dateFormat.format(n.date),
                            style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  // ──────────────────── TAB 4: PROFILE ────────────────────

  Widget _buildProfileTab(bool isMobile) {
    final nameCtrl = TextEditingController(text: controller.fullName.value);
    final emailCtrl = TextEditingController(text: controller.email.value);
    final phoneCtrl = TextEditingController(text: controller.phone.value);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Profile Settings',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Update your personal information and contact preferences for e-pin deliveries.',
            style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          Text(
            'Full Name',
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline, size: 20)),
          ),
          const SizedBox(height: 20),

          Text(
            'Email Address (Delivery Destination)',
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: emailCtrl,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined, size: 20)),
          ),
          const SizedBox(height: 20),

          Text(
            'Phone Number (WhatsApp delivery notifications)',
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.number,
            maxLength: 11,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
              counterText: '',
            ),
          ),
          const SizedBox(height: 28),

          ElevatedButton(
            onPressed: () {
              controller.updateProfile(
                name: nameCtrl.text,
                emailAddr: emailCtrl.text,
                phoneNum: phoneCtrl.text,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile information updated successfully!'),
                  backgroundColor: AppColors.emeraldGreen,
                ),
              );
            },
            child: const Text('Save Profile Changes'),
          ),

          const SizedBox(height: 36),
          const Divider(),
          const SizedBox(height: 24),

          // Security PIN Section
          Text(
            'Security & PIN Protection',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your six-digit Security PIN protects access to e-pins, orders, and payment checkouts.',
            style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.pin_rounded, color: AppColors.emeraldGreen, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security PIN Active (••••••)',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PIN verification enforced on each active login session.',
                        style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => widget.onNavigate('/forgot-pin'),
                  child: const Text('Reset PIN'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Logout button
          OutlinedButton.icon(
            onPressed: () {
              final auth = Get.find<AuthController>();
              auth.logout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully.')),
              );
              widget.onNavigate('/');
            },
            icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
            label: Text(
              'Sign Out of RESOLVA',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
