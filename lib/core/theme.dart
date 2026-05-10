import 'package:flutter/material.dart';

class AppTheme {
  // ── Colors ─────────────────────────────────────
  static const bg        = Color(0xFF07070B);
  static const bg2       = Color(0xFF111018);
  static const card      = Color(0xFF111018);
  static const card2     = Color(0xFF1A1824);
  static const pink      = Color(0xFFFF2D8D);
  static const pinkSoft  = Color(0xFFFF5BAA);
  static const white     = Color(0xFFFFFFFF);
  static const gray      = Color(0xFFA0A0A8);
  static const gray2     = Color(0xFF606068);
  static const gray3     = Color(0xFF2E2C38);
  static const green     = Color(0xFF2ECC71);
  static const gold      = Color(0xFFF5C97A);
  static const red       = Color(0xFFFF4D6D);

  // ── Gradient ───────────────────────────────────
  static const pinkGrad = LinearGradient(
    colors: [Color(0xFFFF2D8D), Color(0xFFFF4FAF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Shadows ────────────────────────────────────
  static List<BoxShadow> pinkShadow = [
    BoxShadow(
      color: Color(0xFFFF2D8D).withOpacity(0.35),
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ];

  // ── Border Radius ──────────────────────────────
  static const double radius     = 18;
  static const double radiusSm   = 12;
  static const double radiusLg   = 24;
  static const double radiusCard = 20;
  static const double radiusPill = 100;

  // ── Theme ──────────────────────────────────────
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      primaryColor: pink,
      colorScheme: const ColorScheme.dark(
        primary: pink,
        secondary: pinkSoft,
        surface: card,
        error: red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(
            color: pink.withOpacity(0.12),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pink,
          foregroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
          elevation: 0,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0B0A12),
        selectedItemColor: pinkSoft,
        unselectedItemColor: Color(0xFF606068),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: pink.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: pink, width: 1.5),
        ),
        hintStyle: const TextStyle(color: Color(0xFF606068)),
      ),
    );
  }
}