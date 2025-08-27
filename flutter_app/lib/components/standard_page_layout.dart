import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'three_dots_menu.dart';
import 'bottom_navigation.dart';

class StandardPageLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final String currentRoute;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool showThreeDotsMenu;
  final Widget? customAppBarContent;

  const StandardPageLayout({
    super.key,
    required this.title,
    required this.child,
    required this.currentRoute,
    this.showBackButton = true,
    this.onBackPressed,
    this.showThreeDotsMenu = true,
    this.customAppBarContent,
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
              child:
                  customAppBarContent ??
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button section
                      if (showBackButton)
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
                        )
                      else
                        const SizedBox.shrink(),
                      // Menu icon
                      if (showThreeDotsMenu)
                        const ThreeDotsMenu()
                      else
                        const SizedBox.shrink(),
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
                      horizontal: 38.0,
                      vertical: 27.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Title
                        Text(
                          title.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(width: 135, height: 1, color: Colors.white),
                        const SizedBox(height: 20),

                        // Content
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Navigation
            BottomNavigation(currentRoute: currentRoute),
          ],
        ),
      ),
    );
  }
}

// Standardized text styles for consistency
class AppTextStyles {
  static TextStyle get pageTitle => GoogleFonts.montserrat(
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 3,
  );

  static TextStyle get sectionTitle => GoogleFonts.montserrat(
    color: const Color(0xFF75F94C),
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 2,
  );

  static TextStyle get buttonText => GoogleFonts.montserrat(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 2,
  );

  static TextStyle get bodyText => GoogleFonts.montserrat(
    color: Colors.white.withValues(alpha: 0.8),
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get backButtonText => GoogleFonts.montserrat(
    color: const Color(0xFF75F94C),
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 3,
  );
}

// Standardized button styles for consistency
class AppButtonStyles {
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF007340),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    padding: EdgeInsets.zero,
  );

  static ButtonStyle get secondaryButton => ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    side: const BorderSide(color: Color(0xFF75F94C), width: 2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    padding: EdgeInsets.zero,
  );

  static ButtonStyle get dangerButton => ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    padding: EdgeInsets.zero,
  );
}

// Standardized spacing constants
class AppSpacing {
  static const double small = 8.0;
  static const double medium = 15.0;
  static const double large = 20.0;
  static const double extraLarge = 30.0;
  static const double huge = 40.0;
  static const double massive = 60.0;
}

// Standardized colors
class AppColors {
  static const Color background = Color(0xFF1E1E1E);
  static const Color cardBackground = Color(0xFF1A1919);
  static const Color primary = Color(0xFF75F94C);
  static const Color accent = Color(0xFF007340);
  static const Color white = Colors.white;
  static const Color danger = Colors.red;
}
