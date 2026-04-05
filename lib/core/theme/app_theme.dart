import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color deepBlack = Color(0xFF0A0A0A);
  static const Color darkBlack = Color(0xFF1A1A1A);
  static const Color mediumBlack = Color(0xFF2A2A2A);
  static const Color luminousGold = Color(0xFFC5A059);
  static const Color brightGold = Color(0xFFEBC374);
  static const Color darkGold = Color(0xFF8B6B3F);
  static const Color royalRed = Color(0xFFE30613);
  static const Color brightRed = Color(0xFFFF1A1A);
  static const Color darkRed = Color(0xFF9E0000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFE0E0E0);
  static const Color mediumGray = Color(0xFF9E9E9E);
  static const Color darkGray = Color(0xFF424242);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
}

class AppFontSizes {
  static const double xs = 10.0;
  static const double sm = 12.0;
  static const double base = 14.0;
  static const double lg = 16.0;
  static const double xl = 18.0;
  static const double xxl = 20.0;
  static const double xxxl = 24.0;
  static const double huge = 32.0;
  static const double massive = 48.0;
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;
}

class AppBorderRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double circular = 50.0;
}

class AppTheme {
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.royalRed,
      scaffoldBackgroundColor: AppColors.deepBlack,
      canvasColor: AppColors.darkBlack,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.royalRed,
        secondary: AppColors.luminousGold,
        tertiary: AppColors.brightRed,
        surface: AppColors.darkBlack,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.deepBlack,
        onSurface: AppColors.white,
        onError: AppColors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF101115),
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: AppFontSizes.xl,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF111318),
        selectedItemColor: Color(0xFFE1306C),
        unselectedItemColor: Color(0xFF8E8E93),
        elevation: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.royalRed,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          ),
          elevation: 4,
          textStyle: GoogleFonts.cairo(
            fontSize: AppFontSizes.lg,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.luminousGold,
          side: const BorderSide(color: AppColors.luminousGold, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: AppFontSizes.lg,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.luminousGold,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: AppFontSizes.lg,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.cairo(
          fontSize: AppFontSizes.massive,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        displayMedium: GoogleFonts.cairo(
          fontSize: AppFontSizes.huge,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        displaySmall: GoogleFonts.cairo(
          fontSize: AppFontSizes.xxxl,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        headlineMedium: GoogleFonts.cairo(
          fontSize: AppFontSizes.xxl,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        headlineSmall: GoogleFonts.cairo(
          fontSize: AppFontSizes.xl,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        titleLarge: GoogleFonts.cairo(
          fontSize: AppFontSizes.lg,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        titleMedium: GoogleFonts.cairo(
          fontSize: AppFontSizes.base,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        titleSmall: GoogleFonts.cairo(
          fontSize: AppFontSizes.sm,
          fontWeight: FontWeight.w600,
          color: AppColors.mediumGray,
        ),
        bodyLarge: GoogleFonts.cairo(
          fontSize: AppFontSizes.lg,
          fontWeight: FontWeight.normal,
          color: AppColors.white,
        ),
        bodyMedium: GoogleFonts.cairo(
          fontSize: AppFontSizes.base,
          fontWeight: FontWeight.normal,
          color: AppColors.lightGray,
        ),
        bodySmall: GoogleFonts.cairo(
          fontSize: AppFontSizes.sm,
          fontWeight: FontWeight.normal,
          color: AppColors.mediumGray,
        ),
        labelLarge: GoogleFonts.cairo(
          fontSize: AppFontSizes.base,
          fontWeight: FontWeight.bold,
          color: AppColors.luminousGold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1C21),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          borderSide: const BorderSide(color: Color(0xFF2A2D33)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          borderSide: const BorderSide(color: Color(0xFF2A2D33), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          borderSide: const BorderSide(color: Color(0xFFE1306C), width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: GoogleFonts.cairo(
          fontSize: AppFontSizes.base,
          color: AppColors.mediumGray,
        ),
        labelStyle: GoogleFonts.cairo(
          fontSize: AppFontSizes.base,
          color: AppColors.luminousGold,
        ),
        errorStyle: GoogleFonts.cairo(
          fontSize: AppFontSizes.sm,
          color: AppColors.error,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkBlack,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkBlack,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        ),
        titleTextStyle: GoogleFonts.cairo(
          fontSize: AppFontSizes.xl,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        contentTextStyle: GoogleFonts.cairo(
          fontSize: AppFontSizes.base,
          color: AppColors.lightGray,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.mediumGray,
        thickness: 1,
        space: AppSpacing.lg,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.mediumBlack,
        selectedColor: AppColors.luminousGold,
        disabledColor: AppColors.mediumGray,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        labelStyle: GoogleFonts.cairo(
          fontSize: AppFontSizes.sm,
          color: AppColors.white,
        ),
        secondaryLabelStyle: GoogleFonts.cairo(
          fontSize: AppFontSizes.sm,
          color: AppColors.deepBlack,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.luminousGold,
        size: 24,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFFE1306C),
        foregroundColor: AppColors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.circular),
        ),
      ),
    );
  }
}
