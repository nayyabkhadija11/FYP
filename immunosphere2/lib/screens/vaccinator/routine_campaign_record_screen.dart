/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../helpers/epi_schedule_helper.dart';
import '../../helpers/vaccination_status_helper.dart';
import '../../services/notification_writer.dart';

/// Routine Immunization campaign ka form.
/// (Polio / Sub National Drive ke liye purani RecordStatusScreen hi khulti hai.)
///
/// Vaccinator yahan us bache ki wo vaccines dekhta hai jo abhi due/overdue hain,
/// jo lagayi unhein tick karta hai, aur Save par:
///  - har vaccine `vaccinations` collection mein save hoti hai (Vaccination Entry jaisi),
///  - bache ka lastVaccine / nextDue / status update hota hai,
///  - campaign_assignments mein bache ka status update hota hai (campaign progress ke liye).
class RoutineCampaignRecordScreen extends StatefulWidget {
  final String assignmentDocId;
  final String childId; // children collection ka document id
  final String regNo;
  final String childName;
  final String campaignId;
  final String currentStatus;
  final String remarks;

  const RoutineCampaignRecordScreen({
    Key? key,
    required this.assignmentDocId,
    required this.childId,
    this.regNo = '',
    required this.childName,
    required this.campaignId,
    this.currentStatus = 'Pending',
    this.remarks = '',
  }) : super(key: key);

  @override
  State<RoutineCampaignRecordScreen> createState() =>
      _RoutineCampaignRecordScreenState();
}

class _PendingVaccine {
  final String name;
  final String stage;
  final bool overdue;
  final bool previouslyRefused;
  _PendingVaccine(this.name, this.stage, this.overdue, this.previouslyRefused);
}

