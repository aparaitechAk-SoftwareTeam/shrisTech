import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Premium custom jewellery wholesale icon composition with subtle floating ambient animation,
/// concentric gold glow rings, and luxury B2B badges.
class JewelleryHeroIllustration extends StatefulWidget {
  const JewelleryHeroIllustration({super.key});

  @override
  State<JewelleryHeroIllustration> createState() =>
      _JewelleryHeroIllustrationState();
}

class _JewelleryHeroIllustrationState extends State<JewelleryHeroIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(
        parent: _floatingController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value),
          child: child,
        );
      },
      child: Center(
        child: SizedBox(
          width: 200,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Background Radial Gold & Blue Glow Rings
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentGoldLight.withValues(alpha: 0.4),
                      AppColors.primaryLightBlue.withValues(alpha: 0.3),
                      AppColors.surfaceWhite.withValues(alpha: 0.0),
                    ],
                    stops: const [0.2, 0.6, 1.0],
                  ),
                ),
              ),

              // Outer Gold Accent Ring Line
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accentGold.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),

              // Center Main Premium Card Badge
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primaryRoyalBlue,
                      AppColors.primaryDarkBlue,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowPrimaryGlow,
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppColors.accentGoldGlow,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: 46,
                    color: AppColors.accentGold,
                  ),
                ),
              ),

              // Floating Top-Right Gold Star Badge
              Positioned(
                top: 10,
                right: 25,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accentGold,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowSoft,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: AppColors.accentGoldDark,
                  ),
                ),
              ),

              // Floating Bottom-Left Verified Badge
              Positioned(
                bottom: 12,
                left: 25,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryRoyalBlue.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowSoft,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: AppColors.primaryRoyalBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '22K / 18K',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryRoyalBlue,
                          letterSpacing: 0.5,
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
  }
}
