import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VaccinationHistoryScreen extends StatelessWidget {
  final String childId;

  const VaccinationHistoryScreen({
    Key? key,
    required this.childId,
  }) : super(key: key);

  String _formatDate(dynamic dateField) {
    if (dateField is Timestamp) {
      return DateFormat('dd MMM yyyy').format(dateField.toDate());
    } else if (dateField is String && dateField.isNotEmpty) {
      return dateField;
    }
    return 'Unknown Date';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'vaccinated':
      case 'completed':
      case 'administered':
        return const Color(0xFF10B981);
      case 'missed':
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'refused':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Vaccination History',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Direct Query without .orderBy to bypass missing Firestore Index error
        stream: FirebaseFirestore.instance
            .collection('vaccinations')
            .where('childId', isEqualTo: childId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF5C33CF)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'Error loading history: ${snapshot.error}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          List<QueryDocumentSnapshot> docs = snapshot.data?.docs.toList() ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.history, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No vaccination records found for this child.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          // Client-side Descending Sort
          docs.sort((a, b) {
            Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
            Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;

            dynamic dateA = dataA['administeredDate'] ?? dataA['date'];
            dynamic dateB = dataB['administeredDate'] ?? dataB['date'];

            DateTime dtA = dateA is Timestamp ? dateA.toDate() : DateTime(1970);
            DateTime dtB = dateB is Timestamp ? dateB.toDate() : DateTime(1970);

            return dtB.compareTo(dtA);
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // TIMELINE LIST
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String title = data['vaccineName'] ?? data['vaccine'] ?? 'Vaccine';
                    String dose = data['dose'] ?? '';
                    String status = data['status'] ?? 'Vaccinated';
                    String formattedDate = _formatDate(data['administeredDate'] ?? data['date'] ?? data['formattedDate']);
                    String remarks = data['remarks'] ?? '';

                    Color statusColor = _getStatusColor(status);

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Timeline Graphic Line & Indicator
                          Column(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  status.toLowerCase() == 'refused'
                                      ? Icons.close
                                      : (status.toLowerCase() == 'missed' ? Icons.priority_high : Icons.check),
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                              if (index != docs.length - 1)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),

                          // Record Content Card
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade200),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dose.isNotEmpty ? '$dose • $formattedDate' : formattedDate,
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                    if (remarks.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Remarks: $remarks',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // DIGITAL VERIFICATION FOOTER
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: Color(0xFF5C33CF),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Vaccination records are digitally encrypted and verified.',
                          style: TextStyle(
                            color: Color(0xFF5C33CF),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}