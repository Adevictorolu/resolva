import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/exam_controller.dart';
import '../../data/models/exam_product.dart';
import '../../widgets/shared/app_navigation.dart';
import '../../widgets/shared/common_widgets.dart';
import 'package:google_fonts/google_fonts.dart';

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

/// Examination E-Pins marketplace screen.
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
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            color: AppColors.white,
            width: double.infinity,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth + 48),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: isMobile ? 32 : 48,
                  ),
                  child: Column(
                    children: [
                      const SectionHeading(
                        title: 'Examination E-Pins',
                        subtitle: 'Instant WAEC, NECO, NABTEB & JAMB examination pins and scratch cards.',
                      ),
                      const SizedBox(height: 32),
                      // Search
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: TextField(
                          onChanged: controller.search,
                          decoration: InputDecoration(
                            hintText: 'Search examination products...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
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
                      Obx(() => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: controller.categories.map((cat) {
                            final isSelected = controller.selectedCategory.value == cat;
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
                                onSelected: (_) => controller.selectCategory(cat),
                                selectedColor: AppColors.royalBlue.withValues(alpha: 0.12),
                                checkmarkColor: AppColors.royalBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                labelStyle: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: isSelected ? AppColors.royalBlue : AppColors.textSecondary,
                                ),
                                side: BorderSide(
                                  color: isSelected ? AppColors.royalBlue : AppColors.border,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Product grid
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth + 48),
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
                      final crossCount = constraints.maxWidth < 500 ? 1 : (constraints.maxWidth < 800 ? 2 : 3);
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossCount,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: crossCount == 1 ? 1.55 : 0.85,
                        ),
                        itemCount: controller.filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = controller.filteredProducts[index];
                          return _ExamProductCard(
                            product: product,
                            onViewDetails: () => controller.selectProduct(product),
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
            color: _hovered ? AppColors.royalBlue.withValues(alpha: 0.35) : AppColors.border,
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.2)),
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
                  p.isAvailable ? StatusBadge.available() : StatusBadge.unavailable(),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  p.description,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '₦${widget.fmt.format(p.price)}',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onViewDetails,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        textStyle: GoogleFonts.montserrat(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: p.isAvailable ? widget.onBuyNow : null,
                      icon: const Icon(Icons.bolt_rounded, size: 16),
                      label: const Text('Buy Now'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        textStyle: GoogleFonts.montserrat(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
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

// ──────────── PRODUCT DETAIL ────────────

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
  late final TextEditingController _qtyController;
  final FocusNode _qtyFocusNode = FocusNode();
  Worker? _qtyWorker;

  ExamController get controller => widget.controller;
  Function(String) get onNavigate => widget.onNavigate;
  bool get isMobile => widget.isMobile;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '${controller.quantity.value}');
    _qtyWorker = ever<int>(controller.quantity, (val) {
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
    super.dispose();
  }

  void _commitQuantity(String raw) {
    final max = controller.selectedProduct.value?.maxQuantity ?? 10;
    final parsed = int.tryParse(raw.trim());
    if (parsed == null || parsed < 1) {
      controller.setQuantity(1);
      _qtyController.text = '1';
    } else if (parsed > max) {
      controller.setQuantity(max);
      _qtyController.text = '$max';
    } else {
      controller.setQuantity(parsed);
      _qtyController.text = '$parsed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 20 : 48),
                child: Obx(() {
                  final product = controller.selectedProduct.value;
                  if (product == null) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      TextButton.icon(
                        onPressed: controller.clearSelection,
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Back to Products'),
                      ),
                      const SizedBox(height: 24),
                      // Product info card
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.royalBlue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    product.provider,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.royalBlue,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                product.isAvailable ? StatusBadge.available() : StatusBadge.unavailable(),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              product.name,
                              style: GoogleFonts.montserrat(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              product.description,
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 24),
                            // Price
                            Text(
                              'Price',
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
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Quantity
                            Text(
                              'Quantity',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_rounded, size: 18),
                                        onPressed: () {
                                          controller.decrementQuantity();
                                          _qtyController.text = '${controller.quantity.value}';
                                        },
                                      ),
                                      SizedBox(
                                        width: 64,
                                        child: TextField(
                                          controller: _qtyController,
                                          focusNode: _qtyFocusNode,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            filled: false,
                                            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                          ),
                                          onChanged: (val) {
                                            final parsed = int.tryParse(val);
                                            if (parsed != null) {
                                              final max = product.maxQuantity ?? 10;
                                              controller.setQuantity(parsed.clamp(1, max));
                                            }
                                          },
                                          onSubmitted: _commitQuantity,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_rounded, size: 18),
                                        onPressed: () {
                                          controller.incrementQuantity();
                                          _qtyController.text = '${controller.quantity.value}';
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            // Order summary
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  _summaryRow('Product', product.name),
                                  const SizedBox(height: 8),
                                  _summaryRow('Unit Price', '₦${_fmt.format(product.price)}'),
                                  const SizedBox(height: 8),
                                  Obx(() => _summaryRow('Quantity', '${controller.quantity.value}')),
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  Obx(() => Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '₦${_fmt.format(controller.totalPrice)}',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryNavy,
                                        ),
                                      ),
                                    ],
                                  )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: product.isAvailable
                                    ? () => _handleCheckout(context, product)
                                    : null,
                                icon: const Icon(Icons.lock_outline_rounded, size: 18),
                                label: const Text('Complete Purchase'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  textStyle: GoogleFonts.montserrat(
                                    fontSize: 15,
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

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.textSecondary)),
        Text(value, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }

  void _handleCheckout(BuildContext context, ExamProduct product) {
    final dashCtrl = Get.find<DashboardController>();
    final total = controller.totalPrice;
    final qty = controller.quantity.value;
    final method = dashCtrl.walletBalance.value >= total ? 'Wallet Balance' : 'Instant Checkout';

    final order = dashCtrl.placeOrder(
      productName: product.name,
      category: 'Examination E-Pins',
      amount: total,
      quantity: qty,
      paymentMethod: method,
      details: '${product.provider} — ${product.name} (x$qty)',
      isInstantPin: true,
    );

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(32),
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
                  child: const Icon(Icons.verified_rounded, size: 34, color: AppColors.success),
                ),
                const SizedBox(height: 18),
                Text(
                  'Order Completed',
                  style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your ${product.provider} e-pin(s) have been generated and saved to your dashboard.',
                  style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      _receiptRow('Order ID', order.id),
                      const SizedBox(height: 6),
                      _receiptRow('Product', product.name),
                      const SizedBox(height: 6),
                      _receiptRow('Provider', product.provider),
                      const SizedBox(height: 6),
                      _receiptRow('Quantity', '$qty'),
                      const SizedBox(height: 6),
                      _receiptRow('Total Paid', '₦${_fmt.format(total)}'),
                      if (order.pins != null && order.pins!.isNotEmpty) ...[
                        const Divider(height: 20),
                        Text(
                          'Generated E-PIN: ${order.pins!.first}',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.royalBlue,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          controller.clearSelection();
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
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
                          onNavigate('/orders');
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        child: const Text('View Order'),
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
        Text(label, style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
