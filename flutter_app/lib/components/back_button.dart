import 'package:flutter/material.dart';
import '../theme/text_styles.dart';
import '../theme/colors.dart';

class CustomBackButton extends StatelessWidget {
  final Function()? onPressed;

  const CustomBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ?? () => Navigator.of(context).pop(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back_ios, color: AppColors.accentGreen, size: 24),
          Text('BACK', style: AppTextStyles.backButtonStyle),
        ],
      ),
    );
  }
}
