import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/exam_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/exam_product.dart';
import '../../data/models/order.dart';
import '../../widgets/shared/app_navigation.dart';
import '../../widgets/shared/common_widgets.dart';

String? _examLogoAsset(String provider) {
  switch (provider.toUpperCase()) {
    case 'WAEC':
      return 'assets/images/waec_logo.png';
    case 'NECO':
      return 'assets/images/neco_logo.png';
    case 'NABTEB':
      return 'assets/images/nabteb_logo.png';
    case 'JAMB':
      return 'assets/images/jamb_logo.png';
    default:
      return null;
  }
}

/// Other Services — Examination E-Pins marketplace screen powered by Bigisub Education API
/// (`https://rif.africa/technotronics/api/bigisub/education`).
class ExamPinsScreen extends StatelessWidget {
  final Function(String) onNavigate;

  const ExamPinsScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExamController>();
    final width = MediaQuery.of(context).size.width;
    final isMobileView = isMobile(width);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: ResolvaDrawer(onNavigate: onNavigate),
      body: Column(
        children: [
          ResolvaAppBar(currentIndex: 1, onNavigate: onNavigate),
          Expanded(
            child: Obx(() {
              if (controller.selectedProduct.value != null) {
                return _ProductDetailView(
                  controller: controller,
                  onNavigate: onNavigate,
                  isMobile: isMobileView,
                );
              }
              return _ProductListView(
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

// ──────────── PRODUCT LIST ────────────

class _ProductListView extends StatelessWidget {
  final ExamController controller;
  final Function(String) onNavigate;
  final bool isMobile;

  const _ProductListView({
    required this.controller,
    required this.onNavigate,
    required this.isMobile,
  });

  static final _fmt = NumberFormat('#,##0', 'en_NG');

  @override
  Widget build(BuildContext context) {
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
                    vertical: isMobile ? 32 : 48,
                  ),
                  child: Column(
                    children: [
                      const SectionHeading(
                        title: 'Other Services — Examination E-Pins',
                        subtitle:
                            'Official WAEC, NECO & NABTEB Result Checker PINs delivered instantly to your Order & E-PIN Vault.',
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
                                onTap: () =>
                                    _showExamQuickFundModal(context, dashCtrl),
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

                      // Search
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: TextField(
                          onChanged: controller.search,
                          decoration: InputDecoration(
                            hintText:
                                'Search WAEC, NECO, or NABTEB result checkers...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Category filters with brand logos
                      Obx(
                        () => SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: controller.categories.map((cat) {
                              final isSelected =
                                  controller.selectedCategory.value == cat;
                              final logo = _examLogoAsset(cat);
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  avatar: logo != null
                                      ? ClipOval(
                                          child: Image.asset(
                                            logo,
                                            width: 18,
                                            height: 18,
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                      : null,
                                  label: Text(cat),
                                  selected: isSelected,
                                  onSelected: (_) =>
                                      controller.selectCategory(cat),
                                  selectedColor: AppColors.royalBlue
                                      .withValues(alpha: 0.12),
                                  checkmarkColor: AppColors.royalBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  labelStyle: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.royalBlue
                                        : AppColors.textSecondary,
                                  ),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.royalBlue
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

          // Product grid
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstants.maxContentWidth + 48,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                child: Obx(() {
                  if (controller.filteredProducts.isEmpty) {
                    return const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No products found',
                      subtitle: 'Try adjusting your search or filter criteria.',
                    );
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final crossCount = constraints.maxWidth < 500
                          ? 1
                          : (constraints.maxWidth < 800 ? 2 : 3);
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossCount,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          mainAxisExtent: 295,
                        ),
                        itemCount: controller.filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = controller.filteredProducts[index];
                          return _ExamProductCard(
                            product: product,
                            onViewDetails: () =>
                                controller.selectProduct(product),
                            onBuyNow: () => controller.selectProduct(product),
                            fmt: _fmt,
                          );
                        },
                      );
                    },
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

class _ExamProductCard extends StatefulWidget {
  final ExamProduct product;
  final VoidCallback onViewDetails;
  final VoidCallback onBuyNow;
  final NumberFormat fmt;

  const _ExamProductCard({
    required this.product,
    required this.onViewDetails,
    required this.onBuyNow,
    required this.fmt,
  });

  @override
  State<_ExamProductCard> createState() => _ExamProductCardState();
}

class _ExamProductCardState extends State<_ExamProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final logoAsset = _examLogoAsset(p.provider);

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
            color: _hovered
                ? AppColors.royalBlue.withValues(alpha: 0.35)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? AppColors.royalBlue.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: _hovered ? 20 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.royalBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (logoAsset != null) ...[
                          Image.asset(
                            logoAsset,
                            width: 18,
                            height: 18,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          p.provider,
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.royalBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  p.isAvailable
                      ? StatusBadge.available()
                      : StatusBadge.unavailable(),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                p.name,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  p.description,
                  style: GoogleFonts.montserrat(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.verified_outlined,
                    size: 14,
                    color: AppColors.emeraldGreen,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      p.validity,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.emeraldGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price per PIN',
                        style: GoogleFonts.montserrat(
                          fontSize: 10.5,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      Text(
                        '₦${widget.fmt.format(p.price)}',
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: p.isAvailable ? widget.onBuyNow : null,
                    icon: const Icon(Icons.bolt_rounded, size: 16),
                    label: const Text('Buy PIN'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      textStyle: GoogleFonts.montserrat(
                        fontSize: 12.5,
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
}

// ──────────── PRODUCT DETAIL & CHECKOUT ────────────

class _ProductDetailView extends StatefulWidget {
  final ExamController controller;
  final Function(String) onNavigate;
  final bool isMobile;

  const _ProductDetailView({
    required this.controller,
    required this.onNavigate,
    required this.isMobile,
  });

  @override
  State<_ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<_ProductDetailView> {
  static final _fmt = NumberFormat('#,##0', 'en_NG');
  final _pinController = TextEditingController();
  String _errorMessage = '';

  ExamController get controller => widget.controller;
  Function(String) get onNavigate => widget.onNavigate;
  bool get isMobile => widget.isMobile;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashCtrl = Get.find<DashboardController>();

    return SingleChildScrollView(
      child: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 740),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 20 : 44),
                child: Obx(() {
                  final product = controller.selectedProduct.value;
                  if (product == null) return const SizedBox.shrink();
                  final total = controller.totalPrice;
                  final hasEnoughBalance =
                      dashCtrl.walletBalance.value >= total;
                  final logoAsset = _examLogoAsset(product.provider);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton.icon(
                        onPressed: controller.clearSelection,
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Back to Examination E-Pins'),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: EdgeInsets.all(isMobile ? 20 : 28),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.royalBlue
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (logoAsset != null) ...[
                                        Image.asset(
                                          logoAsset,
                                          width: 18,
                                          height: 18,
                                          fit: BoxFit.contain,
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Text(
                                        product.provider,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.royalBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                StatusBadge.available(),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              product.name,
                              style: GoogleFonts.montserrat(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              product.description,
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.emeraldGreen
                                    .withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.emeraldGreen
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: AppColors.emeraldGreen,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${product.validity} • PIN & Serial are returned immediately upon purchase and saved in your Order & E-PIN Vault.',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryNavy,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            const Divider(),
                            const SizedBox(height: 20),

                            // Unit Price
                            Text(
                              'Unit Price',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₦${_fmt.format(product.price)}',
                              style: GoogleFonts.montserrat(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Bigisub Allowed Quantities (1, 2, or 5 PINs)
                            Text(
                              'Select Quantity (1, 2, or 5 PINs)',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: product.allowedQuantities.map((qtyOpt) {
                                final isSelected =
                                    controller.quantity.value == qtyOpt;
                                return ChoiceChip(
                                  label: Text(
                                    '$qtyOpt ${qtyOpt == 1 ? "PIN" : "PINs"} (₦${_fmt.format(product.price * qtyOpt)})',
                                  ),
                                  selected: isSelected,
                                  onSelected: (_) =>
                                      controller.setQuantity(qtyOpt),
                                  selectedColor: AppColors.royalBlue,
                                  backgroundColor: AppColors.background,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  labelStyle: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppColors.white
                                        : AppColors.textPrimary,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 22),

                            // Optional 4-digit Transaction PIN
                            Text(
                              'Transaction PIN (Optional if already verified)',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 240,
                              child: TextField(
                                controller: _pinController,
                                obscureText: true,
                                maxLength: 6,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  hintText: '••••',
                                  counterText: '',
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Order Summary
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                children: [
                                  _summaryRow('Examination', product.provider),
                                  const SizedBox(height: 8),
                                  _summaryRow('Product', product.name),
                                  const SizedBox(height: 8),
                                  _summaryRow(
                                    'Unit Price',
                                    '₦${_fmt.format(product.price)}',
                                  ),
                                  const SizedBox(height: 8),
                                  _summaryRow(
                                    'Quantity',
                                    '${controller.quantity.value} PIN(s)',
                                  ),
                                  const SizedBox(height: 8),
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
                                        'Total Amount',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
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
                                        borderRadius: BorderRadius.circular(10),
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
                                              'Fund your wallet via Paystack with at least ₦${_fmt.format((total - dashCtrl.walletBalance.value).ceil().clamp(100, 10000000))} to purchase this E-PIN.',
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
                                                _showExamQuickFundModal(
                                              context,
                                              dashCtrl,
                                              suggestedAmount: (total -
                                                      dashCtrl
                                                          .walletBalance.value)
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
                                                    BorderRadius.circular(999),
                                              ),
                                              textStyle: GoogleFonts.montserrat(
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
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: controller.isSubmittingOrder.value
                                    ? null
                                    : () => _handleCheckout(context, product),
                                icon: controller.isSubmittingOrder.value
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.lock_outline_rounded,
                                        size: 18,
                                      ),
                                label: Text(
                                  controller.isSubmittingOrder.value
                                      ? 'Generating Official Result Checker PIN...'
                                      : (hasEnoughBalance
                                          ? 'Pay from Wallet & Get E-PIN (₦${_fmt.format(total)})'
                                          : 'Fund Wallet via Paystack to Purchase'),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: hasEnoughBalance
                                      ? AppColors.royalBlue
                                      : AppColors.emeraldGreen,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
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
        ],
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
            fontSize: 13.5,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Future<void> _handleCheckout(
    BuildContext context,
    ExamProduct product,
  ) async {
    final dashCtrl = Get.find<DashboardController>();
    final authCtrl = Get.find<AuthController>();
    if (!authCtrl.isLoggedIn.value) {
      onNavigate('/login');
      return;
    }

    final total = controller.totalPrice;
    if (dashCtrl.walletBalance.value < total) {
      final needed = (total - dashCtrl.walletBalance.value)
          .ceilToDouble()
          .clamp(100.0, 10000000.0);
      await _showExamQuickFundModal(
        context,
        dashCtrl,
        suggestedAmount: needed,
      );
      return;
    }

    setState(() => _errorMessage = '');
    controller.isSubmittingOrder.value = true;
    try {
      final res = await dashCtrl.placeExamPinOrder(
        product: product,
        quantity: controller.quantity.value,
        pinCode: _pinController.text.trim(),
      );

      if (!context.mounted) return;
      if (res.error != null || res.order == null) {
        setState(() => _errorMessage = res.error ?? 'Purchase failed.');
        return;
      }

      _showExamReceiptDialog(context, res.order!, product);
    } finally {
      controller.isSubmittingOrder.value = false;
    }
  }

  void _showExamReceiptDialog(
    BuildContext context,
    Order order,
    ExamProduct product,
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
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    size: 34,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${product.provider} E-PIN Delivered!',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your ${product.name} PIN(s) have been issued and saved to your Order & E-PIN Vault.',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
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
                      if (order.bigisubReference != null &&
                          order.bigisubReference!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _receiptRow('Reference', order.bigisubReference!),
                      ],
                      const SizedBox(height: 6),
                      _receiptRow('Exam Type', product.provider),
                      const SizedBox(height: 6),
                      _receiptRow('Product', product.name),
                      const SizedBox(height: 6),
                      _receiptRow('Quantity', '${order.quantity}'),
                      const SizedBox(height: 6),
                      _receiptRow(
                        'Total Paid',
                        '₦${_fmt.format(order.amount)}',
                      ),
                      if (order.pins != null && order.pins!.isNotEmpty) ...[
                        const Divider(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'RESULT CHECKER PIN(S):',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...order.pins!.map(
                          (pin) => Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.royalBlue
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    pin,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.royalBlue,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    size: 16,
                                    color: AppColors.royalBlue,
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: pin));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('PIN copied to clipboard!'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          controller.clearSelection();
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text('Done'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          controller.clearSelection();
                          onNavigate('/dashboard/orders');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.royalBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text('Open E-PIN Vault'),
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

  Widget _receiptRow(String label, String value) {
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
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _showExamQuickFundModal(
  BuildContext context,
  DashboardController dashCtrl, {
  double suggestedAmount = 5250,
}) async {
  final amountCtrl =
      TextEditingController(text: suggestedAmount.round().toString());
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
                  'Top up your RESOLVA wallet via Paystack to purchase WAEC, NECO, or NABTEB Result Checker PINs.',
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
                  children: [1000, 2500, 5250, 10500].map((preset) {
                    return ActionChip(
                      label: Text('₦${fmt.format(preset)}'),
                      onPressed: () =>
                          setModalState(() => amountCtrl.text = '$preset'),
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
                              selectedMethod: 'Debit Card',
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
                                  'Wallet funded with ₦${fmt.format(res.amountNaira)}! You can now complete your purchase.',
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
