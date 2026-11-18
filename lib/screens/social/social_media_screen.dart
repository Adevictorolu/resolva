import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/social_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/order.dart';
import '../../data/models/social_service.dart';
import '../../widgets/shared/app_navigation.dart';
import '../../widgets/shared/common_widgets.dart';

String? _socialLogoAsset(String platformKey) {
  final k = platformKey.toLowerCase();
  if (k.contains('instagram') || k == 'ig') {
    return 'assets/images/instagram_logo.png';
  }
  if (k.contains('tiktok') || k == 'tt') {
    return 'assets/images/tiktok_logo.png';
  }
  if (k.contains('facebook') || k == 'fb') {
    return 'assets/images/facebook_logo.png';
  }
  if (k.contains('youtube') || k == 'yt') {
    return 'assets/images/youtube_logo.png';
  }
  if (k.contains('twitter') || k == 'x') {
    return 'assets/images/x_logo.png';
  }
  if (k.contains('whatsapp') || k == 'wa') {
    return 'assets/images/whatsapp_logo.png';
  }
  if (k.contains('pinterest')) {
    return 'assets/images/pinterest_logo.png';
  }
  return null;
}

/// Social Media Boosting marketplace screen powered by Bigisub Marketing Hub
/// (`https://rif.africa/technotronics/api/bigisub/marketing-hub`).
class SocialMediaScreen extends StatelessWidget {
  final Function(String) onNavigate;

