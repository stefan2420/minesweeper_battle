/// Design tokens for consistent spacing, sizing, and timing throughout the app.
/// Follows an 8dp grid system for spacing and Material Design 3 guidelines.
class DesignTokens {
  // Prevent instantiation
  DesignTokens._();

  // ============================================================================
  // SPACING (8dp grid system)
  // ============================================================================

  /// Extra small spacing: 4dp
  static const double spacingXs = 4.0;

  /// Small spacing: 8dp
  static const double spacingS = 8.0;

  /// Medium spacing: 16dp (default between elements)
  static const double spacingM = 16.0;

  /// Large spacing: 24dp (between sections)
  static const double spacingL = 24.0;

  /// Extra large spacing: 32dp
  static const double spacingXl = 32.0;

  /// Extra extra large spacing: 48dp
  static const double spacingXxl = 48.0;

  // ============================================================================
  // BORDER RADIUS
  // ============================================================================

  /// Small radius: 4dp
  static const double radiusS = 4.0;

  /// Medium radius: 8dp (default for buttons, cards)
  static const double radiusM = 8.0;

  /// Large radius: 12dp
  static const double radiusL = 12.0;

  // ============================================================================
  // TOUCH TARGETS (Accessibility)
  // ============================================================================

  /// Minimum touch target size for accessibility (Material Design guideline)
  static const double minTouchTarget = 48.0;

  /// Minimum cell size for game board
  static const double minCellSize = 32.0;

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================

  /// Fast animation: 150ms (for micro-interactions like button presses)
  static const Duration animationFast = Duration(milliseconds: 150);

  /// Normal animation: 300ms (standard transitions)
  static const Duration animationNormal = Duration(milliseconds: 300);

  /// Slow animation: 500ms (emphasis animations)
  static const Duration animationSlow = Duration(milliseconds: 500);

  // ============================================================================
  // ELEVATION (Material Design)
  // ============================================================================

  /// No elevation
  static const double elevationNone = 0.0;

  /// Low elevation (for cards)
  static const double elevationLow = 2.0;

  /// Medium elevation (for floating action buttons)
  static const double elevationMedium = 4.0;

  /// High elevation (for dialogs)
  static const double elevationHigh = 8.0;
}
