/*import 'package:flutter/material.dart';
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

  static const Color primaryGreen = Color(0xFF00563B);
  static const Color lightGreenBg = Color(0xFFE8F5E9);
  static const Color textDark = Color(0xFF1E293B);

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Campaigns',
          style: TextStyle(
            color: textDark,
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
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
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
        backgroundColor: primaryGreen,
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
          return const Center(
            child: CircularProgressIndicator(color: primaryGreen),
          );
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
        final DateTime now = DateTime.now();

        final actualFilteredDocs = allDocs.where((doc) {
          final data = doc.data();

          DateTime? endDate;
          if (data['endDate'] is Timestamp) {
            endDate = (data['endDate'] as Timestamp).toDate();
          }

          final String explicitStatus =
              (data['status'] ?? '').toString().toLowerCase().trim();

          bool isReallyCompleted = false;
          if (explicitStatus == 'completed') {
            isReallyCompleted = true;
          } else if (explicitStatus == 'active') {
            isReallyCompleted = false;
          } else if (endDate != null) {
            isReallyCompleted = now.isAfter(endDate);
          }

          if (statusType == 'completed') {
            return isReallyCompleted;
          } else {
            return !isReallyCompleted;
          }
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

            Set<String> campaignChildIds = {};

            if (childSnapshot.hasData) {
              final childDocs = childSnapshot.data!.docs;

              for (var doc in childDocs) {
                final cData = doc.data();
                final String cCampaignId =
                    (cData['campaign_id'] ?? cData['campaignId'] ?? '')
                        .toString()
                        .trim();

                bool belongsToCampaign = false;
                if (cCampaignId.isNotEmpty &&
                    cCampaignId == campaignId.trim()) {
                  belongsToCampaign = true;
                } else if (cCampaignId.isEmpty) {
                  belongsToCampaign = true;
                }

                if (belongsToCampaign) {
                  totalRegistered++;
                  campaignChildIds.add(doc.id);
                }
              }
            }

            if (vacSnapshot.hasData) {
              final vacDocs = vacSnapshot.data!.docs;

              for (var vDoc in vacDocs) {
                final vData = vDoc.data();

                final String vChildId =
                    (vData['child_id'] ?? vData['childId'] ?? '')
                        .toString()
                        .trim();
                if (vChildId.isNotEmpty &&
                    campaignChildIds.isNotEmpty &&
                    !campaignChildIds.contains(vChildId)) {
                  continue;
                }

                final String vaccineName =
                    (vData['vaccineName'] ?? vData['name'] ?? '')
                        .toString()
                        .toLowerCase()
                        .trim();
                final String vStatus =
                    (vData['status'] ?? '').toString().toLowerCase().trim();

                bool isStatusDone = vStatus == 'vaccinated' ||
                    vStatus == 'completed' ||
                    vStatus == 'done' ||
                    vStatus == 'yes';

                bool isExactTargetVaccine = vaccineName == 'opv drops' ||
                    vaccineName == 'ipv injection';

                if (isExactTargetVaccine && isStatusDone) {
                  totalVaccinated++;
                }
              }
            }

            int targetGoal =
                data['target_count'] ?? data['targetCount'] ?? totalRegistered;
            if (targetGoal == 0 && totalRegistered > 0) {
              targetGoal = totalRegistered;
            }
            if (targetGoal == 0) {
              targetGoal = 100;
            }

            double progress = targetGoal > 0
                ? (totalVaccinated / targetGoal).clamp(0.0, 1.0)
                : 0.0;

            return _buildCampaignCard(
                campaignId, data, totalVaccinated, targetGoal,
                progress: progress);
          },
        );
      },
    );
  }

  Widget _buildCampaignCard(String campaignId, Map<String, dynamic> data,
      int vaccinatedCount, int targetCount,
      {double? progress}) {
    final String name = data['name'] ?? 'Campaign Name';
    final String type = data['type'] ?? 'Polio';
    final int healthCenters = data['healthCenters'] ?? 3;
    final double calculatedProgress =
        progress ?? (data['progress'] ?? 0.0).toDouble();
    final int coveragePercent = (calculatedProgress * 100).toInt();

    String startDateStr = '10 Aug 2026';
    DateTime? startDate;
    if (data['startDate'] is Timestamp) {
      startDate = (data['startDate'] as Timestamp).toDate();
      startDateStr = DateFormat('dd MMM yyyy').format(startDate);
    }

    String endDateStr = '15 Aug 2026';
    DateTime? endDate;
    if (data['endDate'] is Timestamp) {
      endDate = (data['endDate'] as Timestamp).toDate();
      endDateStr = DateFormat('dd MMM yyyy').format(endDate);
    }

    final DateTime now = DateTime.now();
    final String explicitStatus =
        (data['status'] ?? '').toString().toLowerCase().trim();
    final bool isCompleted = explicitStatus == 'completed' ||
        (endDate != null && now.isAfter(endDate));

    void deleteCampaign() async {
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 0,
      child: InkWell( // 👈 Tapping on card opens Overview Screen
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(context, '/campaign_overview');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                        color: textDark,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: lightGreenBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          type,
                          style: const TextStyle(
                            color: primaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            size: 18, color: Colors.grey),
                        onSelected: (value) {
                          if (value == 'delete') deleteCampaign();
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete',
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: Colors.grey),
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
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Health Centers: $healthCenters',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Assigned Children', '$targetCount'),
                    _buildStatItem('Vaccinated', '$vaccinatedCount'),
                    _buildStatItem('Coverage', '$coveragePercent%'),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: calculatedProgress,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(primaryGreen),
                  minHeight: 5,
                ),
              ),
              if (isCompleted) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: lightGreenBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Completed',
                      style: TextStyle(
                        color: primaryGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
      ],
    );
  }
} */
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'create_campaign_screen.dart';
import 'campaign_overview_screen.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({Key? key}) : super(key: key);

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const Color primaryGreen = Color(0xFF00563B);
  static const Color lightGreenBg = Color(0xFFE8F5E9);
  static const Color textDark = Color(0xFF1E293B);

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Campaigns',
          style: TextStyle(
            color: textDark,
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
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
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
        backgroundColor: primaryGreen,
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
          return const Center(
            child: CircularProgressIndicator(color: primaryGreen),
          );
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
        final DateTime now = DateTime.now();

        final actualFilteredDocs = allDocs.where((doc) {
          final data = doc.data();

          DateTime? endDate;
          if (data['endDate'] is Timestamp) {
            endDate = (data['endDate'] as Timestamp).toDate();
          }

          final String explicitStatus =
              (data['status'] ?? '').toString().toLowerCase().trim();

          bool isReallyCompleted = false;
          if (explicitStatus == 'completed') {
            isReallyCompleted = true;
          } else if (explicitStatus == 'active') {
            isReallyCompleted = false;
          } else if (endDate != null) {
            isReallyCompleted = now.isAfter(endDate);
          }

          if (statusType == 'completed') {
            return isReallyCompleted;
          } else {
            return !isReallyCompleted;
          }
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

            Set<String> campaignChildIds = {};

            if (childSnapshot.hasData) {
              final childDocs = childSnapshot.data!.docs;

              for (var doc in childDocs) {
                final cData = doc.data();
                final String cCampaignId =
                    (cData['campaign_id'] ?? cData['campaignId'] ?? '')
                        .toString()
                        .trim();

                bool belongsToCampaign = false;
                if (cCampaignId.isNotEmpty &&
                    cCampaignId == campaignId.trim()) {
                  belongsToCampaign = true;
                } else if (cCampaignId.isEmpty) {
                  belongsToCampaign = true;
                }

                if (belongsToCampaign) {
                  totalRegistered++;
                  campaignChildIds.add(doc.id);
                }
              }
            }

            if (vacSnapshot.hasData) {
              final vacDocs = vacSnapshot.data!.docs;

              for (var vDoc in vacDocs) {
                final vData = vDoc.data();

                final String vChildId =
                    (vData['child_id'] ?? vData['childId'] ?? '')
                        .toString()
                        .trim();
                if (vChildId.isNotEmpty &&
                    campaignChildIds.isNotEmpty &&
                    !campaignChildIds.contains(vChildId)) {
                  continue;
                }

                final String vaccineName =
                    (vData['vaccineName'] ?? vData['name'] ?? '')
                        .toString()
                        .toLowerCase()
                        .trim();
                final String vStatus =
                    (vData['status'] ?? '').toString().toLowerCase().trim();

                bool isStatusDone = vStatus == 'vaccinated' ||
                    vStatus == 'completed' ||
                    vStatus == 'done' ||
                    vStatus == 'yes';

                bool isExactTargetVaccine = vaccineName == 'opv drops' ||
                    vaccineName == 'ipv injection';

                if (isExactTargetVaccine && isStatusDone) {
                  totalVaccinated++;
                }
              }
            }

            int targetGoal =
                data['target_count'] ?? data['targetCount'] ?? totalRegistered;
            if (targetGoal == 0 && totalRegistered > 0) {
              targetGoal = totalRegistered;
            }
            if (targetGoal == 0) {
              targetGoal = 100;
            }

            double progress = targetGoal > 0
                ? (totalVaccinated / targetGoal).clamp(0.0, 1.0)
                : 0.0;

            return _buildCampaignCard(
                campaignId, data, totalVaccinated, targetGoal,
                progress: progress);
          },
        );
      },
    );
  }

  Widget _buildCampaignCard(String campaignId, Map<String, dynamic> data,
      int vaccinatedCount, int targetCount,
      {double? progress}) {
    final String name = data['name'] ?? 'Campaign Name';
    final String type = data['type'] ?? 'Polio';
    final int healthCenters = data['healthCenters'] ?? 3;
    final double calculatedProgress =
        progress ?? (data['progress'] ?? 0.0).toDouble();
    final int coveragePercent = (calculatedProgress * 100).toInt();

    String startDateStr = '10 Aug 2026';
    DateTime? startDate;
    if (data['startDate'] is Timestamp) {
      startDate = (data['startDate'] as Timestamp).toDate();
      startDateStr = DateFormat('dd MMM yyyy').format(startDate);
    }

    String endDateStr = '15 Aug 2026';
    DateTime? endDate;
    if (data['endDate'] is Timestamp) {
      endDate = (data['endDate'] as Timestamp).toDate();
      endDateStr = DateFormat('dd MMM yyyy').format(endDate);
    }

    final DateTime now = DateTime.now();
    final String explicitStatus =
        (data['status'] ?? '').toString().toLowerCase().trim();
    final bool isCompleted = explicitStatus == 'completed' ||
        (endDate != null && now.isAfter(endDate));

    void deleteCampaign() async {
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CampaignOverviewScreen(campaignId: campaignId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                        color: textDark,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: lightGreenBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          type,
                          style: const TextStyle(
                            color: primaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            size: 18, color: Colors.grey),
                        onSelected: (value) {
                          if (value == 'delete') deleteCampaign();
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete',
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: Colors.grey),
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
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Health Centers: $healthCenters',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Assigned Children', '$targetCount'),
                    _buildStatItem('Vaccinated', '$vaccinatedCount'),
                    _buildStatItem('Coverage', '$coveragePercent%'),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: calculatedProgress,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(primaryGreen),
                  minHeight: 5,
                ),
              ),
              if (isCompleted) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: lightGreenBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Completed',
                      style: TextStyle(
                        color: primaryGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
      ],
    );
  }
}