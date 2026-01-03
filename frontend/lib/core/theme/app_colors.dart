import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0D0D0F);
  static const Color surface = Color(0xFF1A1A1F);
  static const Color surfaceLight = Color(0xFF2A2A30);
  
  // Accents
  static const Color primary = Color(0xFF00F5D4); // Cyan
  static const Color secondary = Color(0xFF9B5DE5); // Purple
  static const Color accentRose = Color(0xFFF15BB5);
  static const Color accentYellow = Color(0xFFFEE440);
  
  // Functional
  static const Color error = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF00F5D4);
  static const Color online = Color(0xFF00F5D4);
  
  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0A5);
  static const Color textDisable = Color(0xFF505055);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [secondary, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x1AFFFFFF),
      Color(0x0DFFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
