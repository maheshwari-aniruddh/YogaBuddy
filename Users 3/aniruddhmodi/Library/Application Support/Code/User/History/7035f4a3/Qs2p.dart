import 'package:flutter/material.dart';

class AppColors {
  static bool isDark = true;

  // Dynamic colors based on theme
  // Premium Dark Mode: Deep charcoal background, rich dark surface
  static Color get background => isDark ? const Color(0xFF0A0A0B) : const Color(0xFFFAF7F5);
  static Color get surface => isDark ? const Color(0xFF1A1A1D) : const Color(0xFFFFF5F7);
  static Color get surfaceLight => isDark ? const Color(0xFF252529) : const Color(0xFFFFE4E8);
  
  static Color get textPrimary => isDark ? const Color(0xFFF5F5F7) : const Color(0xFF5C4A4F);
  static Color get textSecondary => isDark ? const Color(0xFFB8B8BD) : const Color(0xFF9B8A8E);
  static Color get border => isDark ? const Color(0xFF36363A) : const Color(0xFFE8D5D5);
  static Color get cream => isDark ? const Color(0xFF252529) : const Color(0xFFFFF9F5);

  // Static accents (Rose theme looks good on dark too, but maybe slightly adjusted)
  static const primary = Color(0xFFE8A5A5);
  static const primaryDark = Color(0xFFD88A8F);
  static const accent = Color(0xFFF4C2C2);
  static const roseDeep = Color(0xFFC97A7E);
  static const rosePetal = Color(0xFFFAD2D3);
  static const sage = Color(0xFFB5C5B0);
}

class MoodColors {
  static const List<Color> colors = [
    Color(0xFFD88A8F), // Terrible - deeper rose
    Color(0xFFE8A5A5), // Bad - rose
    Color(0xFFF4C2C2), // Okay - light rose
    Color(0xFFB5C5B0), // Good - sage green
    Color(0xFF9BB09D), // Great - deeper sage
  ];

  static Color getColor(int mood) => colors[mood - 1];
}
