import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart'; // Apni Login Screen file ka path check kar lein

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Application Theme Colors
  static const Color darkGreen = Color(0xFF062D1C);
  static const Color accentGreen = Color(0xFF10B981);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 5), _goToLogin);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goToLogin() {
    if (!mounted) return;
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Background Image Layer
          Positioned.fill(
            child: Image.asset(
              'assets/baby_vaccine.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: darkGreen);
              },
            ),
          ),

          // 2. Smooth Top Dark Gradient Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 480,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF032215).withOpacity(0.92),
                    const Color(0xFF032215).withOpacity(0.70),
                    const Color(0xFF032215).withOpacity(0.20),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 0.80, 1.0],
                ),
              ),
            ),
          ),

          // 3. Smooth Bottom Gradient Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.75),
                    Colors.black.withOpacity(0.20),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.60, 1.0],
                ),
              ),
            ),
          ),

          // 4. Main Foreground UI Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // LOGO IMAGE
                Image.asset(
                  'assets/logo.png',
                  width: 210,
                  height: 170,
                  fit: BoxFit.contain,
                ),

                // TEXT SECTION (Slightly pulled closer to the logo)
                Transform.translate(
                  offset: const Offset(0, -28), // Space reduced between logo and text
                  child: Column(
                    children: [
                      // Main App Title ("ImmunoSphere")
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          children: [
                            TextSpan(
                              text: 'Immuno',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: 'Sphere',
                              style: TextStyle(
                                color: accentGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Subtitle Text
                      const Text(
                        'AI Powered Immunization\nand Vaccination Platform',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Accent Line Divider
                      Container(
                        width: 32,
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: accentGreen,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Tagline Text
                      const Text(
                        'Healthy Children  |  Safer Communities\nA Stronger Tomorrow',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom Pagination Dots & Action Text
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDot(active: true),
                          const SizedBox(width: 6),
                          _buildDot(active: false),
                          const SizedBox(width: 6),
                          _buildDot(active: false),
                        ],
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: _goToLogin,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Swipe to get started',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildDot({required bool active}) {
    return Container(
      width: active ? 18 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? accentGreen : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}