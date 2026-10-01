// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette — deep indigo/violet
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9B94FF);
  static const Color primaryDark = Color(0xFF4A44CC);
  static const Color primaryContainer = Color(0xFF1E1B4B);

  // Secondary — electric cyan
  static const Color secondary = Color(0xFF00D4FF);
  static const Color secondaryLight = Color(0xFF67E8FF);
  static const Color secondaryDark = Color(0xFF0099CC);

  // Accent — warm amber
  static const Color accent = Color(0xFFFFB347);
  static const Color accentLight = Color(0xFFFFD68A);

  // Background (dark theme)
  static const Color backgroundDark = Color(0xFF0D0D1A);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color cardDark = Color(0xFF16213E);
  static const Color cardHover = Color(0xFF1E2A4A);

  // Background (light theme)
  static const Color backgroundLight = Color(0xFFF5F7FF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFEEF0FF);

  // Text
  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF9B9BC0);
  static const Color textMuted = Color(0xFF5C5C7A);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status colors
  static const Color success = Color(0xFF4ADE80);
  static const Color successLight = Color(0xFFBBF7D0);
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFF87171);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF60A5FA);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Task priority
  static const Color priorityLow = Color(0xFF4ADE80);
  static const Color priorityMedium = Color(0xFFFBBF24);
  static const Color priorityHigh = Color(0xFFF87171);
  static const Color priorityUrgent = Color(0xFFA855F7);

  // Gamification
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);
  static const Color xpColor = Color(0xFF7C3AED);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0D0D1A), Color(0xFF1A1A2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E2A4A), Color(0xFF16213E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient streakGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF9500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Border
  static const Color borderDark = Color(0xFF2A2A4A);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Shadow
  static const Color shadowDark = Color(0x40000000);
  static const Color primaryGlow = Color(0x406C63FF);
}
