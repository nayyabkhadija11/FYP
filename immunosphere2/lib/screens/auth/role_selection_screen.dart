/*import 'package:flutter/material.dart';
import 'parent_signup_screen.dart';
import 'vaccinator_signup_screen.dart';
import 'supervisor_signup_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE6F4EA),
          child: Icon(icon, color: const Color(0xFF10B981)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF10B981)),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: Colors.black)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Text('Create Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const Center(
              child: Text('Select your role to continue', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
            const SizedBox(height: 30),
            _buildRoleCard(
              context: context,
              title: 'Parent',
              subtitle: 'Register as Parent',
              icon: Icons.family_restroom,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ParentSignUpScreen())),
            ),
            _buildRoleCard(
              context: context,
              title: 'Vaccinator',
              subtitle: 'Register as Vaccinator',
              icon: Icons.medical_services_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VaccinatorSignUpScreen())),
            ),
            _buildRoleCard(
              context: context,
              title: 'Supervisor',
              subtitle: 'Register as Supervisor',
              icon: Icons.person_outline,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SupervisorSignUpScreen())),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? ', style: TextStyle(fontSize: 13)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text('Login', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
} */
import 'package:flutter/material.dart';
import 'parent_signup_screen.dart';
import 'vaccinator_signup_screen.dart';
import 'supervisor_signup_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  static const Color darkGreen = Color(0xFF004D2D);
  static const Color lightGreenBg = Color(0xFFEBF5EE);
  static const Color cardBg = Color(0xFFF4F9F5);

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: darkGreen.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                // Icon Box
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD3EADB),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: darkGreen,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D2818),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                const Icon(
                  Icons.chevron_right_rounded,
                  color: darkGreen,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar & Logo Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  // Back Button Left Aligned
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEBF5EE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: darkGreen,
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                  // Center Logo
                  Image.asset(
                    'assets/logo.png',
                    height: 55,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.shield_outlined,
                      size: 50,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Brand Name
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: 'Immuno',
                          style: TextStyle(color: darkGreen),
                        ),
                        TextSpan(
                          text: 'Sphere',
                          style: TextStyle(color: Color(0xFF00A859)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Title & Subtitle
            const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Select your role to continue',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 16),

            // Role Cards Container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  _buildRoleCard(
                    context: context,
                    title: 'Parent',
                    subtitle: 'Register as Parent',
                    icon: Icons.groups_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ParentSignUpScreen(),
                        ),
                      );
                    },
                  ),
                  _buildRoleCard(
                    context: context,
                    title: 'Vaccinator',
                    subtitle: 'Register as Vaccinator',
                    icon: Icons.medical_services_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VaccinatorSignUpScreen(),
                        ),
                      );
                    },
                  ),
                  _buildRoleCard(
                    context: context,
                    title: 'Supervisor',
                    subtitle: 'Register as Supervisor',
                    icon: Icons.person_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SupervisorSignUpScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Bottom Graphic Illustration & Login Option
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Bottom Curved Background Wave Art
                ClipPath(
                  clipper: BottomArtClipper(),
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    color: const Color(0xFFC7E3D0),
                  ),
                ),

                // Parent Child Center Icon/Illustration Graphic
                Positioned(
                  bottom: 35,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.family_restroom,
                          size: 32,
                          color: darkGreen,
                        ),
                      ),
                    ],
                  ),
                ),

                // Login Text Link
                Positioned(
                  bottom: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF334155),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Clipper for Bottom Wave Art
class BottomArtClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.4);
    path.quadraticBezierTo(
      size.width * 0.5,
      -20,
      size.width,
      size.height * 0.4,
    );
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}