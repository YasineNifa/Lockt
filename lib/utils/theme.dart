import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    primaryColor: const Color(0xFFBB86FC),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFBB86FC),
      secondary: Color(0xFF03DAC6),
      surface: Color(0xFF1E1E1E),
      onSurface: Colors.white,
      error: Color(0xFFCF6679),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1F1F1F),
      elevation: 0,
      centerTitle: true,
    ),
    // CardTheme removed to avoid potential type mismatch in this environment
    useMaterial3: true,
  );

  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F7F5), // Soft Cream/Green tint
    primaryColor: const Color(0xFF66BB6A), // Zen Green (Level 400)
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF66BB6A),
      secondary: Color(0xFFA5D6A7), // Mint Green
      surface: Colors.white,
      onSurface: Color(0xFF2E3E2E), // Dark Green/Grey Text
      error: Color(0xFFE57373),
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).apply(
      bodyColor: const Color(0xFF2E3E2E),
      displayColor: const Color(0xFF1B5E20),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF5F7F5),
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFF2E3E2E)),
      titleTextStyle: TextStyle(color: Color(0xFF1B5E20), fontSize: 20, fontWeight: FontWeight.bold),
    ),

    useMaterial3: true,
  );
}
