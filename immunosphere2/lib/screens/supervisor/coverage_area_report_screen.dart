import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CoverageAreaReportScreen extends StatefulWidget {
  const CoverageAreaReportScreen({super.key});

  @override
  State<CoverageAreaReportScreen> createState() => _CoverageAreaReportScreenState();
}

class _CoverageAreaReportScreenState extends State<CoverageAreaReportScreen> {
  String _selectedHealthCenter = 'All Health Centers';
  String _selectedMonth = 'May 2024';

  // List for filter dropdown items
  final List<String> _healthCentersList = [
    'All Health Centers',
    'BHU Jand',
    'THQ Hospital Jand',
    'BHU Pindigheb',
    'RHC Hazro',
    'BHU Fateh Jang',
  ];

  final List<String> _monthsList = ['May 2024', 'June 2024', 'July 2024'];

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
          'Coverage Area Report',
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
            // Filter Dropdowns Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedHealthCenter,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF231B92)),
                        items: _healthCentersList.map((center) {
                          return DropdownMenuItem(
                            value: center,
                            child: Text(center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF231B92))),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedHealthCenter = val!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedMonth,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF231B92)),
                        items: _monthsList.map((month) {
                          return DropdownMenuItem(
                            value: month,
                            child: Text(month, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF231B92))),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedMonth = val!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Report Table Container using StreamBuilder for Firebase Real-time Data
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
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Health Center',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF231B92)),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Eligible\nChildren',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF231B92)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Vaccinated',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF231B92)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Missed',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF231B92)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Coverage',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF231B92)),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Firebase StreamBuilder
                  StreamBuilder<QuerySnapshot>(
                    stream: _fetchReportDataFromFirebase(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(child: CircularProgressIndicator(color: Color(0xFF231B92))),
                        );
                      }

                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Center(
                            child: Text('Error loading data: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(30.0),
                          child: Center(
                            child: Text('No records found for selected filters.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;

                          final centerName = data['center'] ?? 'Unknown';
                          final eligible = data['eligible'] ?? 0;
                          final vaccinated = data['vaccinated'] ?? 0;
                          final missed = data['missed'] ?? 0;
                          final coverage = data['coverage'] ?? '0%';

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    centerName,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF231B92)),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    eligible.toString(),
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    vaccinated.toString(),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    missed.toString(),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    coverage,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Download PDF Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF231B92),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {},
                icon: const Icon(Icons.download, color: Colors.white, size: 18),
                label: const Text(
                  'Download PDF',
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

  // Query builder based on selected filters
  Stream<QuerySnapshot> _fetchReportDataFromFirebase() {
    Query query = FirebaseFirestore.instance.collection('coverage_reports');

    // Filter by Month if needed (assuming your document has a 'month' field)
    query = query.where('month', isEqualTo: _selectedMonth);

    // Filter by Health Center if a specific one is selected
    if (_selectedHealthCenter != 'All Health Centers') {
      query = query.where('center', isEqualTo: _selectedHealthCenter);
    }

    return query.snapshots();
  }
}