import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:immunosphere2/helpers/vaccination_status_helper.dart';

import 'register_child_screen.dart';
import 'search_child_screen.dart';
import 'vaccination_entry_screen.dart';
import 'scan_qr_screen.dart';
import 'vaccinator_profile_screen.dart';
import 'reports_screen.dart';
import 'campaigns_list_screen.dart'; 

class VaccinatorDashboardScreen extends StatefulWidget {
  const VaccinatorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<VaccinatorDashboardScreen> createState() => _VaccinatorDashboardScreenState();
}

class _VaccinatorDashboardScreenState extends State<VaccinatorDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardHomeContent(),
    const SearchChildScreen(), 
    const CampaignsListScreen(),
    const ReportsScreen(),            
    const VaccinatorProfileScreen(),  
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: Colors.grey.shade400,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        backgroundColor: Colors.white,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded, size: 20),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.badge_outlined, size: 20),
            label: 'Children',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined, size: 20),
            label: 'Campaigns',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline, size: 20),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 20),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class DashboardHomeContent extends StatefulWidget {
  const DashboardHomeContent({Key? key}) : super(key: key);

  @override
  State<DashboardHomeContent> createState() => _DashboardHomeContentState();
}

class _DashboardHomeContentState extends State<DashboardHomeContent> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  StreamSubscription<QuerySnapshot>? _campaignSubscription;
  String? _lastNotifiedCampaignId;

  @override
  void initState() {
    super.initState();
    _listenForActiveCampaigns();
  }

  @override
  void dispose() {
    _campaignSubscription?.cancel();
    super.dispose();
  }

  void _listenForActiveCampaigns() {
    if (_currentUser == null) return;

    _campaignSubscription = FirebaseFirestore.instance
        .collection('campaigns')
        .where('status', isEqualTo: 'active')
        .where('assignedVaccinators', arrayContains: _currentUser?.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs.first;
        String campaignId = doc.id;
        var data = doc.data() as Map<String, dynamic>;

        if (_lastNotifiedCampaignId != campaignId && mounted) {
          _lastNotifiedCampaignId = campaignId;
          _showCampaignPopUp(
            title: data['title'] ?? 'National Polio Campaign',
            dateRange: data['dateRange'] ?? 'Active Now',
          );
        }
      }
    });
  }

  void _showCampaignPopUp({required String title, required String dateRange}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: Color(0xFF10B981),
                    size: 38,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'New Campaign Active!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                ),
                const SizedBox(height: 4),
                Text(
                  dateRange,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Dismiss', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CampaignsListScreen()),
                          );
                        },
                        child: const Text('View List', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _matchesCurrentVaccinator(Map<String, dynamic> data) {
    final currentUid = _currentUser?.uid;
    if (currentUid == null || currentUid.isEmpty) {
      return false;
    }

    final valuesToCheck = [
      data['registeredBy'],
      data['administeredBy'],
      data['vaccinatorId'],
      data['assignedVaccinatorId'],
      data['assignedVaccinator'],
      data['vaccinatorUid'],
      data['createdBy'],
      data['assignedTo'],
    ];

    for (final value in valuesToCheck) {
      if (value != null && value.toString().trim() == currentUid.trim()) {
        return true;
      }
    }

    final assignedVaccinators = data['assignedVaccinators'];
    if (assignedVaccinators is List) {
      for (final value in assignedVaccinators) {
        if (value != null && value.toString().trim() == currentUid.trim()) {
          return true;
        }
      }
    }

    return false;
  }

  Widget _buildEmptyDashboardState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inbox_outlined,
                  color: Color(0xFF2563EB),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No assigned work yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                'This vaccinator has not been assigned any children or campaigns yet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5C33CF), Color(0xFF4323B0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_currentUser?.uid)
                  .get(),
              builder: (context, snapshot) {
                String userName = 'Vaccinator';
                if (_currentUser?.displayName != null &&
                    _currentUser!.displayName!.isNotEmpty) {
                  userName = _currentUser!.displayName!;
                } else if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>?;
                  userName = data?['name'] ?? data?['fullName'] ?? userName;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hello, $userName 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Vaccinator',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 105, left: 14, right: 14, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- ROBUST STATS SECTION ----
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('children').snapshots(),
                    builder: (context, childrenSnapshot) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('vaccinations').snapshots(),
                        builder: (context, vaccinationsSnapshot) {
                          
                          if (!childrenSnapshot.hasData || !vaccinationsSnapshot.hasData) {
                            return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
                          }

                          final allChildDocs = childrenSnapshot.data!.docs;
                          
                          // Filter children belonging to current vaccinator
                          final assignedChildDocs = allChildDocs.where((doc) {
                            if (!doc.exists) return false;
                            final data = doc.data() as Map<String, dynamic>? ?? const {};
                            return _matchesCurrentVaccinator(data);
                          }).toList();

                          if (assignedChildDocs.isEmpty) {
                            return _buildEmptyDashboardState();
                          }

                          int totalChildren = assignedChildDocs.length;
                          int missedCount = 0;
                          int pendingCount = 0;

                          List<Map<String, dynamic>> allVaccinationDocs = vaccinationsSnapshot.data!.docs
                              .where((doc) => doc.exists)
                              .map((d) => d.data() as Map<String, dynamic>)
                              .toList();
                          
                          final grouped = VaccinationStatusHelper.groupRecordsByChildId(allVaccinationDocs);

                          for (var doc in assignedChildDocs) {
                            var data = doc.data() as Map<String, dynamic>;
                            DateTime dob = VaccinationStatusHelper.parseDob(data['dob']);

                            String docId = doc.id;
                            String regNo = (data['regNo'] ?? '').toString();
                            String childIdField = (data['childId'] ?? '').toString();

                            List<Map<String, dynamic>> childRecords = [
                              ...(grouped[docId] ?? []),
                              if (regNo.isNotEmpty) ...(grouped[regNo] ?? []),
                              if (childIdField.isNotEmpty) ...(grouped[childIdField] ?? []),
                            ];

                            final result = VaccinationStatusHelper.getChildVaccineStatus(dob, childRecords);

                            int mCount = (result['missedCount'] ?? 0) as int;
                            int rCount = (result['refusedCount'] ?? 0) as int;
                            int dCount = (result['dueCount'] ?? 0) as int;

                            bool hasRefusedOrMissedRecord = childRecords.any((rec) {
                              final status = (rec['status'] ?? '').toString().toLowerCase();
                              return status == 'refusal' || 
                                     status == 'refused' || 
                                     status == 'missed' || 
                                     status == 'skipped' || 
                                     status == 'delayed' || 
                                     status == 'defaulted';
                            });

                            if (mCount > 0 || rCount > 0 || hasRefusedOrMissedRecord) {
                              missedCount++;
                            } else if (dCount > 0) {
                              pendingCount++;
                            }
                          }

                          return GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2.1,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('vaccination_tasks')
                                    .where('status', isEqualTo: 'vaccinated')
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  final taskDocs = snapshot.data?.docs.where((doc) {
                                        if (!doc.exists) return false;
                                        final data = doc.data() as Map<String, dynamic>? ?? const {};
                                        return _matchesCurrentVaccinator(data);
                                      }).toList() ??
                                      const [];
                                  int count = taskDocs.length;
                                  return _buildExactStatCard(
                                      "Today's Vaccinations", "$count", const Color(0xFF4F46E5));
                                },
                              ),
                              _buildExactStatCard(
                                  "Registered Children", "$totalChildren", const Color(0xFF10B981)),
                              _buildExactStatCard(
                                  "Pending Cases", "$pendingCount", const Color(0xFF6366F1)),
                              _buildExactStatCard(
                                  "Missed/Refused", "$missedCount", const Color(0xFFF97316)),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // --- CAMPAIGN BANNER FILTERED FOR ASSIGNED VACCINATOR ---
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('campaigns')
                        .where('status', isEqualTo: 'active')
                        .where('assignedVaccinators', arrayContains: _currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      var campaignData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                      String title = campaignData['title'] ?? 'National Polio Campaign';
                      String dates = campaignData['dateRange'] ?? 'Active Now';
                      String area = campaignData['area'] ?? 'Mohallah A, Jand';
                      String team = campaignData['team'] ?? 'Team 07';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Active',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF15803D),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.vaccines_outlined, color: Color(0xFF10B981), size: 28),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(dates, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('Area: ', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                Text(area, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 16),
                                Text('Team: ', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                Text(team, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickActionButton(
                        icon: Icons.search_outlined,
                        label: "Search\nChild",
                        bgColor: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF8B5CF6),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SearchChildScreen(),
                            ),
                          );
                        },
                      ),
                      _buildQuickActionButton(
                        icon: Icons.person_add_alt_1_outlined,
                        label: "Register\nChild",
                        bgColor: const Color(0xFFECFDF5),
                        iconColor: const Color(0xFF10B981),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterChildScreen(),
                            ),
                          );
                        },
                      ),
                      _buildQuickActionButton(
                        icon: Icons.qr_code_scanner_outlined,
                        label: "Scan\nQR",
                        bgColor: const Color(0xFFECFDF5),
                        iconColor: const Color(0xFF10B981),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ScanQrScreen(),
                            ),
                          );
                        },
                      ),
                      _buildQuickActionButton(
                        icon: Icons.vaccines_outlined,
                        label: "Record\nVaccine",
                        bgColor: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF8B5CF6),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VaccinationEntryScreen(childData: {}),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExactStatCard(String title, String number, Color numberColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            number,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: numberColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}