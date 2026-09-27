import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'record_status_screen.dart';

class CampaignChildListScreen extends StatefulWidget {
  final String campaignId;
  final String campaignTitle;
  final String dates;
  final String area;
  final String team;

  const CampaignChildListScreen({
    Key? key,
    required this.campaignId,
    required this.campaignTitle,
    required this.dates,
    required this.area,
    required this.team,
  }) : super(key: key);

  @override
  State<CampaignChildListScreen> createState() => _CampaignChildListScreenState();
}

class _CampaignChildListScreenState extends State<CampaignChildListScreen> {
  String searchQuery = '';

  // FIX: search bar ka focus har letter par khota tha kyunke .snapshots()
  // seedha build() ke andar call ho raha tha — har setState par ek NAYA
  // stream banta tha, StreamBuilder loading state mein jata tha, aur
  // TextField unmount/remount ho kar focus kho deta tha. Ab stream sirf
  // ek dafa banta hai aur controller alag se maintain hota hai.
  final TextEditingController _searchController = TextEditingController();
  Stream<QuerySnapshot>? _assignmentsStream;

  // COLOR THEME: app-wide deep green (dashboard/profile ke sath consistent)
  static const Color primaryGreen = Color(0xFF0B4D30);
  static const Color accentGreen = Color(0xFF0E7A45);

  @override
  void initState() {
    super.initState();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != null) {
      _assignmentsStream = FirebaseFirestore.instance
          .collection('campaign_assignments')
          .where('campaignId', isEqualTo: widget.campaignId)
          .where('vaccinatorId', isEqualTo: currentUid)
          .snapshots();
    }
    _searchController.addListener(() {
      if (mounted) {
        setState(() => searchQuery = _searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.campaignTitle,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.dates,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: currentUid == null
          ? const Center(child: Text('User login nahi hai.', style: TextStyle(color: Colors.grey)))
          : StreamBuilder<QuerySnapshot>(
              stream: _assignmentsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: accentGreen));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 12)));
                }

                final docs = snapshot.data?.docs ?? [];

                int target = docs.length;
                int vaccinated = docs.where((d) => d['status'] == 'Vaccinated').length;
                int pending = docs.where((d) => d['status'] == 'Pending').length;
                int missed = docs.where((d) => d['status'] == 'Missed').length;
                int refused = docs.where((d) => d['status'] == 'Refused').length;

                double progress = target > 0 ? (vaccinated / target) : 0.0;

                final filteredDocs = docs.where((doc) {
                  String name = (doc['childName'] ?? '').toString().toLowerCase();
                  String address = (doc['address'] ?? '').toString().toLowerCase();
                  return name.contains(searchQuery.toLowerCase()) || address.contains(searchQuery.toLowerCase());
                }).toList();

                return Column(
                  children: [
                    // Summary Metrics Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text('Area: ${widget.area}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12), overflow: TextOverflow.ellipsis)),
                              Text('Team: ${widget.team}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatBox("Target", '$target', accentGreen),
                              _buildStatBox("Vaccinated", '$vaccinated', accentGreen),
                              _buildStatBox("Pending", '$pending', const Color(0xFFF59E0B)),
                              _buildStatBox("Missed", '$missed', Colors.redAccent),
                              _buildStatBox("Refused", '$refused', const Color(0xFFEF4444)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Overall Progress', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text('${(progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: accentGreen)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(accentGreen),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TextField(
                        controller: _searchController,
                        cursorColor: accentGreen,
                        decoration: InputDecoration(
                          hintText: 'Search child by name or address',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          fillColor: Colors.white,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: accentGreen, width: 1.5),
                          ),
                        ),
                      ),
                    ),

                    // Dynamic List
                    Expanded(
                      child: filteredDocs.isEmpty
                          ? const Center(child: Text('No matching records found', style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              itemCount: filteredDocs.length,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemBuilder: (context, index) {
                                var data = filteredDocs[index].data() as Map<String, dynamic>;
                                String docId = filteredDocs[index].id;
                                String name = data['childName'] ?? 'Child Name';
                                String age = data['age'] ?? '2Y';
                                String regNo = data['regNo'] ?? 'CH-000';
                                String address = data['address'] ?? 'Address Not Provided';
                                String status = data['status'] ?? 'Pending';

                                String displayStatus = (status == 'Missed' &&
                                        (data['statusReason'] as String?)?.isNotEmpty == true)
                                    ? data['statusReason']
                                    : status;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: ListTile(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => RecordStatusScreen(
                                            assignmentDocId: docId,
                                            childName: name,
                                            currentStatus: displayStatus,
                                            vaccineGiven: data['vaccineGiven'] ?? 'OPV Drops',
                                            fingerMark: data['fingerMark'] ?? 'Done',
                                            remarks: data['remarks'] ?? '',
                                          ),
                                        ),
                                      );
                                    },
                                    leading: CircleAvatar(
                                      backgroundColor: accentGreen.withOpacity(0.1),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(color: accentGreen, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    subtitle: Text(
                                      '$age \u2022 $regNo\n$address',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusBgColor(status),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: _getStatusTextColor(status),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildStatBox(String title, String val, Color col) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: col)),
      ],
    );
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'Vaccinated': return const Color(0xFFECFDF5);
      case 'Pending': return const Color(0xFFFFFBEB);
      case 'Missed':
      case 'House Locked':
      case 'Child Not Available': return Colors.red.shade50;
      case 'Refused': return const Color(0xFFFEF2F2);
      default: return Colors.grey.shade100;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'Vaccinated': return accentGreen;
      case 'Pending': return const Color(0xFFF59E0B);
      case 'Missed':
      case 'House Locked':
      case 'Child Not Available': return Colors.redAccent;
      case 'Refused': return const Color(0xFFEF4444);
      default: return Colors.black;
    }
  }
}