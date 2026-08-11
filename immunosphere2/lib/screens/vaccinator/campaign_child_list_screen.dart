import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.campaignTitle,
              style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.dates,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('campaign_assignments')
            .where('campaignId', isEqualTo: widget.campaignId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00BFA5)));
          }

          final docs = snapshot.data?.docs ?? [];

          // Business Rules Matching Reports Logic
          int target = docs.length;
          int vaccinated = docs.where((d) => d['status'] == 'Vaccinated').length;
          int pending = docs.where((d) => d['status'] == 'Pending').length;
          int missed = docs.where((d) => d['status'] == 'House Locked' || d['status'] == 'Child Not Available').length;
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
                        Text('Area: ${widget.area}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        Text('Team: ${widget.team}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBox("Target", '$target', const Color(0xFF00BFA5)),
                        _buildStatBox("Vaccinated", '$vaccinated', Colors.green),
                        _buildStatBox("Pending", '$pending', Colors.orange),
                        _buildStatBox("Missed", '$missed', Colors.redAccent),
                        _buildStatBox("Refused", '$refused', Colors.red),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Overall Progress', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text('${(progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF00BFA5))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  onChanged: (val) => setState(() => searchQuery = val),
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
                                      currentStatus: status,
                                      vaccineGiven: data['vaccineGiven'] ?? 'OPV Drops',
                                      fingerMark: data['fingerMark'] ?? 'Done',
                                      remarks: data['remarks'] ?? '',
                                    ),
                                  ),
                                );
                              },
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF00BFA5).withOpacity(0.1),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Color(0xFF00BFA5), fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text(
                                '$age • $regNo\n$address',
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
      case 'Vaccinated': return Colors.green.shade50;
      case 'Pending': return Colors.orange.shade50;
      case 'House Locked':
      case 'Child Not Available': return Colors.red.shade50;
      case 'Refused': return Colors.red.shade100;
      default: return Colors.grey.shade100;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'Vaccinated': return Colors.green;
      case 'Pending': return Colors.orange.shade800;
      case 'House Locked':
      case 'Child Not Available': return Colors.redAccent;
      case 'Refused': return Colors.red;
      default: return Colors.black;
    }
  }
}