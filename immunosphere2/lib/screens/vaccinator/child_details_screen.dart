/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:immunosphere2/helpers/epi_schedule_helper.dart';
import 'vaccination_entry_screen.dart';
import 'record_status_screen.dart';

class ChildDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> childData;

  const ChildDetailsScreen({Key? key, required this.childData}) : super(key: key);

  @override
  State<ChildDetailsScreen> createState() => _ChildDetailsScreenState();
}

class _ChildDetailsScreenState extends State<ChildDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color primaryEmerald = Color(0xFF0A6C5D);
  static const Color secondaryEmerald = Color(0xFF10B981);
  static const Color accentGreen = Color(0xFF059669);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color bgCanvas = Color(0xFFF8FAFC);

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

  DateTime _parseDob(dynamic dobVal) {
    if (dobVal is Timestamp) return dobVal.toDate();
    if (dobVal is DateTime) return dobVal;
    if (dobVal is String && dobVal.trim().isNotEmpty) {
      return DateTime.tryParse(dobVal) ?? DateTime.now();
    }
    return DateTime.now();
  }

  String _getFormattedAge(dynamic dobVal) {
    if (dobVal == null) return 'N/A';
    DateTime dob = _parseDob(dobVal);

    final now = DateTime.now();
    int years = now.year - dob.year;
    int months = now.month - dob.month;
    if (months < 0) {
      years--;
      months += 12;
    }
    final formattedDate = DateFormat('dd MMM yyyy').format(dob);
    return '$formattedDate (${years}Y ${months}M)';
  }

  String _normalize(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  void _showQrCodeDialog(BuildContext context, String childId, String childName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Text(
            childName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.qr_code_2, size: 160, color: primaryEmerald),
            ),
            const SizedBox(height: 12),
            Text('ID: $childId', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: primaryEmerald, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String initialDocId = widget.childData['docId'] ??
        widget.childData['id'] ??
        widget.childData['documentId'] ??
        '';

    return StreamBuilder<DocumentSnapshot>(
      key: ValueKey(initialDocId),
      stream: initialDocId.isNotEmpty
          ? FirebaseFirestore.instance.collection('children').doc(initialDocId).snapshots()
          : null,
      builder: (context, snapshot) {
        Map<String, dynamic> data = Map<String, dynamic>.from(widget.childData);

        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          data = snapshot.data!.data() as Map<String, dynamic>;
          data['docId'] = snapshot.data!.id;
        }

        final String childName = data['fullName'] ?? data['name'] ?? data['childName'] ?? 'Child Record';
        final String childRegNo = data['regNo'] ?? data['childId'] ?? 'CH-001246';
        final String firestoreDocId = data['docId'] ?? initialDocId;
        final String status = data['status'] ?? 'VACCINATED';

        final dynamic dobVal = data['dob'];
        final String gender = data['gender'] ?? 'Female';
        final String motherName = data['motherName'] ?? 'Zainab';
        final String cnic = data['cnic'] ?? data['guardianCnic'] ?? data['motherCnic'] ?? '35202-7654321-9';
        final String phone = data['phoneNumber'] ?? data['phone'] ?? 'N/A';
        final String village = data['village'] ?? data['address'] ?? 'N/A';
        final String nextDue = data['nextDue'] ?? 'OPV 3 / Pentavalent 3';

        return Scaffold(
          backgroundColor: bgCanvas,
          appBar: AppBar(
            backgroundColor: primaryEmerald,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_2, color: Colors.white, size: 28),
                onPressed: () => _showQrCodeDialog(context, childRegNo, childName),
              ),
            ],
          ),
          body: Column(
            children: [
              // Header Banner
              Container(
                color: primaryEmerald,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(Icons.child_care, size: 38, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            childName,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: $childRegNo',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: status.toUpperCase() == 'REFUSED'
                                  ? dangerRed
                                  : status.toUpperCase() == 'VACCINATED'
                                      ? accentGreen
                                      : warningAmber,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: primaryEmerald,
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: primaryEmerald,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Routine History'),
                    Tab(text: 'Polio History'),
                  ],
                ),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(dobVal, gender, motherName, cnic, phone, village, nextDue),
                    _buildRoutineHistoryTab(firestoreDocId, childRegNo, dobVal),
                    _buildPolioHistoryTab(firestoreDocId, childRegNo),
                  ],
                ),
              ),
            ],
          ),

          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VaccinationEntryScreen(childData: data),
                        ),
                      );
                    },
                    icon: const Icon(Icons.vaccines, color: Colors.white, size: 18),
                    label: const Text(
                      'Record Vaccine',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryEmerald,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecordStatusScreen(childName: childName),
                        ),
                      );
                    },
                    icon: const Icon(Icons.assignment_turned_in, color: Colors.white, size: 18),
                    label: const Text(
                      'Record Campaign Status',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryEmerald,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(
    dynamic dobVal,
    String gender,
    String motherName,
    String cnic,
    String phone,
    String village,
    String nextDue,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Next Vaccine Due', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        nextDue,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: warningAmber),
                  ),
                  child: const Text('Scheduled', style: TextStyle(color: warningAmber, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const Text(
            'Basic Information',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
          ),
          const SizedBox(height: 14),

          _buildInfoRow(Icons.calendar_today_outlined, 'Date of Birth', _getFormattedAge(dobVal)),
          _buildInfoRow(Icons.person_outline, 'Gender', gender),
          _buildInfoRow(Icons.face_outlined, 'Mother Name', motherName),
          _buildInfoRow(Icons.card_membership_outlined, 'CNIC / Guardian', cnic),
          _buildInfoRow(Icons.phone_outlined, 'Phone Number', phone),
          _buildInfoRow(Icons.location_on_outlined, 'Village / Area', village),
        ],
      ),
    );
  }

  Widget _buildRoutineHistoryTab(String firestoreDocId, String childRegNo, dynamic dobVal) {
    DateTime childDob = _parseDob(dobVal);
    final schedule = EpiScheduleHelper.generateEpiSchedule(childDob);
    final now = DateTime.now();

    List<String> queryTargetIds = [firestoreDocId, childRegNo].where((id) => id.trim().isNotEmpty).toList();

    if (queryTargetIds.isEmpty) {
      return const Center(child: Text('Invalid Child Document ID', style: TextStyle(color: Colors.grey)));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vaccinations')
          .where('childId', whereIn: queryTargetIds)
          .snapshots(),
      builder: (context, snapshot) {
        List<Map<String, dynamic>> givenRecords = [];

        if (snapshot.hasData && snapshot.data != null) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;

            dynamic rawDate = data['dateGiven'] ?? data['administeredDate'] ?? data['createdAt'];
            String formattedDateStr = 'Done';

            if (rawDate is Timestamp) {
              formattedDateStr = DateFormat('dd MMM yyyy').format(rawDate.toDate());
            } else if (rawDate is DateTime) {
              formattedDateStr = DateFormat('dd MMM yyyy').format(rawDate);
            } else if (rawDate is String && rawDate.isNotEmpty) {
              formattedDateStr = rawDate;
            }

            givenRecords.add({
              'vaccineName': (data['vaccineName'] ?? '').toString(),
              'dateGiven': formattedDateStr,
              'status': (data['status'] ?? 'Vaccinated').toString().toLowerCase(), 
            });
          }
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: schedule.length,
          itemBuilder: (context, index) {
            final stageItem = schedule[index];
            final String stageName = stageItem['stage'];
            final DateTime dueDate = stageItem['dueDate'];
            final List<String> vaccines = List<String>.from(stageItem['vaccines']);

            bool isStageDueOrPast = now.isAfter(dueDate) || now.isAtSameMomentAs(dueDate);
            String formattedDueDate = DateFormat('dd MMM yyyy').format(dueDate);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: isStageDueOrPast,
                  title: Text(
                    stageName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isStageDueOrPast ? Colors.black87 : Colors.grey.shade600,
                    ),
                  ),
                  subtitle: Text(
                    'Due Date: $formattedDueDate',
                    style: TextStyle(fontSize: 11, color: isStageDueOrPast ? primaryEmerald : Colors.grey),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isStageDueOrPast ? const Color(0xFFE6F4F1) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isStageDueOrPast ? 'Due / Active' : 'Upcoming',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isStageDueOrPast ? primaryEmerald : Colors.grey,
                      ),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        children: vaccines.map((vaccine) {
                          String? matchedDate;
                          String matchedStatus = '';
                          String targetNormalized = _normalize(vaccine);

                          bool isGiven = givenRecords.any((record) {
                            String storedNormalized = _normalize(record['vaccineName']);

                            bool matches = storedNormalized == targetNormalized ||
                                storedNormalized.contains(targetNormalized) ||
                                targetNormalized.contains(storedNormalized);

                            if (matches) {
                              matchedDate = record['dateGiven'];
                              matchedStatus = record['status'];
                            }
                            return matches;
                          });

                          bool isRefused = isGiven && matchedStatus == 'refused';
                          bool isMissed = !isGiven && now.isAfter(dueDate.add(const Duration(days: 14)));
                          bool isDueNow = !isGiven && isStageDueOrPast && !isMissed;

                          Color badgeColor;
                          String statusText;

                          if (isRefused) {
                            badgeColor = dangerRed;
                            statusText = 'Refused';
                          } else if (isGiven) {
                            badgeColor = accentGreen;
                            statusText = 'Given (${matchedDate ?? 'Done'})';
                          } else if (isMissed) {
                            badgeColor = dangerRed;
                            statusText = 'Missed';
                          } else if (isDueNow) {
                            badgeColor = warningAmber;
                            statusText = 'Due Now';
                          } else {
                            badgeColor = Colors.grey;
                            statusText = 'Upcoming';
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isRefused || isMissed
                                          ? Icons.cancel
                                          : isGiven
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                      size: 16,
                                      color: badgeColor,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(vaccine, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(statusText, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPolioHistoryTab(String firestoreDocId, String childRegNo) {
    List<String> queryTargetIds = [firestoreDocId, childRegNo].where((id) => id.trim().isNotEmpty).toList();

    if (queryTargetIds.isEmpty) {
      return const Center(child: Text('Invalid Child Document ID', style: TextStyle(color: Colors.grey)));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('campaign_records')
          .where('childId', whereIn: queryTargetIds)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primaryEmerald));
        }
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text('No polio/campaign records found.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            dynamic rawDate = data['dateGiven'] ?? data['date'] ?? data['createdAt'];
            String formattedDate = 'N/A';
            if (rawDate is Timestamp) {
              formattedDate = DateFormat('dd MMM yyyy').format(rawDate.toDate());
            } else if (rawDate is String && rawDate.isNotEmpty) {
              formattedDate = rawDate;
            }

            String recordStatus = (data['status'] ?? 'Vaccinated').toString();
            Color statusColor = accentGreen;
            if (recordStatus.toLowerCase() == 'refused') {
              statusColor = dangerRed;
            } else if (recordStatus.toLowerCase() == 'missed') {
              statusColor = warningAmber;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: primaryEmerald, size: 20),
                          const SizedBox(width: 8),
                          Text(data['campaignName'] ?? 'National Polio Campaign', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                        ],
                      ),
                      Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['vaccineName'] ?? data['vaccine'] ?? 'OPV Drops', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text('Dose: ${data['dose'] ?? 'N/A'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(recordStatus, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 14),
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
} */
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:immunosphere2/helpers/epi_schedule_helper.dart';
import 'package:immunosphere2/models/campaign_model.dart';
import 'vaccination_entry_screen.dart';
import 'record_status_screen.dart';

class ChildDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> childData;

  const ChildDetailsScreen({Key? key, required this.childData}) : super(key: key);

  @override
  State<ChildDetailsScreen> createState() => _ChildDetailsScreenState();
}

class _ChildDetailsScreenState extends State<ChildDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // App-wide deep green theme (same as the rest of the app)
  static const Color primaryGreen = Color(0xFF0B4D30);
  static const Color accentGreen = Color(0xFF0E7A45);
  static const Color lightGreenBg = Color(0xFFE5F7ED);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color bgCanvas = Color(0xFFF8FAFC);

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

  DateTime _parseDob(dynamic dobVal) {
    if (dobVal is Timestamp) return dobVal.toDate();
    if (dobVal is DateTime) return dobVal;
    if (dobVal is String && dobVal.trim().isNotEmpty) {
      return DateTime.tryParse(dobVal) ?? DateTime.now();
    }
    return DateTime.now();
  }

  String _getFormattedAge(dynamic dobVal) {
    if (dobVal == null) return 'N/A';
    DateTime dob = _parseDob(dobVal);

    final now = DateTime.now();
    int years = now.year - dob.year;
    int months = now.month - dob.month;
    if (months < 0) {
      years--;
      months += 12;
    }
    final formattedDate = DateFormat('dd MMM yyyy').format(dob);
    return '$formattedDate (${years}Y ${months}M)';
  }

  // Short age text for the header, e.g. "2 years 3 months".
  String _getShortAge(dynamic dobVal) {
    if (dobVal == null) return 'N/A';
    DateTime dob = _parseDob(dobVal);

    final now = DateTime.now();
    int years = now.year - dob.year;
    int months = now.month - dob.month;
    if (months < 0) {
      years--;
      months += 12;
    }
    final parts = <String>[];
    if (years > 0) parts.add('$years year${years > 1 ? 's' : ''}');
    if (months > 0 || parts.isEmpty) parts.add('$months month${months != 1 ? 's' : ''}');
    return parts.join(' ');
  }

  String _normalize(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  void _showQrCodeDialog(BuildContext context, String childId, String childName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Center(
          child: Text(
            childName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(14),
              ),
              child: childId.trim().isEmpty
                  ? const Icon(Icons.qr_code_2, size: 150, color: Colors.grey)
                  : QrImageView(
                      data: childId,
                      version: QrVersions.auto,
                      size: 170.0,
                      foregroundColor: const Color(0xFF1F2937),
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    ),
            ),
            const SizedBox(height: 10),
            Text('ID: $childId',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _genderEmoji(String gender) {
    final g = gender.toLowerCase();
    if (g == 'male' || g == 'boy') return '\u{1F466}';
    if (g == 'female' || g == 'girl') return '\u{1F467}';
    return '\u{1F9D2}';
  }

  IconData _genderIcon(String gender) {
    final g = gender.toLowerCase();
    if (g == 'male' || g == 'boy') return Icons.male;
    if (g == 'female' || g == 'girl') return Icons.female;
    return Icons.person_outline;
  }

  // "Record Campaign Status" needs the child's campaign_assignments doc
  // (that is the doc RecordStatusScreen updates). A child only has one when a
  // supervisor assigned them to a campaign under this vaccinator, so look it up
  // here instead of opening the screen with no document to save to.
  // Prefers a campaign that is running now; otherwise the most recent one.
  Future<void> _openRecordCampaignStatus(
    BuildContext context,
    List<String> childIds,
    String childName,
  ) async {
    final ids = childIds.where((id) => id.trim().isNotEmpty).toSet().toList();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (ids.isEmpty || uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Child ya vaccinator ki pehchan nahi mili.'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('campaign_assignments')
          .where('childId', whereIn: ids)
          .where('vaccinatorId', isEqualTo: uid)
          .get();

      if (!mounted) return;

      if (snap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ye bacha aap ko kisi campaign mein assign nahi hai.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final now = DateTime.now();
      QueryDocumentSnapshot? activePick;
      DateTime? activeStart;
      QueryDocumentSnapshot? latestPick;
      DateTime? latestStart;

      for (var doc in snap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final cid = (d['campaignId'] ?? '').toString();
        DateTime? start;
        DateTime? end;
        String campaignStatus = '';

        if (cid.isNotEmpty) {
          final cDoc = await FirebaseFirestore.instance.collection('campaigns').doc(cid).get();
          if (cDoc.exists && cDoc.data() != null) {
            final c = CampaignModel.fromMap(cDoc.data()!, cDoc.id);
            start = c.startDate;
            end = c.endDate;
            campaignStatus = c.status;
          }
        }

        // End date is saved as a date (midnight), so count the whole last day.
        final isActive = start != null &&
            end != null &&
            campaignStatus != 'completed' &&
            !now.isBefore(start) &&
            now.isBefore(end.add(const Duration(days: 1)));
        final sortKey = start ?? DateTime(2000);

        if (isActive && (activePick == null || sortKey.isAfter(activeStart!))) {
          activePick = doc;
          activeStart = sortKey;
        }
        if (latestPick == null || sortKey.isAfter(latestStart!)) {
          latestPick = doc;
          latestStart = sortKey;
        }
      }

      if (!mounted) return;

      final target = activePick ?? latestPick!;
      final tData = target.data() as Map<String, dynamic>;
      final String assignStatus = (tData['status'] ?? 'Pending').toString();
      final String reason = (tData['statusReason'] ?? '').toString();
      // Same display rule the campaign child list uses.
      final String displayStatus =
          (assignStatus == 'Missed' && reason.isNotEmpty) ? reason : assignStatus;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecordStatusScreen(
            assignmentDocId: target.id,
            childName: childName,
            currentStatus: displayStatus,
            vaccineGiven: (tData['vaccineGiven'] ?? 'OPV Drops').toString(),
            fingerMark: (tData['fingerMark'] ?? 'Done').toString(),
            remarks: (tData['remarks'] ?? '').toString(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Campaign load nahi ho saki: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String initialDocId = widget.childData['docId'] ??
        widget.childData['id'] ??
        widget.childData['documentId'] ??
        '';

    // Keep text size consistent: system font scaling is allowed only within a
    // small range so the layout never looks oversized on any phone.
    final mq = MediaQuery.of(context);
    final clampedMq = mq.copyWith(
      textScaler: mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.05),
    );

    return MediaQuery(
      data: clampedMq,
      child: StreamBuilder<DocumentSnapshot>(
        key: ValueKey(initialDocId),
        stream: initialDocId.isNotEmpty
            ? FirebaseFirestore.instance.collection('children').doc(initialDocId).snapshots()
            : null,
        builder: (context, snapshot) {
          Map<String, dynamic> data = Map<String, dynamic>.from(widget.childData);

          if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
            data = snapshot.data!.data() as Map<String, dynamic>;
            data['docId'] = snapshot.data!.id;
          }

          final String childName = data['fullName'] ?? data['name'] ?? data['childName'] ?? 'Child Record';
          // Left empty (not a made-up ID) when missing; shown as N/A in the UI.
          final String childRegNo = (data['regNo'] ?? data['childId'] ?? initialDocId).toString();
          final String displayRegNo = childRegNo.isNotEmpty ? childRegNo : 'N/A';
          final String firestoreDocId = data['docId'] ?? initialDocId;
          // Same value the parent's QR encodes (the child's document id).
          final String qrId = firestoreDocId.isNotEmpty ? firestoreDocId : childRegNo;
          final String status = data['status'] ?? 'PENDING';

          final dynamic dobVal = data['dob'];
          final String gender = data['gender'] ?? 'N/A';
          final String motherName = data['motherName'] ?? 'N/A';
          final String cnic = data['cnic'] ?? data['guardianCnic'] ?? data['motherCnic'] ?? 'N/A';
          final String phone = data['phoneNumber'] ?? data['phone'] ?? 'N/A';
          final String village = data['village'] ?? data['address'] ?? 'N/A';
          final String nextDue = data['nextDue'] ?? 'N/A';

          return Scaffold(
            backgroundColor: primaryGreen,
            body: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0B4D30), Color(0xFF0F6B42)],
                  ),
                ),
                child: Column(
                  children: [
                    _buildHeader(
                      context,
                      childName: childName,
                      childRegNo: displayRegNo,
                      qrId: qrId,
                      status: status,
                      dobVal: dobVal,
                      gender: gender,
                    ),

                    // White rounded sheet holding the tabs + content
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: Container(
                          color: bgCanvas,
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                ),
                                child: TabBar(
                                  controller: _tabController,
                                  labelColor: primaryGreen,
                                  unselectedLabelColor: Colors.grey.shade600,
                                  indicatorColor: primaryGreen,
                                  indicatorWeight: 2.5,
                                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                                  tabs: [
                                    _buildTab(Icons.grid_view_rounded, 'Overview'),
                                    _buildTab(Icons.event_note_outlined, 'Routine'),
                                    _buildTab(Icons.shield_outlined, 'Polio'),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildOverviewTabLive(firestoreDocId, childRegNo, dobVal, gender, motherName, cnic, phone, village, nextDue),
                                    _buildRoutineHistoryTab(firestoreDocId, childRegNo, dobVal),
                                    _buildPolioHistoryTab(firestoreDocId, childRegNo),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VaccinationEntryScreen(childData: data),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.vaccines, color: Colors.white, size: 18),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'Record Vaccine',
                                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              Icon(Icons.chevron_right, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => _openRecordCampaignStatus(
                            context,
                            [firestoreDocId, childRegNo],
                            childName,
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: lightGreenBg,
                            side: const BorderSide(color: Color(0xFFBFDCCB)),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.verified_user_outlined, color: primaryGreen, size: 18),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'Record Campaign Status',
                                    style: TextStyle(color: primaryGreen, fontSize: 13.5, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              SizedBox(width: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------
  // HEADER: gradient banner with back/QR buttons, avatar, name, ID,
  // status pill, age and gender.
  // ---------------------------------------------------------------
  Widget _buildHeader(
    BuildContext context, {
    required String childName,
    required String childRegNo,
    required String qrId,
    required String status,
    required dynamic dobVal,
    required String gender,
  }) {
    final String statusUpper = status.toUpperCase();
    final Color pillColor = statusUpper == 'REFUSED'
        ? dangerRed
        : statusUpper == 'VACCINATED'
            ? accentGreen
            : warningAmber;
    final IconData pillIcon = statusUpper == 'REFUSED'
        ? Icons.cancel_outlined
        : statusUpper == 'VACCINATED'
            ? Icons.verified_user
            : Icons.schedule;

    return Stack(
      children: [
        Positioned(top: -50, right: -40, child: _decorCircle(160, 0.06)),
        Positioned(top: 60, right: 24, child: _decorCircle(64, 0.05)),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 38,
                      height: 38,
                      child: Material(
                        color: Colors.white.withOpacity(0.15),
                        shape: const CircleBorder(),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 38,
                      height: 38,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.qr_code_2, color: Colors.white, size: 24),
                        onPressed: () => _showQrCodeDialog(context, qrId, childName),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: lightGreenBg,
                        child: Text(_genderEmoji(gender), style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            childName,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: $childRegNo',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: pillColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(pillIcon, color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  statusUpper,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 5,
                            runSpacing: 2,
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 12, color: Colors.white.withOpacity(0.85)),
                              Text(
                                _getShortAge(dobVal),
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                              ),
                              Text('•', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                              Icon(_genderIcon(gender), size: 14, color: Colors.white.withOpacity(0.85)),
                              Text(
                                gender,
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _decorCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }

  Tab _buildTab(IconData icon, String label) {
    return Tab(
      height: 42,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // OVERVIEW TAB
  // ---------------------------------------------------------------
  // Calculates "Next Vaccine Due" live from the vaccinations actually given,
  // so it is always correct (even for older records whose stored nextDue is
  // wrong). Falls back to the stored value until data loads.
  Widget _buildOverviewTabLive(
    String firestoreDocId,
    String childRegNo,
    dynamic dobVal,
    String gender,
    String motherName,
    String cnic,
    String phone,
    String village,
    String storedNextDue,
  ) {
    final ids = [firestoreDocId, childRegNo].where((id) => id.trim().isNotEmpty).toSet().toList();

    if (ids.isEmpty) {
      return _buildOverviewTab(dobVal, gender, motherName, cnic, phone, village, storedNextDue);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vaccinations')
          .where('childId', whereIn: ids)
          .snapshots(),
      builder: (context, snap) {
        String nextDue = storedNextDue;
        if (snap.hasData && snap.data != null) {
          final given = snap.data!.docs
              .map((d) => d.data() as Map<String, dynamic>)
              .where((m) => (m['status'] ?? 'vaccinated').toString().toLowerCase() != 'refused')
              .map((m) => (m['vaccineName'] ?? '').toString())
              .toList();
          nextDue = EpiScheduleHelper.calculateNextDue(given);
        }
        return _buildOverviewTab(dobVal, gender, motherName, cnic, phone, village, nextDue);
      },
    );
  }

  Widget _buildOverviewTab(
    dynamic dobVal,
    String gender,
    String motherName,
    String cnic,
    String phone,
    String village,
    String nextDue,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Next Vaccine Due card
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6EF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCDE7D8)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFD3ECDD),
                  ),
                  child: const Icon(Icons.vaccines, color: primaryGreen, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Vaccine Due',
                        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nextDue,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.black87),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text('Scheduled', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _tabController.animateTo(1),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryGreen,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: primaryGreen),
                    padding: const EdgeInsets.only(left: 10, right: 6),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Schedule', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 15),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Basic Information
          Row(
            children: const [
              Icon(Icons.person, color: primaryGreen, size: 19),
              SizedBox(width: 7),
              Text(
                'Basic Information',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildInfoRow(Icons.calendar_today_outlined, 'Date of Birth', _getFormattedAge(dobVal)),
                _buildInfoDivider(),
                _buildInfoRow(_genderIcon(gender), 'Gender', gender),
                _buildInfoDivider(),
                _buildInfoRow(Icons.person, 'Mother Name', motherName),
                _buildInfoDivider(),
                _buildInfoRow(Icons.badge_outlined, 'CNIC / Guardian', cnic),
                _buildInfoDivider(),
                _buildInfoRow(Icons.phone, 'Phone Number', phone),
                _buildInfoDivider(),
                _buildInfoRow(Icons.location_on, 'Village / Area', village),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // ROUTINE HISTORY TAB (logic unchanged)
  // ---------------------------------------------------------------
  Widget _buildRoutineHistoryTab(String firestoreDocId, String childRegNo, dynamic dobVal) {
    DateTime childDob = _parseDob(dobVal);
    final schedule = EpiScheduleHelper.generateEpiSchedule(childDob);
    final now = DateTime.now();

    List<String> queryTargetIds = [firestoreDocId, childRegNo].where((id) => id.trim().isNotEmpty).toList();

    if (queryTargetIds.isEmpty) {
      return const Center(child: Text('Invalid Child Document ID', style: TextStyle(color: Colors.grey)));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vaccinations')
          .where('childId', whereIn: queryTargetIds)
          .snapshots(),
      builder: (context, snapshot) {
        List<Map<String, dynamic>> givenRecords = [];

        if (snapshot.hasData && snapshot.data != null) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;

            dynamic rawDate = data['dateGiven'] ?? data['administeredDate'] ?? data['createdAt'];
            String formattedDateStr = 'Done';

            if (rawDate is Timestamp) {
              formattedDateStr = DateFormat('dd MMM yyyy').format(rawDate.toDate());
            } else if (rawDate is DateTime) {
              formattedDateStr = DateFormat('dd MMM yyyy').format(rawDate);
            } else if (rawDate is String && rawDate.isNotEmpty) {
              formattedDateStr = rawDate;
            }

            givenRecords.add({
              'vaccineName': (data['vaccineName'] ?? '').toString(),
              'dateGiven': formattedDateStr,
              'status': (data['status'] ?? 'Vaccinated').toString().toLowerCase(),
            });
          }
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          itemCount: schedule.length,
          itemBuilder: (context, index) {
            final stageItem = schedule[index];
            final String stageName = stageItem['stage'];
            final DateTime dueDate = stageItem['dueDate'];
            final List<String> vaccines = List<String>.from(stageItem['vaccines']);

            bool isStageDueOrPast = now.isAfter(dueDate) || now.isAtSameMomentAs(dueDate);
            String formattedDueDate = DateFormat('dd MMM yyyy').format(dueDate);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: isStageDueOrPast,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  title: Text(
                    stageName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isStageDueOrPast ? Colors.black87 : Colors.grey.shade600,
                    ),
                  ),
                  subtitle: Text(
                    'Due Date: $formattedDueDate',
                    style: TextStyle(fontSize: 11, color: isStageDueOrPast ? primaryGreen : Colors.grey),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isStageDueOrPast ? lightGreenBg : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isStageDueOrPast ? 'Due / Active' : 'Upcoming',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isStageDueOrPast ? primaryGreen : Colors.grey,
                      ),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                      child: Column(
                        children: vaccines.map((vaccine) {
                          String? matchedDate;
                          String matchedStatus = '';
                          String targetNormalized = _normalize(vaccine);

                          bool isGiven = givenRecords.any((record) {
                            String storedNormalized = _normalize(record['vaccineName']);

                            bool matches = storedNormalized == targetNormalized ||
                                storedNormalized.contains(targetNormalized) ||
                                targetNormalized.contains(storedNormalized);

                            if (matches) {
                              matchedDate = record['dateGiven'];
                              matchedStatus = record['status'];
                            }
                            return matches;
                          });

                          bool isRefused = isGiven && matchedStatus == 'refused';
                          bool isMissed = !isGiven && now.isAfter(dueDate.add(const Duration(days: 14)));
                          bool isDueNow = !isGiven && isStageDueOrPast && !isMissed;

                          Color badgeColor;
                          String statusText;

                          if (isRefused) {
                            badgeColor = dangerRed;
                            statusText = 'Refused';
                          } else if (isGiven) {
                            badgeColor = accentGreen;
                            statusText = 'Given (${matchedDate ?? 'Done'})';
                          } else if (isMissed) {
                            badgeColor = dangerRed;
                            statusText = 'Missed';
                          } else if (isDueNow) {
                            badgeColor = warningAmber;
                            statusText = 'Due Now';
                          } else {
                            badgeColor = Colors.grey;
                            statusText = 'Upcoming';
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Icon(
                                  isRefused || isMissed
                                      ? Icons.cancel
                                      : isGiven
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                  size: 16,
                                  color: badgeColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    vaccine,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(statusText,
                                      style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------
  // POLIO / CAMPAIGN HISTORY TAB
  // Reads this child's campaign_assignments (the docs RecordStatusScreen
  // updates) and joins each one with its campaign for name and dates.
  // ---------------------------------------------------------------
  final Map<String, CampaignModel?> _campaignCache = {};

  Future<void> _ensureCampaigns(Iterable<String> ids) async {
    final missing = ids.where((id) => id.isNotEmpty && !_campaignCache.containsKey(id)).toSet();
    await Future.wait(missing.map((id) async {
      try {
        final doc = await FirebaseFirestore.instance.collection('campaigns').doc(id).get();
        _campaignCache[id] =
            (doc.exists && doc.data() != null) ? CampaignModel.fromMap(doc.data()!, doc.id) : null;
      } catch (_) {
        _campaignCache[id] = null;
      }
    }));
  }

  DateTime? _asDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String && v.trim().isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  Widget _buildPolioHistoryTab(String firestoreDocId, String childRegNo) {
    final List<String> queryTargetIds =
        [firestoreDocId, childRegNo].where((id) => id.trim().isNotEmpty).toSet().toList();

    if (queryTargetIds.isEmpty) {
      return const Center(child: Text('Invalid Child Document ID', style: TextStyle(color: Colors.grey)));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('campaign_assignments')
          .where('childId', whereIn: queryTargetIds)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Campaign history load nahi ho saki.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: primaryGreen));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 44, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  const Text(
                    'Ye bacha abhi tak kisi campaign mein assign nahi hua.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        final campaignIds = docs
            .map((d) => ((d.data() as Map<String, dynamic>)['campaignId'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toSet();

        if (campaignIds.every(_campaignCache.containsKey)) {
          return _buildCampaignHistoryList(docs);
        }

        return FutureBuilder<void>(
          future: _ensureCampaigns(campaignIds),
          builder: (context, fSnap) {
            if (fSnap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(color: primaryGreen));
            }
            return _buildCampaignHistoryList(docs);
          },
        );
      },
    );
  }

  Widget _buildCampaignHistoryList(List<QueryDocumentSnapshot> docs) {
    final items = docs.map((d) {
      final m = d.data() as Map<String, dynamic>;
      return <String, dynamic>{
        'data': m,
        'campaign': _campaignCache[(m['campaignId'] ?? '').toString()],
      };
    }).toList();

    // Newest campaign first.
    DateTime sortKey(Map<String, dynamic> item) {
      final c = item['campaign'] as CampaignModel?;
      return c?.startDate ?? _asDate((item['data'] as Map<String, dynamic>)['assignedAt']) ?? DateTime(2000);
    }

    items.sort((a, b) => sortKey(b).compareTo(sortKey(a)));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildCampaignCard(
        items[index]['data'] as Map<String, dynamic>,
        items[index]['campaign'] as CampaignModel?,
      ),
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> m, CampaignModel? c) {
    final String status = (m['status'] ?? 'Pending').toString();
    final String reason = (m['statusReason'] ?? '').toString();
    // Same display rule the campaign child list uses.
    final String displayStatus = (status == 'Missed' && reason.isNotEmpty) ? reason : status;

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'vaccinated':
        statusColor = accentGreen;
        break;
      case 'refused':
        statusColor = dangerRed;
        break;
      case 'missed':
        statusColor = warningAmber;
        break;
      default:
        statusColor = Colors.grey;
    }

    final bool isVaccinated = status.toLowerCase() == 'vaccinated';
    final bool isPending = status.toLowerCase() == 'pending';

    final String vaccine = (m['vaccineGiven'] ?? '').toString();
    final String finger = (m['fingerMark'] ?? '').toString();
    final String remarks = (m['remarks'] ?? '').toString().trim();
    final DateTime? recordedOn = _asDate(m['updatedAt']);

    String campaignDates = '';
    if (c != null) {
      final f = DateFormat('dd MMM');
      campaignDates = '${f.format(c.startDate)} - ${DateFormat('dd MMM yyyy').format(c.endDate)}';
    }

    final rows = <Widget>[];
    if (isVaccinated && vaccine.isNotEmpty && vaccine != 'None') {
      rows.add(_buildCampaignDetailRow(Icons.vaccines, 'Vaccine', vaccine));
    }
    if (isVaccinated && finger.isNotEmpty) {
      rows.add(_buildCampaignDetailRow(Icons.fingerprint, 'Finger Mark', finger));
    }
    if (!isPending && recordedOn != null) {
      rows.add(_buildCampaignDetailRow(
        Icons.event_available_outlined,
        'Recorded On',
        DateFormat('dd MMM yyyy, hh:mm a').format(recordedOn),
      ));
    }
    if (remarks.isNotEmpty) {
      rows.add(_buildCampaignDetailRow(Icons.notes, 'Remarks', remarks));
    }
    if (isPending) {
      rows.add(_buildCampaignDetailRow(Icons.hourglass_empty, 'Status', 'Abhi record nahi hua'));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(Icons.shield_outlined, color: primaryGreen, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (c?.name ?? '').isNotEmpty ? c!.name : 'Campaign',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87),
                    ),
                    if (campaignDates.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${c!.type} • $campaignDates',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  displayStatus,
                  style: TextStyle(color: statusColor, fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 8),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 6),
            ...rows,
          ],
        ],
      ),
    );
  }

  Widget _buildCampaignDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          SizedBox(
            width: 82,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: primaryGreen),
          const SizedBox(width: 12),
          SizedBox(
            width: 104,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDivider() {
    return Divider(height: 1, color: Colors.grey.shade200);
  }
}