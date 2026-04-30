import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const primary = Color(0xFF0F172A);    // Deep Slate/Navy
  static const accent = Color(0xFF3B82F6);     // Vivid Blue
  static const secondary = Color(0xFF64748B);  // Slate Gray
  
  // Alert Colors
  static const danger = Color(0xFFE11D48);     // Crimson Red
  static const warning = Color(0xFFF59E0B);    // Orange
  static const success = Color(0xFF10B981);    // Emerald Green
  
  // Neutral Colors
  static const white = Colors.white;
  static const background = Color(0xFFF8FAFC); // Alice Blue/Slate 50
  static const surface = Colors.white;
  static const border = Color(0xFFE2E8F0);     // Slate 200
  
  // Premium Gradients
  static const primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
