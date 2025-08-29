import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user.dart';
import '../components/three_dots_menu.dart';
import '../components/bottom_navigation.dart';
import 'user_test_dashboard.dart';
import 'not_implemented_screen.dart';

class ChooseTestScreen extends StatelessWidget {
  final User user;

  const ChooseTestScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button section
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_back_ios,
                          color: const Color(0xFF75F94C),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'BACK',
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF75F94C),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Menu icon
                  const ThreeDotsMenu(),
                ],
              ),
            ),

            // Main Content Container
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      MediaQuery.of(context).size.width *
                      0.04, // Responsive padding
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF1A1919,
                    ), // Dark background like other pages
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          MediaQuery.of(context).size.width *
                          0.05, // Responsive padding

                      vertical: MediaQuery.of(context).size.height * 0.015,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title - "CHOOSE TEST" with underline
                        Text(
                          'CHOOSE TEST',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.width * 0.038,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.012,
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.34,
                          height: 1,
                          color: Colors.white,
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.025,
                        ),

                        // IMTP Button
                        _buildTestButton(
                          context: context,
                          label: 'IMTP',
                          onPressed: () {
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
                        ),

                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.012,
                        ),

                        // Iso squat Button
                        _buildTestButton(
                          context: context,
                          label: 'Iso squat',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => NotImplementedScreen(
                                      user: user,
                                      testType: 'Iso squat',
                                    ),
                              ),
                            );
                          },
                        ),

                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.012,
                        ),

                        // Bench press Button
                        _buildTestButton(
                          context: context,
                          label: 'Bench press',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => NotImplementedScreen(
                                      user: user,
                                      testType: 'Bench press',
                                    ),
                              ),
                            );
                          },
                        ),

                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.012,
                        ),

                        // Custom Button
                        _buildTestButton(
                          context: context,
                          label: 'Custom',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => NotImplementedScreen(
                                      user: user,
                                      testType: 'Custom',
                                    ),
                              ),
                            );
                          },
                        ),

                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.015,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Navigation
            const BottomNavigation(currentRoute: '/choose-test'),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF007340), // Dark green button like other buttons
        borderRadius: BorderRadius.circular(
          MediaQuery.of(context).size.width * 0.045,
        ), // Responsive radius
      ),
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.055, // Responsive height
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(
            MediaQuery.of(context).size.width * 0.045,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width * 0.03,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
