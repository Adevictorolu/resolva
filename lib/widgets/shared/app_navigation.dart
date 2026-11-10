import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../controllers/auth_controller.dart';
import 'common_widgets.dart';
export '../../core/constants/app_constants.dart' show isMobile, isTablet, isDesktop;

/// Responsive sticky centered glassmorphic navigation bar for RESOLVA.
///
/// - Public visitors see: Home, About Us, Our Services, How It Works, FAQ, Terms & Conditions, Login, Get Started.
/// - Authenticated customers see: Dashboard, Examination E-Pins, Social Media, CAC Registration, Logout.
/// - Authenticated admins see: Home, Admin Panel, Logout.
class ResolvaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentIndex;
  final Function(String) onNavigate;

  const ResolvaAppBar({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  Size get preferredSize => const Size.fromHeight(88);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 1024;
    final authController = Get.find<AuthController>();
    final currentRoute = Get.currentRoute;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isCompact ? 12 : 24,
          isCompact ? 10 : 14,
          isCompact ? 12 : 24,
          8,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryNavy.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppColors.royalBlue.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    height: isCompact ? 60 : 66,
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 16 : 24,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.86),
                          Colors.white.withValues(alpha: 0.72),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 1.2,
                      ),
                    ),
                    child: Obx(() {
                      final isAuthorized = authController.isFullyAuthorized;
                      final isAdmin = authController.isAdmin.value;

                      if (isCompact) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ResolvaLogo(
                              size: 28,
                              onTap: () => onNavigate('/'),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isAuthorized) ...[
                                  _CompactGetStartedButton(
                                    onTap: () => onNavigate('/register'),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryNavy.withValues(alpha: 0.06),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.menu_rounded,
                                      color: AppColors.primaryNavy,
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      Scaffold.of(context).openDrawer();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      // Desktop centered glassmorphic layout
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Brand Logo
                          ResolvaLogo(
                            size: 30,
                            onTap: () => onNavigate('/'),
                          ),

                          // Centered Navigation Links
                          Flexible(
                            child: Center(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: isAuthorized
                                      ? _buildAuthorizedNavItems(isAdmin)
                                      : _buildPublicNavItems(currentRoute),
                                ),
                              ),
                            ),
                          ),

                          // Right Action Buttons
                          _buildActionButtons(authController, isAuthorized, isAdmin),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPublicNavItems(String currentRoute) {
    return [
      _NavItem(
        label: 'Home',
        isActive: currentIndex == 0 && currentRoute == '/',
        onTap: () => onNavigate('/'),
      ),
      _NavItem(
        label: 'About Us',
        isActive: currentRoute == '/about',
        onTap: () => onNavigate('/about'),
      ),
      _NavItem(
        label: 'Our Services',
        isActive: false,
        onTap: () => onNavigate('/#services'),
      ),
      _NavItem(
        label: 'How It Works',
        isActive: false,
        onTap: () => onNavigate('/#how-it-works'),
      ),
      _NavItem(
        label: 'FAQ',
        isActive: currentRoute == '/faq',
        onTap: () => onNavigate('/faq'),
      ),
      _NavItem(
        label: 'Terms & Conditions',
        isActive: currentRoute == '/terms-of-service',
        onTap: () => onNavigate('/terms-of-service'),
      ),
    ];
  }

  List<Widget> _buildAuthorizedNavItems(bool isAdmin) {
    if (isAdmin) {
      return [
        _NavItem(
          label: 'Home',
          isActive: currentIndex == 0,
          onTap: () => onNavigate('/'),
        ),
        _NavItem(
          label: 'Admin Panel',
          isActive: currentIndex == 5,
          onTap: () => onNavigate('/admin'),
          icon: Icons.admin_panel_settings_rounded,
        ),
      ];
    }
    return [
      _NavItem(
        label: 'Dashboard',
        isActive: currentIndex == 4,
        onTap: () => onNavigate('/dashboard'),
        icon: Icons.grid_view_rounded,
      ),
      _NavItem(
        label: 'Examination E-Pins',
        isActive: currentIndex == 1,
        onTap: () => onNavigate('/exam-pins'),
        icon: Icons.school_rounded,
      ),
      _NavItem(
        label: 'Social Media',
        isActive: currentIndex == 2,
        onTap: () => onNavigate('/social-media'),
        icon: Icons.trending_up_rounded,
      ),
      _NavItem(
        label: 'CAC Registration',
        isActive: currentIndex == 3,
        onTap: () => onNavigate('/cac'),
        icon: Icons.domain_verification_rounded,
      ),
    ];
  }

  Widget _buildActionButtons(
    AuthController authController,
    bool isAuthorized,
    bool isAdmin,
  ) {
    if (isAuthorized) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModernPillButton(
            label: isAdmin ? 'Admin Portal' : 'My Account',
            icon: isAdmin
                ? Icons.admin_panel_settings_rounded
                : Icons.person_rounded,
            isPrimary: true,
            onTap: () => onNavigate(isAdmin ? '/admin' : '/dashboard'),
          ),
          const SizedBox(width: 8),
          _ModernPillButton(
            label: 'Logout',
            icon: Icons.logout_rounded,
            isPrimary: false,
            isDanger: true,
            onTap: () {
              authController.logout();
              onNavigate('/');
            },
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ModernPillButton(
          label: 'Login',
          icon: Icons.login_rounded,
          isPrimary: false,
          onTap: () => onNavigate('/login'),
        ),
        const SizedBox(width: 8),
        _ModernPillButton(
          label: 'Get Started',
          icon: Icons.arrow_forward_rounded,
          isPrimary: true,
          onTap: () => onNavigate('/register'),
        ),
      ],
    );
  }
}

