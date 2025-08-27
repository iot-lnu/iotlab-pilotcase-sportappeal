import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class BottomNavigation extends StatelessWidget {
  final String? currentRoute;

  const BottomNavigation({super.key, this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Home Icon
              GestureDetector(
                onTap: () => _navigateToHome(context),
                child: Icon(Icons.home, color: Colors.yellow, size: 30),
              ),

              // Profile/Admin Icon
              GestureDetector(
                onTap: () => _navigateToProfile(context, authService),
                child: Icon(Icons.person, color: Colors.yellow, size: 30),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToHome(BuildContext context) {
    // Navigate to home/auth screen
    if (ModalRoute.of(context)?.settings.name != '/') {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  void _navigateToProfile(BuildContext context, AuthService authService) {
    // Navigate to appropriate profile/dashboard based on user role
    if (authService.isAdmin) {
      // Navigate to admin dashboard
      if (ModalRoute.of(context)?.settings.name != '/admin') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/admin',
          (route) =>
              route.settings.name == '/' || route.settings.name == '/admin',
        );
      }
    } else {
      // Navigate to user profile with current user
      final currentUser = authService.currentUser;
      if (currentUser != null) {
        Navigator.pushNamed(context, '/user-profile', arguments: currentUser);
      }
    }
  }
}
