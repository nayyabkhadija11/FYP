import 'package:flutter/material.dart';
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
}