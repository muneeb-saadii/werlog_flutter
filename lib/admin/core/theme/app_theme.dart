import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Central [ThemeData] for the admin panel.
class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accentGreen,
        primary: AppColors.darkGreen,
        secondary: AppColors.accentGreen,
        surface: AppColors.cardWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkGreen,
        elevation: 0,
        centerTitle: false,
      ),
      splashFactory: InkRipple.splashFactory,
      dividerColor: AppColors.divider,
    );
  }
}

/// Shared layout constants so spacing/radii stay consistent across screens.
class AppMetrics {
  AppMetrics._();

  static const double pagePadding = 16;
  static const double cardRadius = 20;
  static const double headerRadius = 28;
  static const double pillRadius = 24;
  static const double gapSm = 8;
  static const double gapMd = 16;
  static const double gapLg = 24;
}
