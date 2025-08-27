import 'package:flutter/material.dart';
import '../theme/colors.dart';

class AuthCard extends StatelessWidget {
  final Widget child;
  final double width;

  const AuthCard({super.key, required this.child, this.width = 343.0});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 640 && screenWidth <= 1024;

    // Scale width based on screen size
    double containerWidth;
    if (isDesktop) {
      containerWidth = 500; // Wider for desktop
    } else if (isTablet) {
      containerWidth = 400; // Medium for tablet
    } else {
      containerWidth = screenWidth * 0.9; // Mobile size
    }

    return Container(
      width: containerWidth,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}
