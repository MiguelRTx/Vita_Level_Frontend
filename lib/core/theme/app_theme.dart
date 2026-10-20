import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const green = Color(0xFF176B50);
  static const ink = Color(0xFF183A30);
  static const mint = Color(0xFFDDF2D9);
  static ThemeData create(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: green,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark
          ? const Color(0xFF111B17)
          : const Color(0xFFF7F8F3),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: dark ? const Color(0xFF1C2A22) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .45)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF152019) : const Color(0xFFF4F6F1),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 36,
          letterSpacing: -1.2,
          color: dark ? Colors.white : ink,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 28,
          letterSpacing: -.6,
          color: dark ? Colors.white : ink,
        ),
        titleLarge: const TextStyle(fontWeight: FontWeight.w700, fontSize: 21),
        titleMedium: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        bodyLarge: const TextStyle(fontSize: 16, height: 1.55),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: dark
            ? const Color(0xFF111B17)
            : const Color(0xFFF7F8F3),
        scrolledUnderElevation: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        borderRadius: BorderRadius.circular(30),
        linearMinHeight: 10,
        color: scheme.primary,
      ),
    );
  }
}
