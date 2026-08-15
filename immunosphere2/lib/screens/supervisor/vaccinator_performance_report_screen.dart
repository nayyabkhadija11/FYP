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
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF231B92)),
            onPressed: () {},
          ),
        ],
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
                        textAlign: TextAlign.center,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedTimeFilter = val!),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // StreamBuilder to fetch users where role == 'Vaccinator' (Real-time updates included)
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _db.collection('users').where('role', isEqualTo: 'Vaccinator').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: Color(0xFF231B92)),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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

                final vaccinatorDocs = snapshot.data!.docs;

                return Column(
                  children: vaccinatorDocs.map((doc) {
                    final data = doc.data();
                    
                    // Screenshot ke mutabiq fields extract ki gayi hain
                    String name = data['fullName'] ?? data['name'] ?? 'Unknown Vaccinator';
                    String id = data['employeeId'] ?? data['uid'] ?? doc.id;
                    String coverage = data['coverage']?.toString() ?? '90%';
                    int vaccinated = data['vaccinated'] ?? 75;
                    int routine = data['routine'] ?? 10;
                    int polio = data['polio'] ?? 5;
                    int missed = data['missed'] ?? 0;
                    bool isFemale = data['isFemale'] ?? (data['gender']?.toString().toLowerCase().startsWith('f') ?? false);

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
                                      id,
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
                                    coverage,
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
                              _buildStatItem('Vaccinated', '$vaccinated', Colors.black87),
                              _buildStatItem('Routine', '$routine', Colors.black87),
                              _buildStatItem('Polio', '$polio', Colors.black87),
                              _buildStatItem('Missed', '$missed', Colors.red),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),

            // View Detailed Report Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF231B92),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {},
                child: const Text(
                  'View Detailed Report',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}