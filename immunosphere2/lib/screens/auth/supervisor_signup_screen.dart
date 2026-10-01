/*import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'approval_pending_screen.dart';
// Note: If supervisor_dashboard.dart is in a different folder path, 
// update the relative import path below accordingly:
import '../supervisor/supervisor_dashboard.dart'; 

class SupervisorSignUpScreen extends StatefulWidget {
  const SupervisorSignUpScreen({Key? key}) : super(key: key);

  @override
  State<SupervisorSignUpScreen> createState() => _SupervisorSignUpScreenState();
}

class _SupervisorSignUpScreenState extends State<SupervisorSignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _supervisorIdController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;

  void _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    String? err = await _authService.registerUser(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passController.text,
      role: 'Supervisor',
      supervisorId: _supervisorIdController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (err == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Registration sent for approval.'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 4),
        ),
      );
      
      // Navigate to ApprovalPendingScreen or change to SupervisorDashboard 
      // depending on whether admin approval is mandatory before access.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ApprovalPendingScreen()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _supervisorIdController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: Colors.black)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: Text('Supervisor Registration', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
              const Center(child: Text('Enter your details', style: TextStyle(color: Colors.grey, fontSize: 13))),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Full Name is required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Email is required';
                  if (!val.contains('@') || !val.contains('.')) return 'Enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  counterText: "",
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Phone number is required';
                  RegExp phoneRegex = RegExp(r'^03[0-9]{9}$');
                  if (!phoneRegex.hasMatch(val.trim())) {
                    return 'Enter valid 11-digit phone number (e.g. 03001234567)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _supervisorIdController,
                decoration: const InputDecoration(labelText: 'Supervisor ID', border: OutlineInputBorder()),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Supervisor ID is required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _passController,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Password is required';
                  RegExp passwordRegex = RegExp(
                    r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*?&#^()_+\-=\[\]{}|;:,.<>/])[A-Za-z\d@$!%*?&#^()_+\-=\[\]{}|;:,.<>/]{8,}$',
                  );
                  if (!passwordRegex.hasMatch(val)) {
                    return 'Min 8 chars, 1 letter, 1 number & 1 special symbol (@, #, !)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _confirmPassController,
                obscureText: _obscureConfirmPass,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPass ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please confirm your password';
                  if (val != _passController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
} */
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'approval_pending_screen.dart';
import 'login_screen.dart';
// Note: If supervisor_dashboard.dart is in a different folder path, 
// update the relative import path below accordingly:
import '../supervisor/supervisor_dashboard.dart';

class SupervisorSignUpScreen extends StatefulWidget {
  const SupervisorSignUpScreen({Key? key}) : super(key: key);

  @override
  State<SupervisorSignUpScreen> createState() => _SupervisorSignUpScreenState();
}

class _SupervisorSignUpScreenState extends State<SupervisorSignUpScreen> {
  static const Color darkGreen = Color(0xFF015233);
  static const Color midGreen = Color(0xFF00834B);
  static const Color fieldFill = Color(0xFFF8FAFC);

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _supervisorIdController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;

  void _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    String? err = await _authService.registerUser(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passController.text,
      role: 'Supervisor',
      supervisorId: _supervisorIdController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (err == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Registration sent for approval.'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 4),
        ),
      );

      // Navigate to ApprovalPendingScreen or change to SupervisorDashboard 
      // depending on whether admin approval is mandatory before access.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ApprovalPendingScreen()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _supervisorIdController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/login_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFE2EDE8),
              ),
            ),
          ),

          // 2. White Overlay
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.35),
            ),
          ),

          // 3. Main Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12.0),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Column(
                  children: [
                    // Back Button & Top Header
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: darkGreen),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    // Logo & App Name
                    SizedBox(
                      height: 44,
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.shield_outlined,
                          size: 44,
                          color: darkGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                        children: [
                          TextSpan(text: 'Immuno', style: TextStyle(color: darkGreen)),
                          TextSpan(text: 'Sphere', style: TextStyle(color: midGreen)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    const Text(
                      'Supervisor Registration',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: darkGreen,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter your details to get started',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Form Container Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Full Name
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            icon: Icons.person_outline_rounded,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Full Name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Email
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            hint: 'you@example.com',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!val.contains('@') || !val.contains('.')) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Phone Number
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            hint: 'Enter your phone number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            maxLength: 11,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Phone number is required';
                              }
                              RegExp phoneRegex = RegExp(r'^03[0-9]{9}$');
                              if (!phoneRegex.hasMatch(val.trim())) {
                                return 'Enter valid 11-digit phone number (e.g. 03001234567)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Supervisor ID
                          _buildTextField(
                            controller: _supervisorIdController,
                            label: 'Supervisor ID',
                            hint: 'Enter your supervisor ID',
                            icon: Icons.admin_panel_settings_outlined,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Supervisor ID is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Password
                          _buildPasswordField(
                            controller: _passController,
                            label: 'Password',
                            hint: 'Create a strong password',
                            obscureText: _obscurePass,
                            onToggle: () =>
                                setState(() => _obscurePass = !_obscurePass),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Password is required';
                              }
                              RegExp passwordRegex = RegExp(
                                r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*?&#^()_+\-=\[\]{}|;:,.<>/])[A-Za-z\d@$!%*?&#^()_+\-=\[\]{}|;:,.<>/]{8,}$',
                              );
                              if (!passwordRegex.hasMatch(val)) {
                                return 'Min 8 chars, 1 letter, 1 number & 1 special symbol (@, #, !)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Confirm Password
                          _buildPasswordField(
                            controller: _confirmPassController,
                            label: 'Confirm Password',
                            hint: 'Re-enter your password',
                            obscureText: _obscureConfirmPass,
                            onToggle: () => setState(
                                () => _obscureConfirmPass = !_obscureConfirmPass),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (val != _passController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          // Submit Button
                          _buildSubmitButton(),
                          const SizedBox(height: 14),

                          // Already have an account link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already have an account? ",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF4B5563),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                    (route) => false,
                                  );
                                },
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: midGreen,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bottom Footer
                    Column(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
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
          ),
        ],
      ),
    );
  }

  // Text Field Builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    required String? Function(String?) validator,
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
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            prefixIcon: Icon(icon, color: darkGreen, size: 19),
            filled: true,
            fillColor: fieldFill,
            isDense: true,
            counterText: "",
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  // Password Field Builder
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
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
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                color: darkGreen, size: 19),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF94A3B8),
                size: 18,
              ),
              onPressed: onToggle,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  // Submit Button Builder
  Widget _buildSubmitButton() {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
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
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Create Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
}
