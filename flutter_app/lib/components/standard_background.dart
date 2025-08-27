import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'three_dots_menu.dart';
import 'bottom_navigation.dart';

class StandardBackground extends StatelessWidget {
  final String title;
  final Widget child;
  final String? currentRoute;
  final VoidCallback? onBackPressed;
  final bool showBottomNavigation;

  const StandardBackground({
    super.key,
    required this.title,
    required this.child,
    this.currentRoute,
    this.onBackPressed,
    this.showBottomNavigation = true,
  });

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
                    onTap: onBackPressed ?? () => Navigator.pop(context),
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
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1919),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30.0,
                      vertical: 25.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Title with underline
                        Text(
                          title,
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(width: 135, height: 1, color: Colors.white),
                        const SizedBox(height: 30),

                        // Main content
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Navigation (optional)
            if (showBottomNavigation)
              BottomNavigation(currentRoute: currentRoute),
          ],
        ),
      ),
    );
  }
}
