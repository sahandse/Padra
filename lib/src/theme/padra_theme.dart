import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PadraTheme {
  static const Color green = Color(0xFF35D56F);
  static const Color dark = Color(0xFF0C1110);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: green,
      brightness: brightness,
      surface: isDark ? const Color(0xFF111716) : const Color(0xFFF7FAF8),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF090D0C) : const Color(0xFFF5F8F6),
      textTheme: GoogleFonts.vazirmatnTextTheme(),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
