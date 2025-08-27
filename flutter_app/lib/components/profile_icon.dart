import 'package:flutter/material.dart';
import '../theme/colors.dart';

class ProfileIcon extends StatelessWidget {
  final double size;

  const ProfileIcon({super.key, this.size = 104});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primaryGreen,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_outline,
        size: size * 0.6,
        color: AppColors.white,
      ),
    );
  }
}
