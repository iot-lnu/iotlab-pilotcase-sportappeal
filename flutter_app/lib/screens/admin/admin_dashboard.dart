import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/back_button.dart';
import '../../components/primary_button.dart';
import '../../components/three_dots_menu.dart';
import '../../theme/colors.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomBackButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const ThreeDotsMenu(),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              Consumer<AuthService>(
                                builder: (context, authService, child) {
                                  final currentUser = authService.currentUser;
                                  return Text(
                                    currentUser?.username.toUpperCase() ??
                                        "ADMIN",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  );
                                },
                              ),
                              const Divider(
                                color: Colors.white,
                                thickness: 1,
                                indent: 100,
                                endIndent: 100,
                              ),
                              const SizedBox(height: 10),
                              Consumer<AuthService>(
                                builder: (context, authService, child) {
                                  final currentUser = authService.currentUser;
                                  final isJesper =
                                      currentUser?.email == 'jesper@lnu.se';
                                  return Text(
                                    isJesper ? 'DEMO ADMIN' : 'ADMIN USER',
                                    style: TextStyle(
                                      color:
                                          isJesper
                                              ? const Color(0xFFFFE000)
                                              : const Color(0xFF75F94C),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  );
                                },
                              ),

                              const Spacer(),

                              PrimaryButton(
                                text: 'ADD NEW USER',
                                width: double.infinity,
                                onPressed:
                                    () => Navigator.pushNamed(
                                      context,
                                      '/admin/add-user',
                                    ),
                              ),
                              const SizedBox(height: 30),
                              PrimaryButton(
                                text: 'ALL USERS',
                                width: double.infinity,
                                onPressed:
                                    () => Navigator.pushNamed(
                                      context,
                                      '/admin/users',
                                    ),
                              ),
                              const SizedBox(height: 30),
                              PrimaryButton(
                                text: 'SETTING',
                                width: double.infinity,
                                onPressed:
                                    () => Navigator.pushNamed(
                                      context,
                                      '/admin/settings',
                                    ),
                              ),
                              const SizedBox(height: 30),
                              Consumer<AuthService>(
                                builder: (context, authService, child) {
                                  final currentUser = authService.currentUser;
                                  return PrimaryButton(
                                    text: 'RUN TEST (Quick Access)',
                                    width: double.infinity,
                                    onPressed: () {
                                      // Navigate to choose test screen with current user
                                      Navigator.pushNamed(
                                        context,
                                        '/choose-test',
                                        arguments: currentUser,
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 30),
                              Container(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Use the same logout logic as the 3 dots menu
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Logout'),
                                          content: const Text(
                                            'Are you sure you want to log out?',
                                          ),
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
                                                final authService =
                                                    Provider.of<AuthService>(
                                                      context,
                                                      listen: false,
                                                    );
                                                authService.logout();
                                                Navigator.of(context).pop();
                                                Navigator.of(
                                                  context,
                                                ).pushReplacementNamed('/');
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16.0,
                                    ),
                                  ),
                                  child: const Text(
                                    'LOGOUT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),

                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.home,
                              color: Color(0xFFFFE000),
                              size: 32,
                            ),
                            onPressed:
                                () => Navigator.pushReplacementNamed(
                                  context,
                                  '/',
                                ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed:
                                () => Navigator.pushReplacementNamed(
                                  context,
                                  '/admin',
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
