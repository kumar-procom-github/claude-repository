import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern app look (the cards themselves keep their traditional designs).
/// Indigo + coral, soft rounded surfaces, no heavy shadows, clean sans-serif
/// (Plus Jakarta Sans for English, Noto Sans Telugu for Telugu).
class AppTheme {
  AppTheme._();

  static const _indigo = Color(0xFF5B3DF5);
  static const _coral = Color(0xFFFF6B4A);

  static ThemeData light() => _build(
        ColorScheme.fromSeed(seedColor: _indigo, brightness: Brightness.light).copyWith(
          primary: _indigo,
          secondary: _coral,
          surface: const Color(0xFFF8F7FC),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Colors.white,
          surfaceContainer: const Color(0xFFF1EFF9),
          surfaceContainerHigh: const Color(0xFFEAE7F6),
          surfaceContainerHighest: const Color(0xFFE3DFF3),
        ),
      );

  static ThemeData dark() => _build(
        ColorScheme.fromSeed(seedColor: _indigo, brightness: Brightness.dark).copyWith(
          primary: const Color(0xFFA897FF),
          secondary: const Color(0xFFFF8A70),
          surface: const Color(0xFF0E0F1A),
          surfaceContainerLowest: const Color(0xFF0A0B14),
          surfaceContainerLow: const Color(0xFF161727),
          surfaceContainer: const Color(0xFF1B1C2E),
          surfaceContainerHigh: const Color(0xFF222338),
          surfaceContainerHighest: const Color(0xFF2A2B42),
        ),
      );

  static ThemeData _build(ColorScheme s) {
    final base = ThemeData(useMaterial3: true, colorScheme: s, brightness: s.brightness);
    final telugu = GoogleFonts.notoSansTelugu().fontFamily;
    final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: s.onSurface,
      displayColor: s.onSurface,
      fontFamilyFallback: [if (telugu != null) telugu],
    );
    final radius = BorderRadius.circular(20);
    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: s.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: s.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: s.outlineVariant.withAlpha(110)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: s.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: s.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: s.error, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: s.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: const StadiumBorder()),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        side: BorderSide(color: s.outlineVariant.withAlpha(140)),
      ),
      dividerTheme: DividerThemeData(color: s.outlineVariant.withAlpha(90), space: 24),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

/// Light / dark / system, saved with the other user preferences.
class ThemeController {
  ThemeController._();
  static final mode = ValueNotifier<ThemeMode>(ThemeMode.system);
}
