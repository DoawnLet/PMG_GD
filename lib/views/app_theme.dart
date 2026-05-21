import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Colors ---
  static const Color primary   = Color(0xFF1A1A18);
  static const Color secondary = Color(0xFF1D9E75);
  static const Color error     = Color(0xFFE24B4A);
  static const Color warning   = Color(0xFFBA7517);
  static const Color base      = Color(0xFFF5F4F0);
  static const Color surface   = Colors.white;
  static const Color textDark  = Color(0xFF1A1A18);
  static const Color textMuted = Color(0xFF888880);
  static const Color border    = Color(0xFFD3D1C7);

  // --- Spacing ---
  static const double radiusS = 8;
  static const double radiusM = 12;

  static ThemeData theme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: base,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        error: error,
        onError: Colors.white,
        surface: surface,
        onSurface: textDark,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(
        const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
          bodyMedium: TextStyle(fontSize: 14, color: textDark),
          bodySmall: TextStyle(fontSize: 12, color: textMuted),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
          side: const BorderSide(color: border, width: 0.5),
        ),
        margin: const EdgeInsets.only(bottom: 10),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: primary, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusS)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          side: const BorderSide(color: border, width: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusS)),
        ),
      ),
      useMaterial3: true,
    );
  }
}
