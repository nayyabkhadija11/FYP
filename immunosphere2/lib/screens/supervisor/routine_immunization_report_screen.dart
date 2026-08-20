import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RoutineImmunizationReportScreen extends StatefulWidget {
  const RoutineImmunizationReportScreen({super.key});

  @override
  State<RoutineImmunizationReportScreen> createState() => _RoutineImmunizationReportScreenState();
}

class _RoutineImmunizationReportScreenState extends State<RoutineImmunizationReportScreen> {
  final TextEditingController _monthYearController = TextEditingController(text: 'May 2024');
  
  String _selectedHealthCenter = 'THQ Hospital Jand';
  final List<String> _healthCenters = [
    'THQ Hospital Jand',
    'THQ Hospital Attock',
  ];

  // Expanded official vaccine list
  final List<String> _vaccineNames = [
    'BCG',
    'OPV-0',
    'OPV-1',
    'OPV-2',
    'OPV-3',
    'Pentavalent-1',
    'Pentavalent-2',
    'Pentavalent-3',
    'PCV-1',
    'PCV-2',
    'PCV-3',
    'Rotavirus-1',
    'Rotavirus-2',
    'IPV-1',
    'IPV-2',
    'Measles-Rubella (MR-1)',
    'Measles-Rubella (MR-2)',
    'TCV (Typhoid)',
  ];

  @override
  void dispose() {
    _monthYearController.dispose();
    super.dispose();
  }

