import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable Custom Painter for animated concentric circle pattern graphics
/// rendered at corners and behind focal points for luxury branding (Splash & Login screens).
class ConcentricPatternPainter extends CustomPainter {
  final double progress;
  final double logoScale;
  final double glowValue;

  ConcentricPatternPainter({
    required this.progress,
    this.logoScale = 1.0,
    this.glowValue = 1.0,
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

    // 3. Center Focal Synced Concentric Rings
    final centerPos = Offset(size.width * 0.5, size.height * 0.22);
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
        paintBlue.color =
            AppColors.primaryRoyalBlue.withValues(alpha: ringAlpha);
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

    final rings = const [75.0, 100.0, 130.0, 165.0];
    for (int i = 0; i < rings.length; i++) {
      final baseRadius = rings[i];
      final dynamicRadius = baseRadius * logoScale + (i * 3.0 * glowValue);
      final alpha = (0.08 - (i * 0.015)) * glowValue;
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
