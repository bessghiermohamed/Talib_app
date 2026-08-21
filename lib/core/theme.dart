import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// هوية «طالب» البصرية — مترجمة من نموذج التصميم المعتمد
class TalibTheme {
  TalibTheme._();

  static const Color accent = Color(0xFFC8956C);
  static const Color danger = Color(0xFFB4533A);

  static ThemeData get light => _build(false);
  static ThemeData get dark => _build(true);

  static ThemeData _build(bool dark) {
    final primary   = dark ? const Color(0xFF4CAF8A) : const Color(0xFF1B5E4B);
    final onPrimary = dark ? const Color(0xFF10241C) : const Color(0xFFF7F3EA);
    final bg        = dark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F4ED);
    final surface   = dark ? const Color(0xFF1A1A1A) : Colors.white;
    final ink       = dark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);

    final scheme = ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: primary, onPrimary: onPrimary,
      secondary: accent, onSecondary: const Color(0xFF241708),
      surface: surface, onSurface: ink,
      error: danger, onError: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
    );

    return base.copyWith(
      textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(base.textTheme)
          .apply(bodyColor: ink, displayColor: ink),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: ink.withOpacity(.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(99))),
      ),
    );
  }
}