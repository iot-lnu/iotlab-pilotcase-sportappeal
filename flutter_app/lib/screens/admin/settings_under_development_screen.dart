import 'package:flutter/material.dart';
import '../../components/standard_page_layout.dart';

class SettingsUnderDevelopmentScreen extends StatelessWidget {
  const SettingsUnderDevelopmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StandardPageLayout(
      title: 'SETTING',
      currentRoute: '/admin/settings',
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Under Development Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 2),
            ),
            child: const Icon(
              Icons.settings,
              color: AppColors.primary,
              size: 60,
            ),
          ),

          const SizedBox(height: 40),

          // Main Message
          Text(
            'UNDER DEVELOPMENT',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
          ),

          const SizedBox(height: 20),

          // Description Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'The settings page is currently under development. Here you will be able to configure app preferences, notifications, data management, and other system settings.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyText,
            ),
          ),

          const SizedBox(height: 40),

          // Action Buttons
          Column(
            children: [
              // Go to Admin Dashboard Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/admin');
                  },
                  style: AppButtonStyles.primaryButton,
                  child: Text(
                    'ADMIN DASHBOARD',
                    style: AppTextStyles.buttonText,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Go Back Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: AppButtonStyles.secondaryButton,
                  child: Text(
                    'GO BACK',
                    style: AppTextStyles.buttonText.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),
        ],
      ),
    );
  }
}
