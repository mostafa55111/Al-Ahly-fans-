import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App Text Styles - Centralized typography
class AppTextStyles {
  // Google Fonts Setup
  static const String _primaryFont = 'Cairo';
  static const String _secondaryFont = 'Tajawal';
  
  // Headline Styles
  static TextStyle get h1 => GoogleFonts.getFont(
    _primaryFont,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static TextStyle get h2 => GoogleFonts.getFont(
    _primaryFont,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static TextStyle get h3 => GoogleFonts.getFont(
    _primaryFont,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static TextStyle get h4 => GoogleFonts.getFont(
    _primaryFont,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  // Body Text Styles
  static TextStyle get bodyLarge => GoogleFonts.getFont(
    _secondaryFont,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.getFont(
    _secondaryFont,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static TextStyle get bodySmall => GoogleFonts.getFont(
    _secondaryFont,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  // Button Text Styles
  static TextStyle get buttonLarge => GoogleFonts.getFont(
    _primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static TextStyle get buttonMedium => GoogleFonts.getFont(
    _primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static TextStyle get buttonSmall => GoogleFonts.getFont(
    _primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  // Caption and Label Styles
  static TextStyle get caption => GoogleFonts.getFont(
    _secondaryFont,
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: AppColors.textTertiary,
    height: 1.4,
  );
  
  static TextStyle get label => GoogleFonts.getFont(
    _secondaryFont,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.3,
  );
  
  // Specialized Styles
  static TextStyle get appBarTitle => GoogleFonts.getFont(
    _primaryFont,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static TextStyle get cardTitle => GoogleFonts.getFont(
    _primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static TextStyle get cardSubtitle => GoogleFonts.getFont(
    _secondaryFont,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  static TextStyle get errorText => GoogleFonts.getFont(
    _secondaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
    height: 1.4,
  );
  
  static TextStyle get successText => GoogleFonts.getFont(
    _secondaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.success,
    height: 1.4,
  );
  
  // Style Modifiers
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
  
  static TextStyle withSize(TextStyle style, double fontSize) {
    return style.copyWith(fontSize: fontSize);
  }
  
  static TextStyle withWeight(TextStyle style, FontWeight fontWeight) {
    return style.copyWith(fontWeight: fontWeight);
  }
  
  static TextStyle withOpacity(TextStyle style, double opacity) {
    return style.copyWith(color: style.color?.withValues(alpha: opacity));
  }
}
