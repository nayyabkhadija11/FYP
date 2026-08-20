import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'campaign_child_list_screen.dart';

class CampaignsListScreen extends StatelessWidget {
  final String currentTeamNumber; // Misal ke tor par "1"

  const CampaignsListScreen({
    Key? key,
    this.currentTeamNumber = '1', 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Campaigns (Team $currentTeamNumber)', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      // Filtering campaigns based on teamNumber field from Firestore
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('campaigns')
            .where('teamNumber', isEqualTo: currentTeamNumber)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00BFA5)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No Campaigns Assigned for Team $currentTeamNumber', 
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }

          final allCampaigns = snapshot.data!.docs;
          final DateTime now = DateTime.now();

          List<DocumentSnapshot<Map<String, dynamic>>> activeCampaigns = [];
          List<DocumentSnapshot<Map<String, dynamic>>> upcomingCampaigns = [];
          List<DocumentSnapshot<Map<String, dynamic>>> completedCampaigns = [];

          for (var doc in allCampaigns) {
            final data = doc.data();
            final String explicitStatus = (data['status'] ?? '').toString().toLowerCase().trim();

            DateTime? endDate;
            if (data['endDate'] is Timestamp) {
              endDate = (data['endDate'] as Timestamp).toDate();
            }

            bool isCompleted = explicitStatus == 'completed' || (endDate != null && now.isAfter(endDate));
            bool isUpcoming = explicitStatus == 'upcoming';

            if (isCompleted) {
              completedCampaigns.add(doc);
            } else if (isUpcoming) {
              upcomingCampaigns.add(doc);
            } else {
              activeCampaigns.add(doc);
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (activeCampaigns.isNotEmpty) ...[
                const Text('Active Campaign', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                ...activeCampaigns.map((doc) => _buildCampaignCard(context, doc, isActive: true)).toList(),
                const SizedBox(height: 20),
              ],
              if (upcomingCampaigns.isNotEmpty) ...[
                const Text('Upcoming Campaign', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                ...upcomingCampaigns.map((doc) => _buildCampaignCard(context, doc, isUpcoming: true)).toList(),
                const SizedBox(height: 20),
              ],
              if (completedCampaigns.isNotEmpty) ...[
                const Text('Completed Campaigns', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                ...completedCampaigns.map((doc) => _buildCampaignCard(context, doc, isCompleted: true)).toList(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCampaignCard(BuildContext context, DocumentSnapshot<Map<String, dynamic>> doc, {bool isActive = false, bool isUpcoming = false, bool isCompleted = false}) {
    final data = doc.data() ?? {};
    String campaignId = doc.id;
    
    // Correct fields mapping from your Firestore structure
    String title = data['name'] ?? 'Polio Campaign';
    String targetArea = data['targetArea'] ?? 'N/A';
    String targetVillage = data['targetVillage'] ?? '';
    String area = targetVillage.isNotEmpty ? '$targetArea, $targetVillage' : targetArea;
    String team = data['teamNumber'] ?? currentTeamNumber;
    
    // Total children from campaign document field, fallback to 0 if not present
    int docTotalChildren = data['totalChildren'] is int ? data['totalChildren'] : int.tryParse(data['totalChildren']?.toString() ?? '0') ?? 0;

    String formattedDates = 'N/A';
    if (data['startDate'] is Timestamp && data['endDate'] is Timestamp) {
      DateTime start = (data['startDate'] as Timestamp).toDate();
      DateTime end = (data['endDate'] as Timestamp).toDate();
      formattedDates = '${DateFormat('dd MMM yyyy').format(start)} – ${DateFormat('dd MMM yyyy').format(end)}';
    }

    // Fetching vaccinated children dynamically from campaign_assignments collection
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('campaign_assignments')
          .where('campaignId', isEqualTo: campaignId)
          .snapshots(),
      builder: (context, assignmentSnapshot) {
        int totalChildren = docTotalChildren;
        int vaccinatedChildren = 0;
        double progress = 0.0;

        if (assignmentSnapshot.hasData) {
          final assignments = assignmentSnapshot.data!.docs;
          
          // Agar assignments se total children count lena zyada behtar lagay toh yeh use karein:
          if (assignments.isNotEmpty) {
            totalChildren = assignments.length;
          }
          
          vaccinatedChildren = assignments.where((a) {
            final aData = a.data() as Map<String, dynamic>;
            final status = (aData['status'] ?? '').toString().toLowerCase().trim();
            return status == 'vaccinated' || status == 'completed' || status == 'done' || status == 'yes';
          }).length;

          if (totalChildren > 0) {
            progress = (vaccinatedChildren / totalChildren).clamp(0.0, 1.0);
          }
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CampaignChildListScreen(
                  campaignId: campaignId,
                  campaignTitle: title,
                  dates: formattedDates,
                  area: area,
                  team: team,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isActive ? const Color(0xFF00BFA5) : Colors.grey.shade200, width: isActive ? 1.5 : 1),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isActive ? Icons.business_center : isUpcoming ? Icons.lock_outline : Icons.check_circle_outline, 
                          color: isActive ? const Color(0xFF00BFA5) : isUpcoming ? Colors.blue : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.45,
                          child: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.shade50 : isUpcoming ? Colors.blue.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive ? 'Active' : isUpcoming ? 'Upcoming' : 'Completed',
                        style: TextStyle(
                          color: isActive ? Colors.green : isUpcoming ? Colors.blue : Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(formattedDates, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Area: $area', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                    Text('Team: Team $team', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                  ],
                ),
                if (isActive || isCompleted) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progress', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                      Text('$vaccinatedChildren / $totalChildren Children    ${(progress * 100).toInt()}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
                      minHeight: 6,
                    ),
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}