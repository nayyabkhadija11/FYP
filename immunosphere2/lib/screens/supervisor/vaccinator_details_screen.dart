import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VaccinatorDetailsScreen extends StatefulWidget {
  final String vaccinatorId;
  final Map<String, dynamic>? initialData;

  const VaccinatorDetailsScreen({
    Key? key,
    required this.vaccinatorId,
    this.initialData,
  }) : super(key: key);

  @override
  State<VaccinatorDetailsScreen> createState() =>
      _VaccinatorDetailsScreenState();
}

class _VaccinatorDetailsScreenState extends State<VaccinatorDetailsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _selectedFilter = 'This Week';

  // 1. EXTRACT EMPLOYEE ID
  String _getEmployeeId(Map<String, dynamic> data, String docId) {
    List<String> idKeys = [
      'employeeId',
      'employee_id',
      'empId',
      'vaccinatorId',
      'id',
    ];

    for (String key in idKeys) {
      if (data.containsKey(key) &&
          data[key] != null &&
          data[key].toString().trim().isNotEmpty &&
          data[key] is! Map) {
        return data[key].toString().trim();
      }
    }

    for (var key in data.keys) {
      if (data[key] is Map && key.toString().toUpperCase().startsWith('VAC')) {
        return key.toString();
      }
    }

    return docId;
  }

  // 2. FETCH HEALTH CENTER FROM BOTH USERS & VALID_EMPLOYEES COLLECTIONS
  Future<String> _fetchHealthCenter(
      String empId, Map<String, dynamic> userData) async {
    List<String> centerKeys = [
      'healthCenter',
      'health_center',
      'healthCenterName',
      'assignedHealthCenter',
      'center',
    ];

    for (String key in centerKeys) {
      if (userData.containsKey(key) &&
          userData[key] != null &&
          userData[key].toString().trim().isNotEmpty) {
        return userData[key].toString().trim();
      }
    }

    try {
      var docSnapshot =
          await _db.collection('valid_employees').doc(empId).get();

      if (!docSnapshot.exists) {
        final querySnapshot = await _db
            .collection('valid_employees')
            .where('employeeId', isEqualTo: empId)
            .limit(1)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          docSnapshot = querySnapshot.docs.first;
        }
      }

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final empData = docSnapshot.data()!;
        for (String key in centerKeys) {
          if (empData.containsKey(key) &&
              empData[key] != null &&
              empData[key].toString().trim().isNotEmpty) {
            return empData[key].toString().trim();
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching health center: $e");
    }

    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF231B92)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Vaccinator Details',
          style: TextStyle(
            color: Color(0xFF231B92),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF231B92)),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _db.collection('users').doc(widget.vaccinatorId).snapshots(),
        builder: (context, snapshot) {
          Map<String, dynamic> data = widget.initialData ?? {};
          if (snapshot.hasData && snapshot.data!.data() != null) {
            data = snapshot.data!.data()!;
          }

          final String employeeId = _getEmployeeId(data, widget.vaccinatorId);

          // Formatting Joined Date
          String joinedDate = '12 Jan 2024';
          if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
            joinedDate = DateFormat('dd MMM yyyy')
                .format((data['createdAt'] as Timestamp).toDate());
          } else if (data['joinedOn'] != null) {
            joinedDate = data['joinedOn'].toString();
          }

          return SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TOP VACCINATOR PROFILE CARD
                _buildProfileCard(data, widget.vaccinatorId),

                const SizedBox(height: 20),

                // 2. PERFORMANCE OVERVIEW HEADER WITH FILTER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Performance Overview',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF231B92),
                      ),
                    ),
                    _buildFilterDropdown(),
                  ],
                ),

                const SizedBox(height: 12),

                // 3. STATS GRID (USING BOTH VACCINATOR ID & EMPLOYEE ID FOR SAFETY)
                _buildPerformanceGrid(widget.vaccinatorId, employeeId),

                const SizedBox(height: 20),

                // 4. DETAILS CARD
                _buildDetailsCard(data, joinedDate),

                const SizedBox(height: 24),

                // 5. PERFORMANCE REPORT BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF231B92),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opening Performance Report...'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bar_chart_rounded,
                        color: Colors.white),
                    label: const Text(
                      'Performance Report',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // PROFILE CARD WIDGET
  // ==========================================
  Widget _buildProfileCard(Map<String, dynamic> data, String docId) {
    final String name = data['fullName'] ?? data['name'] ?? 'Maryam';
    final String employeeId = _getEmployeeId(data, docId);
    final String status = data['status'] ?? 'Active';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: const Color(0xFFE8EAF6),
            backgroundImage: data['photoUrl'] != null &&
                    data['photoUrl'].toString().isNotEmpty
                ? NetworkImage(data['photoUrl'])
                : null,
            child: (data['photoUrl'] == null ||
                    data['photoUrl'].toString().isEmpty)
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'V',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF231B92),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF231B92),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  employeeId,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.local_hospital_outlined,
                      size: 14,
                      color: Color(0xFF231B92),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: FutureBuilder<String>(
                        future: _fetchHealthCenter(employeeId, data),
                        builder: (context, centerSnapshot) {
                          if (centerSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text(
                              "Loading...",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic),
                            );
                          }
                          return Text(
                            centerSnapshot.data ?? "N/A",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FILTER DROPDOWN
  // ==========================================
  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Color(0xFF231B92), size: 18),
          isDense: true,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF231B92),
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() => _selectedFilter = newValue);
            }
          },
          items: <String>['This Week', 'This Month', 'Today']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ==========================================
  // PERFORMANCE GRID (STATS) - DUAL FIELD QUERY
  // ==========================================
  Widget _buildPerformanceGrid(String vaccinatorUid, String employeeId) {
    DateTime now = DateTime.now();
    DateTime startDate;

    if (_selectedFilter == 'Today') {
      startDate = DateTime(now.year, now.month, now.day);
    } else if (_selectedFilter == 'This Week') {
      startDate = now.subtract(Duration(days: now.weekday - 1));
      startDate = DateTime(startDate.year, startDate.month, startDate.day);
    } else {
      startDate = DateTime(now.year, now.month, 1);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // Fetch all children and filter locally to match either vaccinatorId or employeeId reliably
      stream: _db.collection('children').snapshots(),
      builder: (context, snapshot) {
        int vaccinated = 0;
        int routine = 0;
        int polio = 0;
        int missedRefused = 0;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final allDocs = snapshot.data!.docs;

          // Filter children belonging to this specific vaccinator (checking both UID and Employee ID)
          final vaccinatorDocs = allDocs.where((doc) {
            final docData = doc.data();
            final String cVaccinatorId = (docData['vaccinatorId'] ?? '').toString().trim();
            final String cEmployeeId = (docData['employeeId'] ?? docData['empId'] ?? '').toString().trim();

            return cVaccinatorId == vaccinatorUid || 
                   cVaccinatorId == employeeId || 
                   cEmployeeId == employeeId ||
                   cEmployeeId == vaccinatorUid;
          }).toList();

          // Date filtering
          final filteredDocs = vaccinatorDocs.where((doc) {
            final docData = doc.data();
            Timestamp? t = docData['timestamp'] as Timestamp? ??
                docData['createdAt'] as Timestamp? ??
                docData['date'] as Timestamp?;

            if (t == null) return true;
            return t.toDate().isAfter(startDate) ||
                t.toDate().isAtSameMomentAs(startDate);
          }).toList();

          vaccinated = filteredDocs.where((doc) {
            final st = (doc.data()['status'] ??
                    doc.data()['vaccinationStatus'] ?? '')
                .toString()
                .toLowerCase();
            return st == 'vaccinated' || st == 'completed' || st == 'done';
          }).length;

          routine = filteredDocs.where((doc) {
            final type = (doc.data()['type'] ??
                    doc.data()['vaccineType'] ?? '')
                .toString()
                .toLowerCase();
            return type == 'routine' || type.contains('routine');
          }).length;

          polio = filteredDocs.where((doc) {
            final type = (doc.data()['type'] ??
                    doc.data()['vaccineType'] ?? '')
                .toString()
                .toLowerCase();
            return type == 'polio' || type.contains('polio');
          }).length;

          missedRefused = filteredDocs.where((doc) {
            final st = (doc.data()['status'] ??
                    doc.data()['vaccinationStatus'] ?? '')
                .toString()
                .toLowerCase();
            return st == 'missed' ||
                st == 'refused' ||
                st == 'refusal' ||
                st == 'defaulter' ||
                doc.data()['isMissed'] == true;
          }).length;
        }

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _statCard(
              '$vaccinated',
              'Vaccinated',
              Icons.person_outline,
              const Color(0xFF231B92),
              const Color(0xFFF3F1FD),
            ),
            _statCard(
              '$routine',
              'Routine',
              Icons.center_focus_weak,
              const Color(0xFF2E7D32),
              const Color(0xFFEFF7F2),
            ),
            _statCard(
              '$polio',
              'Polio',
              Icons.medical_services_outlined,
              const Color(0xFF231B92),
              const Color(0xFFF3F1FD),
            ),
            _statCard(
              '$missedRefused',
              'Missed / Refused',
              Icons.person_remove_outlined,
              const Color(0xFFD32F2F),
              const Color(0xFFFDF2F2),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(
    String value,
    String label,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Icon(icon, color: color, size: 24),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DETAILS CARD
  // ==========================================
  Widget _buildDetailsCard(Map<String, dynamic> data, String joinedDate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          const Text(
            'Details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF231B92),
            ),
          ),
          const SizedBox(height: 14),
          _detailRow(
            'Phone',
            data['phone'] ?? '03xxxxxxxxxx',
            Icons.phone_outlined,
          ),
          const Divider(height: 20, thickness: 0.5),
          _detailRow(
            'Joined On',
            joinedDate,
            Icons.calendar_today_outlined,
          ),
          const Divider(height: 20, thickness: 0.5),
          _detailRow(
            'Assigned Area',
            data['assignedArea'] ?? 'Jand Union Council',
            Icons.map_outlined,
          ),
          const Divider(height: 20, thickness: 0.5),
          _detailRow(
            'Supervised Children',
            '${data['supervisedChildren'] ?? 86}',
            null,
            isBoldValue: true,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData? icon,
      {bool isBoldValue = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: isBoldValue ? const Color(0xFF231B92) : Colors.black87,
                fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, size: 16, color: const Color(0xFF231B92)),
            ],
          ],
        ),
      ],
    );
  }
}