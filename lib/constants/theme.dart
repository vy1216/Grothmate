import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0A0F0D);
  static const bg2 = Color(0xFF111A15);
  static const bg3 = Color(0xFF162010);
  static const card = Color(0xFF1C2A20);
  static const card2 = Color(0xFF243329);
  static const primary = Color(0xFF1A3C2E);
  static const secondary = Color(0xFF2D6A4F);
  static const accent = Color(0xFF52B788);
  static const light = Color(0xFF95D5B2);
  static const pale = Color(0xFFD8F3DC);
  static const amber = Color(0xFFF8A947);
  static const coral = Color(0xFFE07A5F);
  static const blue = Color(0xFF4A9EDB);
  static const red = Color(0xFFE05252);
  static const textPrimary = Color(0xFFF0F7F2);
  static const textSecondary = Color(0xFF8BAF96);
  static const textHint = Color(0xFF4A6B55);
  static const border = Color(0xFF1E2E24);
  static const border2 = Color(0xFF243329);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.secondary,
      surface: AppColors.card,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: TextStyle(
        fontFamily: 'Syne',
        fontWeight: FontWeight.w800,
        fontSize: 20,
        color: AppColors.textPrimary,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bg2,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textHint,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
      hintStyle: const TextStyle(color: AppColors.textHint, fontFamily: 'DMSans'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.pale,
        shape: const StadiumBorder(),
        minimumSize: const Size(double.infinity, 50),
        textStyle: const TextStyle(
          fontFamily: 'DMSans',
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
    fontFamily: 'DMSans',
  );
}
