import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/auth_screen.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  final bool requireAdmin;

  const AuthGuard({super.key, required this.child, this.requireAdmin = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // Check if user is logged in
        if (!authService.isLoggedIn) {
          // Redirect to auth screen if not logged in
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AuthScreen()),
            );
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if admin access is required
        if (requireAdmin && !authService.isAdmin) {
          // Redirect to auth screen if not admin
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Access denied. Admin privileges required.'),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AuthScreen()),
            );
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is authenticated and authorized, show the protected content
        return child;
      },
    );
  }
}


