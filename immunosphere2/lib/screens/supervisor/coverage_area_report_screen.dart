import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../helpers/vaccination_status_helper.dart';
import '../../models/campaign_model.dart';
import '../../services/campaign_service.dart';

class CoverageAreaReportScreen extends StatefulWidget {
  const CoverageAreaReportScreen({super.key});

  @override
  State<CoverageAreaReportScreen> createState() =>
      _CoverageAreaReportScreenState();
}

class _CoverageAreaReportScreenState extends State<CoverageAreaReportScreen> {
  static const Color primaryGreen = Color(0xFF025232);

  // Supervisor ki hidayat: sirf DHQ Hospital Attock ke liye report banegi.
  static const String selectedCenter = 'DHQ Hospital Attock';
  static const String selectedDistrict = 'Attock';

  final CampaignService _campaignService = CampaignService();

  String _selectedReportType = 'Routine Immunization';

  late String _selectedMonth;
  late List<String> _monthsList;

  bool _isLoadingCampaigns = true;
  List<CampaignModel> _campaigns = [];
  CampaignModel? _selectedCampaign;

  late Future<List<Map<String, dynamic>>> _routineFuture;
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

    _routineFuture = _loadRoutineAreaReport();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    try {
      final supervisorId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final campaigns =
          await _campaignService.getCampaignsBySupervisor(supervisorId);
      if (!mounted) return;
      setState(() {
        _campaigns = campaigns;
        _selectedCampaign = campaigns.isNotEmpty ? campaigns.first : null;
        _isLoadingCampaigns = false;
        if (_selectedCampaign != null) {
          _polioFuture = _loadPolioAreaReport(_selectedCampaign!);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCampaigns = false);
    }
  }

  // ---------------- Shared: DHQ Hospital Attock ke vaccinators/children ----------------

  /// valid_employees ko source-of-truth ke taur par use karte hain (users doc
  /// mein healthCenter kabhi missing ho sakti hai purane accounts ke liye).
  Future<List<String>> _getVaccinatorUidsForCenter() async {
    final employeesSnap = await FirebaseFirestore.instance
        .collection('valid_employees')
        .where('healthCenter', isEqualTo: selectedCenter)
        .get();

    final employeeIds = employeesSnap.docs
        .where((d) =>
            (d.data()['role'] ?? '').toString().trim().toLowerCase() ==
            'vaccinator')
        .map((d) => d.id)
        .toList();

    final List<String> uids = [];
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
      uids.addAll(snap.docs.map((d) => d.id));
    }
    return uids;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _getChildrenForCenter(List<String> vaccinatorUids) async {
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> childrenDocs = [];
    for (int i = 0; i < vaccinatorUids.length; i += 30) {
      final chunk = vaccinatorUids.sublist(
        i,
        (i + 30 > vaccinatorUids.length) ? vaccinatorUids.length : i + 30,
      );
      if (chunk.isEmpty) continue;
      final snap = await FirebaseFirestore.instance
          .collection('children')
          .where('registeredBy', whereIn: chunk)
          .get();
      childrenDocs.addAll(snap.docs);
    }
    return childrenDocs;
  }

  // ---------------- Routine Immunization (village-wise) ----------------

  Future<List<Map<String, dynamic>>> _loadRoutineAreaReport() async {
    final vaccinatorUids = await _getVaccinatorUidsForCenter();
    if (vaccinatorUids.isEmpty) return [];

    final childrenDocs = await _getChildrenForCenter(vaccinatorUids);
    if (childrenDocs.isEmpty) return [];

    final Set<String> idSet = {};
    for (var doc in childrenDocs) {
      idSet.add(doc.id);
      final regNo = (doc.data()['regNo'] ?? '').toString();
      if (regNo.isNotEmpty) idSet.add(regNo);
    }
    final idList = idSet.toList();

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

    final groupedRecords =
        VaccinationStatusHelper.groupRecordsByChildId(allVaccinationDocs);

    // village -> {eligible, vaccinated, pending, refused, missed}
    final Map<String, Map<String, int>> byVillage = {};

    for (var doc in childrenDocs) {
      final data = doc.data();
      final village = (data['village'] ?? 'Unspecified').toString().trim();
      final villageKey = village.isEmpty ? 'Unspecified' : village;

      byVillage.putIfAbsent(
        villageKey,
        () => {
          'eligible': 0,
          'vaccinated': 0,
          'pending': 0,
          'refused': 0,
          'missed': 0,
        },
      );
      byVillage[villageKey]!['eligible'] =
          (byVillage[villageKey]!['eligible'] ?? 0) + 1;

      final dynamic dobVal = data['dob'];
      if (!VaccinationStatusHelper.hasValidDob(dobVal)) continue;

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
        _selectedMonth,
      );

      for (var entry in doseStatuses) {
        final status = entry['status'] as String;
        byVillage[villageKey]![status] =
            (byVillage[villageKey]![status] ?? 0) + 1;
      }
    }

    final List<Map<String, dynamic>> rows = byVillage.entries.map((e) {
      final v = e.value;
      final doseTotal =
          (v['vaccinated'] ?? 0) + (v['pending'] ?? 0) + (v['refused'] ?? 0) + (v['missed'] ?? 0);
      final coverage = doseTotal > 0
          ? ((v['vaccinated'] ?? 0) / doseTotal * 100).round()
          : 0;
      return {
        'center': e.key,
        'eligible': v['eligible'],
        'vaccinated': v['vaccinated'],
        'pending': v['pending'],
        'refused': v['refused'],
        'missed': v['missed'],
        'coverage': '$coverage%',
        'coverageValue': coverage,
      };
    }).toList()
      ..sort((a, b) => (a['center'] as String).compareTo(b['center'] as String));

    return rows;
  }

