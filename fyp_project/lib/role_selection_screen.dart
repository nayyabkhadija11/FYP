import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9), // Light mint/grey background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Header Section ---
              const Icon(Icons.shield, size: 80, color: Color(0xFF0091EA)),
              const SizedBox(height: 16),
              const Text(
                "ImmunoSphere",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00838F),
                ),
              ),
              const Text(
                "AI-Powered Immunization & Vaccination Management Portal",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                "Protecting Pakistan's Children, One Dose at a Time",
                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
              const SizedBox(height: 40),

              // --- Role Cards List ---
              roleCard(
                context,
                "Vaccinator",
                "Record vaccinations in the field",
                Icons.timeline,
                const Color(0xFF448AFF),
              ),
              roleCard(
                context,
                "Supervisor",
                "Monitor campaigns and coverage",
                Icons.people_alt_outlined,
                const Color(0xFF00C853),
              ),
              roleCard(
                context,
                "Parent",
                "Track your child's vaccinations",
                Icons.face_retouching_natural,
                const Color(0xFFAB47BC),
              ),
              roleCard(
                context,
                "Finance Officer",
                "Manage payments and salaries",
                Icons.account_balance_wallet_outlined,
                const Color(0xFFFF6D00),
              ),
              roleCard(
                context,
                "AI Analytics",
                "View predictions and insights",
                Icons.psychology_outlined,
                const Color(0xFFFF5252),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget roleCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color iconBgColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/login', arguments: title),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 20),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}