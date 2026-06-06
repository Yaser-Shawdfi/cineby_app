import 'package:flutter/material.dart';

/// Palette that matches cineby.at's dark theme.
class AppColors {
  AppColors._();

  // Match cineby.at's dark theme exactly
  static const Color background = Color(0xFF0F0F0F);
  static const Color navBar = Color(0xFF141414);
  static const Color navBarBorder = Color(0xFF2A2A2A);
  static const Color accent = Color(0xFFE50914); // cineby red
  static const Color iconActive = Color(0xFFFFFFFF);
  static const Color iconInactive = Color(0xFF6B6B6B);

  // Supplementary shades
  static const Color surface = Color(0xFF1A1A1A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color divider = Color(0xFF2A2A2A);
}
