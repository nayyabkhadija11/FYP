/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/campaign_model.dart';
import '../../services/campaign_service.dart';

class PolioCampaignReportScreen extends StatefulWidget {
  final String campaignId;

  const PolioCampaignReportScreen({super.key, required this.campaignId});

  @override
  State<PolioCampaignReportScreen> createState() =>
      _PolioCampaignReportScreenState();
}

class _PolioCampaignReportScreenState
    extends State<PolioCampaignReportScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CampaignService _campaignService = CampaignService();
  static const Color primaryGreen = Color(0xFF005A36);

  bool _isLoadingCampaigns = true;
  List<CampaignModel> _campaigns = [];
  CampaignModel? _selectedCampaign;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    try {
      final supervisorId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final campaigns = await _campaignService.getCampaignsBySupervisor(supervisorId);

      CampaignModel? initial;
      for (var c in campaigns) {
        if (c.id == widget.campaignId) {
          initial = c;
          break;
        }
      }
      // Agar diya gaya campaignId is supervisor ki list mein nahi mila,
      // phir bhi seedha uska data fetch kar lete hain taake screen
      // khaali na rahe.
      initial ??= await _campaignService.getCampaignById(widget.campaignId);

      if (!mounted) return;
      setState(() {
        _campaigns = campaigns;
        _selectedCampaign = initial;
        _isLoadingCampaigns = false;
      });
    } catch (e) {
      // Pehle yahan koi try/catch nahi tha — Firestore index missing
      // hone jaisi errors par screen hamesha loading spinner mein atki
      // reh jati thi, kabhi error na dikhata tha na aage barhta tha.
      if (!mounted) return;
      setState(() {
        _loadError = 'Campaign load nahi ho saka: $e';
        _isLoadingCampaigns = false;
      });
    }
  }

  Future<void> _openCampaignPicker() async {
    if (_campaigns.isEmpty) return;
    final pickedId = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Select Campaign',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen)),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _campaigns.length,
                  itemBuilder: (context, index) {
                    final c = _campaigns[index];
                    final isSelected = c.id == _selectedCampaign?.id;
                    return ListTile(
                      leading: Icon(Icons.water_drop_outlined,
                          color: isSelected ? primaryGreen : Colors.grey),
                      title: Text(c.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isSelected ? primaryGreen : Colors.black87)),
                      subtitle: Text(
                          '${DateFormat('dd MMM').format(c.startDate)} – ${DateFormat('dd MMM yyyy').format(c.endDate)}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      trailing: isSelected ? const Icon(Icons.check, color: primaryGreen) : null,
                      onTap: () => Navigator.pop(sheetContext, c.id),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (pickedId != null && pickedId != _selectedCampaign?.id) {
      final chosen = _campaigns.firstWhere((c) => c.id == pickedId);
      setState(() => _selectedCampaign = chosen);
    }
  }

  Future<void> _saveReportToFirestore(String campaignId, String campaignName,
      int totalChildren, int vaccinated, int pending, int refused, int missed, int coverage) async {
    try {
      await _db.collection('polio_campaign_reports').doc(campaignId).set({
        'campaignId': campaignId,
        'campaignName': campaignName,
        'totalChildren': totalChildren,
        'vaccinated': vaccinated,
        'pending': pending,
        'refused': refused,
        'missed': missed,
        'coverage': '$coverage%',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving report: $e');
    }
  }

  List<_DayPoint> _buildDailySeries(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, CampaignModel campaign) {
    final total = docs.length;
    final startDay = DateTime(campaign.startDate.year, campaign.startDate.month, campaign.startDate.day);
    final now = DateTime.now();
    final cap = now.isBefore(campaign.endDate) ? now : campaign.endDate;
    final endDay = DateTime(cap.year, cap.month, cap.day);

    if (endDay.isBefore(startDay) || total == 0) {
      return [_DayPoint(startDay, 0, total, 0, 0)];
    }

    final totalDays = endDay.difference(startDay).inDays;
    final points = <_DayPoint>[];

    for (int i = 0; i <= totalDays; i++) {
      final day = startDay.add(Duration(days: i));
      final dayEnd = day.add(const Duration(days: 1));
      int vaccinated = 0, refused = 0, missed = 0;
      for (var doc in docs) {
        final data = doc.data();
        final updatedAt = data['updatedAt'];
        if (updatedAt is! Timestamp) continue;
        if (updatedAt.toDate().isBefore(dayEnd)) {
          switch (data['status']) {
            case 'Vaccinated':
              vaccinated++;
              break;
            case 'Refused':
              refused++;
              break;
            case 'Missed':
              missed++;
              break;
          }
        }
      }
      final pending = total - vaccinated - refused - missed;
      points.add(_DayPoint(day, vaccinated, pending < 0 ? 0 : pending, refused, missed));
    }
    return points;
  }

  Future<void> _generateAndDownloadPdf({
    required CampaignModel campaign,
    required int totalChildren,
    required int vaccinated,
    required int pending,
    required int refused,
    required int missed,
    required int coverage,
    required List<Map<String, dynamic>> teamPerformance,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Text(
            'Polio Campaign Report',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Campaign: ${campaign.name}', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
          pw.Text('Type: ${campaign.type}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.Text(
            'Duration: ${DateFormat('dd MMM yyyy').format(campaign.startDate)} – ${DateFormat('dd MMM yyyy').format(campaign.endDate)}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          if (campaign.targetAreas.isNotEmpty)
            pw.Text('Target Areas: ${campaign.targetAreas.join(', ')}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.Text('Report Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.Divider(thickness: 1.5, color: PdfColors.green900),
          pw.SizedBox(height: 16),

          pw.Text('Campaign Summary Statistics',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headers: ['Status', 'Count', 'Percentage'],
            data: [
              ['Vaccinated', '$vaccinated', '${totalChildren > 0 ? ((vaccinated / totalChildren) * 100).round() : 0}%'],
              ['Pending (Not Yet Visited)', '$pending', '${totalChildren > 0 ? ((pending / totalChildren) * 100).round() : 0}%'],
              ['Refused (Visit Done, Not Vaccinated)', '$refused', '${totalChildren > 0 ? ((refused / totalChildren) * 100).round() : 0}%'],
              ['Missed (Could Not Reach)', '$missed', '${totalChildren > 0 ? ((missed / totalChildren) * 100).round() : 0}%'],
              ['Eligible Children (Total)', '$totalChildren', '100%'],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
            cellAlignment: pw.Alignment.centerLeft,
          ),

          pw.SizedBox(height: 20),
          pw.Text('Team Performance (By Vaccinator)',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headers: ['Vaccinator', 'Target', 'Vaccinated', 'Refused', 'Missed', 'Coverage'],
            data: teamPerformance
                .map((t) => [
                      t['name'].toString(),
                      '${t['target']}',
                      '${t['vaccinated']}',
                      '${t['refused']}',
                      '${t['missed']}',
                      '${t['coverage']}%',
                    ])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: 'Polio_Campaign_Report_${campaign.name.replaceAll(' ', '_')}.pdf',
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Polio Campaign Report',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoadingCampaigns
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(_loadError!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  ),
                )
              : _selectedCampaign == null
                  ? const Center(child: Text('Koi campaign nahi mila.', style: TextStyle(color: Colors.grey)))
                  : _buildBody(_selectedCampaign!),
    );
  }

  Widget _buildBody(CampaignModel campaign) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      key: ValueKey(campaign.id),
      stream: _db
          .collection('campaign_assignments')
          .where('campaignId', isEqualTo: campaign.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primaryGreen));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('Data load nahi ho saka: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final int totalChildren = docs.length;

        int vaccinatedCount = 0, pendingCount = 0, refusedCount = 0, missedCount = 0;
        for (var doc in docs) {
          switch ((doc.data()['status'] ?? 'Pending').toString()) {
            case 'Vaccinated':
              vaccinatedCount++;
              break;
            case 'Refused':
              refusedCount++;
              break;
            case 'Missed':
              missedCount++;
              break;
            default:
              pendingCount++;
          }
        }
        final int coveragePercentage =
            totalChildren > 0 ? ((vaccinatedCount / totalChildren) * 100).round() : 0;

        final List<Map<String, dynamic>> teamPerformance = campaign.vaccinatorIds.map((vId) {
          final vDocs = docs.where((d) => d.data()['vaccinatorId'] == vId).toList();
          final target = vDocs.length;
          final vac = vDocs.where((d) => d.data()['status'] == 'Vaccinated').length;
          final ref = vDocs.where((d) => d.data()['status'] == 'Refused').length;
          final mis = vDocs.where((d) => d.data()['status'] == 'Missed').length;
          final cov = target > 0 ? ((vac / target) * 100).round() : 0;
          return {'vaccinatorId': vId, 'target': target, 'vaccinated': vac, 'refused': ref, 'missed': mis, 'coverage': cov};
        }).toList();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _saveReportToFirestore(campaign.id, campaign.name, totalChildren, vaccinatedCount,
              pendingCount, refusedCount, missedCount, coveragePercentage);
        });

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _campaignService.getVaccinatorsByIds(campaign.vaccinatorIds),
          builder: (context, vaccinatorSnap) {
            final vaccinatorNameById = {
              for (var v in (vaccinatorSnap.data ?? [])) v['id'] as String: v['name'] as String
            };
            for (var t in teamPerformance) {
              t['name'] = vaccinatorNameById[t['vaccinatorId']] ?? 'Unknown';
            }

            final dailySeries = _buildDailySeries(docs, campaign);

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _campaignHeaderCard(campaign),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildTopStatCard(title: 'Eligible Children', value: '$totalChildren', icon: Icons.group, iconBg: const Color(0xFFE8F5E9), iconColor: primaryGreen, valueColor: primaryGreen),
                              const SizedBox(width: 8),
                              _buildTopStatCard(title: 'Vaccinated', value: '$vaccinatedCount', icon: Icons.check_circle_outline, iconBg: const Color(0xFFE8F5E9), iconColor: primaryGreen, valueColor: primaryGreen),
                              const SizedBox(width: 8),
                              _buildTopStatCard(title: 'Pending', value: '$pendingCount', icon: Icons.access_time, iconBg: const Color(0xFFFFF3E0), iconColor: Colors.orange.shade800, valueColor: Colors.orange.shade800),
                              const SizedBox(width: 8),
                              _buildTopStatCard(title: 'Refused', value: '$refusedCount', icon: Icons.cancel_outlined, iconBg: const Color(0xFFFFEBEE), iconColor: Colors.red.shade700, valueColor: Colors.red.shade700),
                              const SizedBox(width: 8),
                              _buildTopStatCard(title: 'Missed', value: '$missedCount', icon: Icons.remove_circle_outline, iconBg: const Color(0xFFF5F5F5), iconColor: Colors.grey.shade700, valueColor: Colors.grey.shade700),
                              const SizedBox(width: 8),
                              _buildTopStatCard(title: 'Coverage', value: '$coveragePercentage%', icon: Icons.pie_chart_outline, iconBg: const Color(0xFFE8F5E9), iconColor: primaryGreen, valueColor: primaryGreen),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _dailyProgressCard(dailySeries),
                        const SizedBox(height: 20),
                        _teamPerformanceCard(teamPerformance),
                        const SizedBox(height: 20),
                        _totalSummaryCard(totalChildren, vaccinatedCount, pendingCount, refusedCount, missedCount),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _generateAndDownloadPdf(
                        campaign: campaign,
                        totalChildren: totalChildren,
                        vaccinated: vaccinatedCount,
                        pending: pendingCount,
                        refused: refusedCount,
                        missed: missedCount,
                        coverage: coveragePercentage,
                        teamPerformance: teamPerformance,
                      ),
                      icon: const Icon(Icons.download, color: Colors.white, size: 20),
                      label: const Text('Download PDF',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _campaignHeaderCard(CampaignModel campaign) {
    final now = DateTime.now();
    final isCompleted = campaign.status == 'completed' || now.isAfter(campaign.endDate);
    return InkWell(
      onTap: _campaigns.length > 1 ? _openCampaignPicker : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined, color: primaryGreen, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(campaign.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
                  Text(
                    '${DateFormat('dd MMM').format(campaign.startDate)} – ${DateFormat('dd MMM yyyy').format(campaign.endDate)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.grey.shade200 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(isCompleted ? 'Completed' : 'Active',
                  style: TextStyle(
                      color: isCompleted ? Colors.grey.shade700 : primaryGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
            if (_campaigns.length > 1) ...[
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, color: primaryGreen),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dailyProgressCard(List<_DayPoint> points) {
    if (points.length < 2) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text('Daily progress chart 2+ dinon ka data hone par dikhegi.',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
      );
    }

    final maxY = points
        .map((p) => [p.vaccinated, p.pending, p.refused, p.missed].reduce((a, b) => a > b ? a : b))
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Progress',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: const [
              _LegendDot(color: primaryGreen, label: 'Vaccinated'),
              _LegendDot(color: Colors.orange, label: 'Pending'),
              _LegendDot(color: Colors.red, label: 'Refused'),
              _LegendDot(color: Colors.grey, label: 'Missed'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY == 0 ? 10 : maxY * 1.2,
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v, meta) {
                      return Text(v.toInt().toString(), style: const TextStyle(fontSize: 9, color: Colors.grey));
                    }),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: (points.length / 6).clamp(1, 1000).toDouble(),
                      getTitlesWidget: (v, meta) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(DateFormat('d MMM').format(points[idx].date),
                              style: const TextStyle(fontSize: 9, color: Colors.grey)),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  _series(points.map((p) => p.vaccinated.toDouble()).toList(), primaryGreen),
                  _series(points.map((p) => p.pending.toDouble()).toList(), Colors.orange),
                  _series(points.map((p) => p.refused.toDouble()).toList(), Colors.red),
                  _series(points.map((p) => p.missed.toDouble()).toList(), Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _series(List<double> values, Color color) {
    return LineChartBarData(
      spots: [for (int i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _teamPerformanceCard(List<Map<String, dynamic>> teamPerformance) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Team Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen)),
          ),
          const Divider(height: 1),
          if (teamPerformance.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Koi vaccinator assign nahi hua.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 44,
                columns: const [
                  DataColumn(label: Text('Vaccinator', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Target', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Vaccinated', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Refused', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Missed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Coverage', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                ],
                rows: teamPerformance.map((t) {
                  return DataRow(cells: [
                    DataCell(Text(t['name'], style: const TextStyle(fontSize: 12))),
                    DataCell(Text('${t['target']}', style: const TextStyle(fontSize: 12))),
                    DataCell(Text('${t['vaccinated']}', style: const TextStyle(fontSize: 12, color: primaryGreen, fontWeight: FontWeight.bold))),
                    DataCell(Text('${t['refused']}', style: const TextStyle(fontSize: 12, color: Colors.red))),
                    DataCell(Text('${t['missed']}', style: const TextStyle(fontSize: 12, color: Colors.grey))),
                    DataCell(Text('${t['coverage']}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                  ]);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _totalSummaryCard(int total, int vac, int pending, int refused, int missed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Total Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen)),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.grey.shade50,
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 1, child: Text('Count', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 1, child: Text('Percentage', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          const Divider(height: 1),
          _summaryRow('Vaccinated', '$vac', '${total > 0 ? ((vac / total) * 100).round() : 0}%', primaryGreen),
          _summaryRow('Pending (Not Yet Visited)', '$pending', '${total > 0 ? ((pending / total) * 100).round() : 0}%', Colors.amber.shade800),
          _summaryRow('Refused (Visit Done, Not Vaccinated)', '$refused', '${total > 0 ? ((refused / total) * 100).round() : 0}%', Colors.red),
          _summaryRow('Missed (Could Not Reach)', '$missed', '${total > 0 ? ((missed / total) * 100).round() : 0}%', Colors.grey.shade700),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade50.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.group, color: primaryGreen, size: 18),
                const SizedBox(width: 8),
                const Expanded(flex: 3, child: Text('Eligible Children (Total)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryGreen))),
                Expanded(flex: 1, child: Text('$total', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryGreen))),
                const Expanded(flex: 1, child: Text('100%', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryGreen))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStatCard({required String title, required String value, required IconData icon, required Color iconBg, required Color iconColor, required Color valueColor}) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          CircleAvatar(radius: 16, backgroundColor: iconBg, child: Icon(icon, size: 18, color: iconColor)),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  Widget _summaryRow(String title, String count, String percentage, Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.black87))),
          Expanded(flex: 1, child: Text(count, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87))),
          Expanded(flex: 1, child: Text(percentage, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87))),
        ],
      ),
    );
  }
}

class _DayPoint {
  final DateTime date;
  final int vaccinated;
  final int pending;
  final int refused;
  final int missed;
  _DayPoint(this.date, this.vaccinated, this.pending, this.refused, this.missed);
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
} */
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/campaign_model.dart';
import '../../services/campaign_service.dart';

class PolioCampaignReportScreen extends StatefulWidget {
  final String? campaignId; // optional — na diya jaye to khud latest campaign select hogi

  const PolioCampaignReportScreen({super.key, this.campaignId});

  @override
  State<PolioCampaignReportScreen> createState() =>
      _PolioCampaignReportScreenState();
}

class _PolioCampaignReportScreenState
    extends State<PolioCampaignReportScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CampaignService _campaignService = CampaignService();
  static const Color primaryGreen = Color(0xFF005A36);

  bool _isLoadingCampaigns = true;
  List<CampaignModel> _campaigns = [];
  CampaignModel? _selectedCampaign;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    try {
      final supervisorId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final campaigns = await _campaignService.getCampaignsBySupervisor(supervisorId);

      CampaignModel? initial;

      if (widget.campaignId != null) {
        // Kisi specific campaign se aaye hain (Campaign Overview se
        // "Campaign Reports" button) — wahi campaign khulni chahiye,
        // exact wahi jo pehle se ban chuki screen dikhati thi.
        for (var c in campaigns) {
          if (c.id == widget.campaignId) {
            initial = c;
            break;
          }
        }
        initial ??= await _campaignService.getCampaignById(widget.campaignId!);
      } else if (campaigns.isNotEmpty) {
        // Reports tab se seedha aaye hain, koi specific campaignId
        // nahi diya gaya — is supervisor ki sabse nayi campaign
        // khud-ba-khud select ho jati hai. Header par hamesha ek
        // dropdown arrow dikhta hai (neeche _campaignHeaderCard mein)
        // taake supervisor ko pata chale ke wo yahan se koi bhi apni
        // campaign select kar sakta hai.
        initial = campaigns.first;
      }

      if (!mounted) return;
      setState(() {
        _campaigns = campaigns;
        _selectedCampaign = initial;
        _isLoadingCampaigns = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Campaign load nahi ho saka: $e';
        _isLoadingCampaigns = false;
      });
    }
  }

  Future<void> _openCampaignPicker() async {
    if (_campaigns.isEmpty) return;
    final pickedId = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Select Campaign',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen)),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _campaigns.length,
                  itemBuilder: (context, index) {
                    final c = _campaigns[index];
                    final isSelected = c.id == _selectedCampaign?.id;
                    return ListTile(
                      leading: Icon(Icons.water_drop_outlined,
                          color: isSelected ? primaryGreen : Colors.grey),
                      title: Text(c.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isSelected ? primaryGreen : Colors.black87)),
                      subtitle: Text(
                          '${DateFormat('dd MMM').format(c.startDate)} – ${DateFormat('dd MMM yyyy').format(c.endDate)}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      trailing: isSelected ? const Icon(Icons.check, color: primaryGreen) : null,
                      onTap: () => Navigator.pop(sheetContext, c.id),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (pickedId != null && pickedId != _selectedCampaign?.id) {
      final chosen = _campaigns.firstWhere((c) => c.id == pickedId);
      setState(() => _selectedCampaign = chosen);
    }
  }

  Future<void> _saveReportToFirestore(String campaignId, String campaignName,
      int totalChildren, int vaccinated, int pending, int refused, int missed, int coverage) async {
    try {
      await _db.collection('polio_campaign_reports').doc(campaignId).set({
        'campaignId': campaignId,
        'campaignName': campaignName,
        'totalChildren': totalChildren,
        'vaccinated': vaccinated,
        'pending': pending,
        'refused': refused,
        'missed': missed,
        'coverage': '$coverage%',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving report: $e');
    }
  }

  List<_DayPoint> _buildDailySeries(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, CampaignModel campaign) {
    final total = docs.length;
    final startDay = DateTime(campaign.startDate.year, campaign.startDate.month, campaign.startDate.day);
    final now = DateTime.now();
    final cap = now.isBefore(campaign.endDate) ? now : campaign.endDate;
    final endDay = DateTime(cap.year, cap.month, cap.day);

    if (endDay.isBefore(startDay) || total == 0) {
      return [_DayPoint(startDay, 0, total, 0, 0)];
    }

    final totalDays = endDay.difference(startDay).inDays;
    final points = <_DayPoint>[];

    for (int i = 0; i <= totalDays; i++) {
      final day = startDay.add(Duration(days: i));
      final dayEnd = day.add(const Duration(days: 1));
      int vaccinated = 0, refused = 0, missed = 0;
      for (var doc in docs) {
        final data = doc.data();
        final updatedAt = data['updatedAt'];
        if (updatedAt is! Timestamp) continue;
        if (updatedAt.toDate().isBefore(dayEnd)) {
          switch (data['status']) {
            case 'Vaccinated':
              vaccinated++;
              break;
            case 'Refused':
              refused++;
              break;
            case 'Missed':
              missed++;
              break;
          }
        }
      }
      final pending = total - vaccinated - refused - missed;
      points.add(_DayPoint(day, vaccinated, pending < 0 ? 0 : pending, refused, missed));
    }
    return points;
  }

  Future<void> _generateAndDownloadPdf({
    required CampaignModel campaign,
    required int totalChildren,
    required int vaccinated,
    required int pending,
    required int refused,
    required int missed,
    required int coverage,
    required List<Map<String, dynamic>> teamPerformance,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Text(
            'Polio Campaign Report',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Campaign: ${campaign.name}', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
          pw.Text('Type: ${campaign.type}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.Text(
            'Duration: ${DateFormat('dd MMM yyyy').format(campaign.startDate)} - ${DateFormat('dd MMM yyyy').format(campaign.endDate)}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          if (campaign.targetAreas.isNotEmpty)
            pw.Text('Target Areas: ${campaign.targetAreas.join(', ')}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.Text('Report Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.Divider(thickness: 1.5, color: PdfColors.green900),
          pw.SizedBox(height: 16),

          pw.Text('Campaign Summary Statistics',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headers: ['Status', 'Count', 'Percentage'],
            data: [
              ['Vaccinated', '$vaccinated', '${totalChildren > 0 ? ((vaccinated / totalChildren) * 100).round() : 0}%'],
              ['Pending (Not Yet Visited)', '$pending', '${totalChildren > 0 ? ((pending / totalChildren) * 100).round() : 0}%'],
              ['Refused (Visit Done, Not Vaccinated)', '$refused', '${totalChildren > 0 ? ((refused / totalChildren) * 100).round() : 0}%'],
              ['Missed (Could Not Reach)', '$missed', '${totalChildren > 0 ? ((missed / totalChildren) * 100).round() : 0}%'],
              ['Eligible Children (Total)', '$totalChildren', '100%'],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
            cellAlignment: pw.Alignment.centerLeft,
          ),

          pw.SizedBox(height: 20),
          pw.Text('Team Performance (By Vaccinator)',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headers: ['Vaccinator', 'Target', 'Vaccinated', 'Refused', 'Missed', 'Coverage'],
            data: teamPerformance
                .map((t) => [
                      t['name'].toString(),
                      '${t['target']}',
                      '${t['vaccinated']}',
                      '${t['refused']}',
                      '${t['missed']}',
                      '${t['coverage']}%',
                    ])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: 'Polio_Campaign_Report_${campaign.name.replaceAll(' ', '_')}.pdf',
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Polio Campaign Report',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoadingCampaigns
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(_loadError!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  ),
                )
              : _selectedCampaign == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.water_drop_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Aap ne abhi tak koi campaign create nahi ki.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildBody(_selectedCampaign!),
    );
  }

  Widget _buildBody(CampaignModel campaign) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      key: ValueKey(campaign.id),
      stream: _db
          .collection('campaign_assignments')
          .where('campaignId', isEqualTo: campaign.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primaryGreen));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('Data load nahi ho saka: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final int totalChildren = docs.length;

        int vaccinatedCount = 0, pendingCount = 0, refusedCount = 0, missedCount = 0;
        for (var doc in docs) {
          switch ((doc.data()['status'] ?? 'Pending').toString()) {
            case 'Vaccinated':
              vaccinatedCount++;
              break;
            case 'Refused':
              refusedCount++;
              break;
            case 'Missed':
              missedCount++;
              break;
            default:
              pendingCount++;
          }
        }
        final int coveragePercentage =
            totalChildren > 0 ? ((vaccinatedCount / totalChildren) * 100).round() : 0;

        final List<Map<String, dynamic>> teamPerformance = campaign.vaccinatorIds.map((vId) {
          final vDocs = docs.where((d) => d.data()['vaccinatorId'] == vId).toList();
          final target = vDocs.length;
          final vac = vDocs.where((d) => d.data()['status'] == 'Vaccinated').length;
          final ref = vDocs.where((d) => d.data()['status'] == 'Refused').length;
          final mis = vDocs.where((d) => d.data()['status'] == 'Missed').length;
          final cov = target > 0 ? ((vac / target) * 100).round() : 0;
          return {'vaccinatorId': vId, 'target': target, 'vaccinated': vac, 'refused': ref, 'missed': mis, 'coverage': cov};
        }).toList();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _saveReportToFirestore(campaign.id, campaign.name, totalChildren, vaccinatedCount,
              pendingCount, refusedCount, missedCount, coveragePercentage);
        });

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _campaignService.getVaccinatorsByIds(campaign.vaccinatorIds),
          builder: (context, vaccinatorSnap) {
            final vaccinatorNameById = {
              for (var v in (vaccinatorSnap.data ?? [])) v['id'] as String: v['name'] as String
            };
            for (var t in teamPerformance) {
              t['name'] = vaccinatorNameById[t['vaccinatorId']] ?? 'Unknown';
            }

            final dailySeries = _buildDailySeries(docs, campaign);

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _campaignHeaderCard(campaign),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildTopStatCard(title: 'Eligible Children', value: '$totalChildren', icon: Icons.group, iconBg: const Color(0xFFE8F5E9), iconColor: primaryGreen, valueColor: primaryGreen),
                              const SizedBox(width: 8),
                              _buildTopStatCard(title: 'Vaccinated', value: '$vaccinatedCount', icon: Icons.check_circle_outline, iconBg: const Color(0xFFE8F5E9), iconColor: primaryGreen, valueColor: primaryGreen),
                              const SizedBox(width: 8),
                              _buildTopStatCard(title: 'Pending', value: '$pendingCount', icon: Icons.access_time, iconBg: const Color(0xFFFFF3E0), iconColor: Colors.orange.shade800, valueColor: Colors.orange.shade800),
                              const SizedBox(width: 8),
                              _buildTopStatCard(title: 'Refused', value: '$refusedCount', icon: Icons.cancel_outlined, iconBg: const Color(0xFFFFEBEE), iconColor: Colors.red.shade700, valueColor: Colors.red.shade700),
                              const SizedBox(width: 8),
                              _buildTopStatCard(title: 'Missed', value: '$missedCount', icon: Icons.remove_circle_outline, iconBg: const Color(0xFFF5F5F5), iconColor: Colors.grey.shade700, valueColor: Colors.grey.shade700),
                              const SizedBox(width: 8),
                              _buildTopStatCard(title: 'Coverage', value: '$coveragePercentage%', icon: Icons.pie_chart_outline, iconBg: const Color(0xFFE8F5E9), iconColor: primaryGreen, valueColor: primaryGreen),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _dailyProgressCard(dailySeries),
                        const SizedBox(height: 20),
                        _teamPerformanceCard(teamPerformance),
                        const SizedBox(height: 20),
                        _totalSummaryCard(totalChildren, vaccinatedCount, pendingCount, refusedCount, missedCount),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _generateAndDownloadPdf(
                        campaign: campaign,
                        totalChildren: totalChildren,
                        vaccinated: vaccinatedCount,
                        pending: pendingCount,
                        refused: refusedCount,
                        missed: missedCount,
                        coverage: coveragePercentage,
                        teamPerformance: teamPerformance,
                      ),
                      icon: const Icon(Icons.download, color: Colors.white, size: 20),
                      label: const Text('Download PDF',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _campaignHeaderCard(CampaignModel campaign) {
    final now = DateTime.now();
    final isCompleted = campaign.status == 'completed' || now.isAfter(campaign.endDate);
    return InkWell(
      // NEW: pehle dropdown arrow sirf tab dikhta tha jab 2+ campaigns
      // hoti thin — is wajah se agar sirf 1 campaign ho to lagta tha
      // yeh selectable hi nahi hai. Ab arrow hamesha dikhega (jab tak
      // koi campaign list mein ho), taake supervisor ko saaf pata chale
      // ke yahan se koi bhi campaign select ki ja sakti hai.
      onTap: _campaigns.isNotEmpty ? _openCampaignPicker : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined, color: primaryGreen, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(campaign.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
                  Text(
                    '${DateFormat('dd MMM').format(campaign.startDate)} – ${DateFormat('dd MMM yyyy').format(campaign.endDate)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.grey.shade200 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(isCompleted ? 'Completed' : 'Active',
                  style: TextStyle(
                      color: isCompleted ? Colors.grey.shade700 : primaryGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
            if (_campaigns.isNotEmpty) ...[
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, color: primaryGreen),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dailyProgressCard(List<_DayPoint> points) {
    if (points.length < 2) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text('Daily progress chart 2+ dinon ka data hone par dikhegi.',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
      );
    }

    final maxY = points
        .map((p) => [p.vaccinated, p.pending, p.refused, p.missed].reduce((a, b) => a > b ? a : b))
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Progress',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: const [
              _LegendDot(color: primaryGreen, label: 'Vaccinated'),
              _LegendDot(color: Colors.orange, label: 'Pending'),
              _LegendDot(color: Colors.red, label: 'Refused'),
              _LegendDot(color: Colors.grey, label: 'Missed'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY == 0 ? 10 : maxY * 1.2,
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v, meta) {
                      return Text(v.toInt().toString(), style: const TextStyle(fontSize: 9, color: Colors.grey));
                    }),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: (points.length / 6).clamp(1, 1000).toDouble(),
                      getTitlesWidget: (v, meta) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(DateFormat('d MMM').format(points[idx].date),
                              style: const TextStyle(fontSize: 9, color: Colors.grey)),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  _series(points.map((p) => p.vaccinated.toDouble()).toList(), primaryGreen),
                  _series(points.map((p) => p.pending.toDouble()).toList(), Colors.orange),
                  _series(points.map((p) => p.refused.toDouble()).toList(), Colors.red),
                  _series(points.map((p) => p.missed.toDouble()).toList(), Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _series(List<double> values, Color color) {
    return LineChartBarData(
      spots: [for (int i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _teamPerformanceCard(List<Map<String, dynamic>> teamPerformance) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Team Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen)),
          ),
          const Divider(height: 1),
          if (teamPerformance.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Koi vaccinator assign nahi hua.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 44,
                columns: const [
                  DataColumn(label: Text('Vaccinator', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Target', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Vaccinated', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Refused', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Missed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Coverage', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                ],
                rows: teamPerformance.map((t) {
                  return DataRow(cells: [
                    DataCell(Text(t['name'], style: const TextStyle(fontSize: 12))),
                    DataCell(Text('${t['target']}', style: const TextStyle(fontSize: 12))),
                    DataCell(Text('${t['vaccinated']}', style: const TextStyle(fontSize: 12, color: primaryGreen, fontWeight: FontWeight.bold))),
                    DataCell(Text('${t['refused']}', style: const TextStyle(fontSize: 12, color: Colors.red))),
                    DataCell(Text('${t['missed']}', style: const TextStyle(fontSize: 12, color: Colors.grey))),
                    DataCell(Text('${t['coverage']}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                  ]);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _totalSummaryCard(int total, int vac, int pending, int refused, int missed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Total Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen)),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.grey.shade50,
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 1, child: Text('Count', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 1, child: Text('Percentage', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          const Divider(height: 1),
          _summaryRow('Vaccinated', '$vac', '${total > 0 ? ((vac / total) * 100).round() : 0}%', primaryGreen),
          _summaryRow('Pending (Not Yet Visited)', '$pending', '${total > 0 ? ((pending / total) * 100).round() : 0}%', Colors.amber.shade800),
          _summaryRow('Refused (Visit Done, Not Vaccinated)', '$refused', '${total > 0 ? ((refused / total) * 100).round() : 0}%', Colors.red),
          _summaryRow('Missed (Could Not Reach)', '$missed', '${total > 0 ? ((missed / total) * 100).round() : 0}%', Colors.grey.shade700),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade50.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.group, color: primaryGreen, size: 18),
                const SizedBox(width: 8),
                const Expanded(flex: 3, child: Text('Eligible Children (Total)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryGreen))),
                Expanded(flex: 1, child: Text('$total', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryGreen))),
                const Expanded(flex: 1, child: Text('100%', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryGreen))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStatCard({required String title, required String value, required IconData icon, required Color iconBg, required Color iconColor, required Color valueColor}) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          CircleAvatar(radius: 16, backgroundColor: iconBg, child: Icon(icon, size: 18, color: iconColor)),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  Widget _summaryRow(String title, String count, String percentage, Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.black87))),
          Expanded(flex: 1, child: Text(count, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87))),
          Expanded(flex: 1, child: Text(percentage, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87))),
        ],
      ),
    );
  }
}

class _DayPoint {
  final DateTime date;
  final int vaccinated;
  final int pending;
  final int refused;
  final int missed;
  _DayPoint(this.date, this.vaccinated, this.pending, this.refused, this.missed);
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}