  // ---------------- Polio Campaign (village-wise) ----------------

  Future<List<Map<String, dynamic>>> _loadPolioAreaReport(
      CampaignModel campaign) async {
    final assignmentsSnap = await FirebaseFirestore.instance
        .collection('campaign_assignments')
        .where('campaignId', isEqualTo: campaign.id)
        .get();

    final assignments = assignmentsSnap.docs;
    if (assignments.isEmpty) return [];

    // Har assignment ka village jaanne ke liye children ko batch mein fetch
    // karte hain.
    final Set<String> childIds = assignments
        .map((d) => (d.data()['childId'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();

    final Map<String, String> villageByChildId = {};
    final idList = childIds.toList();
    for (int i = 0; i < idList.length; i += 30) {
      final chunk = idList.sublist(
        i,
        (i + 30 > idList.length) ? idList.length : i + 30,
      );
      if (chunk.isEmpty) continue;
      final snap = await FirebaseFirestore.instance
          .collection('children')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (var doc in snap.docs) {
        villageByChildId[doc.id] =
            (doc.data()['village'] ?? 'Unspecified').toString().trim();
      }
    }

    final Map<String, Map<String, int>> byVillage = {};

    for (var doc in assignments) {
      final data = doc.data();
      final childId = (data['childId'] ?? '').toString();
      final village = villageByChildId[childId] ?? 'Unspecified';
      final villageKey = village.isEmpty ? 'Unspecified' : village;

      byVillage.putIfAbsent(
        villageKey,
        () => {'eligible': 0, 'vaccinated': 0, 'refused': 0, 'missed': 0},
      );
      byVillage[villageKey]!['eligible'] =
          (byVillage[villageKey]!['eligible'] ?? 0) + 1;

      switch ((data['status'] ?? 'Pending').toString()) {
        case 'Vaccinated':
          byVillage[villageKey]!['vaccinated'] =
              (byVillage[villageKey]!['vaccinated'] ?? 0) + 1;
          break;
        case 'Refused':
          byVillage[villageKey]!['refused'] =
              (byVillage[villageKey]!['refused'] ?? 0) + 1;
          break;
        case 'Missed':
          byVillage[villageKey]!['missed'] =
              (byVillage[villageKey]!['missed'] ?? 0) + 1;
          break;
      }
    }

    final List<Map<String, dynamic>> rows = byVillage.entries.map((e) {
      final v = e.value;
      final eligible = v['eligible'] ?? 0;
      final coverage = eligible > 0
          ? ((v['vaccinated'] ?? 0) / eligible * 100).round()
          : 0;
      return {
        'center': e.key,
        'eligible': eligible,
        'vaccinated': v['vaccinated'],
        'refused': v['refused'],
        'missed': v['missed'],
        'coverage': '$coverage%',
        'coverageValue': coverage,
      };
    }).toList()
      ..sort((a, b) => (a['center'] as String).compareTo(b['center'] as String));

    return rows;
  }

  void _onMonthChanged(String? val) {
    if (val == null) return;
    setState(() {
      _selectedMonth = val;
      _routineFuture = _loadRoutineAreaReport();
    });
  }

  void _onCampaignChanged(CampaignModel campaign) {
    setState(() {
      _selectedCampaign = campaign;
      _polioFuture = _loadPolioAreaReport(campaign);
    });
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
            children: _campaigns
                .map((c) => ListTile(
                      leading: const Icon(Icons.water_drop_outlined, color: primaryGreen),
                      title: Text(c.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      onTap: () => Navigator.pop(sheetContext, c.id),
                    ))
                .toList(),
          ),
        );
      },
    );
    if (pickedId != null) {
      final chosen = _campaigns.firstWhere((c) => c.id == pickedId);
      _onCampaignChanged(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isRoutine = _selectedReportType == 'Routine Immunization';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Coverage Area Report',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report Type',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      title: 'Routine Immunization',
                      isSelected: isRoutine,
                      onTap: () => setState(() => _selectedReportType = 'Routine Immunization'),
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      title: 'Polio Campaign',
                      isSelected: !isRoutine,
                      onTap: () => setState(() => _selectedReportType = 'Polio Campaign'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Filters row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isRoutine ? 'Month' : 'Campaign',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      isRoutine
                          ? _buildDropdownContainer(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedMonth,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                                  items: _monthsList
                                      .map((m) => DropdownMenuItem(
                                          value: m,
                                          child: Text(m, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)))
                                      .toList(),
                                  onChanged: _onMonthChanged,
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: _openCampaignPicker,
                              child: _buildDropdownContainer(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedCampaign?.name ?? (_isLoadingCampaigns ? 'Loading...' : 'No campaign'),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.keyboard_arrow_down, size: 18),
                                  ],
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('District', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      _buildDropdownContainer(
                        child: const Text(selectedDistrict, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Health Center', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      _buildDropdownContainer(
                        child: const Text(selectedCenter, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              'Coverage by Area (Village)',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryGreen),
            ),
            const SizedBox(height: 12),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: isRoutine ? _routineFuture : _polioFuture,
              builder: (context, snapshot) {
                if (isRoutine == false && _selectedCampaign == null && !_isLoadingCampaigns) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: const Color(0xFFF7FAF8), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: const Center(child: Text('Koi campaign nahi mili.', style: TextStyle(color: Colors.grey))),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator(color: primaryGreen)),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                    child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 11)),
                  );
                }

                final records = snapshot.data ?? [];

                if (records.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: const Color(0xFFF7FAF8), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: const Center(child: Text('Is period ke liye koi data nahi mila.', style: TextStyle(color: Colors.grey))),
                  );
                }

                return Container(
                  decoration: BoxDecoration(color: const Color(0xFFF7FAF8), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 350),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: const BoxDecoration(color: Color(0xFFE8F2EC), borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
                            child: Row(children: _buildTableHeaders(isRoutine)),
                          ),
                          ...records.map((data) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                              child: Row(children: _buildTableCells(data, isRoutine)),
                            );
                          }),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            decoration: const BoxDecoration(color: Color(0xFFEFF6F1), borderRadius: BorderRadius.vertical(bottom: Radius.circular(12))),
                            child: Row(children: _buildSummaryCells(records, isRoutine)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: isRoutine ? _routineFuture : _polioFuture,
              builder: (context, snapshot) {
                final records = snapshot.data ?? [];
                if (records.isEmpty) return const SizedBox.shrink();

                final sorted = [...records]..sort((a, b) => (a['coverageValue'] as int).compareTo(b['coverageValue'] as int));
                final lowestValue = sorted.first['coverageValue'] as int;
                final highestValue = sorted.last['coverageValue'] as int;

                final lowestNames = records
                    .where((r) => (r['coverageValue'] as int) == lowestValue)
                    .map((r) => r['center'] as String)
                    .join(', ');
                final highestNames = records
                    .where((r) => (r['coverageValue'] as int) == highestValue)
                    .map((r) => r['center'] as String)
                    .join(', ');

                return Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFF3F9F5), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade100)),
                        child: Row(
                          children: [
                            const Icon(Icons.emoji_events, color: primaryGreen, size: 36),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Highest Coverage', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryGreen)),
                                  const SizedBox(height: 2),
                                  Text('$highestNames (${highestValue}%)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFFFF5F5), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade100)),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled, color: Colors.red, size: 36),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Lowest Coverage', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                                  const SizedBox(height: 2),
                                  Text('$lowestNames (${lowestValue}%)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({required String title, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: isSelected ? primaryGreen : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
      ),
    );
  }

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: child,
    );
  }

  List<Widget> _buildTableHeaders(bool isRoutine) {
    final headers = isRoutine
        ? const [
            {'label': 'Area', 'width': 110.0, 'align': TextAlign.left},
            {'label': 'Eligible', 'width': 60.0, 'align': TextAlign.center},
            {'label': 'Vaccinated', 'width': 70.0, 'align': TextAlign.center},
            {'label': 'Pending', 'width': 60.0, 'align': TextAlign.center},
            {'label': 'Refused', 'width': 60.0, 'align': TextAlign.center},
            {'label': 'Missed', 'width': 60.0, 'align': TextAlign.center},
            {'label': 'Coverage', 'width': 65.0, 'align': TextAlign.center},
          ]
        : const [
            {'label': 'Area', 'width': 110.0, 'align': TextAlign.left},
            {'label': 'Target', 'width': 60.0, 'align': TextAlign.center},
            {'label': 'Vaccinated', 'width': 70.0, 'align': TextAlign.center},
            {'label': 'Missed', 'width': 60.0, 'align': TextAlign.center},
            {'label': 'Refused', 'width': 60.0, 'align': TextAlign.center},
            {'label': 'Coverage', 'width': 65.0, 'align': TextAlign.center},
          ];

    return headers.map((h) {
      return SizedBox(
        width: h['width'] as double,
        child: Text(
          h['label'] as String,
          textAlign: h['align'] as TextAlign,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: primaryGreen),
        ),
      );
    }).toList();
  }

  List<Widget> _buildTableCells(Map<String, dynamic> data, bool isRoutine) {
    Widget cell(double width, String text, {TextAlign align = TextAlign.center, Color color = Colors.black87}) {
      return SizedBox(
        width: width,
        child: Text(text, textAlign: align, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      );
    }

    if (isRoutine) {
      return [
        cell(110, data['center'] ?? '', align: TextAlign.left),
        cell(60, '${data['eligible'] ?? 0}'),
        cell(70, '${data['vaccinated'] ?? 0}', color: primaryGreen),
        cell(60, '${data['pending'] ?? 0}', color: Colors.orange),
        cell(60, '${data['refused'] ?? 0}', color: Colors.red),
        cell(60, '${data['missed'] ?? 0}'),
        cell(65, data['coverage'] ?? '0%', color: primaryGreen),
      ];
    } else {
      return [
        cell(110, data['center'] ?? '', align: TextAlign.left),
        cell(60, '${data['eligible'] ?? 0}'),
        cell(70, '${data['vaccinated'] ?? 0}', color: primaryGreen),
        cell(60, '${data['missed'] ?? 0}', color: Colors.orange),
        cell(60, '${data['refused'] ?? 0}', color: Colors.red),
        cell(65, data['coverage'] ?? '0%', color: primaryGreen),
      ];
    }
  }

  List<Widget> _buildSummaryCells(List<Map<String, dynamic>> records, bool isRoutine) {
    Widget cell(double width, String text, {TextAlign align = TextAlign.center, Color color = primaryGreen}) {
      return SizedBox(
        width: width,
        child: Text(text, textAlign: align, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      );
    }

    int totalEligible = records.fold(0, (sum, item) => sum + ((item['eligible'] ?? 0) as int));
    int totalVaccinated = records.fold(0, (sum, item) => sum + ((item['vaccinated'] ?? 0) as int));
    int totalRefused = records.fold(0, (sum, item) => sum + ((item['refused'] ?? 0) as int));
    int totalMissed = records.fold(0, (sum, item) => sum + ((item['missed'] ?? 0) as int));

    if (isRoutine) {
      int totalPending = records.fold(0, (sum, item) => sum + ((item['pending'] ?? 0) as int));
      int doseTotal = totalVaccinated + totalPending + totalRefused + totalMissed;
      String avgCoverage = doseTotal > 0 ? '${((totalVaccinated / doseTotal) * 100).toStringAsFixed(1)}%' : '0%';
      return [
        cell(110, 'Total / Average', align: TextAlign.left),
        cell(60, '$totalEligible'),
        cell(70, '$totalVaccinated'),
        cell(60, '$totalPending', color: Colors.orange),
        cell(60, '$totalRefused', color: Colors.red),
        cell(60, '$totalMissed', color: Colors.black87),
        cell(65, avgCoverage),
      ];
    } else {
      String avgCoverage = totalEligible > 0 ? '${((totalVaccinated / totalEligible) * 100).toStringAsFixed(1)}%' : '0%';
      return [
        cell(110, 'Total / Average', align: TextAlign.left),
        cell(60, '$totalEligible'),
        cell(70, '$totalVaccinated'),
        cell(60, '$totalMissed', color: Colors.orange),
        cell(60, '$totalRefused', color: Colors.red),
        cell(65, avgCoverage),
      ];
    }
  }
}