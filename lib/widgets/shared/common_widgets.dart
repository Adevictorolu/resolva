import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// A polished service card with icon, title, description, brand logos, and modern pill action button.
class ServiceCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final List<String> tags;
  final Map<String, String>? tagLogos;
  final String buttonText;
  final VoidCallback? onTap;
  final bool isComingSoon;

  const ServiceCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    this.tags = const [],
    this.tagLogos,
    required this.buttonText,
    this.onTap,
    this.isComingSoon = false,
  });

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _isHovered ? -5 : 0, 0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHovered
                  ? widget.iconColor.withValues(alpha: 0.4)
                  : AppColors.border,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.iconColor.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: _isHovered ? 24 : 10,
                offset: Offset(0, _isHovered ? 10 : 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.iconColor.withValues(alpha: 0.16),
                            widget.iconColor.withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: widget.iconColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Icon(widget.icon, color: widget.iconColor, size: 26),
                    ),
                    if (widget.isComingSoon)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Coming Soon',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                      )
                    else if (widget.tagLogos != null && widget.tagLogos!.isNotEmpty)
                      Flexible(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: widget.tagLogos!.values.take(5).map((assetPath) {
                              return Container(
                                width: 34,
                                height: 34,
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    assetPath,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  widget.title,
                  style: GoogleFonts.montserrat(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.description,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                if (widget.tags.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.tags.map((tag) {
                      final logoAsset = widget.tagLogos?[tag];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.border),
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
                              const SizedBox(width: 7),
                            ],
                            Text(
                              tag,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: widget.isComingSoon
                      ? OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(widget.buttonText),
                        )
                      : ElevatedButton(
                          onPressed: widget.onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.iconColor,
                            foregroundColor: AppColors.white,
                            elevation: _isHovered ? 4 : 0,
                            shadowColor: widget.iconColor.withValues(alpha: 0.35),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.buttonText,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Status badge widget for orders, availability, etc.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  factory StatusBadge.available() => const StatusBadge(
    label: 'Available',
    color: AppColors.success,
  );

  factory StatusBadge.unavailable() => const StatusBadge(
    label: 'Unavailable',
    color: AppColors.error,
  );

  factory StatusBadge.pending() => const StatusBadge(
    label: 'Pending',
    color: AppColors.warning,
  );

  factory StatusBadge.processing() => const StatusBadge(
    label: 'Processing',
    color: AppColors.info,
  );

  factory StatusBadge.completed() => const StatusBadge(
    label: 'Completed',
    color: AppColors.success,
  );

  factory StatusBadge.cancelled() => const StatusBadge(
    label: 'Cancelled',
    color: AppColors.error,
  );

  factory StatusBadge.paid() => const StatusBadge(
    label: 'Paid',
    color: AppColors.success,
  );

  factory StatusBadge.failed() => const StatusBadge(
    label: 'Failed',
    color: AppColors.error,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Dashboard summary card with icon, label, and value.
class SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const SummaryCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state placeholder widget.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onButtonTap;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 36, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onButtonTap,
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Official RESOLVA Brand Logo widget.
///
/// Renders the official stylized 'R ESOLVA' brand mark (`logo_blue.png` or `logo_white.png`)
/// or the boxed badge (`logo_mark_blue.png`), with optional wordmark text for accessibility/testing.
class ResolvaLogo extends StatelessWidget {
  final double size;
  final bool isLightOnDark;
  final bool showWordmark;
  final bool useBoxedBadge;
  final double fontSize;
  final VoidCallback? onTap;

  const ResolvaLogo({
    super.key,
    this.size = 44,
    this.isLightOnDark = false,
    this.showWordmark = false,
    this.useBoxedBadge = false,
    this.fontSize = 22,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String assetPath = useBoxedBadge
        ? 'assets/images/logo_mark_blue.png'
        : (isLightOnDark ? 'assets/images/logo_white.png' : 'assets/images/logo_blue.png');

    Widget logoImage = Image.asset(
      assetPath,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isLightOnDark ? AppColors.white.withValues(alpha: 0.15) : AppColors.brandBlue,
            borderRadius: BorderRadius.circular(size * 0.25),
          ),
          child: Center(
            child: Text(
              'R',
              style: TextStyle(
                color: AppColors.white,
                fontSize: size * 0.52,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      },
    );

    if (useBoxedBadge) {
      logoImage = ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.26),
        child: SizedBox(
          width: size,
          height: size,
          child: logoImage,
        ),
      );
    }

    Widget result = !showWordmark
        ? logoImage
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              logoImage,
              const SizedBox(width: 10),
              Text(
                'RESOLVA',
                style: GoogleFonts.montserrat(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: isLightOnDark ? AppColors.white : AppColors.brandBlue,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          );

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: result,
        ),
      );
    }
    return result;
  }
}

/// Section heading used across pages.
class SectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool centered;

  const SectionHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.centered = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
          textAlign: centered ? TextAlign.center : TextAlign.start,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          Text(
            subtitle!,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: centered ? TextAlign.center : TextAlign.start,
          ),
        ],
      ],
    );
  }
}
