import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Reusable Section Title widget for BBS GOLD Auth screens.
class SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final Alignment alignment;

  const SectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    final isCenter = alignment == Alignment.center;

    return Column(
      crossAxisAlignment:
          isCenter ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: AppTypography.displayMedium.copyWith(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          textAlign: isCenter ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.45,
          ),
          textAlign: isCenter ? TextAlign.center : TextAlign.start,
        ),
      ],
    );
  }
}
