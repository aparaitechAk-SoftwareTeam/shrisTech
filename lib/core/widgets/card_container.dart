import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Premium Animated Card Container for BBS GOLD.
/// Features dynamic animated rounded corners, luxury gold-to-royal-blue gradient borders,
/// pure white surface, and multi-layered soft ambient shadows.
class CardContainer extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final bool showGoldGlowBorder;
  final double borderRadius;
  final Duration animationDuration;

  const CardContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.showGoldGlowBorder = false,
    this.borderRadius = 24.0,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<CardContainer> createState() => _CardContainerState();
}

class _CardContainerState extends State<CardContainer> {
  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    final defaultPadding = isCompact ? const EdgeInsets.all(16.0) : const EdgeInsets.all(24.0);

    return AnimatedContainer(
      duration: widget.animationDuration,
      curve: Curves.easeOutCubic,
      margin: widget.margin,
      padding: widget.padding ?? defaultPadding,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        // gradient: LinearGradient(
        //   // colors: [
        //   //   AppColors.surfaceWhite,
        //   //   AppColors.primaryLightBlue.withValues(alpha: 0.25),
        //   // ],
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        // ),
        // border: Border.all(
        //   color: widget.showGoldGlowBorder
        //       ? AppColors.accentGold
        //       : AppColors.accentGold.withValues(alpha: 0.3),
        //   width: widget.showGoldGlowBorder ? 1.8 : 1.2,
        // ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 28,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: AppColors.shadowPrimaryGlow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.accentGoldGlow.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: widget.child,
    );
  }
}
