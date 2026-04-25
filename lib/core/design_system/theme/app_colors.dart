import 'package:flutter/material.dart';

/// App Colors - Centralized color scheme
class AppColors {
  // Primary Brand Colors (Al Ahly)
  static const Color primary = Color(0xFFD4AF37); // Gold
  static const Color primaryDark = Color(0xFFB8941F); // Dark Gold
  static const Color primaryLight = Color(0xFFE8C547); // Light Gold
  
  // Secondary Colors
  static const Color secondary = Color(0xFFE53935); // Red
  static const Color secondaryDark = Color(0xFFC62828); // Dark Red
  static const Color secondaryLight = Color(0xFFEF5350); // Light Red
  
  // Neutral Colors
  static const Color background = Color(0xFF000000); // Black
  static const Color surface = Color(0xFF1A1A1A); // Dark Gray
  static const Color surfaceVariant = Color(0xFF2A2A2A); // Lighter Gray
  static const Color onSurface = Color(0xFFFFFFFF); // White
  static const Color onSurfaceVariant = Color(0xFFB3B3B3); // Light Gray Text
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color warning = Color(0xFFFF9800); // Orange
  static const Color error = Color(0xFFF44336); // Red
  static const Color info = Color(0xFF2196F3); // Blue
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // White
  static const Color textSecondary = Color(0xFFB3B3B3); // Light Gray
  static const Color textTertiary = Color(0xFF808080); // Gray
  static const Color textDisabled = Color(0xFF4A4A4A); // Dark Gray
  
  // Gradient Colors
  static const List<Color> goldGradient = [
    Color(0xFFD4AF37),
    Color(0xFFB8941F),
  ];
  
  static const List<Color> redGradient = [
    Color(0xFFE53935),
    Color(0xFFC62828),
  ];
  
  static const List<Color> darkGradient = [
    Color(0xFF1A1A1A),
    Color(0xFF000000),
  ];
  
  // Opacity Colors
  static Color primaryWithOpacity(double opacity) => primary.withValues(alpha: opacity);
  static Color secondaryWithOpacity(double opacity) => secondary.withValues(alpha: opacity);
  static Color surfaceWithOpacity(double opacity) => surface.withValues(alpha: opacity);
}
