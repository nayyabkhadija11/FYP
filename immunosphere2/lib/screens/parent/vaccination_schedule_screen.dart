/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:immunosphere2/helpers/epi_schedule_helper.dart';
import 'package:immunosphere2/models/campaign_model.dart';

class VaccinationScheduleScreen extends StatefulWidget {
  final String? childId;
  final String childName;
  final String? parentCNIC;

  const VaccinationScheduleScreen({
    Key? key,
    this.childId,
    this.childName = 'Ali Ahmad',
    this.parentCNIC,
  }) : super(key: key);

  @override
  State<VaccinationScheduleScreen> createState() =>
      _VaccinationScheduleScreenState();
}

class _VaccinationScheduleScreenState extends State<VaccinationScheduleScreen> {
  int _outerTabIndex = 0; // 0: Routine, 1: Campaigns
  int _selectedTabIndex = 0; // Routine -> 0: Upcoming, 1: Completed
  int _campaignTabIndex = 0; // Campaigns -> 0: Active, 1: Completed

  // Unified deep-green theme (same as rest of the app)
  static const Color darkGreen = Color(0xFF0B4D30);
  static const Color primaryGreen = Color(0xFF0E7A45);
  static const Color lightGreenBg = Color(0xFFE5F7ED);
  static const Color pageBg = Color(0xFFF7F9FB);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _normalize(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  DateTime _parseDob(dynamic dobVal) {
    if (dobVal is Timestamp) return dobVal.toDate();
    if (dobVal is DateTime) return dobVal;
    if (dobVal is String && dobVal.trim().isNotEmpty) {
      return DateTime.tryParse(dobVal) ?? DateTime.now();
    }
    return DateTime.now();
  }

  String _formatAge(DateTime dob) {
    final now = DateTime.now();
    int years = now.year - dob.year;
    int months = now.month - dob.month;
    if (now.day < dob.day) months--;
    if (months < 0) {
      years--;
      months += 12;
    }
    if (years <= 0) return '$months Months';
    return '$years Years, $months Months';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderCard(),
            Expanded(
              child: _outerTabIndex == 0 ? _buildRoutineTab() : _buildCampaignsTab(),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lightGreenBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.shield_outlined, color: darkGreen, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Keep your child's vaccinations up to date for a healthy future.",
                      style: TextStyle(
                        fontSize: 11,
                        color: darkGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // HEADER: slim green top bar + white profile card + green toggle buttons
  // ==========================================================
  Widget _buildHeaderCard() {
    return Column(
      children: [
        // 1) SLIM GREEN TOP BAR — sirf back arrow + title
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: darkGreen,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Center(
                child: Text(
                  'Vaccination Schedule',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              Positioned(
                left: 4,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),

        // 2) WHITE PROFILE CARD — avatar, naam, age, gender badge
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: widget.childId != null && widget.childId!.isNotEmpty
              ? StreamBuilder<DocumentSnapshot>(
                  stream: _firestore.collection('children').doc(widget.childId).snapshots(),
                  builder: (context, snap) {
                    String gender = 'Male';
                    String ageText = '';
                    if (snap.hasData && snap.data!.exists) {
                      final data = snap.data!.data() as Map<String, dynamic>;
                      gender = (data['gender'] ?? 'Male').toString();
                      final dob = _parseDob(data['dob'] ?? data['dateOfBirth']);
                      ageText = _formatAge(dob);
                    }
                    final isMale = gender.toLowerCase() == 'male' || gender.toLowerCase() == 'boy';
                    return _profileRow(gender, ageText, isMale);
                  },
                )
              : _profileRow('Male', '', true),
        ),

        // 3) WHITE BACKGROUND STRIP — GREEN toggle buttons on top of it
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              _buildOuterTabButton(title: 'Routine', icon: Icons.shield_outlined, tabIndex: 0),
              const SizedBox(width: 10),
              _buildOuterTabButton(title: 'Campaigns', icon: Icons.campaign_outlined, tabIndex: 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileRow(String gender, String ageText, bool isMale) {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: lightGreenBg,
          child: Text(isMale ? '👦' : '👧', style: const TextStyle(fontSize: 24)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.childName,
                style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (ageText.isNotEmpty)
                Text(ageText, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  gender,
                  style: const TextStyle(color: Color(0xFF0284C7), fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // ROUTINE TAB (same logic, restyled inner toggle)
  // ==========================================================
  Widget _buildRoutineTab() {
    return Column(
      children: [
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTabButton(title: 'Upcoming', tabIndex: 0),
                _buildTabButton(title: 'Completed', tabIndex: 1),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: (widget.childId == null || widget.childId!.isEmpty)
              ? _buildEmptyState()
              : StreamBuilder<DocumentSnapshot>(
                  stream: _firestore.collection('children').doc(widget.childId).snapshots(),
                  builder: (context, childSnap) {
                    if (childSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: primaryGreen));
                    }
                    if (!childSnap.hasData || !childSnap.data!.exists) {
                      return _buildEmptyState();
                    }

                    final childData = childSnap.data!.data() as Map<String, dynamic>;
                    final dob = _parseDob(childData['dob'] ?? childData['dateOfBirth']);
                    final schedule = EpiScheduleHelper.generateEpiSchedule(dob);
                    final now = DateTime.now();

                    return StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('vaccinations')
                          .where('childId', isEqualTo: widget.childId)
                          .snapshots(),
                      builder: (context, recSnap) {
                        if (recSnap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: primaryGreen));
                        }

                        List<Map<String, dynamic>> givenRecords = [];
                        if (recSnap.hasData) {
                          for (var doc in recSnap.data!.docs) {
                            final d = doc.data() as Map<String, dynamic>;
                            dynamic rawDate = d['dateGiven'] ?? d['administeredDate'] ?? d['createdAt'];
                            String formattedDateStr = 'Done';
                            if (rawDate is Timestamp) {
                              formattedDateStr = DateFormat('dd-MM-yyyy').format(rawDate.toDate());
                            } else if (rawDate is String && rawDate.isNotEmpty) {
                              formattedDateStr = rawDate;
                            }
                            givenRecords.add({
                              'vaccineName': (d['vaccineName'] ?? '').toString(),
                              'dateGiven': formattedDateStr,
                              'status': (d['status'] ?? 'vaccinated').toString().toLowerCase(),
                            });
                          }
                        }

                        List<Map<String, dynamic>> upcomingRows = [];
                        List<Map<String, dynamic>> completedRows = [];

                        for (var stage in schedule) {
                          final DateTime dueDate = stage['dueDate'];
                          final List<String> vaccines = List<String>.from(stage['vaccines']);
                          final bool isStageDueOrPast = now.isAfter(dueDate) || now.isAtSameMomentAs(dueDate);
                          final String formattedDueDate = DateFormat('dd-MM-yyyy').format(dueDate);

                          for (var vaccine in vaccines) {
                            String targetNorm = _normalize(vaccine);
                            String? matchedDate;
                            String matchedStatus = '';

                            bool isGiven = givenRecords.any((r) {
                              String storedNorm = _normalize(r['vaccineName']);
                              bool matches = storedNorm == targetNorm ||
                                  storedNorm.contains(targetNorm) ||
                                  targetNorm.contains(storedNorm);
                              if (matches) {
                                matchedDate = r['dateGiven'];
                                matchedStatus = r['status'];
                              }
                              return matches;
                            });

                            bool isRefused = isGiven && matchedStatus == 'refused';
                            bool isMissed = !isGiven && now.isAfter(dueDate.add(const Duration(days: 14)));
                            bool isDueNow = !isGiven && isStageDueOrPast && !isMissed;

                            if (isGiven && !isRefused) {
                              completedRows.add({
                                'vaccine': vaccine,
                                'stage': stage['stage'],
                                'date': matchedDate ?? 'Done',
                              });
                            } else {
                              String badge;
                              Color color;
                              Color bg;
                              if (isRefused) {
                                badge = 'Refused';
                                color = Colors.red;
                                bg = const Color(0xFFFEF2F2);
                              } else if (isMissed) {
                                badge = 'Missed';
                                color = Colors.red;
                                bg = const Color(0xFFFEF2F2);
                              } else if (isDueNow) {
                                badge = 'Due Now';
                                color = Colors.orange;
                                bg = const Color(0xFFFFF7ED);
                              } else {
                                badge = 'Upcoming';
                                color = const Color(0xFF0284C7);
                                bg = const Color(0xFFE0F2FE);
                              }
                              upcomingRows.add({
                                'vaccine': vaccine,
                                'stage': stage['stage'],
                                'dueDate': formattedDueDate,
                                'badge': badge,
                                'color': color,
                                'bg': bg,
                              });
                            }
                          }
                        }

                        final rows = _selectedTabIndex == 0 ? upcomingRows : completedRows;
                        if (rows.isEmpty) return _buildEmptyState();

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          itemCount: rows.length,
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            final isFirst = index == 0;
                            final isLast = index == rows.length - 1;

                            if (_selectedTabIndex == 0) {
                              return _buildTimelineTile(
                                title: row['vaccine'],
                                subtitle: '${row['stage']} • Due on ${row['dueDate']}',
                                badgeText: row['badge'],
                                badgeColor: row['color'],
                                badgeBg: row['bg'],
                                isFirst: isFirst,
                                isLast: isLast,
                              );
                            } else {
                              return _buildTimelineTile(
                                title: row['vaccine'],
                                subtitle: '${row['stage']} • Given on ${row['date']}',
                                badgeText: 'Completed',
                                badgeColor: primaryGreen,
                                badgeBg: lightGreenBg,
                                isFirst: isFirst,
                                isLast: isLast,
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==========================================================
  // CAMPAIGNS TAB — sirf isi bachay ki campaigns
  // campaign_assignments collection se childId match karke
  // ==========================================================
  Widget _buildCampaignsTab() {
    if (widget.childId == null || widget.childId!.isEmpty) {
      return _buildCampaignEmptyState();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('campaign_assignments')
          .where('childId', isEqualTo: widget.childId)
          .snapshots(),
      builder: (context, assignSnap) {
        if (assignSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primaryGreen));
        }

        final assignDocs = assignSnap.data?.docs ?? [];
        final campaignIds = assignDocs
            .map((d) => (d.data() as Map<String, dynamic>)['campaignId']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();

        if (campaignIds.isEmpty) return _buildCampaignEmptyState();

        return FutureBuilder<List<CampaignModel>>(
          future: _fetchCampaignsByIds(campaignIds),
          builder: (context, campSnap) {
            if (campSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: primaryGreen));
            }

            final campaigns = campSnap.data ?? [];
            final now = DateTime.now();

            final active = campaigns.where((c) => !(c.status == 'completed' || now.isAfter(c.endDate))).toList();
            final completed = campaigns.where((c) => (c.status == 'completed' || now.isAfter(c.endDate))).toList();
            final shownList = _campaignTabIndex == 0 ? active : completed;

            return Column(
              children: [
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildCampaignInnerTab(title: 'Active (${active.length})', tabIndex: 0),
                        _buildCampaignInnerTab(title: 'Completed (${completed.length})', tabIndex: 1),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _campaignTabIndex == 0 ? 'Active Campaigns' : 'Completed Campaigns',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: shownList.isEmpty
                      ? _buildCampaignEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          itemCount: shownList.length,
                          itemBuilder: (context, index) => _buildCampaignCard(shownList[index], now),
                        ),
                ),
                if (shownList.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, size: 16, color: Color(0xFF2563EB)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Campaign vaccinations are different from routine vaccines. They are conducted for specific target groups and areas.',
                              style: TextStyle(fontSize: 10.5, color: Color(0xFF1E3A8A)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<CampaignModel>> _fetchCampaignsByIds(List<String> ids) async {
    final List<CampaignModel> result = [];
    for (var i = 0; i < ids.length; i += 10) {
      final end = (i + 10 > ids.length) ? ids.length : i + 10;
      final chunk = ids.sublist(i, end);
      if (chunk.isEmpty) continue;
      final snap = await _firestore.collection('campaigns').where(FieldPath.documentId, whereIn: chunk).get();
      for (var doc in snap.docs) {
        result.add(CampaignModel.fromMap(doc.data(), doc.id));
      }
    }
    result.sort((a, b) => b.startDate.compareTo(a.startDate));
    return result;
  }

  Widget _buildCampaignCard(CampaignModel campaign, DateTime now) {
    final isCompleted = campaign.status == 'completed' || now.isAfter(campaign.endDate);
    final isPolio = campaign.type.toLowerCase().contains('polio');
    final vaccineLabel = isPolio ? 'OPV (Polio Vaccine)' : campaign.type;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: lightGreenBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPolio ? Icons.shield_outlined : Icons.campaign_outlined,
              color: primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        campaign.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.grey.shade200 : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isCompleted ? 'Completed' : 'Active',
                        style: TextStyle(
                          color: isCompleted ? Colors.grey.shade700 : primaryGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _campaignInfoLine(Icons.vaccines_outlined, 'Vaccine: $vaccineLabel'),
                const SizedBox(height: 4),
                _campaignInfoLine(
                  Icons.place_outlined,
                  'Target Area: ${campaign.targetAreas.isNotEmpty ? campaign.targetAreas.join(', ') : 'N/A'}',
                ),
                const SizedBox(height: 4),
                _campaignInfoLine(
                  Icons.calendar_today_outlined,
                  '${DateFormat('dd MMM').format(campaign.startDate)} – ${DateFormat('dd MMM yyyy').format(campaign.endDate)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _campaignInfoLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: primaryGreen),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ),
      ],
    );
  }

  Widget _buildCampaignEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            _campaignTabIndex == 0 ? 'No active campaigns for this child.' : 'No completed campaigns yet.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SHARED UI HELPERS
  // ==========================================================
  Widget _buildOuterTabButton({required String title, required IconData icon, required int tabIndex}) {
    final isSelected = _outerTabIndex == tabIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _outerTabIndex = tabIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? darkGreen : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? darkGreen : Colors.grey.shade300,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignInnerTab({required String title, required int tabIndex}) {
    final isSelected = _campaignTabIndex == tabIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _campaignTabIndex = tabIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? darkGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({required String title, required int tabIndex}) {
    final isSelected = _selectedTabIndex == tabIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = tabIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? darkGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_selectedTabIndex == 0 ? Icons.event_available : Icons.verified, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            _selectedTabIndex == 0 ? 'No upcoming vaccinations found.' : 'No completed vaccinations recorded yet.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTile({
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast || !isFirst)
                  Positioned(
                    top: isFirst ? 14 : 0,
                    bottom: isLast ? 14 : 0,
                    child: Container(width: 2, color: Colors.grey.shade300),
                  ),
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                        const SizedBox(height: 2),
                        Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      badgeText,
                      style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} */
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:immunosphere2/helpers/epi_schedule_helper.dart';
import 'package:immunosphere2/models/campaign_model.dart';
import 'vaccine_details_screen.dart';
import 'campaign_details_screen.dart';

class VaccinationScheduleScreen extends StatefulWidget {
  final String? childId;
  final String childName;
  final String? parentCNIC;

  const VaccinationScheduleScreen({
    Key? key,
    this.childId,
    this.childName = 'Ali Ahmad',
    this.parentCNIC,
  }) : super(key: key);

  @override
  State<VaccinationScheduleScreen> createState() =>
      _VaccinationScheduleScreenState();
}

class _VaccinationScheduleScreenState extends State<VaccinationScheduleScreen> {
  int _outerTabIndex = 0; // 0: Routine, 1: Campaigns
  int _selectedTabIndex = 0; // Routine -> 0: Upcoming, 1: Completed
  int _campaignTabIndex = 0; // Campaigns -> 0: Active, 1: Completed

  // Unified deep-green theme (same as rest of the app)
  static const Color darkGreen = Color(0xFF0B4D30);
  static const Color primaryGreen = Color(0xFF0E7A45);
  static const Color lightGreenBg = Color(0xFFE5F7ED);
  static const Color pageBg = Color(0xFFF7F9FB);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _normalize(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  DateTime _parseDob(dynamic dobVal) {
    if (dobVal is Timestamp) return dobVal.toDate();
    if (dobVal is DateTime) return dobVal;
    if (dobVal is String && dobVal.trim().isNotEmpty) {
      return DateTime.tryParse(dobVal) ?? DateTime.now();
    }
    return DateTime.now();
  }

  String _formatAge(DateTime dob) {
    final now = DateTime.now();
    int years = now.year - dob.year;
    int months = now.month - dob.month;
    if (now.day < dob.day) months--;
    if (months < 0) {
      years--;
      months += 12;
    }
    if (years <= 0) return '$months Months';
    return '$years Years, $months Months';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderCard(),
            Expanded(
              child: _outerTabIndex == 0 ? _buildRoutineTab() : _buildCampaignsTab(),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lightGreenBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.shield_outlined, color: darkGreen, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Keep your child's vaccinations up to date for a healthy future.",
                      style: TextStyle(
                        fontSize: 11,
                        color: darkGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // HEADER: slim green top bar + white profile card + green toggle buttons
  // ==========================================================
  Widget _buildHeaderCard() {
    return Column(
      children: [
        // 1) SLIM GREEN TOP BAR — sirf back arrow + title
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: darkGreen,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Center(
                child: Text(
                  'Vaccination Schedule',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              Positioned(
                left: 4,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),

        // 2) WHITE PROFILE CARD — avatar, naam, age, gender badge
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: widget.childId != null && widget.childId!.isNotEmpty
              ? StreamBuilder<DocumentSnapshot>(
                  stream: _firestore.collection('children').doc(widget.childId).snapshots(),
                  builder: (context, snap) {
                    String gender = 'Male';
                    String ageText = '';
                    if (snap.hasData && snap.data!.exists) {
                      final data = snap.data!.data() as Map<String, dynamic>;
                      gender = (data['gender'] ?? 'Male').toString();
                      final dob = _parseDob(data['dob'] ?? data['dateOfBirth']);
                      ageText = _formatAge(dob);
                    }
                    final isMale = gender.toLowerCase() == 'male' || gender.toLowerCase() == 'boy';
                    return _profileRow(gender, ageText, isMale);
                  },
                )
              : _profileRow('Male', '', true),
        ),

        // 3) WHITE BACKGROUND STRIP — GREEN toggle buttons on top of it
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              _buildOuterTabButton(title: 'Routine', icon: Icons.shield_outlined, tabIndex: 0),
              const SizedBox(width: 10),
              _buildOuterTabButton(title: 'Campaigns', icon: Icons.campaign_outlined, tabIndex: 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileRow(String gender, String ageText, bool isMale) {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: lightGreenBg,
          child: Text(isMale ? '👦' : '👧', style: const TextStyle(fontSize: 24)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.childName,
                style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (ageText.isNotEmpty)
                Text(ageText, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  gender,
                  style: const TextStyle(color: Color(0xFF0284C7), fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // ROUTINE TAB (same logic, restyled inner toggle)
  // ==========================================================
  Widget _buildRoutineTab() {
    return Column(
      children: [
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTabButton(title: 'Upcoming', tabIndex: 0),
                _buildTabButton(title: 'Completed', tabIndex: 1),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: (widget.childId == null || widget.childId!.isEmpty)
              ? _buildEmptyState()
              : StreamBuilder<DocumentSnapshot>(
                  stream: _firestore.collection('children').doc(widget.childId).snapshots(),
                  builder: (context, childSnap) {
                    if (childSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: primaryGreen));
                    }
                    if (!childSnap.hasData || !childSnap.data!.exists) {
                      return _buildEmptyState();
                    }

                    final childData = childSnap.data!.data() as Map<String, dynamic>;
                    final dob = _parseDob(childData['dob'] ?? childData['dateOfBirth']);
                    final schedule = EpiScheduleHelper.generateEpiSchedule(dob);
                    final now = DateTime.now();

                    return StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('vaccinations')
                          .where('childId', isEqualTo: widget.childId)
                          .snapshots(),
                      builder: (context, recSnap) {
                        if (recSnap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: primaryGreen));
                        }

                        List<Map<String, dynamic>> givenRecords = [];
                        if (recSnap.hasData) {
                          for (var doc in recSnap.data!.docs) {
                            final d = doc.data() as Map<String, dynamic>;
                            dynamic rawDate = d['dateGiven'] ?? d['administeredDate'] ?? d['createdAt'];
                            String formattedDateStr = 'Done';
                            if (rawDate is Timestamp) {
                              formattedDateStr = DateFormat('dd-MM-yyyy').format(rawDate.toDate());
                            } else if (rawDate is String && rawDate.isNotEmpty) {
                              formattedDateStr = rawDate;
                            }
                            givenRecords.add({
                              'vaccineName': (d['vaccineName'] ?? '').toString(),
                              'dateGiven': formattedDateStr,
                              'status': (d['status'] ?? 'vaccinated').toString().toLowerCase(),
                            });
                          }
                        }

                        List<Map<String, dynamic>> upcomingRows = [];
                        List<Map<String, dynamic>> completedRows = [];

                        for (var stage in schedule) {
                          final DateTime dueDate = stage['dueDate'];
                          final List<String> vaccines = List<String>.from(stage['vaccines']);
                          final bool isStageDueOrPast = now.isAfter(dueDate) || now.isAtSameMomentAs(dueDate);
                          final String formattedDueDate = DateFormat('dd-MM-yyyy').format(dueDate);

                          for (var vaccine in vaccines) {
                            String targetNorm = _normalize(vaccine);
                            String? matchedDate;
                            String matchedStatus = '';

                            bool isGiven = givenRecords.any((r) {
                              String storedNorm = _normalize(r['vaccineName']);
                              bool matches = storedNorm == targetNorm ||
                                  storedNorm.contains(targetNorm) ||
                                  targetNorm.contains(storedNorm);
                              if (matches) {
                                matchedDate = r['dateGiven'];
                                matchedStatus = r['status'];
                              }
                              return matches;
                            });

                            bool isRefused = isGiven && matchedStatus == 'refused';
                            bool isMissed = !isGiven && now.isAfter(dueDate.add(const Duration(days: 14)));
                            bool isDueNow = !isGiven && isStageDueOrPast && !isMissed;

                            if (isGiven && !isRefused) {
                              completedRows.add({
                                'vaccine': vaccine,
                                'stage': stage['stage'],
                                'date': matchedDate ?? 'Done',
                              });
                            } else {
                              String badge;
                              Color color;
                              Color bg;
                              if (isRefused) {
                                badge = 'Refused';
                                color = Colors.red;
                                bg = const Color(0xFFFEF2F2);
                              } else if (isMissed) {
                                badge = 'Missed';
                                color = Colors.red;
                                bg = const Color(0xFFFEF2F2);
                              } else if (isDueNow) {
                                badge = 'Due Now';
                                color = Colors.orange;
                                bg = const Color(0xFFFFF7ED);
                              } else {
                                badge = 'Upcoming';
                                color = const Color(0xFF0284C7);
                                bg = const Color(0xFFE0F2FE);
                              }
                              upcomingRows.add({
                                'vaccine': vaccine,
                                'stage': stage['stage'],
                                'dueDate': formattedDueDate,
                                'badge': badge,
                                'color': color,
                                'bg': bg,
                              });
                            }
                          }
                        }

                        final rows = _selectedTabIndex == 0 ? upcomingRows : completedRows;
                        if (rows.isEmpty) return _buildEmptyState();

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          itemCount: rows.length,
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            final isFirst = index == 0;
                            final isLast = index == rows.length - 1;

                            if (_selectedTabIndex == 0) {
                              return _buildTimelineTile(
                                title: row['vaccine'],
                                subtitle: '${row['stage']} • Due on ${row['dueDate']}',
                                badgeText: row['badge'],
                                badgeColor: row['color'],
                                badgeBg: row['bg'],
                                isFirst: isFirst,
                                isLast: isLast,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VaccineDetailsScreen(
                                        childId: widget.childId!,
                                        vaccineName: row['vaccine'],
                                        stageLabel: row['stage'],
                                        isCompleted: false,
                                      ),
                                    ),
                                  );
                                },
                              );
                            } else {
                              return _buildTimelineTile(
                                title: row['vaccine'],
                                subtitle: '${row['stage']} • Given on ${row['date']}',
                                badgeText: 'Completed',
                                badgeColor: primaryGreen,
                                badgeBg: lightGreenBg,
                                isFirst: isFirst,
                                isLast: isLast,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VaccineDetailsScreen(
                                        childId: widget.childId!,
                                        vaccineName: row['vaccine'],
                                        stageLabel: row['stage'],
                                        isCompleted: true,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==========================================================
  // CAMPAIGNS TAB — sirf isi bachay ki campaigns
  // campaign_assignments collection se childId match karke
  // ==========================================================
  Widget _buildCampaignsTab() {
    if (widget.childId == null || widget.childId!.isEmpty) {
      return _buildCampaignEmptyState();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('campaign_assignments')
          .where('childId', isEqualTo: widget.childId)
          .snapshots(),
      builder: (context, assignSnap) {
        if (assignSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primaryGreen));
        }

        final assignDocs = assignSnap.data?.docs ?? [];
        final campaignIds = assignDocs
            .map((d) => (d.data() as Map<String, dynamic>)['campaignId']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();

        if (campaignIds.isEmpty) return _buildCampaignEmptyState();

        return FutureBuilder<List<CampaignModel>>(
          future: _fetchCampaignsByIds(campaignIds),
          builder: (context, campSnap) {
            if (campSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: primaryGreen));
            }

            final campaigns = campSnap.data ?? [];
            final now = DateTime.now();

            final active = campaigns.where((c) => !(c.status == 'completed' || now.isAfter(c.endDate))).toList();
            final completed = campaigns.where((c) => (c.status == 'completed' || now.isAfter(c.endDate))).toList();
            final shownList = _campaignTabIndex == 0 ? active : completed;

            return Column(
              children: [
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildCampaignInnerTab(title: 'Active (${active.length})', tabIndex: 0),
                        _buildCampaignInnerTab(title: 'Completed (${completed.length})', tabIndex: 1),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _campaignTabIndex == 0 ? 'Active Campaigns' : 'Completed Campaigns',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: shownList.isEmpty
                      ? _buildCampaignEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          itemCount: shownList.length,
                          itemBuilder: (context, index) => _buildCampaignCard(shownList[index], now),
                        ),
                ),
                if (shownList.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, size: 16, color: Color(0xFF2563EB)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Campaign vaccinations are different from routine vaccines. They are conducted for specific target groups and areas.',
                              style: TextStyle(fontSize: 10.5, color: Color(0xFF1E3A8A)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<CampaignModel>> _fetchCampaignsByIds(List<String> ids) async {
    final List<CampaignModel> result = [];
    for (var i = 0; i < ids.length; i += 10) {
      final end = (i + 10 > ids.length) ? ids.length : i + 10;
      final chunk = ids.sublist(i, end);
      if (chunk.isEmpty) continue;
      final snap = await _firestore.collection('campaigns').where(FieldPath.documentId, whereIn: chunk).get();
      for (var doc in snap.docs) {
        result.add(CampaignModel.fromMap(doc.data(), doc.id));
      }
    }
    result.sort((a, b) => b.startDate.compareTo(a.startDate));
    return result;
  }

  Widget _buildCampaignCard(CampaignModel campaign, DateTime now) {
    final isCompleted = campaign.status == 'completed' || now.isAfter(campaign.endDate);
    final isPolio = campaign.type.toLowerCase().contains('polio');
    final vaccineLabel = isPolio ? 'OPV (Polio Vaccine)' : campaign.type;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CampaignDetailsScreen(
              campaign: campaign,
              childId: widget.childId!,
            ),
          ),
        );
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: lightGreenBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPolio ? Icons.shield_outlined : Icons.campaign_outlined,
              color: primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        campaign.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.grey.shade200 : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isCompleted ? 'Completed' : 'Active',
                        style: TextStyle(
                          color: isCompleted ? Colors.grey.shade700 : primaryGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _campaignInfoLine(Icons.vaccines_outlined, 'Vaccine: $vaccineLabel'),
                const SizedBox(height: 4),
                _campaignInfoLine(
                  Icons.place_outlined,
                  'Target Area: ${campaign.targetAreas.isNotEmpty ? campaign.targetAreas.join(', ') : 'N/A'}',
                ),
                const SizedBox(height: 4),
                _campaignInfoLine(
                  Icons.calendar_today_outlined,
                  '${DateFormat('dd MMM').format(campaign.startDate)} – ${DateFormat('dd MMM yyyy').format(campaign.endDate)}',
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _campaignInfoLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: primaryGreen),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ),
      ],
    );
  }

  Widget _buildCampaignEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            _campaignTabIndex == 0 ? 'No active campaigns for this child.' : 'No completed campaigns yet.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SHARED UI HELPERS
  // ==========================================================
  Widget _buildOuterTabButton({required String title, required IconData icon, required int tabIndex}) {
    final isSelected = _outerTabIndex == tabIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _outerTabIndex = tabIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? darkGreen : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? darkGreen : Colors.grey.shade300,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignInnerTab({required String title, required int tabIndex}) {
    final isSelected = _campaignTabIndex == tabIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _campaignTabIndex = tabIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? darkGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({required String title, required int tabIndex}) {
    final isSelected = _selectedTabIndex == tabIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = tabIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? darkGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_selectedTabIndex == 0 ? Icons.event_available : Icons.verified, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            _selectedTabIndex == 0 ? 'No upcoming vaccinations found.' : 'No completed vaccinations recorded yet.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTile({
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
    bool isFirst = false,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast || !isFirst)
                  Positioned(
                    top: isFirst ? 14 : 0,
                    bottom: isLast ? 14 : 0,
                    child: Container(width: 2, color: Colors.grey.shade300),
                  ),
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                          const SizedBox(height: 2),
                          Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        badgeText,
                        style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}