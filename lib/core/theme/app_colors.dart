import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFFF6A9BE);
  static const Color primaryLight = Color(0xFFFFD6E0);
  static const Color primaryDark = Color(0xFFE8899E);

  // Secondary
  static const Color secondary = Color(0xFFF8D66D);
  static const Color secondaryLight = Color(0xFFFBE8A6);

  // Background & Surface
  static const Color background = Color(0xFFFFF7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceGlass = Color(0x1AF6A9BE); // 10% primary

  // Border
  static const Color border = Color(0xFFF8C4D2);
  static const Color borderLight = Color(0x33F8C4D2); // 20% opacity
  static const Color borderGlass = Color(0x66F8C4D2); // 40% opacity

  // Text
  static const Color textPrimary = Color(0xFF2F2F2F);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textLight = Color(0xFF999999);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF89D38F);
  static const Color error = Color(0xFFFF8A8A);
  static const Color warning = Color(0xFFF8D66D);
  static const Color info = Color(0xFF8AC4FF);

  // Glass
  static const Color glassWhite = Color(0x26FFFFFF); // 15%
  static const Color glassBorder = Color(0x33FFFFFF); // 20%
  static const Color glassOverlay = Color(0x0DFFFFFF); // 5%

  // Shadows
  static const Color shadowLight = Color(0x0AF6A9BE); // 4% primary
  static const Color shadowMedium = Color(0x14F6A9BE); // 8% primary

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF7FA), Color(0xFFFFF0F5)],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
  );
}
