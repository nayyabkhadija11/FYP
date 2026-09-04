/*import 'package:flutter/material.dart';
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
} */
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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

  // Color Palette
  static const Color headerGreen = Color(0xFF025E37);
  static const Color primaryGreen = Color(0xFF018749);
  static const Color lightBgGreen = Color(0xFFEBF7F0);
  static const Color polioBlue = Color(0xFF1D4ED8);
  static const Color polioLightBlue = Color(0xFFEFF6FF);
  static const Color cardBg = Colors.white;
  static const Color scaffoldBg = Color(0xFFF7F9F8);

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
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
          selectedItemColor: primaryGreen,
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              label: 'Vaccinators',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insert_drive_file_outlined),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profile',
            ),
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
                          bottom: -22, // Adjusted offset so card does not block top text
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
                          _buildVaccinationSummarySection(),
                          const SizedBox(height: 14),
                          _buildCoverageSection(),
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

  // GREEN HEADER WITH INCREASED BOTTOM PADDING TO PREVENT OVERLAP
  Widget _buildHeader(Map<String, dynamic> user) {
    return Container(
      width: double.infinity,
      color: headerGreen,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 36, bottom: 58),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
              Stack(
                children: [
                  const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.lightGreenAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '3',
                        style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user['fullName'] ?? 'insharae',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user['designation'] ?? 'EPI Supervisor',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white70, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          user['location'] ?? 'BHU Jand, Attock',
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
                child: user['photoUrl'] == null
                    ? const Icon(Icons.person, color: Colors.white, size: 28)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // COMPACT ACTIVE CAMPAIGN CARD
  Widget _buildActiveCampaignCard() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('campaigns').where('status', isEqualTo: 'active').limit(1).snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final c = docs.isNotEmpty ? docs.first.data() : <String, dynamic>{};

        final start = (c['startDate'] as Timestamp?)?.toDate();
        final end = (c['endDate'] as Timestamp?)?.toDate();
        final dateRange = (start != null && end != null)
            ? '${DateFormat('dd MMM').format(start)} – ${DateFormat('dd MMM yyyy').format(end)}'
            : '10 Aug – 15 Aug 2026';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            ],
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
                      children: const [
                        CircleAvatar(radius: 2.5, backgroundColor: primaryGreen),
                        SizedBox(width: 4),
                        Text(
                          'Active Campaign',
                          style: TextStyle(fontSize: 10, color: primaryGreen, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c['name'] ?? 'National Polio Campaign (Aug 2026)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 10, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(dateRange, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
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
                  decoration: BoxDecoration(
                    border: Border.all(color: primaryGreen.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(16),
                  ),
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

  // TOP STATS GRID
  Widget _buildTopStatsGrid() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('children').snapshots(),
      builder: (context, childrenSnap) {
        final childrenCount = childrenSnap.data?.docs.length ?? 0;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db.collection('users').where('role', whereIn: ['vaccinator', 'Vaccinator', 'VACCINATOR']).snapshots(),
          builder: (context, vaccinatorsSnap) {
            final vaccinatorsCount = vaccinatorsSnap.data?.docs.length ?? 0;

            return Row(
              children: [
                Expanded(
                  child: _topStatCard(
                    icon: Icons.groups_outlined,
                    title: 'Registered Children (All)',
                    value: childrenCount == 0 ? '36' : '$childrenCount',
                    subtext: 'Total unique children\nregistered in the system',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _topStatCard(
                    icon: Icons.person_outline,
                    title: 'Vaccinators',
                    value: vaccinatorsCount == 0 ? '2' : '$vaccinatorsCount',
                    subtext: 'Active vaccinators\nin your area',
                    onTap: () {
                      setState(() {
                        _currentIndex = 1;
                      });
                    },
                  ),
                ),
              ],
            );
          },
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
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                Expanded(
                  child: Text(
                    subtext,
                    style: const TextStyle(fontSize: 9, color: Colors.grey, height: 1.2),
                  ),
                ),
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

  // VACCINATION SUMMARY SECTION
  Widget _buildVaccinationSummarySection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Vaccination Summary – August 2026',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: lightBgGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.calendar_month, color: primaryGreen, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'August 2026',
                      style: TextStyle(
                        fontSize: 10,
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: primaryGreen, size: 12),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _db.collection('vaccinations').snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              final routineCount = docs
                  .where((d) => (d.data()['type'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains('routine'))
                  .length;
              final polioCount = docs
                  .where((d) => (d.data()['type'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains('polio'))
                  .length;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _summaryBox(
                      title: 'Routine Immunization',
                      titleColor: primaryGreen,
                      iconBg: lightBgGreen,
                      mainIcon: Icons.shield,
                      mainIconColor: primaryGreen,
                      val1: routineCount == 0 ? '320' : '$routineCount',
                      label1: 'Children Vaccinated',
                      val2: '486',
                      label2: 'Vaccine Doses Given',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _summaryBox(
                      title: 'Polio Campaign',
                      titleColor: polioBlue,
                      iconBg: polioLightBlue,
                      mainIcon: Icons.water_drop,
                      mainIconColor: polioBlue,
                      val1: polioCount == 0 ? '480' : '$polioCount',
                      label1: 'Children Vaccinated',
                      val2: '480',
                      label2: 'Campaign Doses Given',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lightBgGreen.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline, size: 13, color: primaryGreen),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Children Vaccinated = Unique children who received at least one vaccine/dose in the selected period.',
                    style: TextStyle(fontSize: 9, color: Colors.black87, height: 1.2),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _summaryBox({
    required String title,
    required Color titleColor,
    required Color iconBg,
    required IconData mainIcon,
    required Color mainIconColor,
    required String val1,
    required String label1,
    required String val2,
    required String label2,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconBg.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: titleColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(mainIcon, color: mainIconColor, size: 12),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: titleColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label1,
                            style: const TextStyle(fontSize: 7.5, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.info_outline, size: 8, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.accessibility_new, size: 14, color: mainIconColor),
                        const SizedBox(width: 2),
                        Text(
                          val1,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: titleColor),
                        ),
                      ],
                    ),
                    const Text('Unique children', style: TextStyle(fontSize: 7, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label2,
                            style: const TextStyle(fontSize: 7.5, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.info_outline, size: 8, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.medical_services_outlined, size: 13, color: mainIconColor),
                        const SizedBox(width: 2),
                        Text(
                          val2,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: titleColor),
                        ),
                      ],
                    ),
                    const Text('Total doses', style: TextStyle(fontSize: 7, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // COVERAGE SECTION
  Widget _buildCoverageSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vaccination Coverage (August 2026)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _coverageCard(
                  icon: Icons.verified_user_outlined,
                  title: 'Routine Immunization Coverage',
                  percentage: '85%',
                  progress: 0.85,
                  ratioText: '320 / 376',
                  color: primaryGreen,
                  bg: lightBgGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _coverageCard(
                  icon: Icons.water_drop_outlined,
                  title: 'Polio Campaign Coverage',
                  percentage: '92%',
                  progress: 0.92,
                  ratioText: '480 / 520',
                  color: polioBlue,
                  bg: polioLightBlue,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _coverageCard({
    required IconData icon,
    required String title,
    required String percentage,
    required double progress,
    required String ratioText,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(percentage, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Target: 95%', style: TextStyle(fontSize: 8, color: Colors.grey)),
                    Row(
                      children: [
                        Text(ratioText, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 2),
                        const Icon(Icons.info_outline, size: 8, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // QUICK ACTIONS SECTION
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

  Widget _actionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
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