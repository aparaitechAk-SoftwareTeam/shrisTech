import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/brand_badge.dart';
import '../../core/widgets/feature_card.dart';
import '../../core/widgets/jewellery_hero_illustration.dart';
import '../../core/widgets/primary_button.dart';

import '../../navigation/navigation_helper.dart';
import '../auth/login_screen.dart';

/// Production-ready Welcome Screen for BBS GOLD.
/// Designed according to 2026 Modern SaaS standards (Stripe, Linear, Apple aesthetic).
/// Fully responsive across all iOS & Android form factors (iPhone SE to iPad/tablets).
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onContinuePressed() async {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    HapticFeedback.lightImpact();

    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      setState(() {
        _isNavigating = false;
      });
      NavigationHelper.pushFadeScale(context, const LoginScreen());
    }
  }

  void _openTerms() {
    HapticFeedback.selectionClick();
    _showLegalModal(
      title: 'Terms of Service',
      content:
          'BBS GOLD Wholesale Terms & Conditions (Est. 1985).\n\n1. Registration is restricted to verified B2B jewellery shop owners and authorized wholesalers.\n2. All gold products listed are hallmark-certified (22K / 18K).\n3. Orders are subject to wholesaler approval prior to dispatch.',
    );
  }

  void _openPrivacy() {
    HapticFeedback.selectionClick();
    _showLegalModal(
      title: 'Privacy Policy',
      content:
          'BBS GOLD Privacy Commitment.\n\nWe adhere to global standards of business data protection. Your business registration details, GST credentials, and trade transactions are encrypted and confidential.',
    );
  }

  void _showLegalModal({required String title, required String content}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.primaryRoyalBlue,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(color: AppColors.borderLight),
              const SizedBox(height: 12),
              Text(
                content,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Close',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 48.0 : 20.0,
                    vertical: 16.0,
                  ),
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Section: Brand Header & Title
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),

                              // Header Row with Logo and Heritage Badge
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Image.asset(
                                    AppConstants.logoAsset,
                                    height: 48,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stack) =>
                                        const Icon(
                                      Icons.workspace_premium_rounded,
                                      size: 40,
                                      color: AppColors.primaryRoyalBlue,
                                    ),
                                  ),
                                  const BrandBadge(text: AppConstants.sinceTag),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Welcome Title with Accent Highlight
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Welcome to ',
                                      style: AppTypography.displayMedium
                                          .copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(
                                      text: AppConstants.appName,
                                      style: AppTypography.displayMedium
                                          .copyWith(
                                        color: AppColors.primaryRoyalBlue,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Subtitle
                              Text(
                                AppConstants.welcomeSubtitle,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Middle Section: Premium Hero Illustration + Feature Cards
                          Column(
                            children: [
                              // Hero Composition
                              const JewelleryHeroIllustration(),
                              const SizedBox(height: 20),

                              // Feature Cards List
                              const FeatureCard(
                                icon: Icons.verified_user_rounded,
                                title: AppConstants.feature1Title,
                                subtitle: AppConstants.feature1Subtitle,
                              ),
                              const FeatureCard(
                                icon: Icons.diamond_rounded,
                                title: AppConstants.feature2Title,
                                subtitle: AppConstants.feature2Subtitle,
                              ),
                              const FeatureCard(
                                icon: Icons.local_shipping_rounded,
                                title: AppConstants.feature3Title,
                                subtitle: AppConstants.feature3Subtitle,
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Bottom Section: CTA Button & Legal Footer
                          Column(
                            children: [
                              // Primary Action CTA
                              PrimaryButton(
                                text: AppConstants.ctaContinue,
                                isLoading: _isNavigating,
                                onPressed: _onContinuePressed,
                              ),
                              const SizedBox(height: 16),

                              // Interactive Terms & Privacy Policy Text
                              Center(
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      AppConstants.termsText,
                                      style: AppTypography.caption,
                                    ),
                                    GestureDetector(
                                      onTap: _openTerms,
                                      child: Text(
                                        AppConstants.termsLink,
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.primaryRoyalBlue,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                          decorationColor:
                                              AppColors.primaryRoyalBlue,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      AppConstants.andText,
                                      style: AppTypography.caption,
                                    ),
                                    GestureDetector(
                                      onTap: _openPrivacy,
                                      child: Text(
                                        AppConstants.privacyLink,
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.primaryRoyalBlue,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                          decorationColor:
                                              AppColors.primaryRoyalBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
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
    );
  }
}
