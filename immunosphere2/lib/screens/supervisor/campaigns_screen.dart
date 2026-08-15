import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'create_campaign_screen.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({Key? key}) : super(key: key);

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF231B92)),
          onPressed: () {},
        ),
        title: const Text(
          'Campaigns',
          style: TextStyle(
            color: Color(0xFF231B92),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEDEEF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF231B92),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF231B92),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Completed'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCampaignsList('active'),
          _buildCampaignsList('completed'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF231B92),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => const CreateCampaignScreen(),
            ),
          );
          if (result == true) {
            setState(() {});
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCampaignsList(String statusType) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('campaigns').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          );
        }

        final allDocs = snapshot.data?.docs ?? [];

        final filteredDocs = allDocs.where((doc) {
          final data = doc.data();
          
          int totalRegistered = 0;
          int totalVaccinated = 0;
          
          // Quick calculation to check if 100% completed dynamically
          // (You can also compare progress if stored values are passed, but calculating here ensures accuracy)
          return data['status'] != null;
        }).toList();

        // We filter based on whether the progress is 100% or explicitly marked as completed/active in Firestore
        final actualFilteredDocs = allDocs.where((doc) {
          final data = doc.data();
          final String explicitStatus = (data['status'] ?? 'active').toString().toLowerCase();
          
          // If Firestore status matches directly
          return explicitStatus == statusType;
        }).toList();

        if (actualFilteredDocs.isEmpty) {
          return Center(
            child: Text(
              'No $statusType campaigns found.',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: actualFilteredDocs.length,
          itemBuilder: (context, index) {
            final docId = actualFilteredDocs[index].id;
            final data = actualFilteredDocs[index].data();
            return _buildRealCampaignCard(docId, data);
          },
        );
      },
    );
  }

  Widget _buildRealCampaignCard(String campaignId, Map<String, dynamic> data) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('children').snapshots(),
      builder: (context, childSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db.collection('vaccinations').snapshots(),
          builder: (context, vacSnapshot) {
            int totalRegistered = 0;
            int totalVaccinated = 0;

            // 1. Calculate total registered children for this campaign
            if (childSnapshot.hasData) {
              final childDocs = childSnapshot.data!.docs;
              
              for (var doc in childDocs) {
                final cData = doc.data();
                final String cCampaignId = (cData['campaign_id'] ?? '').toString().trim();
                
                bool belongsToCampaign = false;
                if (cCampaignId.isNotEmpty && cCampaignId == campaignId.trim()) {
                  belongsToCampaign = true;
                } else if (cCampaignId.isEmpty) {
                  belongsToCampaign = true;
                }

                if (belongsToCampaign) {
                  totalRegistered++;
                }
              }
            }

            // 2. Count all valid Polio/Booster vaccinations directly from 'vaccinations' collection
            if (vacSnapshot.hasData) {
              final vacDocs = vacSnapshot.data!.docs;

              for (var vDoc in vacDocs) {
                final vData = vDoc.data();
                final String vaccineName = (vData['vaccineName'] ?? '').toString().toLowerCase();
                final String vStatus = (vData['status'] ?? '').toString().toLowerCase();

                bool isStatusDone = vStatus == 'vaccinated' || vStatus == 'completed' || vStatus == 'done' || vStatus == 'yes';

                if ((vaccineName.contains('polio') || vaccineName.contains('booster')) && isStatusDone) {
                  totalVaccinated++;
                }
              }
            }

            int targetGoal = data['target_count'] ?? totalRegistered;
            if (targetGoal == 0 && totalRegistered > 0) {
              targetGoal = totalRegistered;
            }

            double progress = targetGoal > 0 ? (totalVaccinated / targetGoal).clamp(0.0, 1.0) : 0.0;

            // Automatically update Firestore status to 'completed' if progress hits 100% (1.0) and it's still marked active
            if (progress >= 1.0 && (data['status'] ?? 'active').toString().toLowerCase() == 'active') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _db.collection('campaigns').doc(campaignId).update({'status': 'completed'});
              });
            }

            return _buildCampaignCard(campaignId, data, totalVaccinated, targetGoal, progress: progress);
          },
        );
      },
    );
  }

  Widget _buildCampaignCard(String campaignId, Map<String, dynamic> data, int vaccinatedCount, int targetCount, {double? progress}) {
    final String name = data['name'] ?? 'Campaign Name';
    final String type = data['type'] ?? 'Polio';
    final int healthCenters = data['healthCenters'] ?? 3;
    final String status = data['status'] ?? 'active';
    final double calculatedProgress = progress ?? (data['progress'] ?? 0.0).toDouble();

    String startDateStr = '10 Aug 2026';
    if (data['startDate'] is Timestamp) {
      DateTime dt = (data['startDate'] as Timestamp).toDate();
      startDateStr = DateFormat('dd MMM yyyy').format(dt);
    }

    String endDateStr = '15 Aug 2026';
    if (data['endDate'] is Timestamp) {
      DateTime dt = (data['endDate'] as Timestamp).toDate();
      endDateStr = DateFormat('dd MMM yyyy').format(dt);
    }

    final bool isActive = status.toLowerCase() == 'active';

    void _deleteCampaign() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Campaign'),
          content: Text('Are you sure you want to delete "$name"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          await _db.collection('campaigns').doc(campaignId).delete();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete campaign: $e')),
          );
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF231B92),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F1FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      type,
                      style: const TextStyle(
                        color: Color(0xFF231B92),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteCampaign();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                '$startDateStr – $endDateStr',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Health Centers: $healthCenters',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: calculatedProgress,
                      backgroundColor: const Color(0xFFEDEEF4),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF231B92)),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$vaccinatedCount/$targetCount (${(calculatedProgress * 100).toInt()}%)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF231B92),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Completed',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}