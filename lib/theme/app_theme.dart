import 'package:flutter/material.dart';

class AppTheme {
  static const double borderRadius = 24.0;
  static const double smallRadius = 12.0;

  static const double toolbarHeight = 80.0;

  static const double spacing24 = 24.0;
  static const double spacing20 = 20.0;
  static const double spacing16 = 16.0;
  static const double spacing12 = 12.0;
  static const double spacing8 = 8.0;
  static const double spacing4 = 4.0;
  static const double spacing2 = 2.0;

  static const double padding24 = 24.0;
  static const double padding20 = 20.0;
  static const double padding16 = 16.0;
  static const double padding12 = 12.0;
  static const double padding8 = 8.0;
  static const double padding4 = 4.0;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
      primary: const Color(0xFF007AFF), // iOS blue
      onPrimary: Colors.white,
      secondary: const Color(0xFF34C759), // iOS green
      onSecondary: Colors.white,
      surface: const Color(0xFFF8F9FA), // iOS light background
      onSurface: Colors.black,
      error: const Color(0xFFFF3B30), // iOS red
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
      primary: const Color(0xFF0A84FF), // iOS blue
      onPrimary: Colors.white,
      secondary: const Color(0xFF30D158), // iOS green
      onSecondary: Colors.white,
      surface: const Color(0xFF1C1C1E), // iOS dark background
      onSurface: Colors.white,
      error: const Color(0xFFFF453A), // iOS red
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF1C1C1E),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ),
  );
}
