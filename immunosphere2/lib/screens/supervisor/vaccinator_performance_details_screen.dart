import 'package:flutter/material.dart';

/// Performance drill-down screen for a single vaccinator, opened from
/// "View Details" in VaccinatorPerformanceReportScreen's table.
/// Not to be confused with vaccinator_details_screen.dart, which is a
/// separate "Contact Vaccinator" (call/SMS) screen.
class VaccinatorPerformanceDetailsScreen extends StatelessWidget {
  final String reportType; // 'Routine Immunization' or 'Polio Campaign'
  final Map<String, dynamic> vaccinatorData;
  final String healthCenter;
  final String periodLabel; // month name or campaign name

  const VaccinatorPerformanceDetailsScreen({
    super.key,
    required this.reportType,
    required this.vaccinatorData,
    required this.healthCenter,
    required this.periodLabel,
  });

  static const Color primaryGreen = Color(0xFF005E38);

  @override
  Widget build(BuildContext context) {
    final bool isRoutine = reportType == 'Routine Immunization';

    final String name = vaccinatorData['name'] ?? 'Unknown';
    final String vaccinatorId = vaccinatorData['vaccinatorId'] ?? '';
    final String assignedArea = vaccinatorData['assignedArea'] ?? '-';
    final int target = (vaccinatorData['targetChildren'] ?? 0) as int;
    final int vaccinated = (vaccinatorData['vaccinated'] ?? 0) as int;
    final int pending = (vaccinatorData['pending'] ?? 0) as int;
    final int refused = (vaccinatorData['refused'] ?? 0) as int;
    final int missed = (vaccinatorData['missed'] ?? 0) as int;
    final int coverage = (vaccinatorData['coverage'] ?? 0) as int;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Vaccinator Details', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: primaryGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isRoutine ? Icons.vaccines : Icons.water_drop_outlined, size: 14, color: primaryGreen),
                  const SizedBox(width: 6),
                  Text(reportType, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryGreen)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                children: [
                  CircleAvatar(radius: 28, backgroundColor: primaryGreen.withOpacity(0.1), child: const Icon(Icons.person, size: 32, color: primaryGreen)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _labelValue('Vaccinator ID', vaccinatorId),
                        const SizedBox(height: 8),
                        _labelValue('Vaccinator Name', name),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _labelValue(isRoutine ? 'Vaccination Center' : 'Campaign', isRoutine ? healthCenter : periodLabel),
                        const SizedBox(height: 8),
                        if (!isRoutine) _labelValue('Assigned Area', assignedArea),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text('Performance Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryGreen)),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _statCard('Target Children', '$target', Icons.people_outline, primaryGreen),
                  _statCard(isRoutine ? 'Vaccinated' : 'OPV Given', '$vaccinated', Icons.check_circle_outline, primaryGreen),
                  if (isRoutine) _statCard('Pending', '$pending', Icons.access_time, Colors.orange.shade800),
                  _statCard('Refused', '$refused', Icons.cancel_outlined, Colors.red),
                  _statCard('Missed', '$missed', Icons.remove_circle_outline, Colors.grey.shade700),
                  _statCard('Coverage', '$coverage%', Icons.pie_chart_outline, primaryGreen, filled: true),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('Detailed Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryGreen)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                children: [
                  _breakdownRow('Target Children', '$target'),
                  _divider(),
                  _breakdownRow(isRoutine ? 'Vaccinated' : 'OPV Given', '$vaccinated (${_pct(vaccinated, target)}%)'),
                  if (isRoutine) ...[
                    _divider(),
                    _breakdownRow('Pending', '$pending (${_pct(pending, target)}%)'),
                  ],
                  _divider(),
                  _breakdownRow('Refused', '$refused (${_pct(refused, target)}%)'),
                  _divider(),
                  _breakdownRow('Missed', '$missed (${_pct(missed, target)}%)'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF1F8F5), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFD0E6DB))),
              child: Text(
                isRoutine
                    ? 'Vaccination is provided at the vaccination center ($healthCenter).'
                    : 'Campaign: $periodLabel',
                style: const TextStyle(fontSize: 11, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: primaryGreen), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: primaryGreen, size: 18),
                label: const Text('Back to Overview', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _pct(int part, int total) => total > 0 ? (part / total * 100).round() : 0;

  Widget _labelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, {bool filled = false}) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: filled ? color : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: filled ? color : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: filled ? Colors.white : color, size: 20),
          const SizedBox(height: 6),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: filled ? Colors.white70 : Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: filled ? Colors.white : color)),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade100);
}