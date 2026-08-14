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

  // Helper to format CNIC with standard dashes (XXXXX-XXXXXXX-X)
  String get _formattedCNIC {
    String clean = _cleanCNIC;
    if (clean.length == 13) {
      return "${clean.substring(0, 5)}-${clean.substring(5, 12)}-${clean.substring(12)}";
    }
    return widget.parentCNIC;
  }

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
                .where('parentCNIC', whereIn: [_cleanCNIC, _formattedCNIC])
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
                          .collection('vaccine_records')
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
                                (data['parentCNIC'] ?? data['cnic'] ?? '')
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
}