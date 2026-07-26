import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // PDF Generator Function
  Future<void> _generatePdfReport(String reportType, Map<String, dynamic> stats) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start, // Fixed parameter name here
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('ImmunoSphere - $reportType Vaccination Report',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Generated On: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}'),
                pw.Divider(),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  headers: ['Metric', 'Value'],
                  data: [
                    ['Total Vaccinations Given', stats['totalVaccinations'].toString()],
                    ['Registered Children', stats['registeredChildren'].toString()],
                    ['Pending / Due Cases', stats['pendingCases'].toString()],
                    ['Missed Doses', stats['missedCases'].toString()],
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Text('Report Summary Note: Operational activity synchronized from ImmunoSphere Cloud Platform.',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'ImmunoSphere_${reportType}_Report.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Reports & Analytics',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3F51B5),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF3F51B5),
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('children').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF3F51B5)),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          int registered = docs.length;
          int pending = docs.where((doc) {
            final status = (doc.data() as Map<String, dynamic>)['status'] ?? '';
            return status.toString().contains('Due');
          }).length;

          int missed = docs.where((doc) {
            final status = (doc.data() as Map<String, dynamic>)['status'] ?? '';
            return status.toString().contains('Missed');
          }).length;

          int vaccinated = docs.where((doc) {
            final status = (doc.data() as Map<String, dynamic>)['status'] ?? '';
            return status.toString().contains('Vaccinated');
          }).length;

          final stats = {
            'totalVaccinations': vaccinated,
            'registeredChildren': registered,
            'pendingCases': pending,
            'missedCases': missed,
          };

          return TabBarView(
            controller: _tabController,
            children: [
              _buildDailyReport(stats),
              _buildWeeklyReport(stats),
              _buildMonthlyReport(stats),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDailyReport(Map<String, dynamic> stats) {
    final todayStr = DateFormat('EEEE, dd MMM yyyy').format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Color(0xFF3F51B5)),
                const SizedBox(width: 8),
                Text('Today: $todayStr',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildReportCard("Total Vaccinations", "${stats['totalVaccinations']}", const Color(0xFF3F51B5)),
              _buildReportCard("Registered Children", "${stats['registeredChildren']}", const Color(0xFF10B981)),
              _buildReportCard("Pending Cases", "${stats['pendingCases']}", const Color(0xFFF59E0B)),
              _buildReportCard("Missed Cases", "${stats['missedCases']}", const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _generatePdfReport('Daily', stats),
            icon: const Icon(Icons.download, size: 18, color: Colors.white),
            label: const Text('Download Daily Report (PDF)', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F51B5),
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyReport(Map<String, dynamic> stats) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final dateRange = '${DateFormat('dd MMM').format(startOfWeek)} – ${DateFormat('dd MMM yyyy').format(endOfWeek)}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(dateRange, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 16),
          Container(
            height: 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar("Mon", 40),
                _buildBar("Tue", 65),
                _buildBar("Wed", 45),
                _buildBar("Thu", 90),
                _buildBar("Fri", 80),
                _buildBar("Sat", 60),
                _buildBar("Sun", 20),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _generatePdfReport('Weekly', stats),
            icon: const Icon(Icons.download, size: 18, color: Colors.white),
            label: const Text('Download Weekly Report (PDF)', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F51B5),
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyReport(Map<String, dynamic> stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMonthlyCard("Total Vaccinations", "${stats['totalVaccinations']}"),
          _buildMonthlyCard("Total Registered Children", "${stats['registeredChildren']}"),
          _buildMonthlyCard("Pending Cases", "${stats['pendingCases']}"),
          _buildMonthlyCard("Missed Cases", "${stats['missedCases']}"),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _generatePdfReport('Monthly', stats),
            icon: const Icon(Icons.download, size: 18, color: Colors.white),
            label: const Text('Download Monthly Report (PDF)', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F51B5),
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String day, double heightPercent) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 14,
          height: heightPercent,
          decoration: BoxDecoration(color: const Color(0xFF3F51B5), borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(height: 6),
        Text(day, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildReportCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildMonthlyCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}