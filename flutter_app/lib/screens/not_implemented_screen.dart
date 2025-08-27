import 'package:flutter/material.dart';
import '../models/user.dart';
import '../components/standard_page_layout.dart';
import 'user_test_dashboard.dart';

class NotImplementedScreen extends StatelessWidget {
  final User user;
  final String testType;

  const NotImplementedScreen({
    super.key,
    required this.user,
    required this.testType,
  });

  @override
  Widget build(BuildContext context) {
    return StandardPageLayout(
      title: testType,
      currentRoute: '/not-implemented',
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
              Icons.construction,
              color: AppColors.primary,
              size: 60,
            ),
          ),

          const SizedBox(height: 40),

          // Main Message
          Text(
            'COMING SOON',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
          ),

          const SizedBox(height: 20),

          // Description Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'The $testType test is currently under development. Please check back later or try the IMTP test instead.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyText,
            ),
          ),

          const SizedBox(height: 40),

          // Action Buttons
          Column(
            children: [
              // Try IMTP Test Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                UserTestDashboard(user: user, testType: 'IMTP'),
                      ),
                    );
                  },
                  style: AppButtonStyles.primaryButton,
                  child: Text('TRY IMTP TEST', style: AppTextStyles.buttonText),
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
