import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  static const baseTextStyle = TextStyle(
    fontWeight: FontWeight.w700,
    letterSpacing: 3.0,
  );

  static final headerStyle = baseTextStyle.copyWith(
    fontSize: 15.0,
    color: AppColors.white,
  );

  static final backButtonStyle = baseTextStyle.copyWith(
    fontSize: 15.0,
    color: AppColors.accentGreen,
  );

  static final labelStyle = baseTextStyle.copyWith(
    fontSize: 12.0,
    color: AppColors.textGrey,
  );

  static final buttonTextStyle = baseTextStyle.copyWith(
    fontSize: 12.0,
    color: AppColors.white,
  );

  static final linkStyle = baseTextStyle.copyWith(
    fontSize: 12.0,
    color: AppColors.textGrey,
  );
}
