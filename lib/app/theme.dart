import 'package:flutter/material.dart';

import '../core/constants/alert_constants.dart';

/// Centralised colour palette for NamALERT.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0B5C3F); // Namibian deep green
  static const Color primaryDark = Color(0xFF07402C);
  static const Color secondary = Color(0xFF1E88E5); // water/utility blue
  static const Color surfaceTint = Color(0xFFF4F7F5);

  // Category accents — always paired with text labels in the UI.
  static const Color water = Color(0xFF1E88E5);
  static const Color electricity = Color(0xFFF9A825);
  static const Color internet = Color(0xFF8E24AA);
  static const Color roads = Color(0xFFE53935);

  // Severity accents (never colour-only; chips include labels).
  static const Color severityLow = Color(0xFF2E7D32);
  static const Color severityMedium = Color(0xFFF9A825);
  static const Color severityHigh = Color(0xFFEF6C00);
  static const Color severityCritical = Color(0xFFC62828);

  static const Color verified = Color(0xFF2E7D32);
  static const Color pending = Color(0xFF757575);
  static const Color resolved = Color(0xFF546E7A);
}

/// Material theme built from the NamALERT palette.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: Colors.white,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surfaceTint,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
      ),
      snackBarTheme:
          base.snackBarTheme.copyWith(behavior: SnackBarBehavior.floating),
    );
  }
}

/// Shared helpers mapping categories/severities to icons and colours so the
/// UI stays consistent. Colour is never the only signal — labels accompany.
IconData categoryIcon(AlertCategory category) => switch (category) {
      AlertCategory.water => Icons.water_drop_rounded,
      AlertCategory.electricity => Icons.bolt_rounded,
      AlertCategory.internet => Icons.wifi_off_rounded,
      AlertCategory.roads => Icons.road_rounded,
    };

Color categoryColor(AlertCategory category) => switch (category) {
      AlertCategory.water => AppColors.water,
      AlertCategory.electricity => AppColors.electricity,
      AlertCategory.internet => AppColors.internet,
      AlertCategory.roads => AppColors.roads,
    };

Color severityColor(AlertSeverity severity) => switch (severity) {
      AlertSeverity.low => AppColors.severityLow,
      AlertSeverity.medium => AppColors.severityMedium,
      AlertSeverity.high => AppColors.severityHigh,
      AlertSeverity.critical => AppColors.severityCritical,
    };

Color statusColor(AlertStatus status) => switch (status) {
      AlertStatus.published => AppColors.primary,
      AlertStatus.investigating => AppColors.secondary,
      AlertStatus.resolved => AppColors.resolved,
      AlertStatus.pendingReview => AppColors.pending,
      AlertStatus.rejected => AppColors.roads,
    };
