import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../controllers/social_controller.dart';
import '../../data/models/social_service.dart';
import '../../widgets/shared/app_navigation.dart';
import '../../widgets/shared/app_footer.dart';
import '../../widgets/shared/common_widgets.dart';
import 'package:google_fonts/google_fonts.dart';

/// Social Media Services marketplace screen.
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

class _ServiceListView extends StatelessWidget {
  final SocialController controller;
  final Function(String) onNavigate;
  final bool isMobile;

  const _ServiceListView({
    required this.controller,
    required this.onNavigate,
    required this.isMobile,
  });

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
                        title: 'Grow Your Social Presence',
                        subtitle: 'Explore engagement services for your content, brand, or business.',
                      ),
                      const SizedBox(height: 36),
                      // Platform cards
                      _PlatformSelector(controller: controller, isMobile: isMobile),
                      const SizedBox(height: 24),
                      // Category filters
                      Obx(() => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: controller.categories.map((cat) {
                            final isSelected = controller.selectedCategory.value == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(cat),
                                selected: isSelected,
                                onSelected: (_) => controller.selectCategory(cat),
                                selectedColor: AppColors.emeraldGreen.withValues(alpha: 0.1),
                                checkmarkColor: AppColors.emeraldGreen,
                                labelStyle: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? AppColors.emeraldGreen : AppColors.textSecondary,
                                ),
                                side: BorderSide(
                                  color: isSelected ? AppColors.emeraldGreen : AppColors.border,
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
          // Service grid
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth + 48),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Obx(() {
                  if (controller.filteredServices.isEmpty) {
                    return const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No services found',
                      subtitle: 'Try selecting a different platform or category.',
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
                          childAspectRatio: crossCount == 1 ? 1.5 : 0.78,
                        ),
                        itemCount: controller.filteredServices.length,
                        itemBuilder: (context, index) {
                          final service = controller.filteredServices[index];
                          final platform = controller.platforms.firstWhere(
                            (p) => p.id == service.platformId,
                          );
                          return _SocialServiceCard(
                            service: service,
                            platform: platform,
                            onOrder: () => controller.selectService(service),
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

class _PlatformSelector extends StatelessWidget {
  final SocialController controller;
  final bool isMobile;

  const _PlatformSelector({required this.controller, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: controller.platforms.map((platform) {
        final isSelected = controller.selectedPlatformId.value == platform.id;
        return InkWell(
          onTap: () => controller.selectPlatform(platform.id),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 20,
              vertical: isMobile ? 10 : 14,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? platform.color.withValues(alpha: 0.1)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? platform.color : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  platform.icon,
                  size: 18,
                  color: isSelected ? platform.color : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  platform.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? platform.color : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ));
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
  static final _fmt = NumberFormat('#,##0', 'en_NG');

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final p = widget.platform;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _hovered ? p.color.withValues(alpha: 0.3) : AppColors.border),
          boxShadow: [
            BoxShadow(
              color: _hovered ? p.color.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.02),
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: p.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: FaIcon(p.icon, size: 18, color: p.color)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: p.color),
                        ),
                        Text(
                          s.category,
                          style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                s.name,
                style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  s.description,
                  style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),
              // Meta info
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    s.estimatedDelivery,
                    style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.textTertiary),
                  ),
                  const Spacer(),
                  Text(
                    '${_fmt.format(s.minQuantity)} – ${_fmt.format(s.maxQuantity)}',
                    style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From',
                        style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.textTertiary),
                      ),
                      Text(
                        '₦${_fmt.format(s.startingPrice)}',
                        style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryNavy),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: widget.onOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.color,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      textStyle: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Order Now'),
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
  late final TextEditingController _qtyController;
  final FocusNode _qtyFocusNode = FocusNode();
  Worker? _qtyWorker;
  static final _fmt = NumberFormat('#,##0', 'en_NG');

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '${widget.controller.quantity.value}');
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

    return SingleChildScrollView(
      child: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Padding(
                padding: EdgeInsets.all(widget.isMobile ? 20 : 48),
                child: Form(
                  key: _formKey,
                  child: Obx(() {
                    final service = ctrl.selectedService.value;
                    if (service == null) return const SizedBox.shrink();
                    final platform = ctrl.selectedPlatform;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton.icon(
                          onPressed: ctrl.clearSelection,
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Back to Services'),
                        ),
                        const SizedBox(height: 24),
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
                              Text(
                                'Place Order',
                                style: GoogleFonts.montserrat(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Platform
                              _fieldLabel('Platform'),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    if (platform != null) ...[
                                      FaIcon(platform.icon, size: 16, color: platform.color),
                                      const SizedBox(width: 10),
                                      Text(
                                        platform.name,
                                        style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Service
                              _fieldLabel('Service'),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  service.name,
                                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // URL
                              _fieldLabel('Profile / Post / Video URL'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _urlController,
                                onChanged: ctrl.setProfileUrl,
                                decoration: const InputDecoration(
                                  hintText: 'https://...',
                                  prefixIcon: Icon(Icons.link_rounded, size: 18),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Please enter a URL';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Never share your password. We only need the public URL.',
                                style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textTertiary),
                              ),
                              const SizedBox(height: 20),
                              // Quantity
                              _fieldLabel('Quantity'),
                              const SizedBox(height: 6),
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
                                            ctrl.decrementQuantity();
                                            _qtyController.text = '${ctrl.quantity.value}';
                                          },
                                        ),
                                        SizedBox(
                                          width: 88,
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
                                              final parsed = int.tryParse(val.replaceAll(',', ''));
                                              if (parsed != null) {
                                                ctrl.setQuantity(
                                                  parsed.clamp(service.minQuantity, service.maxQuantity),
                                                );
                                              }
                                            },
                                            onSubmitted: _commitQuantity,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_rounded, size: 18),
                                          onPressed: () {
                                            ctrl.incrementQuantity();
                                            _qtyController.text = '${ctrl.quantity.value}';
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      'Min: ${_fmt.format(service.minQuantity)} — Max: ${_fmt.format(service.maxQuantity)}',
                                      style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textTertiary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Estimated delivery: ${service.estimatedDelivery}',
                                style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textTertiary),
                              ),
                              const SizedBox(height: 28),
                              // Order summary
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order Summary',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _summaryRow('Service', service.name),
                                    const SizedBox(height: 6),
                                    _summaryRow('Platform', platform?.name ?? ''),
                                    const SizedBox(height: 6),
                                    _summaryRow('Price per unit', '₦${_fmt.format(service.pricePerUnit)}'),
                                    const SizedBox(height: 6),
                                    Obx(() => _summaryRow('Quantity', _fmt.format(ctrl.quantity.value))),
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    const SizedBox(height: 12),
                                    Obx(() => Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Estimated Total',
                                          style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700),
                                        ),
                                        Text(
                                          '₦${_fmt.format(ctrl.totalPrice)}',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 24,
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
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      _showDemoConfirmation(context, service, platform);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: platform?.color ?? AppColors.royalBlue,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    textStyle: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                  child: const Text('Continue'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: Text(
                                  'This is a frontend demonstration. No real order will be placed.',
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
          ),
          ResolvaFooter(onNavigate: widget.onNavigate),
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

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSecondary)),
        Flexible(
          child: Text(value, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.end),
        ),
      ],
    );
  }

  void _showDemoConfirmation(BuildContext context, SocialService service, SocialPlatform? platform) {
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
                  'Demo Order Review',
                  style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is a demonstration order review. No order has been sent to a real supplier.',
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
                      _demoRow('Service', service.name),
                      const SizedBox(height: 6),
                      _demoRow('Platform', platform?.name ?? ''),
                      const SizedBox(height: 6),
                      Obx(() => _demoRow('Quantity', _fmt.format(widget.controller.quantity.value))),
                      const SizedBox(height: 6),
                      Obx(() => _demoRow('Total', '₦${_fmt.format(widget.controller.totalPrice)}')),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      widget.controller.clearSelection();
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
        Flexible(child: Text(value, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.end)),
      ],
    );
  }
}