  const SocialMediaScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SocialController>();
    final width = MediaQuery.of(context).size.width;
    final isMobileView = isMobile(width);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: ResolvaDrawer(onNavigate: onNavigate),
      body: Column(
        children: [
          ResolvaAppBar(currentIndex: 2, onNavigate: onNavigate),
          Expanded(
            child: Obx(() {
              if (controller.selectedService.value != null) {
                return _OrderFormView(
                  controller: controller,
                  onNavigate: onNavigate,
                  isMobile: isMobileView,
                );
              }
              return _ServiceListView(
                controller: controller,
                onNavigate: onNavigate,
                isMobile: isMobileView,
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ──────────── SERVICE LIST ────────────

class _ServiceListView extends StatefulWidget {
  final SocialController controller;
  final Function(String) onNavigate;
  final bool isMobile;

  const _ServiceListView({
    required this.controller,
    required this.onNavigate,
    required this.isMobile,
  });

  @override
  State<_ServiceListView> createState() => _ServiceListViewState();
}

class _ServiceListViewState extends State<_ServiceListView> {
  int _visibleCount = 36;
  static final _fmt = NumberFormat('#,##0.##', 'en_NG');

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final isMobile = widget.isMobile;
    final dashCtrl = Get.find<DashboardController>();
    final authCtrl = Get.find<AuthController>();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            color: AppColors.white,
            width: double.infinity,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppConstants.maxContentWidth + 48,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: isMobile ? 28 : 40,
                  ),
                  child: Column(
                    children: [
                      const SectionHeading(
                        title: 'Social Media Boosting',
                        subtitle:
                            'Official Marketing Hub — High-retention followers, views, likes, comments & engagement across Instagram, TikTok, YouTube, X, Facebook, Telegram, WhatsApp, Audiomack & Spotify.',
                      ),
                      const SizedBox(height: 20),

                      // Live Wallet Balance Bar
                      Obx(() {
                        if (!authCtrl.isLoggedIn.value) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: 16,
                                    color: AppColors.emeraldGreen,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Wallet Balance: ₦${_fmt.format(dashCtrl.walletBalance.value)}',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () => _showQuickFundWalletModal(
                                  context,
                                  dashCtrl,
                                ),
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.emeraldGreen,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.add_card_rounded,
                                        size: 14,
                                        color: AppColors.white,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Fund Wallet (Paystack)',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      // Search & Region Filter Row
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: TextField(
                              onChanged: (val) {
                                setState(() => _visibleCount = 36);
                                controller.search(val);
                              },
                              decoration: InputDecoration(
                                hintText:
                                    'Search services, platforms, or service ID...',
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                ),
                                isDense: true,
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(999),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          Obx(
                            () => Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: controller.countries.map((entry) {
                                final isSelected =
                                    controller.selectedCountry.value ==
                                        entry.$1;
                                return ChoiceChip(
                                  label: Text(entry.$2),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() => _visibleCount = 36);
                                    controller.selectCountry(entry.$1);
                                  },
                                  selectedColor: AppColors.primaryNavy,
                                  backgroundColor: AppColors.background,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  labelStyle: GoogleFonts.montserrat(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppColors.white
                                        : AppColors.textSecondary,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Platform selector pills
                      _PlatformSelector(
                        controller: controller,
                        isMobile: isMobile,
                        onChanged: () => setState(() => _visibleCount = 36),
                      ),
                      const SizedBox(height: 20),

                      // Category filters
                      Obx(
                        () => SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: controller.categories.map((cat) {
                              final isSelected =
                                  controller.selectedCategory.value == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(cat),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() => _visibleCount = 36);
                                    controller.selectCategory(cat);
                                  },
                                  selectedColor: AppColors.emeraldGreen
                                      .withValues(alpha: 0.12),
                                  checkmarkColor: AppColors.emeraldGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  labelStyle: GoogleFonts.montserrat(
                                    fontSize: 12.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.emeraldGreen
                                        : AppColors.textSecondary,
                                  ),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.emeraldGreen
                                        : AppColors.border,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Service grid
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstants.maxContentWidth + 48,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                child: Obx(() {
                  if (controller.filteredServices.isEmpty) {
                    return const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No matching services found',
                      subtitle:
                          'Try selecting a different platform, region, or category.',
                    );
                  }

                  final totalCount = controller.filteredServices.length;
                  final displayItems = controller.filteredServices
                      .take(_visibleCount)
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Showing ${displayItems.length} of $totalCount live services',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (controller.selectedPlatformId.value.isNotEmpty ||
                                controller.selectedCountry.value != 'all' ||
                                controller.selectedCategory.value != 'All' ||
                                controller.searchQuery.value.isNotEmpty)
                              TextButton.icon(
                                onPressed: () {
                                  controller.selectedPlatformId.value = '';
                                  controller.selectedCountry.value = 'all';
                                  controller.selectedCategory.value = 'All';
                                  controller.search('');
                                  setState(() => _visibleCount = 36);
                                },
                                icon: const Icon(Icons.clear_all_rounded, size: 16),
                                label: const Text('Reset Filters'),
                              ),
                          ],
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossCount = constraints.maxWidth < 520
                              ? 1
                              : (constraints.maxWidth < 860 ? 2 : 3);
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossCount,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              mainAxisExtent: 286,
                            ),
                            itemCount: displayItems.length,
                            itemBuilder: (context, index) {
                              final service = displayItems[index];
                              final platform =
                                  controller.platformFor(service.platformId);
                              return _SocialServiceCard(
                                service: service,
                                platform: platform,
                                onOrder: () =>
                                    controller.selectService(service),
                              );
                            },
                          );
                        },
                      ),
                      if (_visibleCount < totalCount) ...[
                        const SizedBox(height: 28),
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() => _visibleCount += 48);
                            },
                            icon: const Icon(Icons.expand_more_rounded),
                            label: Text(
                              'Load More Services (${totalCount - _visibleCount} remaining)',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformSelector extends StatelessWidget {
  final SocialController controller;
  final bool isMobile;
  final VoidCallback onChanged;

  const _PlatformSelector({
    required this.controller,
    required this.isMobile,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: controller.platforms.map((platform) {
          final isSelected =
              controller.selectedPlatformId.value == platform.id;
          final logoAsset =
              _socialLogoAsset(platform.name) ?? _socialLogoAsset(platform.id);
          return InkWell(
            onTap: () {
              controller.selectPlatform(platform.id);
              onChanged();
            },
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 18,
                vertical: isMobile ? 9 : 11,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? platform.color.withValues(alpha: 0.1)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? platform.color : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (logoAsset != null)
                    ClipOval(
                      child: Image.asset(
                        logoAsset,
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    )
                  else
                    FaIcon(
                      platform.icon,
                      size: 16,
                      color: isSelected
                          ? platform.color
                          : AppColors.textSecondary,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    platform.name,
                    style: GoogleFonts.montserrat(
                      fontSize: 12.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? platform.color
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SocialServiceCard extends StatefulWidget {
  final SocialService service;
  final SocialPlatform platform;
  final VoidCallback onOrder;

  const _SocialServiceCard({
    required this.service,
    required this.platform,
    required this.onOrder,
  });

  @override
  State<_SocialServiceCard> createState() => _SocialServiceCardState();
}

class _SocialServiceCardState extends State<_SocialServiceCard> {
  bool _hovered = false;
  static final _fmt = NumberFormat('#,##0.##', 'en_NG');

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final p = widget.platform;
    final logoAsset = _socialLogoAsset(p.name) ?? _socialLogoAsset(p.id);
    final countryFlag = switch (s.country) {
      'nigeria' => '🇳🇬 NG',
      'ghana' => '🇬🇭 GH',
      _ => '🌍 Global',
    };

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                _hovered ? p.color.withValues(alpha: 0.35) : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? p.color.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: _hovered ? 18 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top header: Platform + Country + Service ID
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    padding: logoAsset != null
                        ? const EdgeInsets.all(5)
                        : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: p.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: logoAsset != null
                        ? ClipOval(
                            child: Image.asset(logoAsset, fit: BoxFit.contain),
                          )
                        : Center(
                            child: FaIcon(p.icon, size: 17, color: p.color),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: GoogleFonts.montserrat(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: p.color,
                          ),
                        ),
                        Text(
                          s.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      countryFlag,
                      style: GoogleFonts.montserrat(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Service Name
              Text(
                s.name,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Capabilities & Badges
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _miniChip(
                    '₦${_fmt.format(s.displayAmount)} / ${s.displayUnit.replaceAll("per ", "")}',
                    AppColors.emeraldGreen,
                  ),
                  if (s.hasRefill)
                    _miniChip('Refill', AppColors.royalBlue),
                  if (s.hasCancel)
                    _miniChip('Cancellable', AppColors.primaryNavy),
                  if (s.requiresCustomText)
                    _miniChip('Custom Text', AppColors.accentGold),
                ],
              ),
              const Spacer(),

              // Delivery & Min-Max
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 13,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      s.estimatedDelivery,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  Text(
                    'Min ${_fmt.format(s.minQuantity)} • Max ${_fmt.format(s.maxQuantity)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Price & Order button
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Starts from (${_fmt.format(s.minQuantity)} min)',
                        style: GoogleFonts.montserrat(
                          fontSize: 10.5,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      Text(
                        '₦${_fmt.format(s.startingPrice)}',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: widget.onOrder,
                    icon: const Icon(Icons.bolt_rounded, size: 15),
                    label: const Text('Order Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.color,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      textStyle: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ──────────── ORDER FORM ────────────

class _OrderFormView extends StatefulWidget {
  final SocialController controller;
  final Function(String) onNavigate;
  final bool isMobile;

  const _OrderFormView({
    required this.controller,
    required this.onNavigate,
    required this.isMobile,
  });

  @override
  State<_OrderFormView> createState() => _OrderFormViewState();
}

class _OrderFormViewState extends State<_OrderFormView> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _customTextController = TextEditingController();
  final _pollAnswerController = TextEditingController(text: '1');
  final _hashtagController = TextEditingController();
  late final TextEditingController _qtyController;
  final FocusNode _qtyFocusNode = FocusNode();
  Worker? _qtyWorker;
  String _errorMessage = '';

  static final _fmt = NumberFormat('#,##0.##', 'en_NG');

  @override
  void initState() {
    super.initState();
    _qtyController =
        TextEditingController(text: '${widget.controller.quantity.value}');
    _qtyWorker = ever<int>(widget.controller.quantity, (val) {
      if (!_qtyFocusNode.hasFocus && _qtyController.text != '$val') {
        _qtyController.text = '$val';
      }
    });
    _qtyFocusNode.addListener(() {
      if (!_qtyFocusNode.hasFocus) {
        _commitQuantity(_qtyController.text);
      }
    });
  }

  @override
  void dispose() {
    _qtyWorker?.dispose();
    _qtyFocusNode.dispose();
    _qtyController.dispose();
    _urlController.dispose();
    _customTextController.dispose();
    _pollAnswerController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }

  void _commitQuantity(String raw) {
    final service = widget.controller.selectedService.value;
    if (service == null) return;
    final cleaned = raw.replaceAll(',', '').trim();
    final parsed = int.tryParse(cleaned);
    if (parsed == null || parsed < service.minQuantity) {
      widget.controller.setQuantity(service.minQuantity);
      _qtyController.text = '${service.minQuantity}';
    } else if (parsed > service.maxQuantity) {
      widget.controller.setQuantity(service.maxQuantity);
      _qtyController.text = '${service.maxQuantity}';
    } else {
      widget.controller.setQuantity(parsed);
      _qtyController.text = '$parsed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final dashCtrl = Get.find<DashboardController>();

    return SingleChildScrollView(
      child: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 740),
              child: Padding(
                padding: EdgeInsets.all(widget.isMobile ? 18 : 40),
                child: Form(
                  key: _formKey,
                  child: Obx(() {
                    final service = ctrl.selectedService.value;
                    if (service == null) return const SizedBox.shrink();
                    final platform = ctrl.platformFor(service.platformId);
                    final isSubscription =
                        service.serviceType == 'Subscriptions';
                    final needsCustomText = service.requiresCustomText ||
                        service.serviceType == 'Custom Comments' ||
                        service.serviceType == 'Custom Comments Package';
                    final isPoll = service.serviceType == 'Poll';
                    final isHashtag = service.serviceType == 'Mentions Hashtag';
                    final total = ctrl.totalPrice;
                    final hasEnoughBalance =
                        dashCtrl.walletBalance.value >= total;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton.icon(
                          onPressed: ctrl.clearSelection,
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Back to Social Boosting Services'),
                        ),
                        const SizedBox(height: 16),

                        Container(
                          padding: EdgeInsets.all(widget.isMobile ? 20 : 28),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with Platform & Service ID
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          platform.color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        FaIcon(
                                          platform.icon,
                                          size: 14,
                                          color: platform.color,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${platform.name} • ${service.countryLabel}',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: platform.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Service #${service.bigisubServiceId}',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                service.name,
                                style: GoogleFonts.montserrat(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Category: ${service.category} • Rate: ₦${_fmt.format(service.displayAmount)} ${service.displayUnit}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.emeraldGreen,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Rules & Instructions Box
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.royalBlue
                                      .withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.royalBlue
                                        .withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.verified_user_rounded,
                                          size: 17,
                                          color: AppColors.royalBlue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Service Rules & Delivery Guidelines',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryNavy,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ...service.serviceRules.map(
                                      (rule) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 6),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(top: 5),
                                              child: Icon(
                                                Icons.circle,
                                                size: 5,
                                                color: AppColors.royalBlue,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                rule,
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary,
                                                  height: 1.45,
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
                              const SizedBox(height: 22),

                              // Target URL or Username
                              _fieldLabel(
                                isSubscription
                                    ? 'Target Username (No @, No URL)'
                                    : 'Target Profile / Post / Video Link',
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _urlController,
                                onChanged: ctrl.setProfileUrl,
                                decoration: InputDecoration(
                                  hintText: isSubscription
                                      ? 'e.g. ade_victor'
                                      : 'https://...',
                                  prefixIcon: Icon(
                                    isSubscription
                                        ? Icons.alternate_email_rounded
                                        : Icons.link_rounded,
                                    size: 18,
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return isSubscription
                                        ? 'Please enter the target username'
                                        : 'Please enter the target post or profile link';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              // Conditional Custom Comments field
                              if (needsCustomText) ...[
                                _fieldLabel(
                                  'Custom Comments / Text (One per line)',
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _customTextController,
                                  maxLines: 4,
                                  onChanged: ctrl.setCustomText,
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Great post!\nAmazing content!\nLove this!',
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'This service requires custom comments/text (one per line)';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),
                              ],

                              // Conditional Poll Option Number
                              if (isPoll) ...[
                                _fieldLabel('Poll Option Number (1, 2, 3...)'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _pollAnswerController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (v) => ctrl.pollAnswerNumber.value =
                                      int.tryParse(v) ?? 1,
                                  decoration: const InputDecoration(
                                    hintText: '1',
                                    prefixIcon:
                                        Icon(Icons.poll_rounded, size: 18),
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ],

                              // Conditional Hashtag field
                              if (isHashtag) ...[
                                _fieldLabel('Target Hashtag (without #)'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _hashtagController,
                                  onChanged: (v) => ctrl.hashtag.value = v,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. lagosfashion',
                                    prefixIcon:
                                        Icon(Icons.tag_rounded, size: 18),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter a hashtag';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),
                              ],

                              // Quantity
                              _fieldLabel('Quantity'),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(10),
                                      border:
                                          Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_rounded,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            ctrl.decrementQuantity();
                                            _qtyController.text =
                                                '${ctrl.quantity.value}';
                                          },
                                        ),
                                        SizedBox(
                                          width: 92,
                                          child: TextField(
                                            controller: _qtyController,
                                            focusNode: _qtyFocusNode,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.montserrat(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              filled: false,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                vertical: 8,
                                                horizontal: 4,
                                              ),
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                            ),
                                            onChanged: (val) {
                                              final parsed = int.tryParse(
                                                val.replaceAll(',', ''),
                                              );
                                              if (parsed != null) {
                                                ctrl.setQuantity(
                                                  parsed.clamp(
                                                    service.minQuantity,
                                                    service.maxQuantity,
                                                  ),
                                                );
                                              }
                                            },
                                            onSubmitted: _commitQuantity,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_rounded,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            ctrl.incrementQuantity();
                                            _qtyController.text =
                                                '${ctrl.quantity.value}';
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      'Min: ${_fmt.format(service.minQuantity)} — Max: ${_fmt.format(service.maxQuantity)}',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Estimated delivery: ${service.estimatedDelivery}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Order Summary & Wallet Balance Verification
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order & Pricing Summary',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _summaryRow('Service', service.name),
                                    const SizedBox(height: 6),
                                    _summaryRow(
                                      'Platform & Region',
                                      '${platform.name} (${service.countryLabel})',
                                    ),
                                    const SizedBox(height: 6),
                                    _summaryRow(
                                      'Rate',
                                      '₦${_fmt.format(service.displayAmount)} ${service.displayUnit}',
                                    ),
                                    const SizedBox(height: 6),
                                    _summaryRow(
                                      'Quantity',
                                      _fmt.format(ctrl.quantity.value),
                                    ),
                                    const SizedBox(height: 6),
                                    _summaryRow(
                                      'Your Wallet Balance',
                                      '₦${_fmt.format(dashCtrl.walletBalance.value)}',
                                      valueColor: hasEnoughBalance
                                          ? AppColors.emeraldGreen
                                          : AppColors.error,
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total Order Cost',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          '₦${_fmt.format(total)}',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primaryNavy,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (!hasEnoughBalance) ...[
                                      const SizedBox(height: 14),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: AppColors.warning
                                                .withValues(alpha: 0.35),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons
                                                  .account_balance_wallet_rounded,
                                              size: 18,
                                              color: AppColors.warning,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Fund your wallet via Paystack with at least ₦${_fmt.format((total - dashCtrl.walletBalance.value).ceil().clamp(100, 10000000))} to complete this purchase.',
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton.icon(
                                              onPressed: () =>
                                                  _showQuickFundWalletModal(
                                                context,
                                                dashCtrl,
                                                suggestedAmount: (total -
                                                        dashCtrl.walletBalance
                                                            .value)
                                                    .ceilToDouble()
                                                    .clamp(100, 10000000),
                                              ),
                                              icon: const Icon(
                                                Icons.add_card_rounded,
                                                size: 15,
                                              ),
                                              label: const Text('Fund Wallet'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.emeraldGreen,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 10,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    999,
                                                  ),
                                                ),
                                                textStyle:
                                                    GoogleFonts.montserrat(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              if (_errorMessage.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Text(
                                  _errorMessage,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 22),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: ctrl.isSubmittingOrder.value
                                      ? null
                                      : () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            _handlePlaceOrder(
                                              context,
                                              service,
                                              platform,
                                            );
                                          }
                                        },
                                  icon: ctrl.isSubmittingOrder.value
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: AppColors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.rocket_launch_rounded,
                                          size: 18,
                                        ),
                                  label: Text(
                                    ctrl.isSubmittingOrder.value
                                        ? 'Submitting Order to Bigisub...'
                                        : (hasEnoughBalance
                                            ? 'Pay from Wallet & Place Order (₦${_fmt.format(total)})'
                                            : 'Fund Wallet via Paystack to Order'),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: hasEnoughBalance
                                        ? platform.color
                                        : AppColors.emeraldGreen,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    textStyle: GoogleFonts.montserrat(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Future<void> _handlePlaceOrder(
    BuildContext context,
    SocialService service,
    SocialPlatform platform,
  ) async {
    final dashCtrl = Get.find<DashboardController>();
    final authCtrl = Get.find<AuthController>();
    if (!authCtrl.isLoggedIn.value) {
      widget.onNavigate('/login');
      return;
    }

    final total = widget.controller.totalPrice;
    if (dashCtrl.walletBalance.value < total) {
      final needed = (total - dashCtrl.walletBalance.value)
          .ceilToDouble()
          .clamp(100.0, 10000000.0);
      await _showQuickFundWalletModal(
        context,
        dashCtrl,
        suggestedAmount: needed,
      );
      return;
    }

    setState(() => _errorMessage = '');
    widget.controller.isSubmittingOrder.value = true;
    try {
      final res = await dashCtrl.placeSocialBoostingOrder(
        service: service,
        platformName: platform.name,
        targetLinkOrUsername: _urlController.text.trim(),
        quantity: widget.controller.quantity.value,
        customText: _customTextController.text.trim(),
        pollAnswerNumber: widget.controller.pollAnswerNumber.value,
        hashtag: _hashtagController.text.trim(),
      );

      if (!context.mounted) return;
      if (res.error != null || res.order == null) {
        setState(() => _errorMessage = res.error ?? 'Unable to place order.');
        return;
      }

      _showOrderReceiptDialog(context, res.order!, service, platform);
    } finally {
      widget.controller.isSubmittingOrder.value = false;
    }
  }

  void _showOrderReceiptDialog(
    BuildContext context,
    Order order,
    SocialService service,
    SocialPlatform platform,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    size: 34,
                    color: AppColors.emeraldGreen,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Social Boosting Order Placed!',
                  style: GoogleFonts.montserrat(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNavy,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Your order has been dispatched to the Marketing Hub and is now being processed.',
                  style: GoogleFonts.montserrat(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _receiptRow('Transaction ID', order.id),
                      const SizedBox(height: 6),
                      _receiptRow(
                        'Platform',
                        '${platform.name} (${service.countryLabel})',
                      ),
                      const SizedBox(height: 6),
                      _receiptRow('Service', service.name),
                      const SizedBox(height: 6),
                      _receiptRow('Target', order.targetUrl ?? ''),
                      const SizedBox(height: 6),
                      _receiptRow('Quantity', _fmt.format(order.quantity)),
                      const SizedBox(height: 6),
                      _receiptRow(
                        'Start Count / Remains',
                        '${order.startCount ?? 0} / ${order.remains ?? order.quantity}',
                      ),
                      const SizedBox(height: 6),
                      _receiptRow('Paid From', 'RESOLVA Wallet Balance'),
                      const Divider(height: 18),
                      _receiptRow(
                        'Total Paid',
                        '₦${_fmt.format(order.amount)}',
                        highlight: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: order.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order ID copied to clipboard!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 15),
                        label: const Text('Copy ID'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          widget.controller.clearSelection();
                          widget.onNavigate('/dashboard/orders');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.royalBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text('Track in Dashboard'),
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

  Widget _receiptRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: GoogleFonts.montserrat(
              fontSize: highlight ? 14 : 12,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? AppColors.primaryNavy : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _showQuickFundWalletModal(
  BuildContext context,
  DashboardController dashCtrl, {
  double suggestedAmount = 2000,
}) async {
  final amountCtrl =
      TextEditingController(text: suggestedAmount.round().toString());
  String selectedMethod = 'Debit Card';
  bool processing = false;
  String modalError = '';
  final fmt = NumberFormat('#,##0', 'en_NG');

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fund Wallet via Paystack',
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
                  'Top up your RESOLVA wallet instantly to purchase Social Media Boosting or Examination E-Pins.',
                  style: GoogleFonts.montserrat(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Amount (NGN)',
                    prefixText: '₦ ',
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [1000, 2500, 5000, 10000].map((preset) {
                    return ActionChip(
                      label: Text('₦${fmt.format(preset)}'),
                      onPressed: () => setModalState(
                        () => amountCtrl.text = '$preset',
                      ),
                    );
                  }).toList(),
                ),
                if (modalError.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    modalError,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: processing
                        ? null
                        : () async {
                            final amt =
                                double.tryParse(amountCtrl.text.trim()) ?? 0;
                            if (amt < 100) {
                              setModalState(() {
                                modalError = 'Minimum top-up is ₦100.';
                              });
                              return;
                            }
                            setModalState(() {
                              processing = true;
                              modalError = '';
                            });
                            final res = await dashCtrl.fundWalletWithPaystack(
                              amount: amt,
                              selectedMethod: selectedMethod,
                            );
                            if (!ctx.mounted) return;
                            setModalState(() => processing = false);
                            if (res.cancelled) {
                              setModalState(() {
                                modalError =
                                    'Paystack checkout was closed before completion.';
                              });
                              return;
                            }
                            if (!res.isSuccess) {
                              setModalState(() {
                                modalError = res.message;
                              });
                              return;
                            }
                            Navigator.pop(ctx);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Wallet funded with ₦${fmt.format(res.amountNaira)}! You can now place your order.',
                                ),
                                backgroundColor: AppColors.emeraldGreen,
                              ),
                            );
                          },
                    icon: processing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.lock_rounded, size: 17),
                    label: Text(
                      processing
                          ? 'Connecting to Paystack...'
                          : 'Pay with Paystack',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emeraldGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
