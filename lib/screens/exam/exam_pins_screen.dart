import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../controllers/exam_controller.dart';
import '../../data/models/exam_product.dart';
import '../../widgets/shared/app_navigation.dart';
import '../../widgets/shared/app_footer.dart';
import '../../widgets/shared/common_widgets.dart';
import 'package:google_fonts/google_fonts.dart';

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
                        subtitle: 'Find the examination products you need in one convenient place.',
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
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Category filters
                      Obx(() => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: controller.categories.map((cat) {
                            final isSelected = controller.selectedCategory.value == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(cat),
                                selected: isSelected,
                                onSelected: (_) => controller.selectCategory(cat),
                                selectedColor: AppColors.royalBlue.withValues(alpha: 0.1),
                                checkmarkColor: AppColors.royalBlue,
                                labelStyle: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
                padding: const EdgeInsets.all(24),
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
                          childAspectRatio: crossCount == 1 ? 1.6 : 0.85,
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
          ResolvaFooter(onNavigate: onNavigate),
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _hovered ? AppColors.royalBlue.withValues(alpha: 0.3) : AppColors.border),
          boxShadow: [
            BoxShadow(
              color: _hovered ? AppColors.royalBlue.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.02),
              blurRadius: _hovered ? 16 : 4,
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.provider,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.royalBlue,
                      ),
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
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: p.isAvailable ? widget.onBuyNow : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Buy Now'),
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
                              child: ElevatedButton(
                                onPressed: product.isAvailable
                                    ? () => _showDemoConfirmation(context, product)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  textStyle: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                child: const Text('Continue to Checkout'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'This is a frontend demonstration. No real purchase will occur.',
                                style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textTertiary),
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
          ResolvaFooter(onNavigate: onNavigate),
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

  void _showDemoConfirmation(BuildContext context, ExamProduct product) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, size: 32, color: AppColors.success),
                ),
                const SizedBox(height: 20),
                Text(
                  'Order Preview',
                  style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is a demonstration confirmation screen. No real purchase has been made.',
                  style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _demoRow('Product', product.name),
                      const SizedBox(height: 6),
                      _demoRow('Provider', product.provider),
                      const SizedBox(height: 6),
                      Obx(() => _demoRow('Quantity', '${controller.quantity.value}')),
                      const SizedBox(height: 6),
                      Obx(() => _demoRow('Total', '₦${_fmt.format(controller.totalPrice)}')),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      controller.clearSelection();
                    },
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _demoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
