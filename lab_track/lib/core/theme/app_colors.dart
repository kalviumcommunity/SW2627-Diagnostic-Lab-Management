import 'package:flutter/material.dart';

/// God-Level Design System Colors for LabTrack
/// Bio-Tech / Health Tech aesthetic featuring deep dark slates, vibrant electric cyans,
/// luminous medical teals, and glassmorphic card tokens.
class AppColors {
  // Primary brand colors (Medical Teal / Electric Sky)
  static const Color primary = Color(0xFF0284C7); // Electric Sky Blue
  static const Color primaryDark = Color(0xFF0369A1);
  static const Color primaryLight = Color(0xFFE0F2FE);
  static const Color primaryGlow = Color(0x330284C7);

  // Secondary / Accent
  static const Color accent = Color(0xFF0D9488); // Deep Medical Teal
  static const Color accentLight = Color(0xFFCCFBF1);
  static const Color accentGlow = Color(0x330D9488);

  // High-Tech Bioluminescent Tokens
  static const Color electricCyan = Color(0xFF06B6D4);
  static const Color electricCyanLight = Color(0xFFCFFAFE);
  static const Color indigoVibrant = Color(0xFF6366F1);
  static const Color indigoLight = Color(0xFFEEF2FF);
  static const Color purpleVibrant = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFF5F3FF);

  // Status Colors
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF047857);
  static const Color successGlow = Color(0x3310B981);

  static const Color warning = Color(0xFFF59E0B); // Amber for In Transit
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFB45309);
  static const Color warningGlow = Color(0x33F59E0B);

  static const Color info = Color(0xFF3B82F6); // Blue for Processing
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF1D4ED8);

  static const Color error = Color(0xFFEF4444); // Rose/Crimson
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFB91C1C);

  // Neutral Canvas Colors
  static const Color background = Color(0xFFF8FAFC); // Crisp Clean Canvas
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardSubtle = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFEEF2F6);

  // Dark Canvas & High-End Card Tokens
  static const Color darkCanvas = Color(0xFF0A0F1D);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Glassmorphism Surfaces
  static const Color glassWhite = Color(0xCCFFFFFF);
  static const Color glassCard = Color(0xF2FFFFFF);
  static const Color glassBorder = Color(0x1F000000);
  static const Color glassBorderLight = Color(0x0F000000);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Dark Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textTertiary = Color(0xFF94A3B8); // Slate 400

  // ---------------------------------------------------------------------------
  // God-Level Gradients
  // ---------------------------------------------------------------------------

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF0D9488), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroNavyGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanTealGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberOrangeGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B), Color(0xFFFB923C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleIndigoGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldTealGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassCardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coolChainGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ---------------------------------------------------------------------------
  // God-Level Box Shadows
  // ---------------------------------------------------------------------------

  static List<BoxShadow> glowShadow(
    Color color, {
    double opacity = 0.28,
    double blur = 18,
    Offset offset = const Offset(0, 6),
  }) {
    return [
      BoxShadow(
        color: color.withOpacity(opacity),
        blurRadius: blur,
        offset: offset,
      ),
    ];
  }

  static const List<BoxShadow> softCardShadow = [
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x050F172A),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> elevatedCardShadow = [
    BoxShadow(
      color: Color(0x0D0F172A),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x060F172A),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];
}
