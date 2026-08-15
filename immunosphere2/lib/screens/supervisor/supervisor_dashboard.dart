import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Imports verified matching
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

  int _currentIndex = 0;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 👋';
    if (hour < 17) return 'Good Afternoon 👋';
    return 'Good Evening 👋';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Index 0: Dashboard Content
          _buildDashboardContent(),

          // Index 1: Vaccinators Screen
          const VaccinatorsScreen(),

          // Index 2: Integrated Reports Screen
          const ReportsScreen(),

          // Index 3: Profile Screen
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF231B92),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined),
              label: 'Vaccinators',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // DASHBOARD TAB CONTENT
  // ==========================================
  Widget _buildDashboardContent() {
    return SafeArea(
      child: _uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _db.collection('users').doc(_uid).snapshots(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final user = userSnap.data!.data() ?? {};

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(user),
                      const SizedBox(height: 16),
                      _buildActiveCampaign(),
                      const SizedBox(height: 16),
                      _buildStatsGrid(),
                      const SizedBox(height: 20),
                      _buildQuickActions(context),
                      const SizedBox(height: 20),
                      _buildAlerts(),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // ==========================================
  // HEADER
  // ==========================================
  Widget _buildHeader(Map<String, dynamic> user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF231B92),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            backgroundImage: user['photoUrl'] != null
                ? NetworkImage(user['photoUrl'])
                : null,
            child: user['photoUrl'] == null
                ? const Icon(Icons.person, color: Colors.white, size: 32)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting(),
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
                Text(
                  user['fullName'] ?? 'Dr. Ahmed Khan',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '${user['designation'] ?? 'EPI Supervisor'} • ${user['location'] ?? 'BHU Jand, Attock'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.notifications_none, color: Colors.white),
        ],
      ),
    );
  }

  // ==========================================
  // ACTIVE CAMPAIGN CARD (WITH NAVIGATION)
  // ==========================================
  Widget _buildActiveCampaign() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('campaigns')
          .where('status', isEqualTo: 'active')
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final c = snap.data!.docs.first.data();
        final start = (c['startDate'] as Timestamp?)?.toDate();
        final end = (c['endDate'] as Timestamp?)?.toDate();
        final dateRange = (start != null && end != null)
            ? '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}'
            : '';

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CampaignsScreen()),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: Color(0xFF231B92), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          const Text('Active Campaign',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF231B92),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(c['name'] ?? 'National Polio Campaign (Aug 2026)',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(dateRange.isNotEmpty ? dateRange : '10 Aug - 15 Aug 2026',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF231B92)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // REAL-TIME STATS GRID (6 STAT CARDS)
  // ==========================================
  Widget _buildStatsGrid() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('users')
          .where('role', whereIn: ['vaccinator', 'Vaccinator', 'VACCINATOR'])
          .snapshots(),
      builder: (context, vaccinatorsSnap) {
        final dynamicVaccinatorsCount =
            vaccinatorsSnap.data?.docs.length ?? 0;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db.collection('children').snapshots(),
          builder: (context, childrenSnap) {
            final childrenDocs = childrenSnap.data?.docs ?? [];
            final dynamicChildrenCount = childrenDocs.length;

            final totalVaccinatedCount = childrenDocs.where((doc) {
              final data = doc.data();
              final status = (data['status'] ?? data['vaccinationStatus'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();
              return status == 'vaccinated' || status == 'done' || status == 'completed';
            }).length;

            final coveragePercent = dynamicChildrenCount > 0
                ? ((totalVaccinatedCount / dynamicChildrenCount) * 100).round()
                : 85;

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _db.collection('vaccinations').snapshots(),
              builder: (context, vaccinationsSnap) {
                final vaccinationDocs = vaccinationsSnap.data?.docs ?? [];

                final missedCasesCount = vaccinationDocs.where((doc) {
                  final data = doc.data();
                  final status = (data['status'] ?? '').toString().trim().toLowerCase();
                  return status == 'missed' || status == 'defaulter';
                }).length;

                final pendingReportsCount = vaccinationDocs.where((doc) {
                  final data = doc.data();
                  final status = (data['status'] ?? '').toString().trim().toLowerCase();
                  return status == 'pending' || status == 'refused' || status == 'refusal';
                }).length;

                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _currentIndex = 1;
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: _statCard(
                        Icons.person_outline,
                        '$dynamicVaccinatorsCount',
                        'Vaccinators',
                        const Color(0xFF231B92),
                      ),
                    ),
                    _statCard(
                      Icons.center_focus_weak,
                      '$dynamicChildrenCount',
                      'Registered Children',
                      const Color(0xFF2E7D32),
                    ),
                    _statCard(
                      Icons.assignment_outlined,
                      '$totalVaccinatedCount',
                      'Vaccinations Today',
                      const Color(0xFF231B92),
                    ),
                    _statCard(
                      Icons.person_remove_outlined,
                      '$missedCasesCount',
                      'Missed Cases',
                      const Color(0xFFD32F2F),
                    ),
                    _statCard(
                      Icons.medical_services_outlined,
                      '$coveragePercent%',
                      'Coverage',
                      const Color(0xFF2E7D32),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _currentIndex = 2;
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: _statCard(
                        Icons.shopping_bag_outlined,
                        '$pendingReportsCount',
                        'Pending Reports',
                        const Color(0xFFD84315),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Icon(icon, color: color, size: 24),
            ],
          ),
          const Spacer(),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ==========================================
  // QUICK ACTIONS (AI INSIGHTS & CAMPAIGNS)
  // ==========================================
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Quick Actions',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () {
                // Navigates to ViewAllScreen when "View All" is clicked
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ViewAllScreen()),
                );
              },
              child: const Text('View All',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF231B92),
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _actionCard(
                icon: Icons.settings_suggest_outlined,
                label: 'AI Insights',
                iconColor: const Color(0xFF231B92),
                bgColor: const Color(0xFFF3F1FD),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navigating to AI Insights...')),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionCard(
                icon: Icons.campaign_outlined,
                label: 'Campaigns',
                iconColor: const Color(0xFF2E7D32),
                bgColor: const Color(0xFFEFF7F2),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CampaignsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ALERTS
  // ==========================================
  Widget _buildAlerts() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('alerts')
          .where('active', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('All Alerts',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (docs.isEmpty)
              const Text('No active alerts',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ...docs.map((d) {
              final a = d.data();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFFFA726), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(a['message'] ?? '',
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}