import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'campaign_child_list_screen.dart';

class CampaignsListScreen extends StatelessWidget {
  final String currentTeamId;

  const CampaignsListScreen({
    Key? key,
    this.currentTeamId = 'Team 07', // Default value added to fix parameter error
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Campaigns', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('campaigns').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00BFA5)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No Campaigns Available', style: TextStyle(color: Colors.grey)));
          }

          final allCampaigns = snapshot.data!.docs;

          final activeCampaigns = allCampaigns.where((doc) => doc['status'] == 'Active').toList();
          final upcomingCampaigns = allCampaigns.where((doc) => doc['status'] == 'Upcoming').toList();
          final completedCampaigns = allCampaigns.where((doc) => doc['status'] == 'Completed').toList();

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

  Widget _buildCampaignCard(BuildContext context, DocumentSnapshot doc, {bool isActive = false, bool isUpcoming = false, bool isCompleted = false}) {
    final data = doc.data() as Map<String, dynamic>;
    String campaignId = doc.id;
    String title = data['title'] ?? 'Polio Campaign';
    String dates = data['dates'] ?? 'N/A';
    String area = data['area'] ?? 'N/A';
    String team = data['team'] ?? currentTeamId;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('campaign_assignments')
          .where('campaignId', isEqualTo: campaignId)
          .snapshots(),
      builder: (context, assignmentSnapshot) {
        int totalChildren = 0;
        int vaccinatedChildren = 0;
        double progress = 0.0;

        if (assignmentSnapshot.hasData) {
          final assignments = assignmentSnapshot.data!.docs;
          totalChildren = assignments.length;
          vaccinatedChildren = assignments.where((a) => a['status'] == 'Vaccinated').length;
          if (totalChildren > 0) {
            progress = vaccinatedChildren / totalChildren;
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
                  dates: dates,
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
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                Text(dates, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Area: $area', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                    Text('Team: $team', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
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