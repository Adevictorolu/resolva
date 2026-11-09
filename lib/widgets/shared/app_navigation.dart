import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../controllers/auth_controller.dart';
import 'common_widgets.dart';
import 'package:google_fonts/google_fonts.dart';

/// RESOLVA responsive navigation bar for desktop and tablet.
class ResolvaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentIndex;
  final Function(String) onNavigate;
  final VoidCallback? onMenuTap;

  const ResolvaAppBar({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
    this.onMenuTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobileView = width < 1100;
    final authController = Get.find<AuthController>();

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth + 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Logo
                _buildLogo(context),
                if (isMobileView) ...[
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.menu_rounded, color: AppColors.primaryNavy),
                    onPressed: onMenuTap ?? () => Scaffold.of(context).openDrawer(),
                  ),
                ] else ...[
                  const SizedBox(width: 24),
                  // Nav links wrapped in Flexible SingleChildScrollView to prevent overflow on any desktop width
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildNavItem('Home', 0, '/'),
                          _buildNavItem('Examination E-Pins', 1, '/exam-pins'),
                          _buildNavItem('Social Media', 2, '/social-media'),
                          _buildNavItem('CAC Registration', 3, '/cac'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Single consolidated reactive section
                  Obx(() {
                    final isAuth = authController.isFullyAuthorized;
                    final isAdmin = authController.isAdmin.value;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isAuth) ...[
                          if (isAdmin)
                            _buildNavItem('Admin Panel', 5, '/admin')
                          else
                            _buildNavItem('Dashboard', 4, '/dashboard'),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              authController.logout();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Logged out successfully.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              onNavigate('/');
                            },
                            icon: const Icon(Icons.logout_rounded, size: 16),
                            label: const Text('Logout'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.cardBorder),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                          ),
                        ] else ...[
                          TextButton(
                            onPressed: () => onNavigate('/login'),
                            child: Text(
                              'Login',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => onNavigate('/register'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.royalBlue,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            ),
                            child: const Text('Get Started'),
                          ),
                        ],
                      ],
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return GestureDetector(
      onTap: () => onNavigate('/'),
      child: const ResolvaLogo(
        size: 40,
        showWordmark: true,
        fontSize: 22,
      ),
    );
  }

  Widget _buildNavItem(String label, int index, String route) {
    final isActive = currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: () => onNavigate(route),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          foregroundColor: isActive ? AppColors.royalBlue : AppColors.textSecondary,
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? AppColors.royalBlue : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Responsive drawer for mobile navigation.
class ResolvaDrawer extends StatelessWidget {
  final Function(String) onNavigate;

  const ResolvaDrawer({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const ResolvaLogo(
                    size: 40,
                    showWordmark: true,
                    fontSize: 22,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerItem(context, Icons.home_rounded, 'Home', '/'),
                  _drawerItem(context, Icons.school_rounded, 'Examination E-Pins', '/exam-pins'),
                  _drawerItem(context, Icons.trending_up_rounded, 'Social Media Services', '/social-media'),
                  _drawerItem(context, Icons.business_rounded, 'CAC Registration', '/cac'),
                  Obx(() {
                    if (authController.isFullyAuthorized) {
                      final isAdmin = authController.isAdmin.value;
                      return Column(
                        children: [
                          const Divider(indent: 24, endIndent: 24),
                          if (isAdmin)
                            _drawerItem(context, Icons.admin_panel_settings_rounded, 'Admin Panel', '/admin')
                          else ...[
                            _drawerItem(context, Icons.dashboard_rounded, 'Dashboard', '/dashboard'),
                            _drawerItem(context, Icons.receipt_long_rounded, 'My Orders', '/orders'),
                          ],
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  const Divider(indent: 24, endIndent: 24),
                  _drawerItem(context, Icons.info_outline_rounded, 'About Us', '/about'),
                  _drawerItem(context, Icons.contact_mail_rounded, 'Contact Us', '/contact'),
                  _drawerItem(context, Icons.help_outline_rounded, 'FAQ', '/faq'),
                  _drawerItem(context, Icons.description_outlined, 'Terms of Service', '/terms-of-service'),
                  _drawerItem(context, Icons.shield_outlined, 'Privacy Policy', '/privacy-policy'),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: Obx(() {
                  if (authController.isFullyAuthorized) {
                    return OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        authController.logout();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logged out successfully.')),
                        );
                        onNavigate('/');
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    );
                  }

                  return ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onNavigate('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Login'),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon, size: 22, color: AppColors.textSecondary),
      title: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      horizontalTitleGap: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        Navigator.pop(context);
        onNavigate(route);
      },
    );
  }
}
