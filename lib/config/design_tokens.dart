import 'package:flutter/material.dart';

/// Design tokens for consistent spacing, sizing, and timing throughout the app.
/// Follows an 8dp grid system for spacing and Material Design 3 guidelines.
class DesignTokens {
  DesignTokens._();

  // ============================================================================
  // SPACING (8dp grid system)
  // ============================================================================
  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ============================================================================
  // BORDER RADIUS
  // ============================================================================
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXl = 20.0;

  // ============================================================================
  // TOUCH TARGETS
  // ============================================================================
  static const double minTouchTarget = 48.0;
  static const double minCellSize = 32.0;

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // ============================================================================
  // ELEVATION
  // ============================================================================
  static const double elevationNone = 0.0;
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
}

/// Semantic color tokens used throughout the app.
/// Centralises all hard-coded colors to one place for easy theming + dark mode.
class AppColors {
  AppColors._();

  // Tier / rank colors
  static const Color tierBronze    = Color(0xFFCD7F32);
  static const Color tierSilver    = Color(0xFFB0B7C3);
  static const Color tierGold      = Color(0xFFFFD700);
  static const Color tierPlatinum  = Color(0xFF4FC3F7);
  static const Color tierDiamond   = Color(0xFF9C27B0);
  static const Color tierMaster    = Color(0xFFE53935);
  static const Color tierQualifier = Color(0xFF78909C);

  // Semantic feedback colors
  static const Color success  = Color(0xFF2E7D32);
  static const Color warning  = Color(0xFFE65100);
  static const Color danger   = Color(0xFFC62828);
  static const Color info     = Color(0xFF1565C0);

  // Semantic feedback surfaces (light + dark aware — use with opacity)
  static Color successSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1B5E20).withValues(alpha: 0.35)
          : const Color(0xFFE8F5E9);

  static Color warningSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFBF360C).withValues(alpha: 0.35)
          : const Color(0xFFFFF3E0);

  static Color infoSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0D47A1).withValues(alpha: 0.35)
          : const Color(0xFFE3F2FD);

  // Minesweeper number colors (WCAG AA compliant)
  static const List<Color> numberColors = [
    Colors.transparent,      // 0 — no display
    Color(0xFF1565C0),        // 1 — blue
    Color(0xFF2E7D32),        // 2 — green
    Color(0xFFC62828),        // 3 — red
    Color(0xFF4A148C),        // 4 — deep purple
    Color(0xFF6D4C41),        // 5 — brown
    Color(0xFF006064),        // 6 — teal
    Color(0xFF212121),        // 7 — near-black
    Color(0xFF546E7A),        // 8 — blue-grey
  ];

  // Medal colors
  static const Color medalGold   = Color(0xFFFFD700);
  static const Color medalSilver = Color(0xFFB0B7C3);
  static const Color medalBronze = Color(0xFFCD7F32);

  // Gradient for rank-tier avatars
  static LinearGradient avatarGradient(int eloRating) {
    if (eloRating >= 1800) {
      return const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFFE040FB)]);
    } else if (eloRating >= 1600) {
      return const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]);
    } else if (eloRating >= 1400) {
      return const LinearGradient(colors: [Color(0xFFB0B7C3), Color(0xFF78909C)]);
    } else if (eloRating >= 1200) {
      return const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]);
    } else {
      return const LinearGradient(colors: [Color(0xFFCD7F32), Color(0xFFA1887F)]);
    }
  }
}
