import 'package:flutter/material.dart';
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
}