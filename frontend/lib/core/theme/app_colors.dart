import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds - Deep purple theme
  static const Color background = Color(0xFF0D0B1E); // Deep purple-black
  static const Color surface = Color(0xFF1A1528); // Purple surface
  static const Color surfaceLight = Color(0xFF2D2545); // Lighter purple surface
  
  // Accents
  static const Color primary = Color(0xFF9B5DE5); // Purple (main accent now)
  static const Color secondary = Color(0xFFBB86FC); // Light purple
  static const Color accentRose = Color(0xFFF15BB5);
  static const Color accentYellow = Color(0xFFFEE440);
  static const Color accentCyan = Color(0xFF00F5D4);
  
  // Functional
  static const Color error = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF4ADE80);
  static const Color online = Color(0xFF4ADE80); // Green for online status
  static const Color live = Color(0xFFFF3B5C); // Red for live
  
  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0A8C0);
  static const Color textDisable = Color(0xFF605878);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF9B5DE5), Color(0xFFBB86FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF1A1035), Color(0xFF0D0B1E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x20FFFFFF),
      Color(0x08FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF9B5DE5), Color(0xFF7B2FD4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
