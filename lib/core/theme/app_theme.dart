// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // ── Core Colors ──────────────────────────────────────────────────────────
  static const Color primaryColor = Color(0xFF0A6E7F);
  static const Color primaryDark  = Color(0xFF004D5C);
  static const Color primaryLight = Color(0xFF1A8E9F);

  static const Color cardBlue    = Color(0xFFCBEDF5); // light blue cards
  static const Color bgLight     = Color(0xFFEDF6F9); // very light bg
  static const Color bgDark      = Color(0xFF0D3D47);

  static const Color success = Color(0xFF00897B);
  static const Color warning = Color(0xFFFFA726);
  static const Color danger  = Color(0xFFEF4444);

  // ── Light Theme ──────────────────────────────────────────────────────────
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: primaryLight,
      surface: bgLight,
      error: danger,
    ),
    scaffoldBackgroundColor: bgLight,

    appBarTheme: const AppBarTheme(
      backgroundColor: bgLight,
      foregroundColor: primaryColor,
      elevation: 0,
      centerTitle: true,
    ),

    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: EdgeInsets.zero,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      hintStyle: TextStyle(
        color: primaryColor.withOpacity(0.4),
        fontSize: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) =>
          states.contains(MaterialState.selected)
              ? primaryColor
              : Colors.transparent),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w900,
        color: primaryDark,
        height: 1.1,
      ),
      displayMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: primaryDark,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: primaryDark,
      ),
      headlineLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: primaryDark,
      ),
      headlineMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: primaryDark,
      ),
      headlineSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryDark,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: primaryDark,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xFF5A8A96),
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Color(0xFF7AA0AA),
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        letterSpacing: 0.5,
      ),
    ),
  );

  // ── Dark Theme ───────────────────────────────────────────────────────────
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryLight,
      secondary: cardBlue,
      surface: bgDark,
      error: danger,
    ),
    scaffoldBackgroundColor: bgDark,

    appBarTheme: const AppBarTheme(
      backgroundColor: bgDark,
      foregroundColor: cardBlue,
      elevation: 0,
    ),

    cardTheme: CardTheme(
      color: const Color(0xFF1A5A6E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: EdgeInsets.zero,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A5A6E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryLight, width: 2),
      ),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w900,
        color: cardBlue,
        height: 1.1,
      ),
      displayMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: cardBlue,
      ),
      headlineSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        color: Colors.white,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.white70,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: Colors.white54,
      ),
    ),
  );
}