import 'package:flutter/material.dart';

/// RESOLVA brand color palette.
class AppColors {
  AppColors._();

  // Primary brand colors (Brand Identity: #0C4CB0 & #FFFFFF)
  static const Color brandBlue = Color(0xFF0C4CB0);
  static const Color primaryNavy = Color(0xFF09367D);
  static const Color royalBlue = Color(0xFF0C4CB0);
  static const Color electricBlue = Color(0xFF2563EB);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color accentGold = Color(0xFFF59E0B);

  // Background colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF1F5F9);
  static const Color cardBackground = Color(0xFFF8FAFC);

  // Text colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textSecondaryDark = Color(0xFFDBEAFE);

  // Border & divider
  static const Color border = Color(0xFFE2E8F0);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF0C4CB0);

  // Social platform colors
  static const Color instagram = Color(0xFFE4405F);
  static const Color tiktok = Color(0xFF000000);
  static const Color facebook = Color(0xFF1877F2);
  static const Color youtube = Color(0xFFFF0000);
  static const Color twitter = Color(0xFF000000);

  // Card & surface
  static const Color cardShadow = Color(0x0A000000);
  static const Color overlay = Color(0x33000000);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF09367D), Color(0xFF0C4CB0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF082E6B), Color(0xFF0C4CB0), Color(0xFF135DD1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
