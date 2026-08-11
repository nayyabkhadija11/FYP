/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'vaccination_history_screen.dart';
import 'vaccination_entry_screen.dart';

class ChildDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> childData;

  const ChildDetailsScreen({Key? key, required this.childData}) : super(key: key);

  @override
  State<ChildDetailsScreen> createState() => _ChildDetailsScreenState();
}

class _ChildDetailsScreenState extends State<ChildDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 2 Tabs: Overview & History (Documents tab removed)
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Safe Dynamic Age & Date Parser
  String _getFormattedAge(dynamic dobVal) {
    if (dobVal == null) return 'N/A';

    DateTime? dob;

    if (dobVal is Timestamp) {
      dob = dobVal.toDate();
    } else if (dobVal is DateTime) {
      dob = dobVal;
    } else if (dobVal is String) {
      if (dobVal.trim().isEmpty) return 'N/A';
      dob = DateTime.tryParse(dobVal);
    }

    if (dob == null) return dobVal.toString();

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

  // Dialog to show QR representation
  void _showQrCodeDialog(BuildContext context, String childId, String childName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.qr_code_2, size: 160, color: Color(0xFF5C33CF)),
            ),
            const SizedBox(height: 12),
            Text(
              'Child ID: $childId',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF5C33CF))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String docId = widget.childData['docId'] ?? widget.childData['regNo'] ?? widget.childData['id'] ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: docId.isNotEmpty
          ? FirebaseFirestore.instance.collection('children').doc(docId).snapshots()
          : null,
      builder: (context, snapshot) {
        Map<String, dynamic> data = widget.childData;
        if (snapshot.hasData && snapshot.data!.exists) {
          data = snapshot.data!.data() as Map<String, dynamic>;
          data['docId'] = snapshot.data!.id;
        }

        final String childName = data['fullName'] ?? data['name'] ?? data['childName'] ?? 'Unknown Name';
        final String childId = data['regNo'] ?? data['childId'] ?? data['id'] ?? 'CH-000000';
        final String status = data['status'] ?? 'Registered';
        
        final dynamic dobVal = data['dob']; 
        final String gender = data['gender'] ?? 'N/A';
        final String motherName = data['motherName'] ?? 'N/A';
        final String cnic = data['cnic'] ?? data['guardianCnic'] ?? data['motherCnic'] ?? 'N/A';
        final String phone = data['phoneNumber'] ?? data['phone'] ?? 'N/A';
        final String village = data['village'] ?? data['address'] ?? 'N/A';
        final String nextDue = data['nextDue'] ?? 'Polio & BCG Doses';

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('Child Details', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              // Top Banner
              Container(
                color: const Color(0xFF5C33CF),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.child_care, size: 36, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            childName,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text('ID: $childId', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: status.toLowerCase().contains('vaccinated')
                                  ? const Color(0xFF10B981)
                                  : status.toLowerCase().contains('missed') || status.toLowerCase().contains('refused')
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.qr_code_2, color: Colors.white, size: 32),
                      onPressed: () => _showQrCodeDialog(context, childId, childName),
                    ),
                  ],
                ),
              ),

              // TabBar Navigation (Only Overview & History)
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF5C33CF),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF5C33CF),
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'History'),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(dobVal, gender, motherName, cnic, phone, village, nextDue),
                    VaccinationHistoryScreen(childId: childId),
                  ],
                ),
              ),
            ],
          ),

          // Bottom Action Bar
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showQrCodeDialog(context, childId, childName),
                    icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF5C33CF), size: 18),
                    label: const Text('Show QR Code', style: TextStyle(color: Color(0xFF5C33CF), fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF5C33CF)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
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
                    label: const Text('Give Vaccine', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C33CF),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          const Text('Basic Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.calendar_today_outlined, 'Date of Birth', _getFormattedAge(dobVal)),
          _buildInfoRow(Icons.person_outline, 'Gender', gender),
          _buildInfoRow(Icons.face_outlined, 'Mother Name', motherName),
          _buildInfoRow(Icons.card_membership_outlined, 'CNIC / Guardian', cnic),
          _buildInfoRow(Icons.phone_outlined, 'Phone Number', phone),
          _buildInfoRow(Icons.location_on_outlined, 'Village / Area', village),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(14),
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
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: const Text('Scheduled', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
} */
// File: lib/screens/vaccinator/child_details_screen.dart


/*import 'package:immunosphere2/helpers/epi_schedule_helper.dart';
// File: lib/screens/vaccinator/child_details_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'vaccination_entry_screen.dart';
import 'record_status_screen.dart'; // Polio campaign status screen

class ChildDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> childData;

  const ChildDetailsScreen({Key? key, required this.childData}) : super(key: key);

  @override
  State<ChildDetailsScreen> createState() => _ChildDetailsScreenState();
}

class _ChildDetailsScreenState extends State<ChildDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Colors
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
    final String docId = widget.childData['docId'] ?? widget.childData['regNo'] ?? widget.childData['id'] ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: docId.isNotEmpty
          ? FirebaseFirestore.instance.collection('children').doc(docId).snapshots()
          : null,
      builder: (context, snapshot) {
        Map<String, dynamic> data = widget.childData;
        if (snapshot.hasData && snapshot.data!.exists) {
          data = snapshot.data!.data() as Map<String, dynamic>;
          data['docId'] = snapshot.data!.id;
        }

        final String childName = data['fullName'] ?? data['name'] ?? data['childName'] ?? 'Fatima Ali';
        final String childId = data['regNo'] ?? data['childId'] ?? data['id'] ?? 'CH-001246';
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
              // Top Right AppBar Icon -> Displays Digital QR Code
              IconButton(
                icon: const Icon(Icons.qr_code_2, color: Colors.white, size: 28),
                onPressed: () => _showQrCodeDialog(context, childId, childName),
              ),
            ],
          ),
          body: Column(
            children: [
              // Header Card
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
                            'ID: $childId',
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

              // Tab Bar Navigation
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
                    _buildRoutineHistoryTab(childId, dobVal),
                    _buildPolioHistoryTab(childId),
                  ],
                ),
              ),
            ],
          ),

          // Clean Bottom Action Panel (QR Button Removed from bottom)
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
                // 1. Record Vaccine Button
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
                // 2. Record Campaign Status Button
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

  // OVERVIEW TAB
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

  // ROUTINE HISTORY TAB
  Widget _buildRoutineHistoryTab(String childId, dynamic dobVal) {
    DateTime childDob = _parseDob(dobVal);
    final schedule = EpiScheduleHelper.generateEpiSchedule(childDob);
    final now = DateTime.now();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('routine_vaccinations')
          .where('childId', isEqualTo: childId)
          .snapshots(),
      builder: (context, snapshot) {
        Set<String> givenVaccines = {};
        Map<String, String> givenDates = {};

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            String vaccineName = data['vaccineName'] ?? '';
            String givenDate = data['dateGiven'] ?? 'Done';
            if (vaccineName.isNotEmpty) {
              givenVaccines.add(vaccineName);
              givenDates[vaccineName] = givenDate;
            }
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
                          bool isGiven = givenVaccines.contains(vaccine);
                          bool isMissed = !isGiven && now.isAfter(dueDate.add(const Duration(days: 14)));
                          bool isDueNow = !isGiven && isStageDueOrPast && !isMissed;

                          Color badgeColor;
                          String statusText;

                          if (isGiven) {
                            badgeColor = accentGreen;
                            statusText = 'Given (${givenDates[vaccine] ?? 'Done'})';
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
                                      isGiven
                                          ? Icons.check_circle
                                          : isMissed
                                              ? Icons.cancel
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

  // POLIO HISTORY TAB
  Widget _buildPolioHistoryTab(String childId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('campaign_records')
          .where('childId', isEqualTo: childId)
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
                      Text(data['dateGiven'] ?? data['date'] ?? 'N/A', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
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
                        decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                        child: Text(data['status'] ?? 'Vaccinated', style: const TextStyle(color: accentGreen, fontSize: 11, fontWeight: FontWeight.bold)),
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
// File: lib/screens/vaccinator/child_details_screen.dart
/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:immunosphere2/helpers/epi_schedule_helper.dart';
import 'vaccination_entry_screen.dart';
import 'record_status_screen.dart'; // Polio campaign status screen

class ChildDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> childData;

  const ChildDetailsScreen({Key? key, required this.childData}) : super(key: key);

  @override
  State<ChildDetailsScreen> createState() => _ChildDetailsScreenState();
}

class _ChildDetailsScreenState extends State<ChildDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Colors
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
    final String docId = widget.childData['docId'] ?? widget.childData['regNo'] ?? widget.childData['id'] ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: docId.isNotEmpty
          ? FirebaseFirestore.instance.collection('children').doc(docId).snapshots()
          : null,
      builder: (context, snapshot) {
        Map<String, dynamic> data = widget.childData;
        if (snapshot.hasData && snapshot.data!.exists) {
          data = snapshot.data!.data() as Map<String, dynamic>;
          data['docId'] = snapshot.data!.id;
        }

        final String childName = data['fullName'] ?? data['name'] ?? data['childName'] ?? 'Fatima Ali';
        final String childId = data['regNo'] ?? data['childId'] ?? data['id'] ?? 'CH-001246';
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
                onPressed: () => _showQrCodeDialog(context, childId, childName),
              ),
            ],
          ),
          body: Column(
            children: [
              // Header Card
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
                            'ID: $childId',
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

              // Tab Bar Navigation
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
                    _buildRoutineHistoryTab(childId, dobVal),
                    _buildPolioHistoryTab(childId),
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

  // OVERVIEW TAB
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

  // ROUTINE HISTORY TAB (SAFE TIMESTAMP PARSING & STRING MATCHING)
  Widget _buildRoutineHistoryTab(String childId, dynamic dobVal) {
    DateTime childDob = _parseDob(dobVal);
    final schedule = EpiScheduleHelper.generateEpiSchedule(childDob);
    final now = DateTime.now();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vaccinations')
          .where('childId', isEqualTo: childId)
          .snapshots(),
      builder: (context, snapshot) {
        List<Map<String, dynamic>> givenRecords = [];

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;

            // Safe parsing for Timestamp or String date fields
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
              'vaccineName': data['vaccineName'] ?? '',
              'dateGiven': formattedDateStr,
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
                          bool isGiven = givenRecords.any((record) {
                            String storedName = record['vaccineName'].toString().toLowerCase();
                            String targetVaccine = vaccine.toLowerCase();
                            bool matches = storedName.contains(targetVaccine) || targetVaccine.contains(storedName);
                            if (matches) {
                              matchedDate = record['dateGiven'];
                            }
                            return matches;
                          });

                          bool isMissed = !isGiven && now.isAfter(dueDate.add(const Duration(days: 14)));
                          bool isDueNow = !isGiven && isStageDueOrPast && !isMissed;

                          Color badgeColor;
                          String statusText;

                          if (isGiven) {
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
                                      isGiven
                                          ? Icons.check_circle
                                          : isMissed
                                              ? Icons.cancel
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

  // POLIO HISTORY TAB
  Widget _buildPolioHistoryTab(String childId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('campaign_records')
          .where('childId', isEqualTo: childId)
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
                        decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                        child: Text(data['status'] ?? 'Vaccinated', style: const TextStyle(color: accentGreen, fontSize: 11, fontWeight: FontWeight.bold)),
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
                          String targetNormalized = _normalize(vaccine);

                          bool isGiven = givenRecords.any((record) {
                            String storedNormalized = _normalize(record['vaccineName']);

                            bool matches = storedNormalized == targetNormalized ||
                                storedNormalized.contains(targetNormalized) ||
                                targetNormalized.contains(storedNormalized);

                            if (matches) {
                              matchedDate = record['dateGiven'];
                            }
                            return matches;
                          });

                          bool isMissed = !isGiven && now.isAfter(dueDate.add(const Duration(days: 14)));
                          bool isDueNow = !isGiven && isStageDueOrPast && !isMissed;

                          Color badgeColor;
                          String statusText;

                          if (isGiven) {
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
                                      isGiven
                                          ? Icons.check_circle
                                          : isMissed
                                              ? Icons.cancel
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
}*/
import 'package:flutter/material.dart';
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
}