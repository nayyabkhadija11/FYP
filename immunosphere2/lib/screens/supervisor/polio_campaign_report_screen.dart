import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PolioCampaignReportScreen extends StatefulWidget {
  const PolioCampaignReportScreen({super.key});

  @override
  State<PolioCampaignReportScreen> createState() => _PolioCampaignReportScreenState();
}

class _PolioCampaignReportScreenState extends State<PolioCampaignReportScreen> {
  final TextEditingController _campaignController = TextEditingController(text: 'National Polio Campaign (Aug 2026)');
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  Map<String, dynamic>? _savedReportData;
  bool _isLoadingSavedReport = false;

  @override
  void initState() {
    super.initState();
    _fetchReportForCampaign(_campaignController.text.trim());
  }

  @override
  void dispose() {
    _campaignController.dispose();
    super.dispose();
  }

  String _getDocId(String campaignName) {
    return campaignName.replaceAll(RegExp(r'[^\w\s]+'), '_').trim().toLowerCase();
  }

  Future<void> _fetchReportForCampaign(String campaignName) async {
    if (campaignName.isEmpty) return;
    setState(() => _isLoadingSavedReport = true);

    try {
      String docId = _getDocId(campaignName);
      DocumentSnapshot<Map<String, dynamic>> doc = await _db.collection('polio_campaign_reports').doc(docId).get();
      
      if (doc.exists && doc.data() != null) {
        setState(() {
          _savedReportData = doc.data();
          _isLoadingSavedReport = false;
        });
      } else {
        setState(() {
          _savedReportData = null;
          _isLoadingSavedReport = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching report: $e');
      setState(() => _isLoadingSavedReport = false);
    }
  }

  Future<void> _savePolioReportToFirestore(int totalChildren, int vaccinated, int missed, int coverage) async {
    String campaignName = _campaignController.text.trim();
    if (campaignName.isEmpty) return;

    String docId = _getDocId(campaignName);

    Map<String, dynamic> reportData = {
      'campaignName': campaignName,
      'totalChildren': totalChildren,
      'vaccinated': vaccinated,
      'missed': missed,
      'coverage': '$coverage%',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _db.collection('polio_campaign_reports').doc(docId).set(reportData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving polio campaign report: $e');
    }
  }

  Future<void> _generateAndDownloadPdf(int totalChildren, int vaccinated, int missed, int coverage) async {
    final pdf = pw.Document();
    String campaignName = _campaignController.text.trim();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Polio Campaign Report',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Campaign: $campaignName',
                style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
              ),
              pw.Divider(thickness: 1.5, color: PdfColors.indigo900),
              pw.SizedBox(height: 16),
              pw.Text(
                'Campaign Summary Statistics',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildPdfStatBox('Total Children', '$totalChildren', PdfColors.indigo900),
                  _buildPdfStatBox('Vaccinated', '$vaccinated', PdfColors.green800),
                  _buildPdfStatBox('Missed', '$missed', PdfColors.red800),
                  _buildPdfStatBox('Coverage', '$coverage%', PdfColors.indigo900),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      name: 'Polio_Campaign_Report_${campaignName.replaceAll(' ', '_')}.pdf',
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPdfStatBox(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      width: 120,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700), textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
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
          'Polio Campaign Report',
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
            TextField(
              controller: _campaignController,
              onChanged: (val) {
                setState(() {});
                _fetchReportForCampaign(val.trim());
              },
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF231B92)),
              decoration: InputDecoration(
                labelText: 'Campaign Name / Month / Year',
                labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF231B92), width: 1.5),
                ),
                suffixIcon: const Icon(Icons.edit, color: Color(0xFF231B92), size: 18),
              ),
            ),
            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _db.collection('children').snapshots(),
              builder: (context, childSnapshot) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _db.collection('vaccinations').snapshots(),
                  builder: (context, vacSnapshot) {
                    
                    if (childSnapshot.connectionState == ConnectionState.waiting || 
                        vacSnapshot.connectionState == ConnectionState.waiting || 
                        _isLoadingSavedReport) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!childSnapshot.hasData || !vacSnapshot.hasData) {
                      return const Center(child: Text('Loading data from Firebase...'));
                    }

