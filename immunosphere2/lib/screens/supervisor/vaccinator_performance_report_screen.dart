import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../helpers/vaccination_status_helper.dart';
import '../../models/campaign_model.dart';
import '../../services/campaign_service.dart';
import 'vaccinator_performance_details_screen.dart';

class VaccinatorPerformanceReportScreen extends StatefulWidget {
  const VaccinatorPerformanceReportScreen({super.key});

  @override
  State<VaccinatorPerformanceReportScreen> createState() =>
      _VaccinatorPerformanceReportScreenState();
}

class _VaccinatorPerformanceReportScreenState
    extends State<VaccinatorPerformanceReportScreen> {
  static const Color primaryGreen = Color(0xFF005E38);
  static const String selectedCenter = 'DHQ Hospital Attock';

  final CampaignService _campaignService = CampaignService();

  String _selectedReportType = 'Routine Immunization';

  late String _selectedMonth;
  late List<String> _monthsList;

  bool _isLoadingCampaigns = true;
  List<CampaignModel> _campaigns = [];
  CampaignModel? _selectedCampaign;

  // Routine ka RAW data (children + vaccination records) sirf EK dafa fetch
  // hota hai. Month badalne par sirf isi cached data par dobara calculation
  // hoti hai (koi naya Firestore query nahi) — is liye month switch turant
  // (fast) hota hai.
  late Future<List<_VaccinatorRawData>> _routineRawFuture;

  Future<List<Map<String, dynamic>>>? _polioFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthsList = List.generate(12, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return DateFormat('MMMM yyyy').format(d);
    });
    _selectedMonth = _monthsList.first;

    _routineRawFuture = _loadRoutineRawData();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    try {
      final supervisorId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final campaigns = await _campaignService.getCampaignsBySupervisor(supervisorId);
      if (!mounted) return;
      setState(() {
        _campaigns = campaigns;
        _selectedCampaign = campaigns.isNotEmpty ? campaigns.first : null;
        _isLoadingCampaigns = false;
        if (_selectedCampaign != null) {
          _polioFuture = _loadPolioPerformance(_selectedCampaign!);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCampaigns = false);
    }
  }

  // ---------------- Vaccinators at DHQ Hospital Attock ----------------

  Future<List<Map<String, String>>> _getVaccinatorsForCenter() async {
    final employeesSnap = await FirebaseFirestore.instance
        .collection('valid_employees')
        .where('healthCenter', isEqualTo: selectedCenter)
        .get();

    final employeeIds = employeesSnap.docs
        .where((d) => (d.data()['role'] ?? '').toString().trim().toLowerCase() == 'vaccinator')
        .map((d) => d.id)
        .toList();

    final List<Map<String, String>> vaccinators = [];
    for (int i = 0; i < employeeIds.length; i += 30) {
      final chunk = employeeIds.sublist(i, (i + 30 > employeeIds.length) ? employeeIds.length : i + 30);
      if (chunk.isEmpty) continue;
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('employeeId', whereIn: chunk)
          .get();
      for (var d in snap.docs) {
        vaccinators.add({
          'uid': d.id,
          'employeeId': (d.data()['employeeId'] ?? '').toString(),
          'name': (d.data()['fullName'] ?? d.data()['name'] ?? 'Unknown').toString(),
        });
      }
    }
    return vaccinators;
  }

  // ---------------- Routine Immunization: RAW data (fetched once) ----------------

  Future<List<_VaccinatorRawData>> _loadRoutineRawData() async {
    final vaccinators = await _getVaccinatorsForCenter();
    if (vaccinators.isEmpty) return [];

    final List<_VaccinatorRawData> results = [];

    for (var vac in vaccinators) {
      final childrenSnap = await FirebaseFirestore.instance
          .collection('children')
          .where('registeredBy', isEqualTo: vac['uid'])
          .get();

      final childrenDocs = childrenSnap.docs;

      final Set<String> idSet = {};
      for (var doc in childrenDocs) {
        idSet.add(doc.id);
        final regNo = (doc.data()['regNo'] ?? '').toString();
        if (regNo.isNotEmpty) idSet.add(regNo);
      }
      final idList = idSet.toList();

      final List<Map<String, dynamic>> allVaccinationDocs = [];
      for (int i = 0; i < idList.length; i += 30) {
        final chunk = idList.sublist(i, (i + 30 > idList.length) ? idList.length : i + 30);
        if (chunk.isEmpty) continue;
        final snap = await FirebaseFirestore.instance
            .collection('vaccinations')
            .where('childId', whereIn: chunk)
            .get();
        allVaccinationDocs.addAll(snap.docs.map((d) => d.data()));
      }

      final groupedRecords = VaccinationStatusHelper.groupRecordsByChildId(allVaccinationDocs);

      results.add(_VaccinatorRawData(
        uid: vac['uid']!,
        employeeId: vac['employeeId'] ?? '',
        name: vac['name'] ?? 'Unknown',
        childrenDocs: childrenDocs,
        groupedRecords: groupedRecords,
      ));
    }

    return results;
  }

  /// Cached raw data par, selected month ke hisaab se stats calculate
  /// karta hai. Ye sirf local/CPU kaam hai — koi Firestore call nahi, is
  /// liye month badalne par turant chalta hai.
  List<Map<String, dynamic>> _computeRoutineRows(List<_VaccinatorRawData> raw, String month) {
    final List<Map<String, dynamic>> results = [];

    for (var vac in raw) {
      int vaccinated = 0, pending = 0, refused = 0, missed = 0;
      int childrenWithDueDose = 0; // "Target Children" is month ke liye

      for (var doc in vac.childrenDocs) {
        final data = doc.data();
        final dynamic dobVal = data['dob'];
        if (!VaccinationStatusHelper.hasValidDob(dobVal)) continue;

        final dob = VaccinationStatusHelper.parseDob(dobVal);
        final docId = doc.id;
        final regNo = (data['regNo'] ?? '').toString();

        final records = <Map<String, dynamic>>[
          ...(vac.groupedRecords[docId] ?? []),
          if (regNo.isNotEmpty) ...(vac.groupedRecords[regNo] ?? []),
        ];

        final doseStatuses = VaccinationStatusHelper.getDoseStatusForMonth(dob, records, month);
        if (doseStatuses.isEmpty) continue;

        childrenWithDueDose++;
        for (var entry in doseStatuses) {
          switch (entry['status'] as String) {
            case 'vaccinated':
              vaccinated++;
              break;
            case 'pending':
              pending++;
              break;
            case 'refused':
              refused++;
              break;
            case 'missed':
              missed++;
              break;
          }
        }
      }

      final doseTotal = vaccinated + pending + refused + missed;
      final coverage = doseTotal > 0 ? (vaccinated / doseTotal * 100).round() : 0;

      results.add({
        'uid': vac.uid,
        'vaccinatorId': vac.employeeId.isNotEmpty ? vac.employeeId : vac.uid.substring(0, 6).toUpperCase(),
        'name': vac.name,
        'targetChildren': childrenWithDueDose,
        'vaccinated': vaccinated,
        'pending': pending,
        'refused': refused,
        'missed': missed,
        'coverage': coverage,
      });
    }

    results.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    return results;
  }

  // ---------------- Polio Campaign ----------------

  Future<List<Map<String, dynamic>>> _loadPolioPerformance(CampaignModel campaign) async {
    final assignmentsSnap = await FirebaseFirestore.instance
        .collection('campaign_assignments')
        .where('campaignId', isEqualTo: campaign.id)
        .get();

    final assignments = assignmentsSnap.docs;

    // campaign.vaccinatorIds is dono kaam ke liye use hote hain: 'users'
    // collection ke document IDs hi hain, is liye seedha wahan se
    // employeeId aur naam nikal lete hain.
    final Map<String, String> employeeIdByUid = {};
    final Map<String, String> nameByUid = {};
    final vIdList = campaign.vaccinatorIds;
    for (int i = 0; i < vIdList.length; i += 30) {
      final chunk = vIdList.sublist(i, (i + 30 > vIdList.length) ? vIdList.length : i + 30);
      if (chunk.isEmpty) continue;
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (var d in snap.docs) {
        final data = d.data();
        employeeIdByUid[d.id] = (data['employeeId'] ?? '').toString();
        nameByUid[d.id] = (data['fullName'] ?? data['name'] ?? 'Unknown').toString();
      }
    }

    // Assigned Area ke liye assignments ke childId se village nikalte hain.
    final Set<String> childIds = assignments
        .map((d) => (d.data()['childId'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();
    final Map<String, String> villageByChildId = {};
    final childIdList = childIds.toList();
    for (int i = 0; i < childIdList.length; i += 30) {
      final chunk = childIdList.sublist(i, (i + 30 > childIdList.length) ? childIdList.length : i + 30);
      if (chunk.isEmpty) continue;
      final snap = await FirebaseFirestore.instance
          .collection('children')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (var d in snap.docs) {
        villageByChildId[d.id] = (d.data()['village'] ?? '').toString().trim();
      }
    }

    final List<Map<String, dynamic>> results = [];
    for (var vId in campaign.vaccinatorIds) {
      final vDocs = assignments.where((d) => d.data()['vaccinatorId'] == vId).toList();
      final target = vDocs.length;
      final vac = vDocs.where((d) => d.data()['status'] == 'Vaccinated').length;
      final ref = vDocs.where((d) => d.data()['status'] == 'Refused').length;
      final mis = vDocs.where((d) => d.data()['status'] == 'Missed').length;
      final coverage = target > 0 ? (vac / target * 100).round() : 0;

      final Map<String, int> villageCounts = {};
      for (var d in vDocs) {
        final childId = (d.data()['childId'] ?? '').toString();
        final village = villageByChildId[childId] ?? '';
        if (village.isNotEmpty) villageCounts[village] = (villageCounts[village] ?? 0) + 1;
      }
      String assignedArea = '-';
      if (villageCounts.isNotEmpty) {
        final sorted = villageCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        assignedArea = sorted.length > 1 ? '${sorted.first.key} +${sorted.length - 1} more' : sorted.first.key;
      }

      final empId = employeeIdByUid[vId] ?? '';

      results.add({
        'uid': vId,
        'vaccinatorId': empId.isNotEmpty ? empId : (vId.length >= 6 ? vId.substring(0, 6).toUpperCase() : vId),
        'name': nameByUid[vId] ?? 'Unknown',
        'assignedArea': assignedArea,
        'targetChildren': target,
        'vaccinated': vac,
        'refused': ref,
        'missed': mis,
        'coverage': coverage,
      });
    }

    results.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    return results;
  }

  void _onMonthChanged(String? val) {
    if (val == null) return;
    // Sirf setState — dobara Firestore query NAHI hoti, isi wajah se fast hai.
    setState(() => _selectedMonth = val);
  }

  Future<void> _openCampaignPicker() async {
    if (_campaigns.isEmpty) return;
    final pickedId = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _campaigns
              .map((c) => ListTile(
                    leading: const Icon(Icons.water_drop_outlined, color: primaryGreen),
                    title: Text(c.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    onTap: () => Navigator.pop(sheetContext, c.id),
                  ))
              .toList(),
        ),
      ),
    );
    if (pickedId != null) {
      final chosen = _campaigns.firstWhere((c) => c.id == pickedId);
      setState(() {
        _selectedCampaign = chosen;
        _polioFuture = _loadPolioPerformance(chosen);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isRoutine = _selectedReportType == 'Routine Immunization';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Vaccinator Performance Report', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Report Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildToggleTab('Routine Immunization', isRoutine)),
                const SizedBox(width: 12),
                Expanded(child: _buildToggleTab('Polio Campaign', !isRoutine)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isRoutine ? 'Month' : 'Campaign', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      isRoutine
                          ? _dropdownBox(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedMonth,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                                  items: _monthsList.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)))).toList(),
                                  onChanged: _onMonthChanged,
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: _openCampaignPicker,
                              child: _dropdownBox(
                                child: Row(
                                  children: [
                                    Expanded(child: Text(_selectedCampaign?.name ?? (_isLoadingCampaigns ? 'Loading...' : 'No campaign'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                                    const Icon(Icons.keyboard_arrow_down, size: 18),
                                  ],
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Health Center', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      _dropdownBox(child: const Text(selectedCenter, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Vaccinator Performance Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryGreen)),
            const SizedBox(height: 12),
            isRoutine ? _buildRoutineTable() : _buildPolioTable(),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Coverage % = (Vaccinated / Target Children) x 100', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineTable() {
    return FutureBuilder<List<_VaccinatorRawData>>(
      future: _routineRawFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: CircularProgressIndicator(color: primaryGreen)));
        }
        if (snapshot.hasError) {
          return Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 11)));
        }
        final raw = snapshot.data ?? [];
        if (raw.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('Koi vaccinator nahi mila.', style: TextStyle(color: Colors.grey))));
        }

        // Ye calculation local hai (koi network call nahi), is liye month
        // change hone par turant chalta hai.
        final rows = _computeRoutineRows(raw, _selectedMonth);

        int totalTarget = rows.fold(0, (s, r) => s + (r['targetChildren'] as int));
        int totalVaccinated = rows.fold(0, (s, r) => s + (r['vaccinated'] as int));
        int totalPending = rows.fold(0, (s, r) => s + (r['pending'] as int));
        int totalRefused = rows.fold(0, (s, r) => s + (r['refused'] as int));
        int totalMissed = rows.fold(0, (s, r) => s + (r['missed'] as int));
        final doseTotal = totalVaccinated + totalPending + totalRefused + totalMissed;
        final avgCoverage = doseTotal > 0 ? (totalVaccinated / doseTotal * 100) : 0.0;

        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 52,
              horizontalMargin: 12,
              columnSpacing: 14,
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
              columns: [
                _col('Vaccinator ID'),
                _col('Vaccinator Name'),
                _col('Target\nChildren'),
                _col('Vaccinated'),
                _col('Pending'),
                _col('Refused'),
                _col('Missed'),
                _col('Coverage %'),
                _col('Action'),
              ],
              rows: [
                ...rows.map((v) => DataRow(cells: [
                      DataCell(Text(v['vaccinatorId'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      DataCell(Text(v['name'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      DataCell(Text('${v['targetChildren']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      DataCell(Text('${v['vaccinated']}', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold))),
                      DataCell(Text('${v['pending']}', style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold))),
                      DataCell(Text('${v['refused']}', style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold))),
                      DataCell(Text('${v['missed']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      DataCell(Text('${v['coverage']}%', style: const TextStyle(fontSize: 11, color: primaryGreen, fontWeight: FontWeight.bold))),
                      DataCell(
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: primaryGreen), padding: const EdgeInsets.symmetric(horizontal: 10)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VaccinatorPerformanceDetailsScreen(
                                  reportType: _selectedReportType,
                                  vaccinatorData: v,
                                  healthCenter: selectedCenter,
                                  periodLabel: _selectedMonth,
                                ),
                              ),
                            );
                          },
                          child: const Text('View Details', style: TextStyle(fontSize: 10, color: primaryGreen, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ])),
                DataRow(
                  color: WidgetStateProperty.all(const Color(0xFFEFF6F1)),
                  cells: [
                    const DataCell(Text('')),
                    const DataCell(Text('Total / Average', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryGreen))),
                    DataCell(Text('$totalTarget', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryGreen))),
                    DataCell(Text('$totalVaccinated', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryGreen))),
                    DataCell(Text('$totalPending', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange))),
                    DataCell(Text('$totalRefused', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red))),
                    DataCell(Text('$totalMissed', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    DataCell(Text('${avgCoverage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryGreen))),
                    const DataCell(Text('')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPolioTable() {
    if (_selectedCampaign == null && !_isLoadingCampaigns) {
      return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('Koi campaign nahi mili.', style: TextStyle(color: Colors.grey))));
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _polioFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: CircularProgressIndicator(color: primaryGreen)));
        }
        if (snapshot.hasError) {
          return Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 11)));
        }
        final rows = snapshot.data ?? [];
        if (rows.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('Is campaign ke liye koi data nahi mila.', style: TextStyle(color: Colors.grey))));
        }

        int totalTarget = rows.fold(0, (s, r) => s + (r['targetChildren'] as int));
        int totalVaccinated = rows.fold(0, (s, r) => s + (r['vaccinated'] as int));
        int totalRefused = rows.fold(0, (s, r) => s + (r['refused'] as int));
        int totalMissed = rows.fold(0, (s, r) => s + (r['missed'] as int));
        final avgCoverage = totalTarget > 0 ? (totalVaccinated / totalTarget * 100) : 0.0;

        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 52,
              horizontalMargin: 12,
              columnSpacing: 14,
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
              columns: [
                _col('Vaccinator ID'),
                _col('Vaccinator Name'),
                _col('Assigned Area'),
                _col('Target\nChildren'),
                _col('Vaccinated'),
                _col('Refused'),
                _col('Missed'),
                _col('Coverage %'),
                _col('Action'),
              ],
              rows: [
                ...rows.map((v) => DataRow(cells: [
                      DataCell(Text(v['vaccinatorId'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      DataCell(Text(v['name'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      DataCell(Text(v['assignedArea'], style: const TextStyle(fontSize: 11))),
                      DataCell(Text('${v['targetChildren']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      DataCell(Text('${v['vaccinated']}', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold))),
                      DataCell(Text('${v['refused']}', style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold))),
                      DataCell(Text('${v['missed']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      DataCell(Text('${v['coverage']}%', style: const TextStyle(fontSize: 11, color: primaryGreen, fontWeight: FontWeight.bold))),
                      DataCell(
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: primaryGreen), padding: const EdgeInsets.symmetric(horizontal: 10)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VaccinatorPerformanceDetailsScreen(
                                  reportType: _selectedReportType,
                                  vaccinatorData: v,
                                  healthCenter: selectedCenter,
                                  periodLabel: _selectedCampaign?.name ?? '',
                                ),
                              ),
                            );
                          },
                          child: const Text('View Details', style: TextStyle(fontSize: 10, color: primaryGreen, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ])),
                DataRow(
                  color: WidgetStateProperty.all(const Color(0xFFEFF6F1)),
                  cells: [
                    const DataCell(Text('')),
                    const DataCell(Text('Total / Average', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryGreen))),
                    const DataCell(Text('')),
                    DataCell(Text('$totalTarget', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryGreen))),
                    DataCell(Text('$totalVaccinated', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryGreen))),
                    DataCell(Text('$totalRefused', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red))),
                    DataCell(Text('$totalMissed', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    DataCell(Text('${avgCoverage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryGreen))),
                    const DataCell(Text('')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggleTab(String title, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedReportType = title),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: isSelected ? primaryGreen : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSelected ? primaryGreen : Colors.grey.shade300)),
        alignment: Alignment.center,
        child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey.shade700)),
      ),
    );
  }

  Widget _dropdownBox({required Widget child}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
      child: child,
    );
  }

  DataColumn _col(String label) => DataColumn(label: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)));
}

/// Ek vaccinator ka raw (Firestore se fetch kiya hua, month-independent)
/// data. Isay ek dafa fetch kar ke cache kar liya jata hai.
class _VaccinatorRawData {
  final String uid;
  final String employeeId;
  final String name;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> childrenDocs;
  final Map<String, List<Map<String, dynamic>>> groupedRecords;

  _VaccinatorRawData({
    required this.uid,
    required this.employeeId,
    required this.name,
    required this.childrenDocs,
    required this.groupedRecords,
  });
}