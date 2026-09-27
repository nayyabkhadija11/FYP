import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:immunosphere2/helpers/epi_schedule_helper.dart';

class VaccineDetailsScreen extends StatelessWidget {
  final String childId;
  final String vaccineName; // e.g. "BCG", "Pentavalent-3"
  final String stageLabel;  // e.g. "At Birth (Within 24 Hours)", "14 Weeks"
  final bool isCompleted;   // true if opened from the Completed tab

  const VaccineDetailsScreen({
    Key? key,
    required this.childId,
    required this.vaccineName,
    required this.stageLabel,
    required this.isCompleted,
  }) : super(key: key);

  static const Color darkGreen = Color(0xFF0B4D30);
  static const Color primaryGreen = Color(0xFF0E7A45);
  static const Color lightGreenBg = Color(0xFFE5F7ED);

  String _normalize(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  DateTime _parseDob(dynamic dobVal) {
    if (dobVal is Timestamp) return dobVal.toDate();
    if (dobVal is DateTime) return dobVal;
    if (dobVal is String && dobVal.trim().isNotEmpty) {
      return DateTime.tryParse(dobVal) ?? DateTime.now();
    }
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: Column(
          children: [
            // Slim green top bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: darkGreen,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Center(
                    child: Text(
                      'Vaccine Details',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                  ),
                  Positioned(
                    left: 4,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('vaccinations')
                    .where('childId', isEqualTo: childId)
                    .snapshots(),
                builder: (context, vaccSnap) {
                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('children').doc(childId).snapshots(),
                    builder: (context, childSnap) {
                      // ---- Find the matching given-record (if any) ----
                      Map<String, dynamic>? matchedRecord;
                      if (vaccSnap.hasData) {
                        final targetNorm = _normalize(vaccineName);
                        for (var doc in vaccSnap.data!.docs) {
                          final d = doc.data() as Map<String, dynamic>;
                          final storedNorm = _normalize((d['vaccineName'] ?? '').toString());
                          final matches = storedNorm == targetNorm ||
                              storedNorm.contains(targetNorm) ||
                              targetNorm.contains(storedNorm);
                          final status = (d['status'] ?? '').toString().toLowerCase();
                          if (matches && status != 'refused') {
                            matchedRecord = d;
                            break;
                          }
                        }
                      }

                      // ---- Compute "Next Dose" from the EPI schedule ----
                      String nextDoseText = '';
                      if (childSnap.hasData && childSnap.data!.exists) {
                        final childData = childSnap.data!.data() as Map<String, dynamic>;
                        final dob = _parseDob(childData['dob'] ?? childData['dateOfBirth']);
                        final schedule = EpiScheduleHelper.generateEpiSchedule(dob);
                        final targetNorm = _normalize(vaccineName);
                        int? stageIndex;
                        for (int i = 0; i < schedule.length; i++) {
                          final vaccines = List<String>.from(schedule[i]['vaccines']);
                          if (vaccines.any((v) => _normalize(v) == targetNorm)) {
                            stageIndex = i;
                            break;
                          }
                        }
                        if (stageIndex != null && stageIndex + 1 < schedule.length) {
                          final nextStage = schedule[stageIndex + 1];
                          final nextVaccines = List<String>.from(nextStage['vaccines']).join(', ');
                          final nextDue = DateFormat('dd MMM yyyy').format(nextStage['dueDate']);
                          nextDoseText = '$nextVaccines • Due on $nextDue';
                        } else if (stageIndex != null) {
                          nextDoseText = 'All routine doses completed';
                        }
                      }

                      final bool given = matchedRecord != null;
                      final String statusBadge = given ? 'Completed' : 'Upcoming';
                      final Color badgeColor = given ? primaryGreen : const Color(0xFF0284C7);
                      final Color badgeBg = given ? lightGreenBg : const Color(0xFFE0F2FE);

                      String? dateText;
                      String? centerText;
                      String? addressText;
                      String? remarksText;
                      String? administeredByUid;

                      if (given) {
                        final rawDate = matchedRecord!['administeredDate'] ?? matchedRecord['dateGiven'];
                        if (rawDate is Timestamp) {
                          dateText = DateFormat('dd MMM yyyy').format(rawDate.toDate());
                        } else if (rawDate is String && rawDate.isNotEmpty) {
                          dateText = rawDate;
                        }
                        final center = (matchedRecord['centerName'] ?? '').toString();
                        if (center.isNotEmpty) centerText = center;
                        final addr = (matchedRecord['vaccinationAddress'] ?? '').toString();
                        if (addr.isNotEmpty) addressText = addr;
                        final rem = (matchedRecord['remarks'] ?? '').toString();
                        if (rem.isNotEmpty) remarksText = rem;
                        administeredByUid = matchedRecord['administeredBy']?.toString();
                      }

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: lightGreenBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.vaccines_outlined, color: primaryGreen, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vaccineName,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                        Text('Routine Vaccine', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                  statusBadge,
                                  style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Divider(height: 28),

                              if (given) ...[
                                if (dateText != null) _detailRow(Icons.calendar_today_outlined, 'Vaccination Date', dateText),
                                if (centerText != null) _detailRow(Icons.local_hospital_outlined, 'Vaccinated At', centerText),
                                if (addressText != null) _detailRow(Icons.location_on_outlined, 'Vaccination Address', addressText),
                                if (administeredByUid != null)
                                  FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance.collection('users').doc(administeredByUid).get(),
                                    builder: (context, userSnap) {
                                      String vaccinatorName = '';
                                      if (userSnap.hasData && userSnap.data!.exists) {
                                        final u = userSnap.data!.data() as Map<String, dynamic>;
                                        vaccinatorName = (u['fullName'] ?? u['name'] ?? '').toString();
                                      }
                                      if (vaccinatorName.isEmpty) return const SizedBox.shrink();
                                      return _detailRow(Icons.person_outline, 'Vaccinator', vaccinatorName);
                                    },
                                  ),
                                if (remarksText != null) _detailRow(Icons.note_alt_outlined, 'Remarks', remarksText),
                              ] else ...[
                                _detailRow(Icons.event_outlined, 'Stage', stageLabel),
                                _detailRow(Icons.info_outline, 'Status', 'Not yet vaccinated'),
                              ],

                              if (nextDoseText.isNotEmpty) ...[
                                const Divider(height: 28),
                                _detailRow(Icons.arrow_forward_outlined, 'Next Dose', nextDoseText, valueColor: primaryGreen),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color valueColor = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}