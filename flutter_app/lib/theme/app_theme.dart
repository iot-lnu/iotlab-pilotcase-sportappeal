import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF007340);
  static const Color white = Colors.white;

  static TextStyle buttonTextStyle = const TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 15,
    color: white,
    letterSpacing: 3,
  );

  static ButtonStyle authButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: white,
    side: const BorderSide(color: white, width: 1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    minimumSize: const Size.fromHeight(42),
  );
}
