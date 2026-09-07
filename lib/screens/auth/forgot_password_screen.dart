// ignore_for_file: file_names

import 'dart:developer';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/network/api_exception.dart';
import '../../services/auth_service.dart';
import '../../core/widgets/password_checklist_widget.dart';
import '../../core/utils/validation_helper.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialUser; // Optional: prepopulate user if opened from profile

  const ForgotPasswordScreen({super.key, this.initialUser});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FocusNode _userFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // Step 1 or 2
  int _currentStep = 1;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  String? _passwordError;

  // Saved verification info
  String _verifiedUserId = '';
  String _verifiedName = '';
  String _verifiedEmail = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialUser != null && widget.initialUser!.isNotEmpty) {
      _userController.text = widget.initialUser!;
    }
    _passwordController.addListener(_validatePassword);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  void _validatePassword() {
    final password = _passwordController.text;
    final passErr = ValidationHelper.validateRegistrationPassword(password);
    setState(() {
      _passwordError = password.isNotEmpty ? passErr : null;
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePassword);
    _userController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _userFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleVerification() async {
    if (!_formKey1.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService().forgotPassword(_userController.text.trim());
      if (!mounted) return;

      if (response.success) {
        setState(() {
          _verifiedUserId = response.userId ?? _userController.text.trim();
          _verifiedName = response.name ?? 'Valued Retailer';
          _verifiedEmail = response.email ?? '';
          _currentStep = 2;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Verification error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = e is ApiException ? e.message : 'User verification failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleResetPassword() async {
    final passErr = ValidationHelper.validateRegistrationPassword(_passwordController.text);
    if (passErr != null) {
      setState(() {
        _passwordError = passErr;
        _errorMessage = passErr;
      });
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService().resetPassword(
        _verifiedUserId,
        _passwordController.text,
      );
      if (!mounted) return;

      if (response.success) {
        // Pop with success message
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Reset password error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = e is ApiException ? e.message : 'Password reset failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBackBtn = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.backgroundOffWhite,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackBtn
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.accentGold),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        backgroundColor: AppColors.primaryRoyalBlue,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppConstants.appName,
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 28),
                      _currentStep == 1 ? _buildStep1Card() : _buildStep2Card(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.primaryRoyalBlue.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accentGold.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.lock_reset_rounded,
            color: AppColors.primaryRoyalBlue,
            size: 36,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          _currentStep == 1 ? 'Verify Your Account' : 'Choose New Password',
          style: AppTypography.displayMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          _currentStep == 1
              ? 'Enter User ID or Email to initiate secure password reset'
              : 'Setup a strong password to secure your wholesale access',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStep1Card() {
    return Card(
      elevation: 8,
      shadowColor: AppColors.shadowPrimaryGlow.withValues(alpha: 0.12),
      color: AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _PasswordCardCornerPainter(),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Form(
            key: _formKey1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) _buildErrorBanner(),
                CustomTextField(
                  label: 'User ID or Email',
                  hintText: 'e.g. BBS001 or mail@example.com',
                  controller: _userController,
                  focusNode: _userFocusNode,
                  prefixIcon: Icons.person_outline_rounded,
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Verify Identity',
                  isLoading: _isLoading,
                  onPressed: _handleVerification,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep2Card() {
    return Card(
      elevation: 8,
      shadowColor: AppColors.shadowPrimaryGlow.withValues(alpha: 0.12),
      color: AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _PasswordCardCornerPainter(),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Form(
            key: _formKey2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) _buildErrorBanner(),
                // Show verified User preview
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCardSubtle,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRoyalBlue.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: AppColors.primaryRoyalBlue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _verifiedName,
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (_verifiedEmail.isNotEmpty)
                              Text(
                                _verifiedEmail,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'New Password',
                  hintText: 'Enter new password',
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  prefixIcon: Icons.lock_outline_rounded,
                  isObscured: _isPasswordObscured,
                  errorText: _passwordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordObscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordObscured = !_isPasswordObscured;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                PasswordChecklistWidget(
                  password: _passwordController.text,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Confirm New Password',
                  hintText: 'Confirm new password',
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocusNode,
                  prefixIcon: Icons.lock_outline_rounded,
                  isObscured: _isConfirmPasswordObscured,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordObscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Reset Password',
                  isLoading: _isLoading,
                  onPressed: _handleResetPassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.red.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordCardCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Concentric gold circles in top right
    final topRightCenter = Offset(size.width - 10, 10);
    paint.color = AppColors.accentGold.withValues(alpha: 0.18);
    canvas.drawCircle(topRightCenter, 45, paint);
    canvas.drawCircle(topRightCenter, 70, paint);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.accentGold.withValues(alpha: 0.04);
    canvas.drawCircle(topRightCenter, 45, fillPaint);

    // Diagonal Blue lines in bottom left
    final path = Path();
    paint.color = AppColors.primaryRoyalBlue.withValues(alpha: 0.1);
    paint.strokeWidth = 1.5;

    for (int i = 0; i < 4; i++) {
      final offset = i * 15.0;
      path.reset();
      path.moveTo(0, size.height - 80 - offset);
      path.quadraticBezierTo(
        40 + offset,
        size.height - 40 - offset,
        80 + offset,
        size.height,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
