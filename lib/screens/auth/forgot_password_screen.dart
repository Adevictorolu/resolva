import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/shared/app_navigation.dart';

/// Public Forgot Password screen.
class ForgotPasswordScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const ForgotPasswordScreen({super.key, required this.onNavigate});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final auth = Get.find<AuthController>();
      final ok = auth.backendEnabled
          ? await auth.sendPasswordReset(_emailController.text)
          : await Future.delayed(const Duration(milliseconds: 700), () => true);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSent = ok;
      });
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.authError.value), backgroundColor: AppColors.error),
        );
      }
    }
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
                  vertical: isMobileView ? 28 : 48,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Container(
                    padding: EdgeInsets.all(isMobileView ? 24 : 36),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryNavy.withValues(alpha: 0.07),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _isSent ? _buildSuccessView() : _buildFormView(isMobileView),
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.password_rounded, color: AppColors.royalBlue, size: 32),
          ),
          const SizedBox(height: 18),
          Text(
            'Forgot Password',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter the email associated with your RESOLVA account and we will send password reset instructions.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Email Address',
              style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'adebayo.oluwaseun@gmail.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Send Reset Link'),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => widget.onNavigate('/login'),
            child: Text(
              'Back to Sign In',
              style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.emeraldGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: AppColors.emeraldGreen, size: 40),
        ),
        const SizedBox(height: 20),
        Text(
          'Check Your Email',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We have dispatched password recovery instructions to ${_emailController.text}. Follow the link in the message to set your new password.',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => widget.onNavigate('/login'),
          child: const Text('Return to Login'),
        ),
      ],
    );
  }
}
