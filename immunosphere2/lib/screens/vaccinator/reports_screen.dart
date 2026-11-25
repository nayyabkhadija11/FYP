import 'package:flutter/material.dart';
import 'vaccinator_routine_report_screen.dart';
import 'vaccinator_polio_report_screen.dart';

// Reports hub: two entry cards, each opens its own full report screen.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  static const Color primaryGreen = Color(0xFF0B4D30);
  static const Color lightGreenBg = Color(0xFFE5F7ED);
  static const Color bgCanvas = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCanvas,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Reports & Analytics',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _reportCard(
            context,
            icon: Icons.vaccines,
            title: 'Routine Vaccination Report',
            subtitle: 'View daily, weekly and monthly routine vaccination details',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VaccinatorRoutineReportScreen()),
            ),
          ),
          const SizedBox(height: 14),
          _reportCard(
            context,
            icon: Icons.verified_user,
            title: 'Polio Campaign Report',
            subtitle: 'View your assigned campaign and area-wise details',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VaccinatorPolioReportScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: lightGreenBg),
                child: Icon(icon, color: primaryGreen, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: Colors.grey.shade700, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}