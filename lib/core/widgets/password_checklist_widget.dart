import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/validation_helper.dart';

/// Modern SaaS Password Strength Bar & Live Criteria Checklist Widget.
/// Displays live progress meter and interactive criteria indicators:
/// ✔ 8 Characters  ✔ Uppercase  ✔ Lowercase  ✔ Digit  ✔ Symbol
class PasswordChecklistWidget extends StatelessWidget {
  final String password;

  const PasswordChecklistWidget({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final isMinLen = ValidationHelper.hasMinLength(password);
    final hasUpper = ValidationHelper.containsUppercase(password);
    final hasLower = ValidationHelper.containsLowercase(password);
    final hasDigit = ValidationHelper.containsDigit(password);
    final hasSymbol = ValidationHelper.containsSpecialChar(password);

    final strength = ValidationHelper.getPasswordStrength(password);

    Color strengthColor;
    String strengthText;
    double strengthPercent;

    switch (strength) {
      case PasswordStrength.weak:
        strengthColor = const Color(0xFFEF4444); // Red
        strengthText = 'Weak Password';
        strengthPercent = 0.33;
        break;
      case PasswordStrength.medium:
        strengthColor = AppColors.accentGoldDark; // Amber/Gold
        strengthText = 'Medium Strength';
        strengthPercent = 0.66;
        break;
      case PasswordStrength.strong:
        strengthColor = const Color(0xFF10B981); // Emerald Green
        strengthText = 'Strong Password';
        strengthPercent = 1.0;
        break;
      case PasswordStrength.none:
        strengthColor = AppColors.borderLight;
        strengthText = '';
        strengthPercent = 0.0;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),

        // Strength Bar & Badge Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PASSWORD STRENGTH',
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textMuted,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: strengthColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: strengthColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                strengthText.toUpperCase(),
                style: AppTypography.badgeText.copyWith(
                  fontSize: 10,
                  color: strengthColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Animated 3-Segment Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 5,
            child: Stack(
              children: [
                Container(color: AppColors.borderLight),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  widthFactor: strengthPercent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: strengthColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Live SaaS Checklist Items (2 Columns Grid Layout)
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildCheckItem('8+ Characters', isMinLen),
            _buildCheckItem('Uppercase (A-Z)', hasUpper),
            _buildCheckItem('Lowercase (a-z)', hasLower),
            _buildCheckItem('Digit (0-9)', hasDigit),
            _buildCheckItem('Special Symbol', hasSymbol),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckItem(String label, bool isMet) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMet
            ? const Color(0xFF10B981).withValues(alpha: 0.08)
            : AppColors.surfaceCardSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMet
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: isMet ? const Color(0xFF10B981) : AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
              color: isMet ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
