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
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05,
          vertical: MediaQuery.of(context).size.height * 0.02,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),

            // Under Development Icon
            Container(
              width: MediaQuery.of(context).size.width * 0.25,
              height: MediaQuery.of(context).size.width * 0.25,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              child: Icon(
                Icons.construction,
                color: AppColors.primary,
                size: MediaQuery.of(context).size.width * 0.12,
              ),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.03),

            // Main Message
            Text(
              'COMING SOON',
              style: AppTextStyles.sectionTitle.copyWith(
                fontSize: MediaQuery.of(context).size.width * 0.045,
              ),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.02),

            // Description Text
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.04,
              ),
              child: Text(
                'The $testType test is currently under development. Please check back later or try the IMTP test instead.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyText.copyWith(
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.03),

            // Action Buttons
            Column(
              children: [
                // Try IMTP Test Button
                SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.06,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => UserTestDashboard(
                                user: user,
                                testType: 'IMTP',
                              ),
                        ),
                      );
                    },
                    style: AppButtonStyles.primaryButton,
                    child: Text(
                      'TRY IMTP TEST',
                      style: AppTextStyles.buttonText.copyWith(
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).size.height * 0.015),

                // Go Back Button
                SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.06,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: AppButtonStyles.secondaryButton,
                    child: Text(
                      'GO BACK',
                      style: AppTextStyles.buttonText.copyWith(
                        color: AppColors.primary,
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.025),
          ],
        ),
      ),
    );
  }
}
