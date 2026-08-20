import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VaccinatorPerformanceReportScreen extends StatefulWidget {
  const VaccinatorPerformanceReportScreen({super.key});

  @override
  State<VaccinatorPerformanceReportScreen> createState() => _VaccinatorPerformanceReportScreenState();
}

class _VaccinatorPerformanceReportScreenState extends State<VaccinatorPerformanceReportScreen> {
  String _selectedTimeFilter = 'This Month';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF231B92)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Vaccinator Performance Report',
          style: TextStyle(
            color: Color(0xFF231B92),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Filter Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTimeFilter,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF231B92)),
                  items: ['This Month', 'Last Month', 'This Year'].map((filter) {
                    return DropdownMenuItem(
                      value: filter,
                      child: Text(
                        filter,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF231B92)),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedTimeFilter = val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 1. Fetch Vaccinators from 'users'
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _db.collection('users').where('role', isEqualTo: 'Vaccinator').snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: Color(0xFF231B92)),
                    ),
                  );
                }

                if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No vaccinators found in Firebase.',
                        style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  );
                }

                final vaccinatorDocs = userSnapshot.data!.docs;

                // 2. Fetch 'vaccinations' collection
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _db.collection('vaccinations').snapshots(),
                  builder: (context, vaccinationSnapshot) {
                    final allVaccinations = vaccinationSnapshot.hasData ? vaccinationSnapshot.data!.docs : [];

                    // 3. Fetch 'children' collection
                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _db.collection('children').snapshots(),
                      builder: (context, childrenSnapshot) {
                        final allChildren = childrenSnapshot.hasData ? childrenSnapshot.data!.docs : [];

                        return Column(
                          children: vaccinatorDocs.map((doc) {
                            final data = doc.data();
                            
                            String name = data['fullName'] ?? data['name'] ?? 'Unknown Vaccinator';
                            String employeeId = (data['employeeId'] ?? '').toString().trim().toLowerCase();
                            String docId = doc.id.trim(); // e.g. LM7ZgWkJpaW0ib62K...
                            String uid = (data['uid'] ?? '').toString().trim();
                            bool isFemale = data['isFemale'] ?? (data['gender']?.toString().toLowerCase().startsWith('f') ?? false);

                            int vaccinatedCount = 0;
                            int routineCount = 0;
                            int polioCount = 0;
                            int missedCount = 0;

                            // A. Process records from 'vaccinations' collection
                            for (var record in allVaccinations) {
                              final map = record.data();
                              final administeredBy = (map['administeredBy'] ?? '').toString().trim();
                              
                              if (administeredBy == docId || administeredBy == uid || (employeeId.isNotEmpty && administeredBy.toLowerCase() == employeeId)) {
                                String status = (map['status'] ?? '').toString().toLowerCase().trim();
                                String vaccineName = (map['vaccineName'] ?? '').toString().toLowerCase();

                                if (status == 'vaccinated' || status == 'completed' || status == 'done' || status == 'success') {
                                  vaccinatedCount++;
                                  if (vaccineName.contains('polio') || vaccineName.contains('opv') || vaccineName.contains('ipv')) {
                                    polioCount++;
                                  } else {
                                    routineCount++;
                                  }
                                } else if (status == 'missed' || status == 'refused' || status == 'house locked') {
                                  missedCount++;
                                }
                              }
                            }

                            // B. Process records from 'children' collection (where registeredBy matches)
                            for (var childRecord in allChildren) {
                              final map = childRecord.data();
                              final registeredBy = (map['registeredBy'] ?? '').toString().trim();

                              if (registeredBy == docId || registeredBy == uid || (employeeId.isNotEmpty && registeredBy.toLowerCase() == employeeId)) {
                                String status = (map['status'] ?? '').toString().toLowerCase().trim();
                                String lastVaccine = (map['lastVaccine'] ?? '').toString().toLowerCase();

                                if (status == 'vaccinated' || status == 'completed' || status == 'success') {
                                  vaccinatedCount++;
                                  if (lastVaccine.contains('polio') || lastVaccine.contains('opv') || lastVaccine.contains('ipv')) {
                                    polioCount++;
                                  } else {
                                    routineCount++;
                                  }
                                } else if (status == 'missed' || status == 'refused' || status == 'house locked') {
                                  missedCount++;
                                }
                              }
                            }

                            int totalAssigned = vaccinatedCount + missedCount;
                            if (totalAssigned == 0) totalAssigned = vaccinatedCount; // Fallback if no missed records
                            
                            double coveragePercentage = 0.0;
                            if (totalAssigned > 0) {
                              coveragePercentage = (vaccinatedCount / totalAssigned) * 100;
                            }

                            String coverageStr = '${coveragePercentage.toStringAsFixed(0)}%';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Colors.grey.shade200,
                                        child: Icon(
                                          isFemale ? Icons.face_3 : Icons.face,
                                          color: const Color(0xFF231B92),
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF231B92),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              employeeId.isNotEmpty ? employeeId.toUpperCase() : docId,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'Coverage',
                                            style: TextStyle(fontSize: 10, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            coverageStr,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildStatItem('Vaccinated', '$vaccinatedCount', Colors.black87),
                                      _buildStatItem('Routine', '$routineCount', Colors.black87),
                                      _buildStatItem('Polio', '$polioCount', Colors.black87),
                                      _buildStatItem('Missed', '$missedCount', Colors.red),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }
}