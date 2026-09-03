import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'primary_button.dart';

/// Premium B2B Registration Success Dialog for BBS GOLD.
/// Displays gold badge icon, clean message, and OK action button.
class SuccessDialog extends StatelessWidget {
  final VoidCallback onOkPressed;
  final String title;
  final String message;

  const SuccessDialog({
    super.key,
    required this.onOkPressed,
    this.title = AppConstants.verificationDialogTitle,
    this.message = AppConstants.verificationDialogMessage,
  });

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onOkPressed,
    String? title,
    String? message,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessDialog(
        onOkPressed: onOkPressed,
        title: title ?? AppConstants.verificationDialogTitle,
        message: message ?? AppConstants.verificationDialogMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderGold, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 32,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gold Animated Crest Icon Header
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryRoyalBlue.withValues(alpha: 0.1),
                    AppColors.accentGoldSubtle,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: AppColors.accentGold, width: 1.5),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                size: 38,
                color: AppColors.accentGoldDark,
              ),
            ),
            const SizedBox(height: 20),

            // Dialog Header Title
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.primaryRoyalBlue,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Dialog Detailed Message
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Action Button OK
            PrimaryButton(
              text: AppConstants.verificationDialogBtn,
              onPressed: () {
                Navigator.of(context).pop();
                onOkPressed();
              },
            ),
          ],
        ),
      ),
    );
  }
}
