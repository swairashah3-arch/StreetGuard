import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Display Styles
  static const TextStyle display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    letterSpacing: -0.5,
  );

  static const TextStyle title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    letterSpacing: -0.2,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  // Body Styles
  static const TextStyle body = TextStyle(
    fontSize: 15,
    color: AppColors.primary,
    height: 1.5,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    color: AppColors.secondary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.secondary,
    fontWeight: FontWeight.w500,
  );

  // Button Styles
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.2,
  );

  // Premium Decorations
  static BoxDecoration get premiumCard => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.04),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: AppColors.primary.withOpacity(0.04),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration get glassEffect => BoxDecoration(
    color: Colors.white.withOpacity(0.8),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
  );

  // Backward Compatibility (Old names used in some files)
  static BoxDecoration get cardDecoration => premiumCard;
  static TextStyle get bold16 => sectionTitle.copyWith(fontSize: 16);
  static TextStyle get label => body.copyWith(fontWeight: FontWeight.bold);
}
