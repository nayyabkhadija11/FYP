import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  String? selectedRole;
  final List<String> roles = ['Vaccinator', 'Supervisor', 'Parent', 'Finance Officer', 'AI Analytics'];

  @override
  Widget build(BuildContext context) {
    final String? argRole = ModalRoute.of(context)?.settings.arguments as String?;
    if (selectedRole == null && argRole != null) selectedRole = argRole;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            children: [
              const Center(child: CircleAvatar(radius: 35, backgroundColor: Color(0xFF00C853), child: Icon(Icons.shield, color: Colors.white))),
              const SizedBox(height: 15),
              const Text("ImmunoSphere", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Create Account", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _label("Full Name"), _field("Muhammad Ali"),
                    _label("Email"), _field("your.email@example.com"),
                    Row(
                      children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("Phone"), _field("0300-1234567")])),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("CNIC"), _field("12345-1234567-1")])),
                      ],
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF040914)),
                        onPressed: () {
                          // FIXED NAVIGATION LOGIC
                          if (selectedRole == "Vaccinator") {
                            Navigator.pushNamed(context, '/vaccinator_dashboard');
                          } else {
                            Navigator.pushNamed(context, '/dashboard', arguments: selectedRole);
                          }
                        },
                        child: const Text("Create Account", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(top: 12, bottom: 4), child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)));
  Widget _field(String h) => TextField(decoration: InputDecoration(hintText: h, filled: true, fillColor: const Color(0xFFF2F4F7), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)));
}