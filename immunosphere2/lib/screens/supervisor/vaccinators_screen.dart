import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vaccinator_details_screen.dart';

class VaccinatorsScreen extends StatefulWidget {
  const VaccinatorsScreen({Key? key}) : super(key: key);

  @override
  State<VaccinatorsScreen> createState() => _VaccinatorsScreenState();
}

class _VaccinatorsScreenState extends State<VaccinatorsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  // Exact image color hex code
  static const Color primaryThemeGreen = Color(0xFF00563B);
  static const Color bgCanvasColor = Color(0xFFF9FAFB);

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getEmployeeId(Map<String, dynamic> data, String docId) {
    List<String> idKeys = ['employeeId', 'employee_id', 'empId', 'vaccinatorId', 'id'];
    for (String key in idKeys) {
      if (data.containsKey(key) &&
          data[key] != null &&
          data[key].toString().trim().isNotEmpty &&
          data[key] is! Map) {
        return data[key].toString().trim();
      }
    }
    return docId;
  }

  Future<String> _fetchHealthCenter(String empId, Map<String, dynamic> userData) async {
    List<String> centerKeys = ['healthCenter', 'health_center', 'healthCenterName', 'assignedHealthCenter', 'center'];
    for (String key in centerKeys) {
      if (userData.containsKey(key) && userData[key] != null && userData[key].toString().trim().isNotEmpty) {
        return userData[key].toString().trim();
      }
    }
    try {
      var docSnapshot = await _db.collection('valid_employees').doc(empId).get();
      if (!docSnapshot.exists) {
        final querySnapshot = await _db.collection('valid_employees').where('employeeId', isEqualTo: empId).limit(1).get();
        if (querySnapshot.docs.isNotEmpty) {
          docSnapshot = querySnapshot.docs.first;
        }
      }
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final empData = docSnapshot.data()!;
        for (String key in centerKeys) {
          if (empData.containsKey(key) && empData[key] != null && empData[key].toString().trim().isNotEmpty) {
            return empData[key].toString().trim();
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching center: $e");
    }
    return 'BHU Jand';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCanvasColor,
      appBar: AppBar(
        backgroundColor: primaryThemeGreen,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Vaccinators',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search by name or ID...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _db.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryThemeGreen),
                  );
                }

                var docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  final role = (data['role'] ?? '').toString().toLowerCase();
                  if (role.isNotEmpty && role != 'vaccinator' && role != 'user') {
                    return false;
                  }

                  final name = (data['fullName'] ?? data['name'] ?? '').toString().toLowerCase();
                  final empId = _getEmployeeId(data, doc.id).toLowerCase();

                  if (_searchQuery.isNotEmpty) {
                    return name.contains(_searchQuery) || empId.contains(_searchQuery);
                  }
                  return true;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No vaccinators found', style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final String vaccinatorId = doc.id;
                    final String name = data['fullName'] ?? data['name'] ?? 'Pakeeza';
                    final String empId = _getEmployeeId(data, vaccinatorId);
                    final String status = data['status'] ?? 'Active';

                    return _buildVaccinatorCard(
                      context,
                      vaccinatorId: vaccinatorId,
                      data: data,
                      name: name,
                      empId: empId,
                      status: status,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinatorCard(
    BuildContext context, {
    required String vaccinatorId,
    required Map<String, dynamic> data,
    required String name,
    required String empId,
    required String status,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VaccinatorDetailsScreen(
                vaccinatorId: vaccinatorId,
                initialData: data,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty
                    ? NetworkImage(data['photoUrl'])
                    : null,
                child: (data['photoUrl'] == null || data['photoUrl'].toString().isEmpty)
                    ? const Icon(Icons.person, color: primaryThemeGreen, size: 30)
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryThemeGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      empId,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: primaryThemeGreen),
                        const SizedBox(width: 3),
                        FutureBuilder<String>(
                          future: _fetchHealthCenter(empId, data),
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data ?? 'BHU Jand',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryThemeGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 3,
                          backgroundColor: primaryThemeGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: const TextStyle(
                            color: primaryThemeGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: primaryThemeGreen, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}