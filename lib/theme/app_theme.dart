import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const background = Color(0xFFFAF7F2);
  static const backgroundSecondary = Color(0xFFF2F6FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceHighlight = Color(0xFFF3F7FB);
  static const softSurface = Color(0xFFE8EFF7);
  static const border = Color(0xFFDEE4EE);
  static const accent = Color(0xFF345077);
  static const accentDeep = Color(0xFF1B2B45);
  static const accentSoft = Color(0xFF9EB4D0);
  static const premium = Color(0xFF8C7DA4);
  static const success = Color(0xFF5E7E65);
  static const text = Color(0xFF1F2B3A);
  static const textSoft = Color(0xFF6C7A8C);

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
      ).copyWith(
        primary: accent,
        onPrimary: Colors.white,
        secondary: accentSoft,
        onSecondary: Colors.white,
        tertiary: premium,
        onTertiary: Colors.white,
        surface: surface,
        onSurface: text,
        outline: border,
      ),
      scaffoldBackgroundColor: background,
    );

    final bodyTextTheme = GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
      bodyLarge: const TextStyle(
        fontSize: 16,
        height: 1.55,
        color: text,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        height: 1.5,
        color: textSoft,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: const TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: text,
        letterSpacing: -0.15,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: text,
      ),
      labelLarge: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: text,
      ),
      labelMedium: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: textSoft,
      ),
    );

    return base.copyWith(
      textTheme: bodyTextTheme.copyWith(
        displaySmall: GoogleFonts.cormorantGaramond(
          fontSize: 42,
          height: 1.0,
          fontWeight: FontWeight.w700,
          color: text,
          letterSpacing: -1.1,
        ),
        headlineMedium: GoogleFonts.cormorantGaramond(
          fontSize: 34,
          height: 1.02,
          fontWeight: FontWeight.w700,
          color: text,
          letterSpacing: -0.7,
        ),
        headlineSmall: GoogleFonts.cormorantGaramond(
          fontSize: 28,
          height: 1.05,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      iconTheme: const IconThemeData(color: text),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: accentDeep.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface.withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
        indicatorColor: softSurface.withValues(alpha: 0.85),
        height: 74,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? text : textSoft,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
            fontSize: 12,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? accent : textSoft,
            size: 24,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        hintStyle: const TextStyle(color: textSoft),
        labelStyle:
            const TextStyle(color: textSoft, fontWeight: FontWeight.w600),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: accent, width: 1.3),
        ),
        prefixIconColor: textSoft,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          foregroundColor: text,
          backgroundColor: surface.withValues(alpha: 0.82),
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        iconColor: accentDeep,
        textColor: text,
        tileColor: Colors.white.withValues(alpha: 0.62),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white.withValues(alpha: 0.84),
        selectedColor: softSurface.withValues(alpha: 0.72),
        secondarySelectedColor: accent.withValues(alpha: 0.12),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: const TextStyle(
          color: text,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: accentDeep,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
