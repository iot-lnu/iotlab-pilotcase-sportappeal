import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ThreeDotsMenu extends StatelessWidget {
  final bool isCircular;
  final Color? borderColor;
  final Color? iconColor;
  final double size;
  final VoidCallback? onMenuTap;

  const ThreeDotsMenu({
    super.key,
    this.isCircular = false,
    this.borderColor,
    this.iconColor,
    this.size = 44,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBorderColor = borderColor ?? const Color(0xFF75F94C);
    final defaultIconColor = iconColor ?? const Color(0xFF75F94C);

    if (isCircular) {
      // Circular 3 dots menu (horizontal dots)
      return GestureDetector(
        onTap: onMenuTap ?? () => _showLogoutDialog(context),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: defaultBorderColor, width: 1.5),
          ),
          child: Center(child: Icon(Icons.more_horiz, color: defaultIconColor)),
        ),
      );
    } else {
      // Standard 3 dots menu (vertical dots) - DEFAULT
      return GestureDetector(
        onTap: onMenuTap ?? () => _showLogoutDialog(context),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: Icon(Icons.more_vert, color: Colors.white, size: 24),
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () {
                final authService = Provider.of<AuthService>(
                  context,
                  listen: false,
                );
                authService.logout();
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/');
              },
            ),
          ],
        );
      },
    );
  }
}
