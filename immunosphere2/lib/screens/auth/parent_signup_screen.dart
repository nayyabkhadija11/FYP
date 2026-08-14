import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Digits filter ke liye import add kiya hai
import '../../services/auth_service.dart';
import 'email_verification_screen.dart';

class ParentSignUpScreen extends StatefulWidget {
  const ParentSignUpScreen({Key? key}) : super(key: key);

  @override
  State<ParentSignUpScreen> createState() => _ParentSignUpScreenState();
}

class _ParentSignUpScreenState extends State<ParentSignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController();
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
      cnic: _cnicController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passController.text,
      role: 'Parent',
    );

    setState(() => _isLoading = false);

    if (err == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account successfully created! Verification email sent.'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EmailVerificationScreen()),
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
    _cnicController.dispose();
    _phoneController.dispose();
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
              const Center(child: Text('Create Parent Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
              const Center(child: Text('Enter your details to get started', style: TextStyle(color: Colors.grey, fontSize: 13))),
              const SizedBox(height: 20),
              
              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Full Name is required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              // Email
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

              // CNIC Field (Auto-fill Popup completely disabled)
              TextFormField(
                controller: _cnicController,
                keyboardType: TextInputType.visiblePassword, // Disable Android AutoFill popup
                inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Only numbers allowed
                maxLength: 13,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: null,
                decoration: const InputDecoration(
                  labelText: 'CNIC Number (13 Digits)',
                  border: OutlineInputBorder(),
                  counterText: "",
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'CNIC Number is required';
                  RegExp cnicRegex = RegExp(r'^[0-9]{13}$');
                  if (!cnicRegex.hasMatch(val.trim())) {
                    return 'Enter a valid 13-digit CNIC number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              // Phone
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
              
              // Password
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
              
              // Confirm Password
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
              
              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), 
                  padding: const EdgeInsets.symmetric(vertical: 14)
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}