                    int totalChildren = 0;
                    int vaccinatedCount = 0;
                    int missedCount = 0;
                    int coveragePercentage = 0;

                    if (_savedReportData != null) {
                      totalChildren = _savedReportData!['totalChildren'] ?? 0;
                      vaccinatedCount = _savedReportData!['vaccinated'] ?? 0;
                      missedCount = _savedReportData!['missed'] ?? 0;
                      String covStr = (_savedReportData!['coverage'] ?? '0%').replaceAll('%', '');
                      coveragePercentage = int.tryParse(covStr) ?? 0;
                    } else {
                      Set<String> validChildIds = {};
                      for (var doc in childSnapshot.data!.docs) {
                        final data = doc.data();
                        validChildIds.add(doc.id.trim().toLowerCase());
                        if (data['childId'] != null) {
                          validChildIds.add(data['childId'].toString().trim().toLowerCase());
                        }
                        if (data['regNo'] != null) {
                          validChildIds.add(data['regNo'].toString().trim().toLowerCase());
                        }
                      }

                      totalChildren = childSnapshot.data!.docs.length;
                      Set<String> vaccinatedChildIds = {};

                      for (var doc in vacSnapshot.data!.docs) {
                        final data = doc.data();
                        final String childId = (data['childId'] ?? '').toString().trim().toLowerCase();
                        final String vaccineName = (data['vaccineName'] ?? '').toString().toLowerCase().trim();
                        final String status = (data['status'] ?? '').toString().toLowerCase().trim();

                        bool isPolioBooster = vaccineName.contains('polio') && vaccineName.contains('booster');
                        bool isVaccinated = status == 'vaccinated';

                        if (isPolioBooster && childId.isNotEmpty && validChildIds.contains(childId)) {
                          if (isVaccinated) {
                            vaccinatedChildIds.add(childId);
                          }
                        }
                      }

                      vaccinatedCount = vaccinatedChildIds.length;
                      missedCount = (totalChildren - vaccinatedCount) >= 0 ? (totalChildren - vaccinatedCount) : 0;

                      coveragePercentage = totalChildren > 0 ? ((vaccinatedCount / totalChildren) * 100).round() : 0;
                      if (coveragePercentage > 100) coveragePercentage = 100;

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _savePolioReportToFirestore(totalChildren, vaccinatedCount, missedCount, coveragePercentage);
                      });
                    }

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: 'Total Children',
                                value: totalChildren.toString(),
                                valueColor: const Color(0xFF231B92),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                title: 'Vaccinated',
                                value: vaccinatedCount.toString(),
                                valueColor: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                title: 'Missed',
                                value: missedCount.toString(),
                                valueColor: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                title: 'Coverage',
                                value: '$coveragePercentage%',
                                valueColor: const Color(0xFF231B92),
                              ),
                            ),
                          ],
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
                            onPressed: () => _generateAndDownloadPdf(totalChildren, vaccinatedCount, missedCount, coveragePercentage),
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
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Campaign Overview',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF231B92),
                              ),
                            ),
                            Row(
                              children: [
                                _buildLegendItem('Vaccinated', Colors.green),
                                const SizedBox(width: 14),
                                _buildLegendItem('Missed', Colors.red),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 240,
                          padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8, left: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: (totalChildren > 0 ? totalChildren : 10).toDouble() * 1.2,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: ((totalChildren > 0 ? totalChildren : 10) / 4).clamp(1, double.infinity),
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.grey.shade100,
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      String text = '';
                                      if (value.toInt() == 0) {
                                        text = 'Overall Status';
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                BarChartGroupData(
                                  x: 0,
                                  barsSpace: 12,
                                  barRods: [
                                    BarChartRodData(
                                      toY: vaccinatedCount.toDouble(),
                                      color: Colors.green,
                                      width: 24,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    BarChartRodData(
                                      toY: missedCount.toDouble(),
                                      color: Colors.red,
                                      width: 24,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required Color valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
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
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}