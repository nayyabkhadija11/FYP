import 'package:flutter/material.dart';
import 'report_details_screen.dart';

class SupervisorReportsScreen extends StatelessWidget {
  const SupervisorReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildReportTile(context, 'Routine Immunization Report',
              'Vaccine wise routine report', Icons.vaccines),
          _buildReportTile(context, 'Polio Campaign Report',
              'Campaign coverage and results', Icons.campaign),
          _buildReportTile(context, 'Coverage Area Report',
              'Area / Health center wise coverage', Icons.map),
          _buildReportTile(context, 'Vaccinator Performance Report',
              'Performance of all vaccinators', Icons.people),
          _buildReportTile(context, 'Children Report',
              'Registered, vaccinated, pending children', Icons.child_care),
          _buildReportTile(context, 'AI Insights',
              'Dropout risks & predictions', Icons.psychology),
        ],
      ),
    );
  }

  Widget _buildReportTile(
      BuildContext context, String title, String sub, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF3F2B96)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportDetailsScreen(reportTitle: title),
            ),
          );
        },
      ),
    );
  }
}