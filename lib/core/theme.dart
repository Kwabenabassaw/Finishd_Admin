import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF006400); // Dark Green
  static const Color accentGreen = Color(0xFF00FF7F); // Spring Green for highlights
  static const Color backgroundDark = Color(0xFF0A0A0A); // Very dark grey, almost black
  static const Color surfaceDark = Color(0xFF161616); // Slightly lighter for cards
  static const Color borderDark = Color(0xFF262626); // Subtle borders

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: primaryGreen,
      onPrimary: Colors.white,
      secondary: accentGreen,
      onSecondary: Colors.black,
      surface: surfaceDark, // background is deprecated, use surface
      onSurface: Colors.white,
      surfaceTint: Colors.transparent, // Remove tint on surface
      outline: borderDark,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: const Color(0xFFEDEDED),
      displayColor: Colors.white,
    ),
    // Commenting out CardTheme to avoid type error with CardThemeData
    // cardTheme: CardTheme(
    //   color: surfaceDark,
    //   elevation: 0,
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(10),
    //     side: const BorderSide(color: borderDark),
    //   ),
    //   margin: EdgeInsets.zero,
    // ),
    dividerTheme: const DividerThemeData(
      color: borderDark,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryGreen),
      ),
      filled: true,
      fillColor: const Color(0xFF202020),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: borderDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
  );

  // Keeping light theme as a fallback, but aligning colors slightly
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryGreen,
      secondary: accentGreen,
      surface: Colors.white,
      // background: Color(0xFFF9F9F9), // Deprecated
      outline: Color(0xFFE5E5E5),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    // cardTheme: CardTheme(
    //   elevation: 0,
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(10),
    //     side: const BorderSide(color: Color(0xFFE5E5E5)),
    //   ),
    // ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.grey[50],
    ),
  );
}
