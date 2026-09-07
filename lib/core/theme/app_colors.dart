import 'package:flutter/material.dart';

/// App color palette for BBS GOLD.
/// Primary: Royal Blue (#1E3A8A) - Dominates CTAs and branding
/// Accent: Gold (#D4AF37) - Used strictly for luxury accents and subtle details
/// Background: White (#FFFFFF) - Pure, clean light theme
abstract class AppColors {
  // Primary Palette
  static const Color primaryRoyalBlue = Color(0xFF1E3A8A);
  static const Color primaryDarkBlue = Color(0xFF172554);
  static const Color primaryLightBlue = Color(0xFFEFF6FF);
  static const Color primaryTintBlue = Color(0xFFDBEAFE);
  static const Color bg = Color(0xFFF5F7FA);

  // Secondary Accent Palette (Gold)
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color accentGoldDark = Color(0xFFB38F24);
  static const Color accentGoldLight = Color(0xFFFEF08A);
  static const Color accentGoldGlow = Color(0x33D4AF37);
  static const Color accentGoldSubtle = Color(0x1AD4AF37);

  // Background & Neutral Surfaces
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color backgroundOffWhite = Color(0xFFFAFAFA);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceCardSubtle = Color(0xFFF8FAFC);

  // Typography & Content
  static const Color textPrimary = Color(
    0xFF0F172A,
  ); // Deep slate for high contrast readability
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // UI Element Borders & Dividers
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFF1F5F9);
  static const Color borderGold = Color(0x40D4AF37);

  // Shadows
  static const Color shadowSoft = Color(0x0C0F172A);
  static const Color shadowMedium = Color(0x1A0F172A);
  static const Color shadowPrimaryGlow = Color(0x261E3A8A);
}
