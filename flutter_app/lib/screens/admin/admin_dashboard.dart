import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/standard_page_layout.dart';
import '../../services/auth_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final currentUser = authService.currentUser;
        return StandardPageLayout(
          title: currentUser?.username ?? "ADMIN",
          currentRoute: '/admin',
          child: Column(
            children: [
              // Admin label
              Consumer<AuthService>(
                builder: (context, authService, child) {
                  final currentUser = authService.currentUser;
                  final isJesper = currentUser?.email == 'jesper@lnu.se';
                  return Text(
                    isJesper ? 'DEMO ADMIN' : 'ADMIN USER',
                    style: AppTextStyles.buttonText.copyWith(
                      color:
                          isJesper
                              ? const Color(0xFFFFE000)
                              : AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Admin Action Buttons
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      () => Navigator.pushNamed(context, '/admin/add-user'),
                  style: AppButtonStyles.primaryButton,
                  child: Text('ADD NEW USER', style: AppTextStyles.buttonText),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/admin/users'),
                  style: AppButtonStyles.primaryButton,
                  child: Text('ALL USERS', style: AppTextStyles.buttonText),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      () => Navigator.pushNamed(context, '/admin/settings'),
                  style: AppButtonStyles.primaryButton,
                  child: Text('SETTING', style: AppTextStyles.buttonText),
                ),
              ),

              const SizedBox(height: 20),

              Consumer<AuthService>(
                builder: (context, authService, child) {
                  final currentUser = authService.currentUser;
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/choose-test',
                          arguments: currentUser,
                        );
                      },
                      style: AppButtonStyles.primaryButton,
                      child: Text(
                        'RUN TEST (Quick Access)',
                        style: AppTextStyles.buttonText,
                      ),
                    ),
                  );
                },
              ),

              const Spacer(),
            ],
          ),
        );
      },
    );
  }
}
