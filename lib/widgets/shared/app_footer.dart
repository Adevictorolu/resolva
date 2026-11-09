import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../controllers/auth_controller.dart';
import 'common_widgets.dart';
import 'package:google_fonts/google_fonts.dart';

/// RESOLVA footer with service links, contact placeholders, and legal links.
class ResolvaFooter extends StatelessWidget {
  final Function(String) onNavigate;

  const ResolvaFooter({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobileView = width < 850;

    return Container(
      color: AppColors.primaryNavy,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxContentWidth + 48,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: isMobileView ? 40 : 64,
            ),
            child: Column(
              children: [
                isMobileView
                    ? _buildMobileLayout(context)
                    : _buildDesktopLayout(context),
                const SizedBox(height: 40),
                Divider(
                  color: AppColors.white.withValues(alpha: 0.14),
                  thickness: 1,
                ),
                const SizedBox(height: 24),
                _buildBottomBar(context, isMobileView),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildBrandSection()),
        const SizedBox(width: 48),
        Expanded(
          flex: 2,
          child: _buildLinksSection('Services', [
            _FooterLink('Examination E-Pins', '/exam-pins'),
            _FooterLink('Social Media Services', '/social-media'),
            _FooterLink('CAC Registration', '/cac'),
          ]),
        ),
        Expanded(
          flex: 2,
          child: _buildLinksSection('Company', [
            _FooterLink('About Us', '/about'),
            _FooterLink('Contact Us', '/contact'),
            _FooterLink('FAQ', '/faq'),
          ]),
        ),
        Expanded(
          flex: 2,
          child: Obx(() => _buildLinksSection('Account', _getAccountLinks())),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBrandSection(),
        const SizedBox(height: 32),
        _buildLinksSection('Services', [
          _FooterLink('Examination E-Pins', '/exam-pins'),
          _FooterLink('Social Media Services', '/social-media'),
          _FooterLink('CAC Registration', '/cac'),
        ]),
        const SizedBox(height: 24),
        _buildLinksSection('Company', [
          _FooterLink('About Us', '/about'),
          _FooterLink('Contact Us', '/contact'),
          _FooterLink('FAQ', '/faq'),
        ]),
        const SizedBox(height: 24),
        Obx(() => _buildLinksSection('Account', _getAccountLinks())),
      ],
    );
  }

  List<_FooterLink> _getAccountLinks() {
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      if (auth.isFullyAuthorized) {
        if (auth.isAdmin.value) {
          return const [
            _FooterLink('Admin Portal', '/admin'),
          ];
        }
        return const [
          _FooterLink('Dashboard', '/dashboard'),
          _FooterLink('My Orders', '/orders'),
        ];
      }
    }
    return const [
      _FooterLink('Login', '/login'),
      _FooterLink('Create Account', '/register'),
    ];
  }

  Widget _buildBrandSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ResolvaLogo(
          size: 38,
          isLightOnDark: true,
          showWordmark: true,
          fontSize: 20,
        ),
        const SizedBox(height: 16),
        Text(
          'A convenient platform for digital products and services in Nigeria.',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: AppColors.textSecondaryDark,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildLinksSection(String title, List<_FooterLink> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map(
          (link) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => onNavigate(link.route),
              child: Text(
                link.label,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: AppColors.textSecondaryDark,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isMobileView) {
    return isMobileView
        ? Column(
            children: [
              Text(
                '© 2026 RESOLVA. All rights reserved.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: AppColors.white.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 6,
                children: [
                  _legalLink('Privacy Policy', '/privacy-policy'),
                  _legalLink('Terms of Service', '/terms-of-service'),
                ],
              ),
            ],
          )
        : Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Text(
                '© 2026 RESOLVA. All rights reserved.',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: AppColors.white.withValues(alpha: 0.65),
                ),
              ),
              Wrap(
                spacing: 24,
                runSpacing: 6,
                children: [
                  _legalLink('Privacy Policy', '/privacy-policy'),
                  _legalLink('Terms of Service', '/terms-of-service'),
                ],
              ),
            ],
          );
  }

  Widget _legalLink(String label, String route) {
    return InkWell(
      onTap: () => onNavigate(route),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          color: AppColors.white.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}

class _FooterLink {
  final String label;
  final String route;
  const _FooterLink(this.label, this.route);
}
