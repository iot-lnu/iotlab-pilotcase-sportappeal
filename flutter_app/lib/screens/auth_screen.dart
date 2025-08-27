import 'package:flutter/material.dart';
import '../components/primary_button.dart';
import '../theme/colors.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 1024;

    // Calculate appropriate button width based on screen size (website/mobile).
    double buttonWidth = isDesktop ? 200 : screenSize.width * 0.8;

    return Scaffold(
      backgroundColor: const Color(0xFF017340),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.fitness_center,
                  size: 100,
                  color: Color(0xFFFFE000),
                ),
                const SizedBox(height: 30),
                Text(
                  'SPORT PERFORMANCE',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: isDesktop ? 30 : 25,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 70),
                SizedBox(
                  width: buttonWidth * 0.8,
                  child: PrimaryButton(
                    text: 'LOG IN',
                    width: double.infinity,
                    showBorder: true,
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: buttonWidth * 0.8,
                  child: PrimaryButton(
                    text: 'REGISTER',
                    width: double.infinity,
                    showBorder: true,
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
