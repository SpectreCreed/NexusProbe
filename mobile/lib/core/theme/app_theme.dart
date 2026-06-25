import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system tokens for Email OSINT App.
/// Deep dark theme with electric cyan accent — premium feel.
class AppTheme {
  AppTheme._();

  // ── Color palette ──────────────────────────────────────────────────────────
  static const Color background     = Color(0xFF0A0E1A); // Deep navy-black
  static const Color surface        = Color(0xFF111827); // Card surface
  static const Color surfaceHigh    = Color(0xFF1C2333); // Elevated card
  static const Color surfaceBorder  = Color(0xFF252D3D); // Subtle border

  static const Color accent         = Color(0xFF00E5FF); // Electric cyan
  static const Color accentDim      = Color(0xFF00B8CC); // Dimmed cyan
  static const Color accentSurface  = Color(0xFF002B33); // Cyan tint bg

  static const Color success        = Color(0xFF22C55E);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color error          = Color(0xFFEF4444);
  static const Color critical       = Color(0xFFDC2626);

  // Risk colors
  static const Color riskLow      = Color(0xFF22C55E);
  static const Color riskMedium   = Color(0xFFF59E0B);
  static const Color riskHigh     = Color(0xFFEF4444);
  static const Color riskCritical = Color(0xFFDC2626);

  static const Color textPrimary   = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted     = Color(0xFF475569);

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF0080FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0A0E1A), Color(0xFF0D1424)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF111827), Color(0xFF161D2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Typography ─────────────────────────────────────────────────────────────
  static TextTheme get textTheme => GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      );

  // ── Full theme ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accentDim,
          surface: surface,
          error: error,
          onPrimary: Color(0xFF000000),
          onSecondary: Color(0xFF000000),
          onSurface: textPrimary,
          onError: textPrimary,
        ),
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.inter(
            color: textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: textPrimary),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: surfaceBorder, width: 1),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceHigh,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: surfaceBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: surfaceBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: error),
          ),
          hintStyle: const TextStyle(color: textMuted, fontSize: 15),
          labelStyle: const TextStyle(color: textSecondary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: accent),
        ),
        dividerTheme: const DividerThemeData(
          color: surfaceBorder,
          thickness: 1,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: accent,
          unselectedItemColor: textMuted,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: surfaceHigh,
          labelStyle: const TextStyle(color: textSecondary, fontSize: 12),
          side: const BorderSide(color: surfaceBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: accent,
          unselectedLabelColor: textMuted,
          indicatorColor: accent,
          dividerColor: surfaceBorder,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: accent,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: surfaceHigh,
          contentTextStyle: const TextStyle(color: textPrimary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        extensions: const [],
      );

  // ── Helper: risk color ─────────────────────────────────────────────────────
  static Color riskColor(String label) {
    switch (label.toLowerCase()) {
      case 'low':
        return riskLow;
      case 'medium':
        return riskMedium;
      case 'high':
        return riskHigh;
      case 'critical':
        return riskCritical;
      default:
        return textMuted;
    }
  }
}
