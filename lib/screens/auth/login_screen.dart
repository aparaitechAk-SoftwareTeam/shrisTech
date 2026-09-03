import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/validation_helper.dart';
import '../../core/widgets/card_container.dart';
import '../../core/widgets/concentric_pattern_painter.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../navigation/navigation_helper.dart';
import '../../services/auth_service.dart';
import '../../core/permissions/permission_manager.dart';
import 'registration_screen.dart';
import 'forgot_password_screen.dart';

/// Ultra-Luxury Enhanced Login Screen for BBS GOLD.
/// Features synchronized concentric background patterns (matching Splash Screen),
/// animated logo zoom & gold radial glow aura, rich brand color palette usage,
/// animated rounded corner containers, real-time input validations, button loading states,
/// and smooth responsive scroll behavior when the soft keyboard opens.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _identityController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _identityFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  // Entrance Animations (matching Splash Screen design language)
  late AnimationController _animController;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _logoFadeAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _formFadeAnim;
  late Animation<Offset> _formSlideAnim;

  bool _isPasswordObscured = true;
  bool _isLoading = false;

  // Real-time validation states
  String? _identityError;
  String? _passwordError;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _identityController.addListener(_validateInputs);
    _passwordController.addListener(_validateInputs);
  }

  void _setupAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _logoScaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.60, curve: Curves.easeOutCubic),
      ),
    );

    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.20, 0.75, curve: Curves.easeInOut),
      ),
    );

    _formFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.35, 0.90, curve: Curves.easeOut),
      ),
    );

    _formSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _identityController.dispose();
    _passwordController.dispose();
    _identityFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  /// Real-time field and overall form validation
  void _validateInputs() {
    final identityText = _identityController.text;
    final passwordText = _passwordController.text;
    final identityValErr = ValidationHelper.validateLoginIdentity(identityText);
    setState(() {
      _identityError = identityText.isNotEmpty ? identityValErr : null;
      _passwordError = null;

      _isFormValid =
          identityText.isNotEmpty &&
          passwordText.isNotEmpty &&
          identityValErr == null;
    });
  }

  void _onLoginPressed() async {
    if (!_isFormValid || _isLoading) return;

    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService().login(
        identity: _identityController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (response.success) {
        final userName = response.user?.name.trim();
        _showSuccessSnackBar(
          userName == null || userName.isEmpty
              ? response.message
              : 'Welcome $userName',
        );
        _navigateAfterLogin(response.role);
      } else {
        _showErrorSnackBar(
          response.message.trim().isEmpty
              ? 'Something went wrong. 5'
              : response.message,
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Something went wrong.6');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.accentGold,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryRoyalBlue,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _navigateAfterLogin(String? role) async {
    await PermissionManager.instance.handlePostLoginFlow(
      context: context,
      role: role,
    );
  }

  void _onForgotPasswordPressed() async {
    HapticFeedback.lightImpact();
    final result = await NavigationHelper.pushSlideHorizontal<bool>(
      context,
      const ForgotPasswordScreen(),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password reset successfully. Please log in.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primaryRoyalBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _navigateToRegister() {
    HapticFeedback.lightImpact();
    NavigationHelper.pushSlideHorizontal(context, const RegistrationScreen());
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.surfaceWhite,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.width >= 600;

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      body: Stack(
        children: [
          // ════════════════════════════════════════════════════════════════
          // LAYER 1: Synchronized Concentric Circle Graphics (Splash Aesthetic)
          // ════════════════════════════════════════════════════════════════
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ConcentricPatternPainter(
                    progress: _animController.value,
                    logoScale: _logoScaleAnim.value,
                    glowValue: _glowAnim.value,
                  ),
                );
              },
            ),
          ),

          // ════════════════════════════════════════════════════════════════
          // LAYER 2: Main Interactive Form Content
          // ════════════════════════════════════════════════════════════════
          SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32.0 : 16.0,
                      vertical: 12.0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 540 : double.infinity,
                          minHeight: constraints.maxHeight - 24.0,
                        ),
                        child: IntrinsicHeight(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 8),

                                // ════════════════════════════════════════════
                                // TOP SECTION: Animated Logo & Luxury Title
                                // ════════════════════════════════════════════
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 24),
                                      // Animated Logo with Radial Gold Glow Aura
                                      AnimatedBuilder(
                                        animation: _animController,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _logoScaleAnim.value,
                                            child: Opacity(
                                              opacity: _logoFadeAnim.value,
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // Animated Luxury Gold Glow Aura
                                            AnimatedBuilder(
                                              animation: _glowAnim,
                                              builder: (context, child) {
                                                return Container(
                                                  width: 200,
                                                  height: 200,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                  ),
                                                );
                                              },
                                            ),

                                            // Existing Brand Logo from Assets
                                            Hero(
                                              tag: 'app_logo_hero',
                                              child: Image.asset(
                                                AppConstants.logoAsset,
                                                height: 180,
                                                width: 180,
                                                fit: BoxFit.contain,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stack,
                                                    ) => const Icon(
                                                      Icons
                                                          .workspace_premium_rounded,
                                                      size: 80,
                                                      color: AppColors
                                                          .primaryRoyalBlue,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 2),

                                      // Application Name with Gradient & Typography
                                      FadeTransition(
                                        opacity: _logoFadeAnim,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Subtitle Badge Banner
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    AppColors.primaryLightBlue,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color:
                                                      AppColors.primaryTintBlue,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                AppConstants.tagline,
                                                style: AppTypography.caption
                                                    .copyWith(
                                                      color: AppColors
                                                          .primaryRoyalBlue,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: 0.3,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // ════════════════════════════════════════════
                                // MIDDLE SECTION: Animated Card Container
                                // ════════════════════════════════════════════
                                SlideTransition(
                                  position: _formSlideAnim,
                                  child: FadeTransition(
                                    opacity: _formFadeAnim,
                                    child: CardContainer(
                                      borderRadius: 24.0,
                                      showGoldGlowBorder: _isFormValid,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Header inside Card
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                AppConstants.loginTitle,
                                                style: AppTypography.titleLarge
                                                    .copyWith(
                                                      color: AppColors
                                                          .primaryRoyalBlue,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 18,
                                                    ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),

                                                child: const Icon(
                                                  Icons.verified_user_outlined,
                                                  size: 22,
                                                  color:
                                                      AppColors.accentGoldDark,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            AppConstants.loginSubtitle,
                                            style: AppTypography.caption
                                                .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 12,
                                                ),
                                          ),
                                          const SizedBox(height: 22),

                                          // 1. Email or User ID Input Field
                                          CustomTextField(
                                            label:
                                                AppConstants.emailOrUserIdLabel,
                                            hintText:
                                                AppConstants.emailOrUserIdHint,
                                            controller: _identityController,
                                            focusNode: _identityFocusNode,
                                            prefixIcon:
                                                Icons.person_outline_rounded,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            textInputAction:
                                                TextInputAction.next,
                                            errorText: _identityError,
                                          ),
                                          const SizedBox(height: 16),

                                          // 2. Password Input Field with Toggle
                                          CustomTextField(
                                            label: AppConstants.passwordLabel,
                                            hintText: AppConstants.passwordHint,
                                            controller: _passwordController,
                                            focusNode: _passwordFocusNode,
                                            prefixIcon:
                                                Icons.lock_outline_rounded,
                                            isObscured: _isPasswordObscured,
                                            errorText: _passwordError,
                                            textInputAction:
                                                TextInputAction.done,
                                            onSubmitted: (_) =>
                                                _onLoginPressed(),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _isPasswordObscured
                                                    ? Icons
                                                          .visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                color: AppColors.textMuted,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _isPasswordObscured =
                                                      !_isPasswordObscured;
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 14),

                                          // Forgot Password Action
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed:
                                                  _onForgotPasswordPressed,
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              child: Text(
                                                AppConstants.forgotPassword,
                                                style: AppTypography.caption
                                                    .copyWith(
                                                      color: AppColors
                                                          .primaryRoyalBlue,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 22),

                                          // 3. Primary Sign In Button (Loading state + Dynamic enabled state)
                                          PrimaryButton(
                                            text: AppConstants.loginButton,
                                            isEnabled: _isFormValid,
                                            isLoading: _isLoading,
                                            onPressed: _onLoginPressed,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const Spacer(),
                                const SizedBox(height: 20),

                                // ════════════════════════════════════════════
                                // BOTTOM SECTION: Register Navigation Footer
                                // ════════════════════════════════════════════
                                FadeTransition(
                                  opacity: _formFadeAnim,
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          const Expanded(
                                            child: Divider(
                                              color: AppColors.borderLight,
                                              thickness: 1,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: Text(
                                              'OR',
                                              style: AppTypography.caption
                                                  .copyWith(
                                                    color: AppColors.textMuted,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 1,
                                                  ),
                                            ),
                                          ),
                                          const Expanded(
                                            child: Divider(
                                              color: AppColors.borderLight,
                                              thickness: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Register Retailer Account Row
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            AppConstants.dontHaveAccount,
                                            style: AppTypography.bodyMedium
                                                .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                          ),
                                          TextButton(
                                            onPressed: _navigateToRegister,
                                            child: Text(
                                              AppConstants.registerNow,
                                              style: AppTypography.titleMedium
                                                  .copyWith(
                                                    fontSize: 15,
                                                    color: AppColors
                                                        .primaryRoyalBlue,
                                                    fontWeight: FontWeight.w700,
                                                    decoration: TextDecoration
                                                        .underline,
                                                    decorationColor: AppColors
                                                        .primaryRoyalBlue,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Developer Credit Footer (Responsive & Modern SaaS styling)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text.rich(
                                            TextSpan(
                                              text: AppConstants.developedBy,
                                              style: AppTypography.caption
                                                  .copyWith(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w400,
                                                    color: AppColors.textMuted,
                                                    letterSpacing: 0.3,
                                                  ),
                                              children: [
                                                TextSpan(
                                                  text: AppConstants
                                                      .developerName,
                                                  style: AppTypography.caption
                                                      .copyWith(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColors
                                                            .primaryRoyalBlue,
                                                        letterSpacing: 0.3,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
