import 'package:flutter/material.dart';
import '../models/user.dart';
import '../components/standard_page_layout.dart';

class AddUserSuccessScreen extends StatelessWidget {
  final User user;

  const AddUserSuccessScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return StandardPageLayout(
      title: 'ADD USER',
      currentRoute: '/add-user-success',
      child: Column(
        children: [
          const SizedBox(height: 60),

          // Success Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF75F94C), width: 3),
            ),
            child: const Center(
              child: Icon(Icons.check, color: Color(0xFF75F94C), size: 48),
            ),
          ),

          const SizedBox(height: 40),

          // Success Message
          Text(
            'USER ADD',
            style: AppTextStyles.pageTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            'SUCCESSFULLY!',
            style: AppTextStyles.pageTitle,
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          // Navigation Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/admin/users');
              },
              style: AppButtonStyles.primaryButton,
              child: Text('GO TO USERS PAGE', style: AppTextStyles.buttonText),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
