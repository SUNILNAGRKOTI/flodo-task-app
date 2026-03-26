import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

class AppTextStyles {
  static TextTheme textTheme(Brightness brightness) {
    final base = ThemeData(brightness: brightness).textTheme;
    final color = brightness == Brightness.dark ? AppColors.textDark : AppColors.textLight;

    return GoogleFonts.interTextTheme(base).apply(
      bodyColor: color,
      displayColor: color,
    );
  }
}

