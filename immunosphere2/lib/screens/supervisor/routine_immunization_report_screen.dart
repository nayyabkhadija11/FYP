import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../helpers/epi_schedule_helper.dart';
import '../../helpers/vaccination_status_helper.dart';

class RoutineImmunizationReportScreen extends StatefulWidget {
  const RoutineImmunizationReportScreen({Key? key}) : super(key: key);

  @override
  State<RoutineImmunizationReportScreen> createState() =>
      _RoutineImmunizationReportScreenState();
}

class _RoutineImmunizationReportScreenState
    extends State<RoutineImmunizationReportScreen> {
  // Supervisor ki hidayat: sirf DHQ Hospital Attock ke liye report banegi.
  static const String selectedCenter = 'DHQ Hospital Attock';

  late String selectedMonth;
  late List<String> months;

  // EPI schedule se nikali gayi asal vaccine order (18 doses).
  late List<String> vaccineOrder;

  late Future<Map<String, dynamic>> _reportFuture;

  @override
  void initState() {
    super.initState();

    // Pichle 12 mahine ki dropdown list bana rahe hain (latest month sab se upar).
    final now = DateTime.now();
    months = List.generate(12, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return DateFormat('MMMM yyyy').format(d);
    });
    selectedMonth = months.first;

    // Schedule se unique vaccine names (in the order they occur) nikal rahe hain,
    // taake report mein hamesha wahi 18 names dikhein jo actually schedule mein hain.
    final dummySchedule = EpiScheduleHelper.generateEpiSchedule(DateTime.now());
    vaccineOrder = dummySchedule
        .expand((stage) => List<String>.from(stage['vaccines']))
        .toList();

    _reportFuture = _loadReportData();
  }

  void _onMonthChanged(String? val) {
    if (val == null) return;
    setState(() {
      selectedMonth = val;
      _reportFuture = _loadReportData();
    });
  }

  /// DHQ Attock ke tamam children ka data laata hai, unke vaccination
  /// records ke sath match karta hai, aur selectedMonth ke liye
  /// vaccine-wise (vaccinated / pending / refused / missed) counts banata hai.
  Future<Map<String, dynamic>> _loadReportData() async {
    // 1) healthCenter field 'users' doc par kabhi missing ho sakti hai
    // (purane accounts jo naye auth_service se pehle bane), lekin
    // 'valid_employees' collection mein ye hamesha guaranteed maujood
    // hoti hai (registration ke waqt hi set ki jati hai). Is liye
    // source-of-truth ke taur par valid_employees use kar rahe hain.
    final employeesSnap = await FirebaseFirestore.instance
        .collection('valid_employees')
        .where('healthCenter', isEqualTo: selectedCenter)
        .get();

    final employeeIds = employeesSnap.docs
        .where((d) =>
            (d.data()['role'] ?? '').toString().trim().toLowerCase() ==
            'vaccinator')
        .map((d) => d.id) // e.g. 'VAC-102'
        .toList();

    debugPrint(
      '🟢 DEBUG: valid_employees with healthCenter="$selectedCenter" = ${employeesSnap.docs.length}, '
      'vaccinator employeeIds = $employeeIds',
    );

    // 2) Ab in employeeIds ko 'users' collection ke 'employeeId' field se
    // match kar ke asal Firebase uid nikal rahe hain (children ka
    // 'registeredBy' field yahi uid store karta hai).
    List<String> vaccinatorUids = [];
    for (int i = 0; i < employeeIds.length; i += 30) {
      final chunk = employeeIds.sublist(
        i,
        (i + 30 > employeeIds.length) ? employeeIds.length : i + 30,
      );
      if (chunk.isEmpty) continue;
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('employeeId', whereIn: chunk)
          .get();
      vaccinatorUids.addAll(snap.docs.map((d) => d.id));
    }

    debugPrint('🟢 DEBUG: matching users (vaccinators) found = ${vaccinatorUids.length} → $vaccinatorUids');

    if (vaccinatorUids.isEmpty) {
      return {
        'vaccineData': vaccineOrder
            .map((v) => {
                  'name': v,
                  'pending': 0,
                  'refused': 0,
                  'missed': 0,
                  'coverage': 0,
                  'progress': 0.0,
                })
            .toList(),
        'totalChildrenRegistered': 0,
        'totalDoseSlots': 0,
        'fullyVaccinated': 0,
        'pending': 0,
        'refused': 0,
        'missed': 0,
        'debugVaccinatorCount': 0,
        'debugChildrenCount': 0,
        'debugVaccinationDocsCount': 0,
        'debugUsersWithHealthCenterCount': employeesSnap.docs.length,
      };
    }

    // ...phir un vaccinators ke registeredBy children nikalte hain (chunked,
    // whereIn max 30 items leta hai).
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> childrenDocs = [];
    for (int i = 0; i < vaccinatorUids.length; i += 30) {
      final chunk = vaccinatorUids.sublist(
        i,
        (i + 30 > vaccinatorUids.length) ? vaccinatorUids.length : i + 30,
      );
      final snap = await FirebaseFirestore.instance
          .collection('children')
          .where('registeredBy', whereIn: chunk)
          .get();
      childrenDocs.addAll(snap.docs);
    }

    debugPrint('🟢 DEBUG: children found for "$selectedCenter" = ${childrenDocs.length}');

    // 2) Vaccination records lookup ke liye ids collect kar rahe hain.
    // childId kabhi doc.id hota hai, kabhi regNo (jaisa child_details_screen
    // mein bhi dono try kiye jate hain), is liye dono include kar rahe hain.
    final Set<String> idSet = {};
    for (var doc in childrenDocs) {
      idSet.add(doc.id);
      final regNo = (doc.data()['regNo'] ?? '').toString();
      if (regNo.isNotEmpty) idSet.add(regNo);
    }
    final idList = idSet.toList();

    // 3) Firestore whereIn max 30 items leta hai, is liye chunks mein query karte hain.
    final List<Map<String, dynamic>> allVaccinationDocs = [];
    for (int i = 0; i < idList.length; i += 30) {
      final chunk = idList.sublist(
        i,
        (i + 30 > idList.length) ? idList.length : i + 30,
      );
      if (chunk.isEmpty) continue;
      final snap = await FirebaseFirestore.instance
          .collection('vaccinations')
          .where('childId', whereIn: chunk)
          .get();
      allVaccinationDocs.addAll(snap.docs.map((d) => d.data()));
    }

    debugPrint('🟢 DEBUG: vaccination docs fetched = ${allVaccinationDocs.length}');

    final groupedRecords =
        VaccinationStatusHelper.groupRecordsByChildId(allVaccinationDocs);

    // 4) Har child ke liye is month mein due doses ka status nikal rahe hain.
    final Map<String, Map<String, int>> vaccineCounts = {};
    int totalVaccinated = 0, totalPending = 0, totalRefused = 0, totalMissed = 0;

    for (var doc in childrenDocs) {
      final data = doc.data();
      final dynamic dobVal = data['dob'];

      // Invalid/missing DOB wale child ko skip karna zaroori hai, warna
      // parseDob() DateTime.now() fallback deta hai jo galat "At Birth"
      // pending count bana deta.
      if (!VaccinationStatusHelper.hasValidDob(dobVal)) {
        debugPrint('🔴 DEBUG: skipping child ${doc.id} — invalid/missing dob: $dobVal');
        continue;
      }

      final dob = VaccinationStatusHelper.parseDob(dobVal);
      final docId = doc.id;
      final regNo = (data['regNo'] ?? '').toString();

      final records = <Map<String, dynamic>>[
        ...(groupedRecords[docId] ?? []),
        if (regNo.isNotEmpty) ...(groupedRecords[regNo] ?? []),
      ];

      final doseStatuses = VaccinationStatusHelper.getDoseStatusForMonth(
        dob,
        records,
        selectedMonth,
      );

      debugPrint(
        '🟡 DEBUG: child ${doc.id} dob=$dob → doses due in "$selectedMonth" = ${doseStatuses.length}',
      );

      for (var entry in doseStatuses) {
        final vName = entry['vaccineName'] as String;
        final status = entry['status'] as String;

        vaccineCounts.putIfAbsent(
          vName,
          () => {'vaccinated': 0, 'refused': 0, 'missed': 0, 'pending': 0},
        );
        vaccineCounts[vName]![status] =
            (vaccineCounts[vName]![status] ?? 0) + 1;

        switch (status) {
          case 'vaccinated':
            totalVaccinated++;
            break;
          case 'refused':
            totalRefused++;
            break;
          case 'missed':
            totalMissed++;
            break;
          case 'pending':
            totalPending++;
            break;
        }
      }
    }

    // 5) UI ke liye vaccine-wise list, EPI schedule ki order mein.
    final List<Map<String, dynamic>> vaccineData = vaccineOrder.map((vName) {
      final counts = vaccineCounts[vName] ??
          {'vaccinated': 0, 'refused': 0, 'missed': 0, 'pending': 0};
      final total = counts.values.fold<int>(0, (a, b) => a + b);
      final vaccinated = counts['vaccinated'] ?? 0;
      final coverage = total > 0 ? (vaccinated / total * 100).round() : 0;

      return {
        'name': vName,
        'pending': counts['pending'],
        'refused': counts['refused'],
        'missed': counts['missed'],
        'coverage': coverage,
        'progress': total > 0 ? vaccinated / total : 0.0,
      };
    }).toList();

    final totalDoseSlots =
        totalVaccinated + totalPending + totalRefused + totalMissed;

    return {
      'vaccineData': vaccineData,
      'totalChildrenRegistered': childrenDocs.length,
      'totalDoseSlots': totalDoseSlots,
      'fullyVaccinated': totalVaccinated,
      'pending': totalPending,
      'refused': totalRefused,
      'missed': totalMissed,
      'debugVaccinatorCount': vaccinatorUids.length,
      'debugChildrenCount': childrenDocs.length,
      'debugVaccinationDocsCount': allVaccinationDocs.length,
      'debugUsersWithHealthCenterCount': employeesSnap.docs.length,
    };
  }

  double _pct(int part, int total) => total > 0 ? (part / total * 100) : 0;

  // ---------------- PDF ----------------

  Future<void> _generatePdfReport(Map<String, dynamic> report) async {
    final vaccineData = report['vaccineData'] as List<Map<String, dynamic>>;
    final totalSlots = report['totalDoseSlots'] as int;
    final fullyVaccinated = report['fullyVaccinated'] as int;
    final pending = report['pending'] as int;
    final refused = report['refused'] as int;
    final missed = report['missed'] as int;

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          final pdf = pw.Document();
          pdf.addPage(
            pw.MultiPage(
              pageFormat: format,
              margin: const pw.EdgeInsets.all(24),
              build: (pw.Context pdfContext) {
                return [
                  pw.Text(
                    'Routine Immunization Report',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Period: $selectedMonth | Health Center: $selectedCenter',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(color: PdfColors.green900, thickness: 1.5),
                  pw.SizedBox(height: 12),
                  pw.Text('Child Status Breakdown (doses due this month)',
                      style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green900)),
                  pw.SizedBox(height: 6),
                  pw.Text('Total Dose Slots Due: $totalSlots',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(
                      'Fully Vaccinated: $fullyVaccinated (${_pct(fullyVaccinated, totalSlots).toStringAsFixed(1)}%)',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Pending: $pending (${_pct(pending, totalSlots).toStringAsFixed(1)}%)',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Refused: $refused (${_pct(refused, totalSlots).toStringAsFixed(1)}%)',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Missed: $missed (${_pct(missed, totalSlots).toStringAsFixed(1)}%)',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 16),
                  pw.Text('Vaccine Wise Summary',
                      style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green900)),
                  pw.SizedBox(height: 6),
                  pw.Table.fromTextArray(
                    headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        fontSize: 9),
                    headerDecoration:
                        const pw.BoxDecoration(color: PdfColors.green900),
                    cellStyle: const pw.TextStyle(fontSize: 8),
                    cellAlignment: pw.Alignment.centerLeft,
                    headers: ['Vaccine', 'Pending', 'Refused', 'Missed', 'Coverage (%)'],
                    data: vaccineData.map((item) {
                      return [
                        item['name'].toString(),
                        item['pending'].toString(),
                        item['refused'].toString(),
                        item['missed'].toString(),
                        '${item['coverage']}%',
                      ];
                    }).toList(),
                  ),
                ];
              },
            ),
          );
          return pdf.save();
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF025232),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Routine Immunization Report',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _reportFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF025232)));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading report: ${snapshot.error}'));
            }

            final report = snapshot.data!;
            final vaccineData = report['vaccineData'] as List<Map<String, dynamic>>;
            final totalChildrenRegistered = report['totalChildrenRegistered'] as int;
            final totalSlots = report['totalDoseSlots'] as int;
            final fullyVaccinated = report['fullyVaccinated'] as int;
            final pending = report['pending'] as int;
            final refused = report['refused'] as int;
            final missed = report['missed'] as int;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedMonth,
                                    isExpanded: true,
                                    icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade700),
                                    items: months.map((String month) {
                                      return DropdownMenuItem<String>(
                                        value: month,
                                        child: Text(month, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                      );
                                    }).toList(),
                                    onChanged: _onMonthChanged,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Health center fixed to DHQ Attock — supervisor's instruction.
                      Expanded(
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_city_outlined, size: 18, color: Colors.grey.shade700),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  selectedCenter,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Vaccine Wise Summary',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF025232),
                                  fontSize: 15,
                                ),
                              ),
                              Icon(Icons.info_outline, color: Color(0xFF025232), size: 20),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 350),
                              child: Column(
                                children: [
                                  Row(
                                    children: const [
                                      SizedBox(width: 130, child: Text('Vaccine', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))),
                                      SizedBox(width: 90, child: Text('Fully\nVaccinated', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))),
                                      SizedBox(width: 45, child: Text('Pending', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))),
                                      SizedBox(width: 45, child: Text('Refused', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))),
                                      SizedBox(width: 45, child: Text('Missed', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))),
                                      SizedBox(width: 50, child: Text('Coverage\n(%)', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Divider(color: Colors.grey.shade200, height: 1),
                                  const SizedBox(height: 6),
                                  ...vaccineData.map((v) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 7.0),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 130,
                                            child: Row(
                                              children: [
                                                const Icon(Icons.check_circle, color: Color(0xFF025232), size: 14),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    v['name'],
                                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width: 90,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  minHeight: 6,
                                                  value: (v['progress'] as num).toDouble(),
                                                  color: const Color(0xFF025232),
                                                  backgroundColor: Colors.grey.shade200,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 45, child: Text('${v['pending']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFF025232), fontWeight: FontWeight.bold))),
                                          SizedBox(width: 45, child: Text('${v['refused']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold))),
                                          SizedBox(width: 45, child: Text('${v['missed']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold))),
                                          SizedBox(width: 50, child: Text('${v['coverage']}%', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFF025232), fontWeight: FontWeight.bold))),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Summary Overview',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF025232),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalChildrenRegistered children registered at $selectedCenter — $totalSlots vaccine doses due in $selectedMonth',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildSummaryCard('Doses Due', '$totalSlots', '100%', Icons.people, const Color(0xFF025232)),
                                _buildSummaryCard('Fully Vaccinated', '$fullyVaccinated', '${_pct(fullyVaccinated, totalSlots).toStringAsFixed(1)}%', Icons.check_circle_outline, const Color(0xFF025232)),
                                _buildSummaryCard('Pending', '$pending', '${_pct(pending, totalSlots).toStringAsFixed(1)}%', Icons.access_time, Colors.amber.shade700),
                                _buildSummaryCard('Refused', '$refused', '${_pct(refused, totalSlots).toStringAsFixed(1)}%', Icons.cancel_outlined, Colors.red),
                                _buildSummaryCard('Missed', '$missed', '${_pct(missed, totalSlots).toStringAsFixed(1)}%', Icons.remove_circle_outline, Colors.blueGrey),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF025232),
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () async {
                          await _generatePdfReport(report);
                        },
                        icon: const Icon(Icons.download, color: Colors.white, size: 18),
                        label: const Text('Download PDF Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count, String percentage, IconData icon, Color color) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(count, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(percentage, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}