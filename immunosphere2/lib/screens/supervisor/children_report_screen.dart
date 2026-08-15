import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChildrenReportScreen extends StatefulWidget {
  const ChildrenReportScreen({super.key});

  @override
  State<ChildrenReportScreen> createState() => _ChildrenReportScreenState();
}

class _ChildrenReportScreenState extends State<ChildrenReportScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _childrenStream;

  @override
  void initState() {
    super.initState();
    _childrenStream = _db.collection('children').snapshots();
  }

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
          'Children Report',
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _childrenStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: Color(0xFF231B92)),
              ),
            );
          }

          final docs = snapshot.hasData ? snapshot.data!.docs : [];

          return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
            future: _db.collection('vaccinations').get(),
            builder: (context, vacSnapshot) {
              if (vacSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF231B92)),
                );
              }

              final vacDocs = vacSnapshot.hasData ? vacSnapshot.data!.docs : [];

              int totalRegistered = docs.length;
              int fullyVaccinated = 0;
              int missed = 0;
              int refused = 0;

              List<Map<String, dynamic>> pendingOrMissedList = [];

              for (var doc in docs) {
                final data = doc.data();
                String childId = data['childId']?.toString() ?? doc.id;
                String overallStatus = data['status']?.toString().toLowerCase().trim() ?? '';

                var childVaccinations = vacDocs.where((vDoc) {
                  var vData = vDoc.data();
                  return vData['childId']?.toString() == childId || vData['childId']?.toString() == doc.id;
                }).toList();

                bool isAllVaccinesDone = false;
                bool hasMissedVaccine = false;

                if (childVaccinations.isNotEmpty) {
                  bool allAreVaccinated = childVaccinations.every((vDoc) {
                    String vStatus = vDoc.data()['status']?.toString().toLowerCase().trim() ?? '';
                    return vStatus == 'vaccinated' || vStatus == 'completed';
                  });

                  if (allAreVaccinated && childVaccinations.length >= 8) {
                    isAllVaccinesDone = true;
                  }

                  // Firebase mein se check karein ke kya kisi vaccine ka status 'missed' hai
                  hasMissedVaccine = childVaccinations.any((vDoc) {
                    String vStatus = vDoc.data()['status']?.toString().toLowerCase().trim() ?? '';
                    return vStatus == 'missed';
                  });
                }

                // Calculation Logic
                if (overallStatus == 'missed' || hasMissedVaccine) {
                  missed++;
                  pendingOrMissedList.add(_mapChildData(doc.id, data));
                } else if (overallStatus == 'refused') {
                  refused++;
                  pendingOrMissedList.add(_mapChildData(doc.id, data));
                } else if (isAllVaccinesDone || overallStatus == 'fully vaccinated' || overallStatus == 'completed') {
                  fullyVaccinated++;
                } else {
                  pendingOrMissedList.add(_mapChildData(doc.id, data));
                }
              }

              // Pending calculation using totalRegistered - fullyVaccinated
              int pending = totalRegistered - fullyVaccinated;
              if (pending < 0) pending = 0;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Registered Children',
                            value: '$totalRegistered',
                            valueColor: const Color(0xFF231B92),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Fully Vaccinated',
                            value: '$fullyVaccinated',
                            valueColor: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Pending',
                            value: '$pending',
                            valueColor: const Color(0xFF231B92),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Missed',
                            value: '$missed',
                            valueColor: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Refused',
                            value: '$refused',
                            valueColor: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Container()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Recent Pending / Missed',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF231B92),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
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
                      child: pendingOrMissedList.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Center(
                                child: Text(
                                  'No pending or missed children found.',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ),
                            )
                          : Column(
                              children: pendingOrMissedList.asMap().entries.map((entry) {
                                int index = entry.key;
                                Map<String, dynamic> child = entry.value;
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor: Colors.grey.shade200,
                                            child: Icon(
                                              child['isFemale'] ? Icons.face_3 : Icons.face,
                                              color: const Color(0xFF231B92),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  child['name'],
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF231B92),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  child['age'],
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            child['due'],
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (index < pendingOrMissedList.length - 1)
                                      Divider(height: 1, color: Colors.grey.shade100, indent: 14, endIndent: 14),
                                  ],
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 24),
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
                          'View Full List',
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
              );
            },
          );
        },
      ),
    );
  }

  Map<String, dynamic> _mapChildData(String docId, Map<String, dynamic> data) {
    return {
      'name': data['name'] ?? data['fullName'] ?? data['childName'] ?? 'Unknown Child',
      'age': data['age'] ?? data['childAge'] ?? 'Age not specified',
      'due': data['due'] ?? data['dueVaccine'] ?? 'Due: Vaccine',
      'isFemale': data['isFemale'] ?? (data['gender']?.toString().toLowerCase().startsWith('f') ?? false),
    };
  }

  Widget _buildStatCard({required String title, required String value, required Color valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}