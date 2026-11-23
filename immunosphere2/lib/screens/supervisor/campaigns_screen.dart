
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

  // Streams sirf ek baar banti hain (har rebuild par nahi)
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _campaignsStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _assignmentsStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _vaccinationsStream;

  static const Color primaryGreen = Color(0xFF00563B);
  static const Color lightGreenBg = Color(0xFFE8F5E9);
  static const Color textDark = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _campaignsStream = _db.collection('campaigns').snapshots();
    _assignmentsStream = _db.collection('campaign_assignments').snapshots();
    _vaccinationsStream = _db.collection('vaccinations').snapshots();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  String _str(dynamic v) => (v ?? '').toString().trim();

  /// Campaign completed hai ya nahi: sirf yehi ek function use hota hai
  /// (filter me bhi aur card me bhi).
  bool _isCampaignCompleted(Map<String, dynamic> data) {
    final status = _str(data['status']).toLowerCase();
    if (status == 'completed') return true;

    final end = _toDate(data['endDate']);
    if (end != null) {
      // end date ke poore din tak campaign active rahe
      final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
      return DateTime.now().isAfter(endOfDay);
    }
    return false;
  }

  bool _isVaccinationDone(String status) {
    return status == 'vaccinated' ||
        status == 'completed' ||
        status == 'done' ||
        status == 'yes';
  }

  /// Campaign ke liye (assigned children, vaccinated children) nikalta hai.
  /// Routine aur Polio dono campaigns ke liye same logic:
  ///  - assigned  -> campaign_assignments (is campaign ke bachche)
  ///  - vaccinated -> assignment ka status 'Vaccinated' ho
  ///                  YA vaccinations mein is campaignId ki vaccinated entry ho
  _CampaignStats _calculateStats(
    String campaignId,
    Map<String, dynamic> data,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> assignmentDocs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> vacDocs,
  ) {
    final String cid = campaignId.trim();
    final Set<String> assignedIds = {};
    final Set<String> vaccinatedIds = {};

    for (final doc in assignmentDocs) {
      final a = doc.data();
      final String aCampaignId = _str(a['campaignId'] ?? a['campaign_id']);
      if (aCampaignId != cid) continue;

      final String childId = _str(a['childId'] ?? a['child_id']);
      final String key = childId.isNotEmpty ? childId : doc.id;
      assignedIds.add(key);

      final String status = _str(a['status']).toLowerCase();
      if (_isVaccinationDone(status)) vaccinatedIds.add(key);
    }

    for (final vDoc in vacDocs) {
      final v = vDoc.data();
      final String vCampaignId = _str(v['campaignId'] ?? v['campaign_id']);
      if (vCampaignId != cid) continue;

      final String childId = _str(v['childId'] ?? v['child_id']);
      if (childId.isEmpty) continue;

      final String status = _str(v['status']).toLowerCase();
      if (_isVaccinationDone(status)) vaccinatedIds.add(childId);
    }

    int target = assignedIds.length;
    if (target == 0) {
      target = _toInt(data['target_count'] ?? data['targetCount']);
    }

    final int vaccinated = vaccinatedIds.length;
    final double progress =
        target > 0 ? (vaccinated / target).clamp(0.0, 1.0) : 0.0;

    return _CampaignStats(
      assigned: target,
      vaccinated: vaccinated,
      progress: progress,
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _campaignsStream,
        builder: (context, campSnap) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _assignmentsStream,
            builder: (context, assignSnap) {
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _vaccinationsStream,
                builder: (context, vacSnap) {
                  if (campSnap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryGreen),
                    );
                  }

                  if (campSnap.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${campSnap.error}',
                        style:
                            const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    );
                  }

                  final campaignDocs = campSnap.data?.docs ?? [];
                  final assignmentDocs = assignSnap.data?.docs ?? [];
                  final vacDocs = vacSnap.data?.docs ?? [];

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCampaignsList(
                          'active', campaignDocs, assignmentDocs, vacDocs),
                      _buildCampaignsList(
                          'completed', campaignDocs, assignmentDocs, vacDocs),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryGreen,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => const CreateCampaignScreen(),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCampaignsList(
    String statusType,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> campaignDocs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> assignmentDocs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> vacDocs,
  ) {
    final filtered = campaignDocs.where((doc) {
      final isDone = _isCampaignCompleted(doc.data());
      return statusType == 'completed' ? isDone : !isDone;
    }).toList();

    // Naya campaign upar
    filtered.sort((a, b) {
      final da = _toDate(a.data()['startDate']) ?? DateTime(1970);
      final db = _toDate(b.data()['startDate']) ?? DateTime(1970);
      return db.compareTo(da);
    });

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No $statusType campaigns found.',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final docId = filtered[index].id;
        final data = filtered[index].data();
        final stats = _calculateStats(docId, data, assignmentDocs, vacDocs);
        return _buildCampaignCard(docId, data, stats);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // CARD
  // ---------------------------------------------------------------------------

  Widget _buildCampaignCard(
      String campaignId, Map<String, dynamic> data, _CampaignStats stats) {
    final String name = _str(data['name']).isEmpty
        ? 'Campaign Name'
        : _str(data['name']);
    final String type =
        _str(data['type']).isEmpty ? 'Polio' : _str(data['type']);
    final List<String> areas = (data['targetAreas'] is List)
        ? (data['targetAreas'] as List)
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];
    final String areaText = areas.isNotEmpty
        ? areas.join(', ')
        : (_str(data['teamName']).isNotEmpty
            ? _str(data['teamName'])
            : 'No area selected');
    final int coveragePercent = (stats.progress * 100).round();

    final DateTime? startDate = _toDate(data['startDate']);
    final DateTime? endDate = _toDate(data['endDate']);
    final String startDateStr =
        startDate != null ? DateFormat('dd MMM yyyy').format(startDate) : '-';
    final String endDateStr =
        endDate != null ? DateFormat('dd MMM yyyy').format(endDate) : '-';

    final bool isCompleted = _isCampaignCompleted(data);

    Future<void> deleteCampaign() async {
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
          if (!mounted) return;
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
              builder: (context) =>
                  CampaignOverviewScreen(campaignId: campaignId),
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
                  Expanded(
                    child: Text(
                      areaText,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                    _buildStatItem('Assigned Children', '${stats.assigned}'),
                    _buildStatItem('Vaccinated', '${stats.vaccinated}'),
                    _buildStatItem('Coverage', '$coveragePercent%'),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: stats.progress,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(primaryGreen),
                  minHeight: 5,
                ),
              ),
              if (isCompleted) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
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

class _CampaignStats {
  final int assigned;
  final int vaccinated;
  final double progress;

  const _CampaignStats({
    required this.assigned,
    required this.vaccinated,
    required this.progress,
  });
}