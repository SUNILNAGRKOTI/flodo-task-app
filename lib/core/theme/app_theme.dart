import 'package:flutter/material.dart';

import 'colors.dart';
import 'text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const radius = 16.0;
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: false,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      cardColor: AppColors.cardBackgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        surface: AppColors.cardBackgroundLight,
        onSurface: AppColors.textLight,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackgroundLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.textLight.withAlpha((255 * 0.08).round()),
      ),
      textTheme: AppTextStyles.textTheme(Brightness.light),
    );
  }

  static ThemeData get darkTheme {
    const radius = 16.0;
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: false,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      cardColor: AppColors.cardBackgroundDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.primary,
        surface: AppColors.cardBackgroundDark,
        onSurface: AppColors.textDark,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackgroundDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.textDark.withAlpha((255 * 0.08).round()),
      ),
      textTheme: AppTextStyles.textTheme(Brightness.dark),
    );
  }
}

