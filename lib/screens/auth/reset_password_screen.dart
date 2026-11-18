import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/shared/app_navigation.dart';

/// Active screen for changing or resetting account password.
/// Accessible via:
/// 1. Supabase email recovery link (`#type=recovery` or auth callback)
/// 2. Direct email 6-digit recovery code input
/// 3. In-app settings / profile password change
class ResetPasswordScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const ResetPasswordScreen({super.key, required this.onNavigate});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isSuccess = false;
  String _errorMessage = '';

  // Whether the user needs to enter email + 6-digit code
  bool _requiresOtp = false;

  @override
  void initState() {
    super.initState();
    final auth = Get.find<AuthController>();

    // If user is already in a session (logged in or recovery link parsed by Supabase)
    if (auth.isLoggedIn.value && auth.userEmail.value.isNotEmpty) {
      _emailController.text = auth.userEmail.value;
      _requiresOtp = false;
    } else {
      // If opened directly without a recovery session, allow entering email + code
      _requiresOtp = true;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int _calculateStrength(String p) {
    if (p.isEmpty) return 0;
    int s = 0;
    if (p.length >= 6) s++;
    if (p.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p)) s++;
    if (RegExp(r'[!@#\$&*~]').hasMatch(p)) s++;
    return s;
  }

  Color _strengthColor(int s) {
    if (s <= 1) return AppColors.error;
    if (s <= 3) return const Color(0xFFF59E0B); // Amber
    return AppColors.emeraldGreen;
  }

  String _strengthLabel(int s) {
    if (s <= 1) return 'Weak';
    if (s <= 3) return 'Moderate';
    return 'Strong';
  }

  Future<void> _handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    final p1 = _passwordController.text.trim();
    final p2 = _confirmPasswordController.text.trim();

    if (p1 != p2) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final auth = Get.find<AuthController>();
    bool ok = false;

    if (_requiresOtp) {
      final email = _emailController.text.trim();
      final code = _codeController.text.trim();
      ok = await auth.verifyRecoveryOtpAndSetPassword(
        email: email,
        token: code,
        newPassword: p1,
      );
    } else {
      ok = await auth.updateAccountPassword(p1);
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (ok) {
        _isSuccess = true;
      } else {
        _errorMessage = auth.authError.value.isNotEmpty
            ? auth.authError.value
            : 'Failed to update password. Please check your reset code or request a new link.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobileView = width < 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: ResolvaDrawer(onNavigate: widget.onNavigate),
      body: Column(
        children: [
          ResolvaAppBar(currentIndex: -1, onNavigate: widget.onNavigate),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: isMobileView ? 24 : 44,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Container(
                    padding: EdgeInsets.all(isMobileView ? 24 : 36),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryNavy.withValues(alpha: 0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _isSuccess
                        ? _buildSuccessView()
                        : _buildFormView(isMobileView),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView(bool isMobile) {
    final auth = Get.find<AuthController>();
    final strength = _calculateStrength(_passwordController.text);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: AppColors.royalBlue,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              'Set New Password',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              _requiresOtp
                  ? 'Enter the 6-digit recovery code from your email and your new password.'
                  : 'Enter a strong new password to secure your RESOLVA account and wallet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Error banner
          if (_errorMessage.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: GoogleFonts.montserrat(
                        fontSize: 12.5,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // If OTP required, show Email + Code fields
          if (_requiresOtp) ...[
            Text(
              'Email Address',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'your.email@example.com',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
              validator: (v) =>
                  v == null || !v.contains('@') ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 16),
            Text(
              '6-Digit Security Code',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: const InputDecoration(
                hintText: 'Enter code from email',
                prefixIcon: Icon(Icons.vpn_key_outlined, size: 20),
                counterText: '',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter the security code' : null,
            ),
            const SizedBox(height: 16),
          ],

          // New Password field
          Text(
            'New Password',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) =>
                v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
          ),

          // Strength indicator
          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: strength / 5.0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _strengthColor(strength),
                      ),
                      minHeight: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _strengthLabel(strength),
                  style: GoogleFonts.montserrat(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _strengthColor(strength),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Confirm Password field
          Text(
            'Confirm New Password',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirm your new password';
              if (v != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),

          const SizedBox(height: 26),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handlePasswordReset,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 19),
              label: Text(
                _isLoading ? 'Updating Password...' : 'Save New Password & Continue',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 3,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Toggle OTP mode if link was expired
          Center(
            child: TextButton(
              onPressed: () => setState(() => _requiresOtp = !_requiresOtp),
              child: Text(
                _requiresOtp
                    ? 'Have an active email reset link? Click here'
                    : 'Need to enter a 6-digit email code instead? Click here',
                style: GoogleFonts.montserrat(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.royalBlue,
                ),
              ),
            ),
          ),

          Center(
            child: TextButton(
              onPressed: () => widget.onNavigate(
                auth.isLoggedIn.value ? '/dashboard' : '/login',
              ),
              child: Text(
                auth.isLoggedIn.value ? 'Cancel & Return to Dashboard' : 'Back to Sign In',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final auth = Get.find<AuthController>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.emeraldGreen.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.verified_rounded,
            color: AppColors.emeraldGreen,
            size: 48,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Password Changed!',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Your RESOLVA password has been updated successfully. Your account is secure and ready for use.',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 13.5,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => widget.onNavigate('/dashboard'),
            icon: const Icon(Icons.dashboard_rounded, size: 18),
            label: const Text('Go to Dashboard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emeraldGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => widget.onNavigate('/#services'),
            icon: const Icon(Icons.rocket_launch_rounded, size: 18),
            label: const Text('Explore Digital Services'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryNavy,
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: const BorderSide(color: AppColors.cardBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
