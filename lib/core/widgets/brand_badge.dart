import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Luxury brand heritage badge displaying "SINCE 1985" with fine gold lines.
class BrandBadge extends StatelessWidget {
  final String text;

  const BrandBadge({
    super.key,
    this.text = 'SINCE 1985',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.accentGoldGlow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 1,
            color: AppColors.accentGold,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTypography.badgeText,
          ),
          const SizedBox(width: 8),
          Container(
            width: 14,
            height: 1,
            color: AppColors.accentGold,
          ),
        ],
      ),
    );
  }
}
