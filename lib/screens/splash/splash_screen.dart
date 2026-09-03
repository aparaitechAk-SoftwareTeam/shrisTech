import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/brand_badge.dart';
import '../../services/auth_service.dart';
import '../welcome/welcome_screen.dart';

/// Premium Splash Screen for BBS GOLD.
/// Features a pure white background, animated logo zoom & fade, luxury gold glow,
/// heritage branding, auto session check, and role-based navigation.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _logoFadeAnim;
  late Animation<double> _textFadeAnim;
  late Animation<double> _glowAnim;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSplashSequence();
  }

  void _setupAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _logoFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _logoScaleAnim = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.60, curve: Curves.easeOutCubic),
      ),
    );

    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.70, curve: Curves.easeInOut),
      ),
    );

    _textFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.40, 0.85, curve: Curves.easeIn),
      ),
    );

    _animController.forward();
  }

  void _startSplashSequence() async {
    final sessionCheckFuture = AuthService().checkInitialSession();
    final delayFuture = Future.delayed(const Duration(milliseconds: 2700));

    final results = await Future.wait([sessionCheckFuture, delayFuture]);
    final isLoggedIn = results[0] as bool;

    if (mounted && !_hasNavigated) {
      _hasNavigated = true;
      if (isLoggedIn) {
        AuthService().navigateByRole(context);
      } else {
        _navigateToWelcome();
      }
    }
  }

  void _navigateToWelcome() {
    _hasNavigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const WelcomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          );
          final scaleAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );
          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set system navigation bar & status bar explicitly for light theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.surfaceWhite,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return PopScope(
      canPop: false, // Prevent physical back button during splash transition
      child: Scaffold(
        backgroundColor: AppColors.surfaceWhite,
        body: Stack(
          children: [
            // Background Synchronized Concentric Pattern Graphics
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

            // Main Splash Screen Content Layer
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                        minWidth: constraints.maxWidth,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),

                            // Main Centered Animated Branding Content
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Animated Logo with Gold Glow & Smooth Zoom
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
                                      // Subtle Luxury Radial Gold Glow
                                      AnimatedBuilder(
                                        animation: _glowAnim,
                                        builder: (context, child) {
                                          return Container(
                                            width: 170,
                                            height: 170,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.accentGold
                                                      .withValues(
                                                        alpha:
                                                            0.25 *
                                                            _glowAnim.value,
                                                      ),
                                                  blurRadius: 40,
                                                  spreadRadius: 10,
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),

                                      // High Quality Scaling Application Logo
                                      Image.asset(
                                        AppConstants.logoAsset,
                                        width: 140,
                                        height: 140,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (
                                              context,
                                              error,
                                              stackTrace,
                                            ) => const Icon(
                                              Icons.workspace_premium_rounded,
                                              size: 100,
                                              color: AppColors.primaryRoyalBlue,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // Animated Typography Section
                                FadeTransition(
                                  opacity: _textFadeAnim,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Main Brand Header Text
                                      Text(
                                        AppConstants.appName,
                                        style: AppTypography.displayLarge
                                            .copyWith(
                                              color: AppColors.primaryRoyalBlue,
                                              letterSpacing: 1.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),

                                      // Luxury Heritage Badge "SINCE 1985"
                                      const BrandBadge(
                                        text: AppConstants.sinceTag,
                                      ),
                                      const SizedBox(height: 16),

                                      // Tagline
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        child: Text(
                                          AppConstants.tagline,
                                          style: AppTypography.bodyLarge
                                              .copyWith(
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.2,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Bottom Royal Blue Loader Indicator
                            Padding(
                              padding: const EdgeInsets.only(bottom: 36),
                              child: FadeTransition(
                                opacity: _textFadeAnim,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.primaryRoyalBlue,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'B2B Jewellery Wholesale',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textMuted,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Painter for animated concentric circle pattern structures
/// rendered at the top-right corner, bottom-left corner, and behind the logo.
class ConcentricPatternPainter extends CustomPainter {
  final double progress;
  final double logoScale;
  final double glowValue;

  ConcentricPatternPainter({
    required this.progress,
    required this.logoScale,
    required this.glowValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paintGold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final paintBlue = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 1. Top Right Corner Concentric Circles
    final topRightCenter = Offset(size.width * 1.02, -size.height * 0.02);
    _drawConcentricRings(
      canvas: canvas,
      center: topRightCenter,
      baseRadii: const [45, 85, 130, 180, 235, 295, 360, 430, 505],
      progress: progress,
      paintGold: paintGold,
      paintBlue: paintBlue,
    );

    // 2. Bottom Left Corner Concentric Circles
    final bottomLeftCenter = Offset(-size.width * 0.02, size.height * 1.02);
    _drawConcentricRings(
      canvas: canvas,
      center: bottomLeftCenter,
      baseRadii: const [55, 100, 150, 205, 265, 330, 400, 475],
      progress: progress,
      paintGold: paintGold,
      paintBlue: paintBlue,
    );

    // 3. Center Ambient Synced Concentric Rings (Behind Logo)
    final centerPos = Offset(size.width * 0.5, size.height * 0.40);
    _drawCenterRings(
      canvas: canvas,
      center: centerPos,
      glowValue: glowValue,
      logoScale: logoScale,
      paintGold: paintGold,
    );
  }

  void _drawConcentricRings({
    required Canvas canvas,
    required Offset center,
    required List<double> baseRadii,
    required double progress,
    required Paint paintGold,
    required Paint paintBlue,
  }) {
    final expansionFactor = 0.88 + (0.12 * progress);
    final fadeOpacity = (progress * 1.25).clamp(0.0, 1.0);

    for (int i = 0; i < baseRadii.length; i++) {
      final radius = baseRadii[i] * expansionFactor;
      final isGold = i % 2 == 0;
      final baseAlpha = isGold ? 0.14 : 0.07;
      final ringAlpha =
          (baseAlpha * (1.0 - (i / (baseRadii.length * 1.4)))) * fadeOpacity;

      if (ringAlpha <= 0) continue;

      if (isGold) {
        paintGold.color = AppColors.accentGold.withValues(alpha: ringAlpha);
        canvas.drawCircle(center, radius, paintGold);
      } else {
        paintBlue.color = AppColors.primaryRoyalBlue.withValues(
          alpha: ringAlpha,
        );
        canvas.drawCircle(center, radius, paintBlue);
      }
    }
  }

  void _drawCenterRings({
    required Canvas canvas,
    required Offset center,
    required double glowValue,
    required double logoScale,
    required Paint paintGold,
  }) {
    if (glowValue <= 0) return;

    final rings = const [95.0, 125.0, 160.0, 200.0];
    for (int i = 0; i < rings.length; i++) {
      final baseRadius = rings[i];
      final dynamicRadius = baseRadius * logoScale + (i * 3.5 * glowValue);
      final alpha = (0.09 - (i * 0.018)) * glowValue;
      if (alpha > 0) {
        paintGold.color = AppColors.accentGold.withValues(alpha: alpha);
        canvas.drawCircle(center, dynamicRadius, paintGold);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ConcentricPatternPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.logoScale != logoScale ||
        oldDelegate.glowValue != glowValue;
  }
}
