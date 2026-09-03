import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

/// Reusable validation message indicator widget.
class ValidationText extends StatelessWidget {
  final String message;
  final bool isError;

  const ValidationText({
    super.key,
    required this.message,
    this.isError = true,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isError ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isError
              ? Icons.error_outline_rounded
              : Icons.check_circle_outline_rounded,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            message,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
