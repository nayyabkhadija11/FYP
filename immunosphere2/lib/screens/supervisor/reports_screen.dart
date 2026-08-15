import 'package:flutter/material.dart';
import 'routine_immunization_report_screen.dart';
import 'polio_campaign_report_screen.dart';
import 'coverage_area_report_screen.dart';
import 'vaccinator_performance_report_screen.dart';
import 'children_report_screen.dart'; // Children Report screen import kiya gaya hai

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF231B92)),
          onPressed: () {
            // Handle menu drawer open if needed
          },
        ),
        title: const Text(
          'Reports',
          style: TextStyle(
            color: Color(0xFF231B92),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildReportCard(
            context,
            icon: Icons.assignment_outlined,
            iconColor: const Color(0xFF231B92),
            title: 'Routine Immunization Report',
            subtitle: 'Vaccine wise routine report',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RoutineImmunizationReportScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            context,
            icon: Icons.rocket_launch_outlined,
            iconColor: const Color(0xFF231B92),
            title: 'Polio Campaign Report',
            subtitle: 'Campaign coverage and results',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PolioCampaignReportScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            context,
            icon: Icons.pie_chart_outline_rounded,
            iconColor: Colors.green,
            title: 'Coverage Area Report',
            subtitle: 'Area / Health center wise coverage',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CoverageAreaReportScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            context,
            icon: Icons.group_outlined,
            iconColor: const Color(0xFF231B92),
            title: 'Vaccinator Performance Report',
            subtitle: 'Performance of all vaccinators',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VaccinatorPerformanceReportScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            context,
            icon: Icons.child_care_outlined,
            iconColor: const Color(0xFF231B92),
            title: 'Children Report',
            subtitle: 'Registered, vaccinated, pending children',
            onTap: () {
              // Navigate to Children Report screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChildrenReportScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF231B92),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF231B92),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}