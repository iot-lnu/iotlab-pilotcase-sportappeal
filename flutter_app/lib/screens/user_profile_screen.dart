import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user.dart';
import '../components/standard_page_layout.dart';
import '../services/users_data.dart';
import 'choose_test_screen.dart';

class UserProfileScreen extends StatelessWidget {
  final User user;

  const UserProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return StandardPageLayout(
      title: user.username,
      currentRoute: '/user-profile',
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Run Test Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChooseTestScreen(user: user),
                  ),
                );
              },
              style: AppButtonStyles.primaryButton,
              child: Text('RUN TEST', style: AppTextStyles.buttonText),
            ),
          ),

          const SizedBox(height: 20),

          // Users Report Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                _showUsersReport(context);
              },
              style: AppButtonStyles.primaryButton,
              child: Text('USERS REPORT', style: AppTextStyles.buttonText),
            ),
          ),

          const SizedBox(height: 20),

          // Delete User Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                _showDeleteConfirmation(context);
              },
              style: AppButtonStyles.primaryButton,
              child: Text('DELETE USER', style: AppTextStyles.buttonText),
            ),
          ),
        ],
      ),
    );
  }

  void _showUsersReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1919),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    'USERS REPORT',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(width: 135, height: 1, color: Colors.white),
                  const SizedBox(height: 40),

                  // Report Icon (similar to settings icon)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007340).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF007340),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.assessment,
                      color: Color(0xFF75F94C),
                      size: 50,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Main Message
                  Text(
                    'UNDER DEVELOPMENT',
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF75F94C),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Description Text
                  Text(
                    'Users report functionality is currently under development. This feature will allow you to view and export detailed reports about user activities and test results.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // OK Button
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007340),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'OK',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1919),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    'DELETE USER',
                    style: GoogleFonts.montserrat(
                      color: Colors.red,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(width: 135, height: 1, color: Colors.red),
                  const SizedBox(height: 40),

                  // Warning Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: const Icon(
                      Icons.warning,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Main Message
                  Text(
                    'PERMANENT DELETION',
                    style: GoogleFonts.montserrat(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Description Text
                  Text(
                    'Are you sure you want to delete your account? This action cannot be undone and you will lose all your data.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Action Buttons
                  Column(
                    children: [
                      // Delete Button
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: () {
                            // Close the dialog first
                            Navigator.of(context).pop();

                            // Delete the user from the data store
                            UsersData.deleteUser(user.id);

                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'User "${user.username}" has been deleted successfully.',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );

                            // Navigate to admin dashboard
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/admin',
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            'DELETE',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Cancel Button
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            side: const BorderSide(
                              color: Color(0xFF75F94C),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            'CANCEL',
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFF75F94C),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
