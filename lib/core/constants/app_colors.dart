import 'package:flutter/material.dart';

class AppColors {
  // Business Mode
  static const Color businessPrimary = Color(0xFF1E3A8A); // Deep Navy
  static const Color businessAccent = Color(0xFFFFD700); // Gold

  // Social Mode
  static const Color socialPrimary = Color(0xFFFF00FF); // Neon Pink
  static const Color socialAccent = Color(0xFF9D00FF); // Purple

  // Private Mode
  static const Color privatePrimary = Color(0xFF333333); // Monotone
  static const Color privateAccent = Color(0xFFC0C0C0); // Silver

  static LinearGradient getGradient(Color primary, Color accent) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primary.withOpacity(0.8), accent.withOpacity(0.6), Colors.black],
    );
  }
}
