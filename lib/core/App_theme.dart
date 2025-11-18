import 'package:flutter/material.dart';

class AppColors {
  // Dark palette
  static const Color backgroundDark = Color(0xFF151522);
  static const Color surfaceDark = Color(0xFF282836);
  static const Color textDark = Color(0xFFFFFFFF);

  // Light palette
  static const Color backgroundLight = Color(0xFFF7F7FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFF1A1A1A);

  // Shared
  static const Color primary = Color(0xFF5766F3);
  static const Color secondary = Color(0xFF70CFCB);
}

class AppTheme {
  // Keep old accessor for backward compatibility (maps to dark)
  static ThemeData get theme => dark;

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      fontFamily: 'custom',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.textDark,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textDark,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textDark,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.bold,
          fontSize: 32,
          fontFamily: 'custom',
        ),
        displayMedium: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
          fontSize: 24,
          fontFamily: 'custom',
        ),
        bodyLarge: TextStyle(
          color: AppColors.textDark,
          fontSize: 16,
          fontFamily: 'custom',
        ),
        bodyMedium: TextStyle(
          color: AppColors.textDark,
          fontSize: 14,
          fontFamily: 'custom',
        ),
        labelLarge: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w500,
          fontSize: 16,
          fontFamily: 'custom',
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          fontFamily: 'custom',
        ),
        iconTheme: IconThemeData(color: AppColors.textDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            fontFamily: 'custom',
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textDark,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'custom',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        hintStyle: TextStyle(color: AppColors.textDark.withValues(alpha: 0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        shadowColor: AppColors.primary.withValues(alpha: 0.2),
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFEFF0F4), // slightly darker bg for contrast
      fontFamily: 'custom',
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textLight,
        surface: Color(0xFFF2F3F7), // softer grey surface instead of pure white
        onSurface: AppColors.textLight,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textLight,
          fontWeight: FontWeight.bold,
          fontSize: 32,
          fontFamily: 'custom',
        ),
        displayMedium: TextStyle(
          color: AppColors.textLight,
          fontWeight: FontWeight.w600,
          fontSize: 24,
          fontFamily: 'custom',
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF222222), // stronger text color
          fontSize: 16,
          fontFamily: 'custom',
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF333333),
          fontSize: 14,
          fontFamily: 'custom',
        ),
        labelLarge: TextStyle(
          color: AppColors.textLight,
          fontWeight: FontWeight.w500,
          fontSize: 16,
          fontFamily: 'custom',
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF2F3F7),
        elevation: 1,
        shadowColor: Colors.black12,
        titleTextStyle: TextStyle(
          color: AppColors.textLight,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          fontFamily: 'custom',
        ),
        iconTheme: IconThemeData(color: AppColors.textLight),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFFF2F3F7),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight.withValues(alpha: 0.6),
        showUnselectedLabels: true,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            fontFamily: 'custom',
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textLight,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'custom',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF2F3F7),
        hintStyle: TextStyle(color: AppColors.textLight.withValues(alpha: 0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFF2F3F7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        shadowColor: Colors.black12,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.textLight.withValues(alpha: 0.2),
        thickness: 1,
        space: 24,
      ),
      iconTheme: const IconThemeData(color: AppColors.textLight),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFFFAFAFA),
        contentTextStyle: const TextStyle(
          color: AppColors.textLight,
          fontFamily: 'custom',
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFF2F3F7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          color: AppColors.textLight,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          fontFamily: 'custom',
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.textLight,
          fontSize: 14,
          fontFamily: 'custom',
        ),
      ),
    );
  }

}