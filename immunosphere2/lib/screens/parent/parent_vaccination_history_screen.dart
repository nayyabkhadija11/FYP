/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParentVaccinationHistoryScreen extends StatefulWidget {
  final String parentCNIC;

  const ParentVaccinationHistoryScreen({
    Key? key,
    required this.parentCNIC,
  }) : super(key: key);

  static const Color primaryGreen = Color(0xFF0E9F6E);

  @override
  State<ParentVaccinationHistoryScreen> createState() =>
      _ParentVaccinationHistoryScreenState();
}

class _ParentVaccinationHistoryScreenState
    extends State<ParentVaccinationHistoryScreen> {
  String _selectedChildId = 'all';

  // Helper to remove dashes and spaces from CNIC
  String get _cleanCNIC => widget.parentCNIC.replaceAll('-', '').trim();

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Vaccination History',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('children')
                .where('cnic', isEqualTo: _cleanCNIC)
                .snapshots(),
            builder: (context, childrenSnapshot) {
              if (childrenSnapshot.hasError) {
                return const Center(
                  child: Text('Error loading children data.'),
                );
              }

              if (childrenSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: ParentVaccinationHistoryScreen.primaryGreen,
                  ),
                );
              }

              final childrenDocs = childrenSnapshot.data?.docs ?? [];

              // Collect all matching Child IDs for filtering vaccine records
              final Set<String> parentChildIds = {};
              for (var doc in childrenDocs) {
                final data = doc.data() as Map<String, dynamic>;
                parentChildIds.add(doc.id);
                if (data['childId'] != null) {
                  parentChildIds.add(data['childId'].toString());
                }
                if (data['id'] != null) {
                  parentChildIds.add(data['id'].toString());
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. DYNAMIC FILTER CHIPS ROW
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'All Children',
                          isSelected: _selectedChildId == 'all',
                          onTap: () {
                            setState(() {
                              _selectedChildId = 'all';
                            });
                          },
                        ),
                        ...childrenDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final String childId =
                              (data['childId'] ?? doc.id).toString();
                          final String childName = data['childName'] ??
                              data['fullName'] ??
                              data['name'] ??
                              'Child';

                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: _buildFilterChip(
                              label: childName,
                              isSelected: _selectedChildId == childId,
                              onTap: () {
                                setState(() {
                                  _selectedChildId = childId;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. VACCINATION HISTORY LIST
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('vaccinations')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Error loading vaccination history.'),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color:
                                  ParentVaccinationHistoryScreen.primaryGreen,
                            ),
                          );
                        }

                        final allRecords = snapshot.data?.docs ?? [];

                        if (allRecords.isEmpty) {
                          return _buildEmptyState();
                        }

                        // Filter completed records corresponding to this parent's children
                        var filteredRecords = allRecords.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;

                          final status = (data['status'] ?? '')
                              .toString()
                              .toLowerCase()
                              .trim();
                          final isDone = data['isDone'] == true ||
                              data['administered'] == true ||
                              data['isGiven'] == true;

                          bool isCompleted = status == 'completed' ||
                              status == 'done' ||
                              status == 'administered' ||
                              status == 'given' ||
                              status == 'vaccinated' ||
                              isDone;

                          // Default fallback if status/isDone are undefined in manual records
                          if (data['status'] == null && data['isDone'] == null) {
                            isCompleted = true;
                          }

                          if (!isCompleted) return false;

                          final String recordChildId =
                              (data['childId'] ?? data['child_id'] ?? '')
                                  .toString();

                          // Filter by selected child filter chip
                          if (_selectedChildId != 'all') {
                            return recordChildId == _selectedChildId;
                          } else {
                            String recCNIC =
                                (data['cnic'] ?? data['parentCNIC'] ?? '')
                                    .toString()
                                    .replaceAll('-', '')
                                    .trim();
                            String recParentId = (data['parentId'] ??
                                    data['parentUid'] ??
                                    '')
                                .toString();

                            bool matchCNIC = _cleanCNIC.isNotEmpty &&
                                recCNIC == _cleanCNIC;
                            bool matchUID = currentUserId != null &&
                                currentUserId.isNotEmpty &&
                                recParentId == currentUserId;
                            bool belongsToParentChild =
                                parentChildIds.contains(recordChildId);

                            return matchCNIC || matchUID || belongsToParentChild;
                          }
                        }).toList();

                        if (filteredRecords.isEmpty) {
                          return _buildEmptyState();
                        }

                        return ListView.separated(
                          itemCount: filteredRecords.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final data = filteredRecords[index].data()
                                as Map<String, dynamic>;

                            return _buildHistoryCard(
                              childName: data['childName'] ??
                                  data['fullName'] ??
                                  data['name'] ??
                                  'Child',
                              vaccineName: data['vaccineName'] ??
                                  data['vaccine'] ??
                                  data['title'] ??
                                  'Vaccine',
                              date: _formatDate(data['administeredDate'] ??
                                  data['date'] ??
                                  data['givenDate'] ??
                                  data['updatedAt']),
                              location: data['centerName'] ??
                                  data['location'] ??
                                  data['hospital'] ??
                                  'BHU Center',
                              batchNo: data['batchNumber'] ??
                                  data['batchNo'] ??
                                  'N/A',
                              isVerified: data['isVerified'] ?? true,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
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
          Icon(
            Icons.history_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No completed vaccination records found.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return 'N/A';
    try {
      DateTime? dt;
      if (rawDate is Timestamp) {
        dt = rawDate.toDate();
      } else if (rawDate is DateTime) {
        dt = rawDate;
      } else if (rawDate is String) {
        dt = DateTime.tryParse(rawDate);
      }

      if (dt != null) {
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      }
    } catch (_) {}
    return rawDate.toString();
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? ParentVaccinationHistoryScreen.primaryGreen
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? ParentVaccinationHistoryScreen.primaryGreen
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard({
    required String childName,
    required String vaccineName,
    required String date,
    required String location,
    required String batchNo,
    bool isVerified = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                childName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                ),
              ),
              if (isVerified)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F7ED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Verified',
                    style: TextStyle(
                      color: ParentVaccinationHistoryScreen.primaryGreen,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            vaccineName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                date,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.location_on_outlined,
                  size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Batch: $batchNo',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
              const Text(
                'Digital Certificate Available',
                style: TextStyle(
                  fontSize: 10,
                  color: ParentVaccinationHistoryScreen.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} */
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:immunosphere2/helpers/epi_schedule_helper.dart';
import 'vaccination_certificates_screen.dart';

class ParentVaccinationHistoryScreen extends StatefulWidget {
  final String parentCNIC;

  const ParentVaccinationHistoryScreen({
    Key? key,
    required this.parentCNIC,
  }) : super(key: key);

  @override
  State<ParentVaccinationHistoryScreen> createState() =>
      _ParentVaccinationHistoryScreenState();
}

class _ParentVaccinationHistoryScreenState extends State<ParentVaccinationHistoryScreen> {
  static const Color darkGreen = Color(0xFF0B4D30);
  static const Color primaryGreen = Color(0xFF0E7A45);
  static const Color lightGreenBg = Color(0xFFE5F7ED);

  String? _selectedChildId;
  String _selectedChildName = '';

  String get _cleanCNIC => widget.parentCNIC.replaceAll('-', '').trim();

  DateTime _parseDob(dynamic dobVal) {
    if (dobVal is Timestamp) return dobVal.toDate();
    if (dobVal is DateTime) return dobVal;
    if (dobVal is String && dobVal.trim().isNotEmpty) {
      return DateTime.tryParse(dobVal) ?? DateTime.now();
    }
    return DateTime.now();
  }

  String _normalize(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: darkGreen,
              child: const Center(
                child: Text(
                  'History',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                "View your child's past vaccination records and download certificates.",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('children')
                    .where('cnic', isEqualTo: _cleanCNIC)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: primaryGreen));
                  }
                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'No children registered yet.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ),
                    );
                  }

                  // Default select the first child once loaded
                  if (_selectedChildId == null ||
                      !docs.any((d) => d.id == _selectedChildId)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      final firstData = docs.first.data() as Map<String, dynamic>;
                      setState(() {
                        _selectedChildId = docs.first.id;
                        _selectedChildName = (firstData['fullName'] ?? firstData['name'] ?? 'Child').toString();
                      });
                    });
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 84,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: docs.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 14),
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final name = (data['fullName'] ?? data['name'] ?? 'Child').toString();
                              final gender = (data['gender'] ?? 'Male').toString();
                              final isSelected = doc.id == _selectedChildId;
                              final isMale = gender.toLowerCase() == 'male' || gender.toLowerCase() == 'boy';

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedChildId = doc.id;
                                    _selectedChildName = name;
                                  });
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? primaryGreen : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: lightGreenBg,
                                        child: Text(isMale ? '👦' : '👧', style: const TextStyle(fontSize: 22)),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? primaryGreen : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_selectedChildId != null)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VaccinationCertificatesScreen(
                                    childId: _selectedChildId!,
                                    childName: _selectedChildName,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: lightGreenBg, borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.description_outlined, color: primaryGreen, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Vaccination Certificates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        SizedBox(height: 2),
                                        Text('Download your child\'s certificates', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),

                        if (_selectedChildId != null) _buildStatusBanner(_selectedChildId!),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(String childId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('children').doc(childId).snapshots(),
      builder: (context, childSnap) {
        if (!childSnap.hasData || !childSnap.data!.exists) return const SizedBox.shrink();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('vaccinations')
              .where('childId', isEqualTo: childId)
              .snapshots(),
          builder: (context, vaccSnap) {
            final childData = childSnap.data!.data() as Map<String, dynamic>;
            final dob = _parseDob(childData['dob'] ?? childData['dateOfBirth']);
            final schedule = EpiScheduleHelper.generateEpiSchedule(dob);
            final now = DateTime.now();

            final givenNames = (vaccSnap.data?.docs ?? []).map((d) {
              final data = d.data() as Map<String, dynamic>;
              return _normalize((data['vaccineName'] ?? '').toString());
            }).toList();

            bool hasOverdue = false;
            for (var stage in schedule) {
              final DateTime dueDate = stage['dueDate'];
              final List<String> vaccines = List<String>.from(stage['vaccines']);
              for (var vaccine in vaccines) {
                final targetNorm = _normalize(vaccine);
                final isGiven = givenNames.any((n) => n == targetNorm || n.contains(targetNorm) || targetNorm.contains(n));
                if (!isGiven && now.isAfter(dueDate)) {
                  hasOverdue = true;
                  break;
                }
              }
              if (hasOverdue) break;
            }

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: hasOverdue ? const Color(0xFFFFF7ED) : lightGreenBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    hasOverdue ? Icons.warning_amber_rounded : Icons.shield_outlined,
                    color: hasOverdue ? Colors.orange.shade800 : darkGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasOverdue
                          ? "$_selectedChildName has a vaccination that is overdue."
                          : "$_selectedChildName's vaccination history is up to date.",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasOverdue ? Colors.orange.shade800 : darkGreen,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}