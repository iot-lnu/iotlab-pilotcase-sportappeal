import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../components/standard_page_layout.dart';
import '../components/custom_text_field.dart';
import '../components/profile_icon.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isTestUser = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // TODO: Simple user creation logic - in a real app this would connect to a database
      final username = _usernameController.text;
      final email = _emailController.text;
      final password = _passwordController.text;

      developer.log(
        'Creating user: $username / $email / ${password.length} chars / isTest: $_isTestUser',
        name: 'AddUserScreen',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test user created successfully')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StandardPageLayout(
      title: 'ADD NEW USER',
      currentRoute: '/add-user',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Profile icon
            const ProfileIcon(size: 80),
            const SizedBox(height: 30),

            // Form fields
            CustomTextField(
              label: 'USERNAME',
              controller: _usernameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a username';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'EMAIL',
              controller: _emailController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'PASSWORD',
              controller: _passwordController,
              isPassword: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 30),

            // Test User Switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'IS TEST USER',
                    style: AppTextStyles.buttonText.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  Switch(
                    value: _isTestUser,
                    onChanged: (value) {
                      setState(() {
                        _isTestUser = value;
                      });
                    },
                    activeColor: const Color(0xFF75F94C),
                    activeTrackColor: const Color(
                      0xFF75F94C,
                    ).withValues(alpha: 0.3),
                    inactiveThumbColor: Colors.white.withValues(alpha: 0.7),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Create User button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: AppButtonStyles.primaryButton,
                child: Text('CREATE USER', style: AppTextStyles.buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
