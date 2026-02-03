import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4B42E0);
  static const Color primaryLight = Color(0xFF8D86FF);
  static const Color background = Color(0xFF0F0F1E);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF252541);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB4B4B4);
  static const Color textTertiary = Color(0xFF6E6E6E);
  static const Color accent = Color(0xFFFF6B9D);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);

  static const LinearGradient primaryGradient = LinearGradient(
    colors:[Color(0xFF6C63FF), Color(0xFFFF6B9D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF252541)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}