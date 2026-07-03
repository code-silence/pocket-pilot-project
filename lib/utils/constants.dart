import 'package:flutter/material.dart';

class AppColors {
  // Primary greens
  static const primary = Color(0xFF2E7D32); // deep green
  static const primaryLight = Color(0xFF4CAF50); // medium green
  static const accent = Color(0xFF81C784); // soft green

  // Backgrounds
  static const background = Color(0xFFFFFFFF); // white
  static const surface = Color(0xFFF1F8E9); // very light green tint

  // Text
  static const textDark = Color(0xFF1B1B1B);
  static const textMuted = Color(0xFF757575);

  // Category colors (for charts later)
  static const food = Color(0xFF66BB6A);
  static const transport = Color(0xFF42A5F5);
  static const shopping = Color(0xFFFF7043);
  static const health = Color(0xFFAB47BC);
  static const education = Color(0xFF26C6DA);
  static const rent = Color(0xFFFF7043);
  static const religious = Color(0xFF8D6E63);
  static const other = Color(0xFFBDBDBD);
}

class AppCategories {
  static const List<String> all = [
    'Food',
    'Transport',
    'Shopping',
    'Health',
    'Education',
    'Rent',
    'Religious',
    'Other',
  ];
}
