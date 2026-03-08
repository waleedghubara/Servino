// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// Application Color Constants
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF1E88E5);
  static const Color primary2 = Color.fromARGB(255, 3, 18, 68);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF29B6F6);

  // Secondary Colors
  static const Color secondary = Color.fromARGB(255, 23, 117, 0);
  static const Color secondaryDark = Color.fromARGB(255, 190, 124, 1);
  static const Color secondaryLight = Color(0xFF8B5BB5);

  // Accent Colors
  static const Color accent = Color(0xFFF093FB);
  static const Color accentDark = Color(0xFFE080E8);
  static const Color accentLight = Color(0xFFFFB3FF);
  static const Color primary22 = Color.fromARGB(255, 0, 41, 177);
  static const Color primary222 = Color.fromARGB(255, 28, 79, 247);
  // للرسالة المستقبلة
  static const Color recipientColor = Color.fromARGB(
    255,
    255,
    255,
    255,
  ); // رمادي هادئ جداً
  static const Color recipientColorSubtle = Color.fromARGB(255, 136, 156, 245);
  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF16213E);

  // Text Colors
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textLight = Color(0xFFB2BEC3);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDAA5D);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF74B9FF);

  // Border & Divider Colors
  static const Color border = Color(0xFFDFE6E9);
  static const Color divider = Color(0xFFECF0F1);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary2, primary2],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFFF5576C)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [backgroundDark, surfaceDark],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
  );
}