class _RoutineCampaignRecordScreenState
    extends State<RoutineCampaignRecordScreen> {
  static const Color primaryGreen = Color(0xFF0B4D30);
  static const Color accentGreen = Color(0xFF0E7A45);

  final List<String> _statusOptions = [
    'Vaccinated',
    'Refused',
    'House Locked',
    'Child Not Available',
  ];

  late TextEditingController _remarksController;
  String _visitStatus = 'Vaccinated';
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  Map<String, dynamic> _childData = {};
  List<Map<String, dynamic>> _records = [];
  List<_PendingVaccine> _pending = [];
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _remarksController = TextEditingController(text: widget.remarks);
    if (_statusOptions.contains(widget.currentStatus)) {
      _visitStatus = widget.currentStatus;
    }
    _load();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  String _shortStage(String stage) =>
      stage.startsWith('At Birth') ? 'At Birth' : stage;

  Future<void> _load() async {
    try {
      final db = FirebaseFirestore.instance;
      final childDoc = await db.collection('children').doc(widget.childId).get();
      final data = childDoc.data();
      if (data == null) {
        setState(() {
          _loadError = 'Bache ka record nahi mila.';
          _loading = false;
        });
        return;
      }
      _childData = data;

      if (!VaccinationStatusHelper.hasValidDob(data['dob'])) {
        setState(() {
          _loadError =
              'Bache ki date of birth maujood nahi, is liye vaccine schedule nahi ban saka.';
          _loading = false;
        });
        return;
      }
      final dob = VaccinationStatusHelper.parseDob(data['dob']);

      final ids = <String>{widget.childId};
      final reg = (data['regNo'] ?? widget.regNo).toString();
      if (reg.isNotEmpty) ids.add(reg);
      final snap = await db
          .collection('vaccinations')
          .where('childId', whereIn: ids.toList())
          .get();
      _records = snap.docs.map((d) => d.data()).toList();

      final now = DateTime.now();
      final list = <_PendingVaccine>[];
      for (final stage in EpiScheduleHelper.generateEpiSchedule(dob)) {
        final due = stage['dueDate'] as DateTime;
        if (due.isAfter(now)) continue;
        for (final v in List<String>.from(stage['vaccines'])) {
          final target = VaccinationStatusHelper.normalize(v);
          bool given = false;
          bool refused = false;
          for (final r in _records) {
            final stored = VaccinationStatusHelper.normalize(
                (r['vaccineName'] ?? '').toString());
            if (stored.isEmpty) continue;
            final match = stored == target ||
                stored.contains(target) ||
                target.contains(stored);
            if (!match) continue;
            if ((r['status'] ?? '').toString().toLowerCase() == 'refused') {
              refused = true;
            } else {
              given = true;
            }
          }
          if (given) continue;
          list.add(_PendingVaccine(
            v,
            _shortStage(stage['stage'].toString()),
            now.isAfter(due.add(const Duration(days: 14))),
            refused,
          ));
        }
      }

      if (!mounted) return;
      setState(() {
        _pending = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Data load nahi ho saka: $e';
        _loading = false;
      });
    }
  }

  String _doseOf(String vaccine) {
    final m = RegExp(r'(\d)\)?$').firstMatch(vaccine.trim());
    if (m == null) return 'Dose 1';
    final n = int.parse(m.group(1)!);
    if (n <= 1) return 'Dose 1';
    if (n == 2) return 'Dose 2';
    return 'Dose 3';
  }

  Future<void> _save() async {
    final isVaccinated = _visitStatus == 'Vaccinated';
    final isRefused = _visitStatus == 'Refused';

    if ((isVaccinated || isRefused) && _selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kam se kam ek vaccine select karein.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final db = FirebaseFirestore.instance;
      final user = FirebaseAuth.instance.currentUser;
      final batch = db.batch();
      final now = DateTime.now();

      String assignmentStatus;
      String vaccineGiven = 'None';

      if (isVaccinated || isRefused) {
        final address =
            (_childData['houseAddress'] ?? _childData['address'] ?? '').toString();

        String centerName = '';
        try {
          if (user != null) {
            final u = await db.collection('users').doc(user.uid).get();
            final ud = u.data();
            if (ud != null) {
              centerName =
                  (ud['healthCenter'] ?? ud['health_center'] ?? '').toString();
            }
          }
        } catch (_) {}

        final chosen = _pending
            .where((p) => _selected.contains(p.name))
            .map((p) => p.name)
            .toList();
        final mapped = isVaccinated ? 'vaccinated' : 'refused';

        for (final name in chosen) {
          final vRef = db.collection('vaccinations').doc();
          batch.set(vRef, {
            'vaccinationId': vRef.id,
            'childId': widget.childId,
            'vaccineName': name,
            'dose': _doseOf(name),
            'administeredDate': Timestamp.fromDate(now),
            'formattedDate': DateFormat('dd MMM yyyy').format(now),
            'status': mapped,
            'remarks': _remarksController.text.trim(),
            'administeredBy': user?.uid ?? 'health_worker',
            'vaccinationAddress': address,
            'centerName': centerName,
            'campaignId': widget.campaignId,
            'createdAt': FieldValue.serverTimestamp(),
          });

          final tRef = db.collection('vaccination_tasks').doc();
          batch.set(tRef, {
            'taskId': tRef.id,
            'childId': widget.childId,
            'vaccineName': name,
            'status': mapped,
            'dueDate': Timestamp.fromDate(now),
            'administeredDate': FieldValue.serverTimestamp(),
            'administeredBy': user?.uid ?? 'health_worker',
          });
        }

        // NEW: parent ko ek hi notification (saari vaccines ek message me)
        final childLabel =
            (_childData['fullName'] ?? _childData['name'] ?? widget.childName).toString();
        NotificationWriter.addToBatch(
          batch,
          cnic: (_childData['cnic'] ?? '').toString(),
          title: isVaccinated ? 'Vaccine Administered' : 'Vaccine Refused',
          message: isVaccinated
              ? '$childLabel has received ${chosen.join(', ')} in the campaign.'
              : 'Campaign vaccination (${chosen.join(', ')}) was marked as refused for $childLabel.',
          childId: widget.childId,
        );

        final givenNames = <String>[
          ..._records
              .where((r) =>
                  (r['status'] ?? '').toString().toLowerCase() != 'refused')
              .map((r) => (r['vaccineName'] ?? '').toString()),
          if (isVaccinated) ...chosen,
        ];

        final childUpdate = <String, dynamic>{
          'lastVaccine': chosen.last,
          'status': isVaccinated ? 'Vaccinated' : 'Refused',
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (isVaccinated) {
          childUpdate['nextDue'] = EpiScheduleHelper.calculateNextDue(givenNames);
        }
        batch.update(db.collection('children').doc(widget.childId), childUpdate);

        assignmentStatus = isVaccinated ? 'Vaccinated' : 'Refused';
        vaccineGiven = isVaccinated ? chosen.join(', ') : 'None';
      } else {
        // House Locked / Child Not Available -> Missed (Polio form jaisa hi rule)
        assignmentStatus = 'Missed';

        // NEW: parent ko "Missed" notification
        NotificationWriter.addToBatch(
          batch,
          cnic: (_childData['cnic'] ?? '').toString(),
          title: 'Vaccine Missed',
          message:
              'The vaccinator visited but ${(_childData['fullName'] ?? _childData['name'] ?? widget.childName)} could not be vaccinated ($_visitStatus). Please visit your nearest BHU center.',
          childId: widget.childId,
        );
      }

      batch.update(
        db.collection('campaign_assignments').doc(widget.assignmentDocId),
        {
          'status': assignmentStatus,
          'statusReason': _visitStatus,
          'vaccineGiven': vaccineGiven,
          'fingerMark': 'N/A',
          'remarks': _remarksController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record save ho gaya!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save nahi ho saka: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          widget.childName,
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: accentGreen))
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_loadError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                )
              : _form(),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
      );

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  Widget _form() {
    final needsVaccines = _visitStatus == 'Vaccinated' || _visitStatus == 'Refused';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.vaccines_outlined, color: accentGreen, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Routine Immunization campaign: yahan likhi vaccines bache ke record mein jud jayengi.',
                    style: TextStyle(fontSize: 11.5, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Visit Status'),
          Container(
            decoration: _cardDecoration,
            child: Column(
              children: _statusOptions.map((s) {
                return RadioListTile<String>(
                  activeColor: accentGreen,
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: Text(s,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  value: s,
                  groupValue: _visitStatus,
                  onChanged: (v) {
                    if (v != null) setState(() => _visitStatus = v);
                  },
                );
              }).toList(),
            ),
          ),
          if (needsVaccines) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _sectionTitle(_visitStatus == 'Vaccinated'
                      ? 'Vaccines jo lagayi gayi'
                      : 'Vaccines jo refuse hui'),
                ),
                if (_pending.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() {
                      if (_selected.length == _pending.length) {
                        _selected.clear();
                      } else {
                        _selected
                          ..clear()
                          ..addAll(_pending.map((p) => p.name));
                      }
                    }),
                    child: Text(
                      _selected.length == _pending.length ? 'Clear' : 'Select all',
                      style: const TextStyle(color: accentGreen, fontSize: 12),
                    ),
                  ),
              ],
            ),
            Container(
              decoration: _cardDecoration,
              child: _pending.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Is bache ki tamam due vaccines pehle se lag chuki hain. '
                        'Agar bacha mila hi nahi to oopar House Locked ya Child Not Available chunein.',
                        style: TextStyle(fontSize: 12.5, color: Colors.black54),
                      ),
                    )
                  : Column(
                      children: _pending.map((p) {
                        final tags = <String>[
                          p.stage,
                          if (p.overdue) 'Overdue',
                          if (p.previouslyRefused) 'Pehle refuse hui thi',
                        ];
                        return CheckboxListTile(
                          activeColor: accentGreen,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(p.name,
                              style: const TextStyle(
                                  fontSize: 13.5, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            tags.join('  \u2022  '),
                            style: TextStyle(
                              fontSize: 11,
                              color: p.overdue ? Colors.redAccent : Colors.grey,
                            ),
                          ),
                          value: _selected.contains(p.name),
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _selected.add(p.name);
                            } else {
                              _selected.remove(p.name);
                            }
                          }),
                        );
                      }).toList(),
                    ),
            ),
          ],
          const SizedBox(height: 20),
          _sectionTitle('Remarks (Optional)'),
          TextField(
            controller: _remarksController,
            maxLines: 3,
            maxLength: 100,
            decoration: InputDecoration(
              hintText: 'Zaroorat ho to wajah likhein...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              fillColor: const Color(0xFFF4F5F7),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: accentGreen, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save & Next',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
} */
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../helpers/epi_schedule_helper.dart';
import '../../helpers/vaccination_status_helper.dart';
import '../../services/notification_writer.dart';

/// Routine Immunization campaign ka form.
/// (Polio / Sub National Drive ke liye purani RecordStatusScreen hi khulti hai.)
///
/// Vaccinator yahan us bache ki wo vaccines dekhta hai jo abhi due/overdue hain,
/// jo lagayi unhein tick karta hai, aur Save par:
///  - har vaccine `vaccinations` collection mein save hoti hai (Vaccination Entry jaisi),
///  - bache ka lastVaccine / nextDue / status update hota hai,
///  - campaign_assignments mein bache ka status update hota hai (campaign progress ke liye).
class RoutineCampaignRecordScreen extends StatefulWidget {
  final String assignmentDocId;
  final String childId; // children collection ka document id
  final String regNo;
  final String childName;
  final String campaignId;
  final String currentStatus;
  final String remarks;

  const RoutineCampaignRecordScreen({
    Key? key,
    required this.assignmentDocId,
    required this.childId,
    this.regNo = '',
    required this.childName,
    required this.campaignId,
    this.currentStatus = 'Pending',
    this.remarks = '',
  }) : super(key: key);

  @override
  State<RoutineCampaignRecordScreen> createState() =>
      _RoutineCampaignRecordScreenState();
}

class _PendingVaccine {
  final String name;
  final String stage;
  final bool overdue;
  final bool previouslyRefused;
  _PendingVaccine(this.name, this.stage, this.overdue, this.previouslyRefused);
}

class _RoutineCampaignRecordScreenState
    extends State<RoutineCampaignRecordScreen> {
  static const Color primaryGreen = Color(0xFF0B4D30);
  static const Color accentGreen = Color(0xFF0E7A45);

  final List<String> _statusOptions = [
    'Vaccinated',
    'Refused',
    'House Locked',
    'Child Not Available',
  ];

  late TextEditingController _remarksController;
  String _visitStatus = 'Vaccinated';
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  Map<String, dynamic> _childData = {};
  List<Map<String, dynamic>> _records = [];
  List<_PendingVaccine> _pending = [];
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _remarksController = TextEditingController(text: widget.remarks);
    if (_statusOptions.contains(widget.currentStatus)) {
      _visitStatus = widget.currentStatus;
    }
    _load();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  String _shortStage(String stage) =>
      stage.startsWith('At Birth') ? 'At Birth' : stage;

  Future<void> _load() async {
    try {
      final db = FirebaseFirestore.instance;
      final childDoc = await db.collection('children').doc(widget.childId).get();
      final data = childDoc.data();
      if (data == null) {
        setState(() {
          _loadError = 'Bache ka record nahi mila.';
          _loading = false;
        });
        return;
      }
      _childData = data;

      if (!VaccinationStatusHelper.hasValidDob(data['dob'])) {
        setState(() {
          _loadError =
              'Bache ki date of birth maujood nahi, is liye vaccine schedule nahi ban saka.';
          _loading = false;
        });
        return;
      }
      final dob = VaccinationStatusHelper.parseDob(data['dob']);

      final ids = <String>{widget.childId};
      final reg = (data['regNo'] ?? widget.regNo).toString();
      if (reg.isNotEmpty) ids.add(reg);
      final snap = await db
          .collection('vaccinations')
          .where('childId', whereIn: ids.toList())
          .get();
      _records = snap.docs.map((d) => d.data()).toList();

      final now = DateTime.now();
      final list = <_PendingVaccine>[];
      for (final stage in EpiScheduleHelper.generateEpiSchedule(dob)) {
        final due = stage['dueDate'] as DateTime;
        if (due.isAfter(now)) continue;
        for (final v in List<String>.from(stage['vaccines'])) {
          final target = VaccinationStatusHelper.normalize(v);
          bool given = false;
          bool refused = false;
          for (final r in _records) {
            final stored = VaccinationStatusHelper.normalize(
                (r['vaccineName'] ?? '').toString());
            if (stored.isEmpty) continue;
            final match = stored == target ||
                stored.contains(target) ||
                target.contains(stored);
            if (!match) continue;
            if ((r['status'] ?? '').toString().toLowerCase() == 'refused') {
              refused = true;
            } else {
              given = true;
            }
          }
          if (given) continue;
          list.add(_PendingVaccine(
            v,
            _shortStage(stage['stage'].toString()),
            now.isAfter(due.add(const Duration(days: 14))),
            refused,
          ));
        }
      }

      if (!mounted) return;
      setState(() {
        _pending = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Data load nahi ho saka: $e';
        _loading = false;
      });
    }
  }

  String _doseOf(String vaccine) {
    final m = RegExp(r'(\d)\)?$').firstMatch(vaccine.trim());
    if (m == null) return 'Dose 1';
    final n = int.parse(m.group(1)!);
    if (n <= 1) return 'Dose 1';
    if (n == 2) return 'Dose 2';
    return 'Dose 3';
  }

  Future<void> _save() async {
    final isVaccinated = _visitStatus == 'Vaccinated';
    final isRefused = _visitStatus == 'Refused';

    if ((isVaccinated || isRefused) && _selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kam se kam ek vaccine select karein.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final db = FirebaseFirestore.instance;
      final user = FirebaseAuth.instance.currentUser;
      final batch = db.batch();
      final now = DateTime.now();

      String assignmentStatus;
      String vaccineGiven = 'None';

      if (isVaccinated || isRefused) {
        final address =
            (_childData['houseAddress'] ?? _childData['address'] ?? '').toString();

        // Campaign ghar par hoti hai, is liye center khali rakhte hain.
        // Certificate mein phir bache ke ghar ka address dikhega.
        const String centerName = '';

        final chosen = _pending
            .where((p) => _selected.contains(p.name))
            .map((p) => p.name)
            .toList();
        final mapped = isVaccinated ? 'vaccinated' : 'refused';

        for (final name in chosen) {
          final vRef = db.collection('vaccinations').doc();
          batch.set(vRef, {
            'vaccinationId': vRef.id,
            'childId': widget.childId,
            'vaccineName': name,
            'dose': _doseOf(name),
            'administeredDate': Timestamp.fromDate(now),
            'formattedDate': DateFormat('dd MMM yyyy').format(now),
            'status': mapped,
            'remarks': _remarksController.text.trim(),
            'administeredBy': user?.uid ?? 'health_worker',
            'vaccinationAddress': address,
            'centerName': centerName,
            'campaignId': widget.campaignId,
            'createdAt': FieldValue.serverTimestamp(),
          });

          final tRef = db.collection('vaccination_tasks').doc();
          batch.set(tRef, {
            'taskId': tRef.id,
            'childId': widget.childId,
            'vaccineName': name,
            'status': mapped,
            'dueDate': Timestamp.fromDate(now),
            'administeredDate': FieldValue.serverTimestamp(),
            'administeredBy': user?.uid ?? 'health_worker',
          });
        }

        // NEW: parent ko ek hi notification (saari vaccines ek message me)
        final childLabel =
            (_childData['fullName'] ?? _childData['name'] ?? widget.childName).toString();
        NotificationWriter.addToBatch(
          batch,
          cnic: (_childData['cnic'] ?? '').toString(),
          title: isVaccinated ? 'Vaccine Administered' : 'Vaccine Refused',
          message: isVaccinated
              ? '$childLabel has received ${chosen.join(', ')} in the campaign.'
              : 'Campaign vaccination (${chosen.join(', ')}) was marked as refused for $childLabel.',
          childId: widget.childId,
        );

        final givenNames = <String>[
          ..._records
              .where((r) =>
                  (r['status'] ?? '').toString().toLowerCase() != 'refused')
              .map((r) => (r['vaccineName'] ?? '').toString()),
          if (isVaccinated) ...chosen,
        ];

        final childUpdate = <String, dynamic>{
          'lastVaccine': chosen.last,
          'status': isVaccinated ? 'Vaccinated' : 'Refused',
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (isVaccinated) {
          childUpdate['nextDue'] = EpiScheduleHelper.calculateNextDue(givenNames);
        }
        batch.update(db.collection('children').doc(widget.childId), childUpdate);

        assignmentStatus = isVaccinated ? 'Vaccinated' : 'Refused';
        vaccineGiven = isVaccinated ? chosen.join(', ') : 'None';
      } else {
        // House Locked / Child Not Available -> Missed (Polio form jaisa hi rule)
        assignmentStatus = 'Missed';

        // NEW: parent ko "Missed" notification
        NotificationWriter.addToBatch(
          batch,
          cnic: (_childData['cnic'] ?? '').toString(),
          title: 'Vaccine Missed',
          message:
              'The vaccinator visited but ${(_childData['fullName'] ?? _childData['name'] ?? widget.childName)} could not be vaccinated ($_visitStatus). Please visit your nearest BHU center.',
          childId: widget.childId,
        );
      }

      batch.update(
        db.collection('campaign_assignments').doc(widget.assignmentDocId),
        {
          'status': assignmentStatus,
          'statusReason': _visitStatus,
          'vaccineGiven': vaccineGiven,
          'fingerMark': 'N/A',
          'remarks': _remarksController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record save ho gaya!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save nahi ho saka: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          widget.childName,
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: accentGreen))
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_loadError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                )
              : _form(),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
      );

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  Widget _form() {
    final needsVaccines = _visitStatus == 'Vaccinated' || _visitStatus == 'Refused';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.vaccines_outlined, color: accentGreen, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Routine Immunization campaign: yahan likhi vaccines bache ke record mein jud jayengi.',
                    style: TextStyle(fontSize: 11.5, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Visit Status'),
          Container(
            decoration: _cardDecoration,
            child: Column(
              children: _statusOptions.map((s) {
                return RadioListTile<String>(
                  activeColor: accentGreen,
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: Text(s,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  value: s,
                  groupValue: _visitStatus,
                  onChanged: (v) {
                    if (v != null) setState(() => _visitStatus = v);
                  },
                );
              }).toList(),
            ),
          ),
          if (needsVaccines) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _sectionTitle(_visitStatus == 'Vaccinated'
                      ? 'Vaccines jo lagayi gayi'
                      : 'Vaccines jo refuse hui'),
                ),
                if (_pending.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() {
                      if (_selected.length == _pending.length) {
                        _selected.clear();
                      } else {
                        _selected
                          ..clear()
                          ..addAll(_pending.map((p) => p.name));
                      }
                    }),
                    child: Text(
                      _selected.length == _pending.length ? 'Clear' : 'Select all',
                      style: const TextStyle(color: accentGreen, fontSize: 12),
                    ),
                  ),
              ],
            ),
            Container(
              decoration: _cardDecoration,
              child: _pending.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Is bache ki tamam due vaccines pehle se lag chuki hain. '
                        'Agar bacha mila hi nahi to oopar House Locked ya Child Not Available chunein.',
                        style: TextStyle(fontSize: 12.5, color: Colors.black54),
                      ),
                    )
                  : Column(
                      children: _pending.map((p) {
                        final tags = <String>[
                          p.stage,
                          if (p.overdue) 'Overdue',
                          if (p.previouslyRefused) 'Pehle refuse hui thi',
                        ];
                        return CheckboxListTile(
                          activeColor: accentGreen,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(p.name,
                              style: const TextStyle(
                                  fontSize: 13.5, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            tags.join('  \u2022  '),
                            style: TextStyle(
                              fontSize: 11,
                              color: p.overdue ? Colors.redAccent : Colors.grey,
                            ),
                          ),
                          value: _selected.contains(p.name),
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _selected.add(p.name);
                            } else {
                              _selected.remove(p.name);
                            }
                          }),
                        );
                      }).toList(),
                    ),
            ),
          ],
          const SizedBox(height: 20),
          _sectionTitle('Remarks (Optional)'),
          TextField(
            controller: _remarksController,
            maxLines: 3,
            maxLength: 100,
            decoration: InputDecoration(
              hintText: 'Zaroorat ho to wajah likhein...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              fillColor: const Color(0xFFF4F5F7),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: accentGreen, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save & Next',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}