import 'package:flutter/material.dart';

/// Static color palette for QuickCalc.
///
/// This app intentionally ignores the system light/dark theme setting —
/// these colors are used everywhere, always.
class AppColors {
  AppColors._();

  // Background
  static const Color background = Color(0xFF121212);

  // Buttons
  static const Color numberButton = Color(0xFF2C2C2C);
  static const Color functionButton = Color(0xFF3A3A3A); // AC, %, backspace
  static const Color operatorButton = Color(0xFF3A3A3A);
  static const Color equalsButton = Color(0xFFFF9500);

  // Button press feedback (splash/highlight)
  static const Color numberButtonPressed = Color(0xFF3A3A3A);
  static const Color functionButtonPressed = Color(0xFF4A4A4A);
  static const Color equalsButtonPressed = Color(0xFFE68600);

  // Text
  static const Color primaryText = Colors.white;
  static const Color expressionText = Colors.white;
  static const Color resultText = Colors.white;
  static const Color equalsText = Colors.white;
  static const Color operatorText = Color(0xFFFF9500);
}