class _CompactGetStartedButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CompactGetStartedButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.royalBlue, AppColors.electricBlue],
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Get Started',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernPillButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isDanger;
  final VoidCallback onTap;

  const _ModernPillButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  State<_ModernPillButton> createState() => _ModernPillButtonState();
}

class _ModernPillButtonState extends State<_ModernPillButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bgGradient = widget.isPrimary
        ? const LinearGradient(
            colors: [AppColors.royalBlue, AppColors.electricBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    final fgColor = widget.isPrimary
        ? AppColors.white
        : (widget.isDanger ? AppColors.error : AppColors.primaryNavy);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: bgGradient,
            color: widget.isPrimary
                ? null
                : (_hovered
                    ? (widget.isDanger
                        ? AppColors.error.withValues(alpha: 0.08)
                        : AppColors.primaryNavy.withValues(alpha: 0.06))
                    : Colors.white.withValues(alpha: 0.65)),
            borderRadius: BorderRadius.circular(999),
            border: widget.isPrimary
                ? null
                : Border.all(
                    color: widget.isDanger
                        ? AppColors.error.withValues(alpha: 0.3)
                        : AppColors.border,
                  ),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: AppColors.royalBlue.withValues(
                        alpha: _hovered ? 0.32 : 0.2,
                      ),
                      blurRadius: _hovered ? 14 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: fgColor,
                ),
              ),
              const SizedBox(width: 6),
              Icon(widget.icon, size: 15, color: fgColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final IconData? icon;

  const _NavItem({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.icon,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? AppColors.royalBlue.withValues(alpha: 0.12)
                : (_hovered
                    ? AppColors.primaryNavy.withValues(alpha: 0.05)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 15,
                  color: active
                      ? AppColors.royalBlue
                      : (_hovered ? AppColors.primaryNavy : AppColors.textSecondary),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active
                      ? AppColors.royalBlue
                      : (_hovered ? AppColors.primaryNavy : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mobile Navigation Drawer
class ResolvaDrawer extends StatelessWidget {
  final Function(String) onNavigate;

  const ResolvaDrawer({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            final isAuthorized = authController.isFullyAuthorized;
            final isAdmin = authController.isAdmin.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ResolvaLogo(size: 32),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),

                if (!isAuthorized) ...[
                  _DrawerItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate('/');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline_rounded,
                    label: 'About Us',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate('/about');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.auto_awesome_mosaic_rounded,
                    label: 'Our Services',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate('/#services');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.bolt_rounded,
                    label: 'How It Works',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate('/#how-it-works');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.help_outline_rounded,
                    label: 'FAQ',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate('/faq');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.gavel_rounded,
                    label: 'Terms & Conditions',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate('/terms-of-service');
                    },
                  ),
                ] else if (isAdmin) ...[
                  _DrawerItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate('/');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Admin Control Center',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate('/admin');
                    },
                  ),
                ] else ...[
                  _DrawerItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Dashboard Overview',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate('/dashboard');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.school_rounded,
                    label: 'Examination E-Pins',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate('/exam-pins');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.trending_up_rounded,
                    label: 'Social Media Services',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate('/social-media');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.domain_verification_rounded,
                    label: 'CAC Registration',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate('/cac');
                    },
                  ),
                ],

                const Spacer(),
                const Divider(),
                const SizedBox(height: 16),

                if (isAuthorized) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        authController.logout();
                        onNavigate('/');
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onNavigate('/login');
                      },
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: const Text('Login'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onNavigate('/register');
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('Get Started'),
                      style: ElevatedButton.styleFrom(
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
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryNavy, size: 22),
      title: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}