  // Function to calculate live metrics and save/update them into Firebase grouped by month & health center
  Future<void> _saveMonthlyReportToFirestore(
      int totalChildren, int fullyVaccinated, int pending, Map<String, int> vaccineCounts) async {
    String monthYear = _monthYearController.text.trim();
    if (monthYear.isEmpty) return;

    String docId = '${monthYear}_$_selectedHealthCenter';

    Map<String, dynamic> reportData = {
      'monthYear': monthYear,
      'healthCenter': _selectedHealthCenter,
      'totalChildren': totalChildren,
      'fullyVaccinated': fullyVaccinated,
      'pending': pending,
      'vaccines': vaccineCounts,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('monthly_reports').doc(docId).set(reportData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving monthly report: $e');
    }
  }

  // Function to generate and download/print the PDF report
  Future<void> _generateAndDownloadPdf() async {
    String monthYear = _monthYearController.text.trim();
    String docId = '${monthYear}_$_selectedHealthCenter';

    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('monthly_reports').doc(docId).get();

    int totalChildren = 0;
    int fullyVaccinated = 0;
    int pending = 0;
    Map<String, dynamic> vaccineData = {};

    if (doc.exists && doc.data() != null) {
      var data = doc.data() as Map<String, dynamic>;
      totalChildren = data['totalChildren'] ?? 0;
      fullyVaccinated = data['fullyVaccinated'] ?? 0;
      pending = data['pending'] ?? 0;
      if (data['vaccines'] is Map) {
        vaccineData = Map<String, dynamic>.from(data['vaccines']);
      }
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Text(
              'Routine Immunization Report',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Health Center: $_selectedHealthCenter | Period: $monthYear',
              style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
            pw.Divider(thickness: 1.5, color: PdfColors.indigo900),
            pw.SizedBox(height: 16),
            pw.Text(
              'Summary Statistics',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildPdfStatBox('Total Children', '$totalChildren', PdfColors.indigo900),
                _buildPdfStatBox('Fully Vaccinated', '$fullyVaccinated', PdfColors.green800),
                _buildPdfStatBox('Pending', '$pending', PdfColors.red800),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Text(
              'Vaccine Wise Summary Breakdown',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo100),
              headerHeight: 25,
              cellHeight: 25,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
              },
              headers: <String>['Vaccine Name', 'Vaccinated Count'],
              data: _vaccineNames.map((name) {
                int count = vaccineData[name] ?? 0;
                return [name, '$count'];
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      name: 'Immunization_Report_${monthYear.replaceAll(' ', '_')}.pdf',
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPdfStatBox(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      width: 160,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.SizedBox(height: 6),
          pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF231B92)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Routine Immunization Report',
          style: TextStyle(
            color: Color(0xFF231B92),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF231B92)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _monthYearController,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter Month & Year',
                        suffixIcon: Icon(Icons.edit, color: Color(0xFF231B92), size: 16),
                      ),
                      onChanged: (val) {
                        setState(() {});
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedHealthCenter,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF231B92)),
                        items: _healthCenters.map((center) {
                          return DropdownMenuItem(
                            value: center,
                            child: Text(center, style: const TextStyle(fontSize: 13, overflow: TextOverflow.ellipsis)),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedHealthCenter = val!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Vaccine Wise Summary',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF231B92),
              ),
            ),
            const SizedBox(height: 14),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('children').snapshots(),
              builder: (context, childrenSnapshot) {
                int totalChildrenCount = 0;
                if (childrenSnapshot.hasData) {
                  totalChildrenCount = childrenSnapshot.data!.docs.length;
                }
                int maxVal = totalChildrenCount > 0 ? totalChildrenCount : 60;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('vaccinations').snapshots(),
                  builder: (context, vaccinationSnapshot) {
                    Map<String, int> vaccineCounts = {};
                    for (var name in _vaccineNames) {
                      vaccineCounts[name] = 0;
                    }

                    int fullyVaccinatedCount = 0;

                    if (vaccinationSnapshot.hasData) {
                      // Map all items cleanly using lowercase keys for matching checks
                      final List<String> requiredVaccines = _vaccineNames.map((v) => v.toLowerCase()).toList();

                      Map<String, Set<String>> vaccinatedChildMap = {};

                      for (var doc in vaccinationSnapshot.data!.docs) {
                        var data = doc.data() as Map<String, dynamic>;
                        String childId = (data['childId'] ?? '').toString().trim();
                        String vaccineName = (data['vaccineName'] ?? '').toString().trim();
                        String status = (data['status'] ?? '').toString().trim().toLowerCase();

                        if (status == 'vaccinated') {
                          for (var key in vaccineCounts.keys) {
                            if (key.toLowerCase() == vaccineName.toLowerCase()) {
                              vaccineCounts[key] = (vaccineCounts[key] ?? 0) + 1;
                            }
                          }

                          if (childId.isNotEmpty && requiredVaccines.contains(vaccineName.toLowerCase())) {
                            if (!vaccinatedChildMap.containsKey(childId)) {
                              vaccinatedChildMap[childId] = {};
                            }
                            vaccinatedChildMap[childId]!.add(vaccineName.toLowerCase());
                          }
                        }
                      }

                      vaccinatedChildMap.forEach((childId, vaccinatedSet) {
                        bool hasAllVaccines = requiredVaccines.every((v) => vaccinatedSet.contains(v));
                        if (hasAllVaccines) {
                          fullyVaccinatedCount++;
                        }
                      });
                    }

                    int pendingCount = totalChildrenCount - fullyVaccinatedCount;
                    if (pendingCount < 0) pendingCount = 0;

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _saveMonthlyReportToFirestore(totalChildrenCount, fullyVaccinatedCount, pendingCount, vaccineCounts);
                    });

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._vaccineNames.map((name) {
                          int count = vaccineCounts[name] ?? 0;
                          double progress = maxVal > 0 ? (count / maxVal).clamp(0.0, 1.0) : 0.0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 170, // Increased width slightly to cleanly display names like Measles-Rubella (MR-1)
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF231B92),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.grey.shade100,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF231B92)),
                                      minHeight: 8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: 'Total Children',
                                value: totalChildrenCount.toString(),
                                valueColor: const Color(0xFF231B92),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                title: 'Fully Vaccinated',
                                value: fullyVaccinatedCount.toString(),
                                valueColor: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                title: 'Pending',
                                value: pendingCount.toString(),
                                valueColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF231B92),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _generateAndDownloadPdf,
                icon: const Icon(Icons.download, color: Colors.white, size: 18),
                label: const Text(
                  'Download PDF',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required Color valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}