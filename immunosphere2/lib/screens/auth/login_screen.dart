import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Navigation Imports
import '../parent/parent_main_navigation_screen.dart';
import '../vaccinator/vaccinator_dashboard_screen.dart';
import '../supervisor/supervisor_dashboard.dart';

import 'forgot_password_screen.dart';
import 'role_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color darkGreen = Color(0xFF015233);
  static const Color midGreen = Color(0xFF00834B);
  static const Color fieldFill = Color(0xFFF8FAFC);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------- EMAIL VS PASSWORD ERROR LOGIC ----------------
  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      _showError('Please enter your email address.');
      return;
    }
    if (password.isEmpty) {
      _showError('Please enter your password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1: Firestore collection se Email verify karein
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isEmpty) {
        // Email database mein nahi mili
        if (mounted) {
          setState(() => _isLoading = false);
          _showError('Email is invalid or not registered.');
        }
        return;
      }

      // Step 2: Email exist karti hai, ab Password authenticate karein
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (!mounted) return;

      String? uid = userCredential.user?.uid;

      if (uid != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (!mounted) return;

        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          String role = (data['role'] ?? '').toString().toLowerCase().trim();
          String parentCnic =
              (data['cnic'] ?? data['parentCNIC'] ?? '').toString().trim();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );

          if (role == 'parent') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ParentMainNavigationScreen(parentCNIC: parentCnic),
              ),
              (route) => false,
            );
          } else if (role == 'vaccinator') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const VaccinatorDashboardScreen(),
              ),
              (route) => false,
            );
          } else if (role == 'supervisor') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const SupervisorDashboard(),
              ),
              (route) => false,
            );
          } else {
            _showError('Assigned role ($role) is invalid!');
          }
        } else {
          _showError('User record not found in database!');
        }
      }
    } on FirebaseAuthException catch (e) {
      // Step 3: Exact Password / Auth Exceptions Handle Karein
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _showError('Password is invalid. Please try again.');
      } else if (e.code == 'invalid-email' || e.code == 'user-not-found') {
        _showError('Email is invalid or not registered.');
      } else if (e.code == 'too-many-requests') {
        _showError('Too many failed attempts. Please try again later.');
      } else {
        _showError(e.message ?? 'Authentication failed.');
      }
    } catch (e) {
      _showError('Password is invalid. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Full-Screen Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/login_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFE2EDE8),
              ),
            ),
          ),

          // 2. Soft Tint Overlay for Readability
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.35),
            ),
          ),

          // 3. Scrollable Main Layout (Fixes Overflow Completely)
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(height: 12),

                          // Top Logo & Header
                          Column(
                            children: [
                              _buildLogoHeader(),
                              const SizedBox(height: 8),
                              const Text(
                                'Welcome Back',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: darkGreen,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Sign in to continue to your account',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF374151),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Form Card Container
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTextField(
                                  controller: _emailController,
                                  label: 'Email Address',
                                  hint: 'you@example.com',
                                  icon: Icons.mail_outline_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 12),
                                _buildPasswordField(),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: midGreen,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _buildLoginButton(),
                                const SizedBox(height: 14),
                                Row(
                                  children: const [
                                    Expanded(
                                      child: Divider(
                                        color: Color(0xFFE5E7EB),
                                        thickness: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 10),
                                      child: Text(
                                        'OR',
                                        style: TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: Color(0xFFE5E7EB),
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _buildCreateAccountButton(),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Bottom Footer Section
                          Column(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite_outline_rounded,
                                  size: 18,
                                  color: darkGreen,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Together for a healthier tomorrow',
                                style: TextStyle(
                                  color: darkGreen,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: Image.asset(
            'assets/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Stack(
              alignment: Alignment.center,
              children: const [
                Icon(
                  Icons.shield_outlined,
                  size: 46,
                  color: darkGreen,
                ),
                Positioned(
                  top: 12,
                  child: Icon(
                    Icons.groups_rounded,
                    size: 20,
                    color: midGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
            children: [
              TextSpan(text: 'Immuno', style: TextStyle(color: darkGreen)),
              TextSpan(text: 'Sphere', style: TextStyle(color: midGreen)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            prefixIcon: Icon(icon, color: darkGreen, size: 19),
            filled: true,
            fillColor: fieldFill,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: midGreen, width: 1.2),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                color: darkGreen, size: 19),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF94A3B8),
                size: 18,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: fieldFill,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: midGreen, width: 1.2),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
  return SizedBox(
    height: 44,
    child: ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: darkGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Stack(
              alignment: Alignment.center,
              children: const [
                // 1. Text hamesha exact Center mein rahega
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // 2. Icon bilkul Right corner par set ho jayega
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
    ),
  );
}
  Widget _buildCreateAccountButton() {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RoleSelectionScreen(),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.person_outline_rounded, color: darkGreen, size: 17),
            SizedBox(width: 6),
            Text(
              'Create Account',
              style: TextStyle(
                color: darkGreen,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}