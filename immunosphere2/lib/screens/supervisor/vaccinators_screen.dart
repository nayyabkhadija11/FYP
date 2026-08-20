import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_vaccinator_screen.dart';
import 'vaccinator_details_screen.dart';

class VaccinatorsScreen extends StatefulWidget {
  const VaccinatorsScreen({Key? key}) : super(key: key);

  @override
  State<VaccinatorsScreen> createState() => _VaccinatorsScreenState();
}

class _VaccinatorsScreenState extends State<VaccinatorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 1. EXTRACT VACCINATOR / EMPLOYEE ID
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
  Future<String> _fetchHealthCenter(String empId, Map<String, dynamic> userData) async {
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
      var docSnapshot = await _db.collection('valid_employees').doc(empId).get();
      
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1B4B)),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Vaccinators',
          style: TextStyle(
            color: Color(0xFF1E1B4B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF1E1B4B)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddVaccinatorScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Search Bar & Filter Button
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase().trim();
                        });
                      },
                      decoration: InputDecoration(
                        icon: const Icon(Icons.search, color: Colors.grey),
                        hintText: "Search by name, ID or center...",
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.filter_list, color: Color(0xFF1E1B4B)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // REAL-TIME FIREBASE VACCINATORS LIST
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                // Direct query matching the exact role in database
                stream: _db
                    .collection('users')
                    .where('role', isEqualTo: 'Vaccinator')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading data: ${snapshot.error}'),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No vaccinators found in Database",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    );
                  }

                  // Local Search Filtering Logic
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data();
                    final name = (data['fullName'] ?? data['name'] ?? '').toString().toLowerCase();
                    final empId = _getEmployeeId(data, doc.id).toLowerCase();

                    return name.contains(_searchQuery) || empId.contains(_searchQuery);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No matching vaccinator found",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data();

                      final String name = data['fullName'] ?? data['name'] ?? 'Unknown';
                      final String employeeId = _getEmployeeId(data, doc.id);

                      final int today = data['todayCount'] ?? data['today'] ?? 0;
                      final int thisWeek = data['thisWeekCount'] ?? data['thisWeek'] ?? 0;
                      final String status = data['status'] ?? 'Active';
                      final String? imageUrl = data['imageUrl'] ?? data['photoUrl'];

                      final bool isActive = status.toLowerCase() == 'active';
                      final Color statusColor = isActive ? Colors.green : Colors.orange;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0.5,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VaccinatorDetailsScreen(
                                  vaccinatorId: doc.id,
                                  initialData: data,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: const Color(0xFF6D5DF6).withOpacity(0.1),
                                      backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                                          ? NetworkImage(imageUrl)
                                          : null,
                                      child: (imageUrl == null || imageUrl.isEmpty)
                                          ? Text(
                                              name.isNotEmpty ? name[0].toUpperCase() : 'V',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                                color: Color(0xFF6D5DF6),
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
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
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Color(0xFF1E1B4B),
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  status,
                                                  style: TextStyle(
                                                    color: statusColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            employeeId,
                                            style: TextStyle(
                                                color: Colors.grey.shade600, fontSize: 12),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.local_hospital_outlined,
                                                size: 15,
                                                color: Color(0xFF6D5DF6),
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
                                                            color: Colors.grey,
                                                            fontSize: 13,
                                                            fontStyle: FontStyle.italic),
                                                      );
                                                    }
                                                    return Text(
                                                      centerSnapshot.data ?? "N/A",
                                                      style: const TextStyle(
                                                          color: Color(0xFF1E1B4B),
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w500),
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
                                  ],
                                ),
                                const Divider(height: 20, thickness: 0.8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text.rich(
                                      TextSpan(
                                        text: "Today: ",
                                        style: TextStyle(
                                            color: Colors.grey.shade600, fontSize: 13),
                                        children: [
                                          TextSpan(
                                            text: "$today",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text.rich(
                                          TextSpan(
                                            text: "This Week: ",
                                            style: TextStyle(
                                                color: Colors.grey.shade600, fontSize: 13),
                                            children: [
                                              TextSpan(
                                                text: "$thisWeek",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.chevron_right,
                                            size: 18, color: Colors.grey),
                                      ],
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Add Vaccinator Button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddVaccinatorScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Add Vaccinator",
                  style: TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B1EAD),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}