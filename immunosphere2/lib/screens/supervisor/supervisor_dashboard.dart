import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../models/campaign_model.dart';
import '../../services/campaign_service.dart';
import 'vaccinators_screen.dart';
import 'reports_screen.dart';
import 'campaigns_screen.dart';
import 'profile_screen.dart';
import 'view_all_screen.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({Key? key}) : super(key: key);

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CampaignService _campaignService = CampaignService();

  int _currentIndex = 0;

  // Supervisor ki hidayat: sirf DHQ Hospital Attock ka data.
  static const String selectedCenter = 'DHQ Hospital Attock';

  static const Color headerGreen = Color(0xFF025E37);
  static const Color primaryGreen = Color(0xFF018749);
  static const Color lightBgGreen = Color(0xFFEBF7F0);
  static const Color cardBg = Colors.white;
  static const Color scaffoldBg = Color(0xFFF7F9F8);

  late Future<_DashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // ---------------- Real data: DHQ Hospital Attock ke vaccinators + children ----------------

  Future<_DashboardStats> _loadStats() async {
    // Same established pattern jo baaki reports mein use hui: valid_employees
    // hi healthCenter ka source-of-truth hai.
    final employeesSnap = await _db
        .collection('valid_employees')
        .where('healthCenter', isEqualTo: selectedCenter)
        .get();

    final employeeIds = employeesSnap.docs
        .where((d) => (d.data()['role'] ?? '').toString().trim().toLowerCase() == 'vaccinator')
        .map((d) => d.id)
        .toList();

    final List<String> vaccinatorUids = [];
    for (int i = 0; i < employeeIds.length; i += 30) {
      final chunk = employeeIds.sublist(i, (i + 30 > employeeIds.length) ? employeeIds.length : i + 30);
      if (chunk.isEmpty) continue;
      final snap = await _db.collection('users').where('employeeId', whereIn: chunk).get();
      vaccinatorUids.addAll(snap.docs.map((d) => d.id));
    }

    int childrenCount = 0;
    try {
      final countSnap = await _db.collection('children').count().get();
      childrenCount = countSnap.count ?? 0;
    } catch (_) {
      // Agar count() aggregation query available na ho (purana Firestore
      // SDK), to fallback mein sab docs fetch kar ke count kar lete hain.
      final snap = await _db.collection('children').get();
      childrenCount = snap.docs.length;
    }

    // Is supervisor ki campaigns mein se koi active (not completed, aaj ki
    // date range ke andar) campaign dhoondte hain.
    CampaignModel? activeCampaign;
    try {
      final campaigns = await _campaignService.getCampaignsBySupervisor(_uid ?? '');
      final now = DateTime.now();
      for (var c in campaigns) {
        final isCompleted = c.status == 'completed' || now.isAfter(c.endDate);
        if (!isCompleted) {
          activeCampaign = c;
          break;
        }
      }
    } catch (_) {}

    return _DashboardStats(
      childrenCount: childrenCount,
      vaccinatorsCount: vaccinatorUids.length,
      activeCampaign: activeCampaign,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardContent(),
          const VaccinatorsScreen(),
          const ReportsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -3))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primaryGreen,
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), label: 'Vaccinators'),
            BottomNavigationBarItem(icon: Icon(Icons.insert_drive_file_outlined), label: 'Reports'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return _uid == null
        ? const Center(child: Text('Not logged in'))
        : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _db.collection('users').doc(_uid).snapshots(),
            builder: (context, userSnap) {
              if (!userSnap.hasData) {
                return const Center(child: CircularProgressIndicator(color: primaryGreen));
              }
              final user = userSnap.data!.data() ?? {};

              return SingleChildScrollView(
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildHeader(user),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: -22,
                          child: _buildActiveCampaignCard(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopStatsGrid(),
                          const SizedBox(height: 14),
                          _buildQuickActions(context),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildHeader(Map<String, dynamic> user) {
    return Container(
      width: double.infinity,
      color: headerGreen,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 36, bottom: 58),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting(), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      user['fullName'] ?? user['name'] ?? 'Supervisor',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user['designation'] ?? 'Immunization Supervisor',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white70, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          (user['healthCenter'] ?? selectedCenter).toString(),
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white24,
                backgroundImage: user['photoUrl'] != null ? NetworkImage(user['photoUrl']) : null,
                child: user['photoUrl'] == null ? const Icon(Icons.person, color: Colors.white, size: 28) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCampaignCard() {
    return FutureBuilder<_DashboardStats>(
      future: _statsFuture,
      builder: (context, snap) {
        final campaign = snap.data?.activeCampaign;

        final dateRange = campaign != null
            ? '${DateFormat('dd MMM').format(campaign.startDate)} \u2013 ${DateFormat('dd MMM yyyy').format(campaign.endDate)}'
            : '';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: lightBgGreen, shape: BoxShape.circle),
                child: const Icon(Icons.campaign_outlined, color: primaryGreen, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(radius: 2.5, backgroundColor: primaryGreen),
                        const SizedBox(width: 4),
                        Text(
                          campaign != null ? 'Active Campaign' : 'No Active Campaign',
                          style: const TextStyle(fontSize: 10, color: primaryGreen, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      campaign?.name ?? 'No campaign currently running',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (campaign != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 10, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(dateRange, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CampaignsScreen()));
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(border: Border.all(color: primaryGreen.withOpacity(0.4)), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: const [
                      Text('View Details', style: TextStyle(fontSize: 10, color: primaryGreen, fontWeight: FontWeight.w600)),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 12, color: primaryGreen),
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopStatsGrid() {
    return FutureBuilder<_DashboardStats>(
      future: _statsFuture,
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final childrenCount = snap.data?.childrenCount ?? 0;
        final vaccinatorsCount = snap.data?.vaccinatorsCount ?? 0;

        return Row(
          children: [
            Expanded(
              child: _topStatCard(
                icon: Icons.groups_outlined,
                title: 'Registered Children',
                value: loading ? '-' : '$childrenCount',
                subtext: 'Total unique children\nregistered in the system',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _topStatCard(
                icon: Icons.person_outline,
                title: 'Vaccinators',
                value: loading ? '-' : '$vaccinatorsCount',
                subtext: 'Active vaccinators\nin your area',
                onTap: () => setState(() => _currentIndex = 1),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _topStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtext,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: lightBgGreen, shape: BoxShape.circle),
                  child: Icon(icon, color: primaryGreen, size: 22),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(title, style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                      const Icon(Icons.info_outline, size: 12, color: Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryGreen)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: Text(subtext, style: const TextStyle(fontSize: 9, color: Colors.grey, height: 1.2))),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: lightBgGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.chevron_right, size: 14, color: primaryGreen),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _actionButton(
                icon: Icons.lightbulb_outline,
                title: 'AI Insights',
                subtitle: 'View predictions & alerts',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ViewAllScreen()));
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionButton(
                icon: Icons.campaign_outlined,
                title: 'Campaigns',
                subtitle: 'View & manage campaigns',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CampaignsScreen()));
                },
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _actionButton({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: lightBgGreen, shape: BoxShape.circle),
              child: Icon(icon, color: primaryGreen, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _DashboardStats {
  final int childrenCount;
  final int vaccinatorsCount;
  final CampaignModel? activeCampaign;

  _DashboardStats({
    required this.childrenCount,
    required this.vaccinatorsCount,
    required this.activeCampaign,
  });
}