/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FullVaccinationPage extends StatelessWidget {
  final String childId;

  const FullVaccinationPage({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Child Vaccination History"),
        backgroundColor: Colors.blue,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vaccinations')
            .where('childId', isEqualTo: childId.toString().trim())
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No REAL vaccination history found"),
            );
          }

          final docs = snapshot.data!.docs;

          // 🔥 REAL SORTING (by date not fake order)
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            DateTime ad = (aData['date'] is Timestamp)
                ? (aData['date'] as Timestamp).toDate()
                : DateTime.tryParse(aData['date'].toString()) ?? DateTime(2000);

            DateTime bd = (bData['date'] is Timestamp)
                ? (bData['date'] as Timestamp).toDate()
                : DateTime.tryParse(bData['date'].toString()) ?? DateTime(2000);

            return bd.compareTo(ad); // latest first
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final v = docs[index].data() as Map<String, dynamic>;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.vaccines, color: Colors.blue),

                  title: Text(
                    "${v['vaccineType'] ?? 'Unknown'} - Dose ${v['dose'] ?? '-'}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Date: ${v['date'] ?? 'Not set'}"),
                      Text("Status: ${v['status'] ?? 'pending'}"),
                    ],
                  ),

                  trailing: Icon(
                    (v['status'] == 'completed')
                        ? Icons.check_circle
                        : Icons.schedule,
                    color: (v['status'] == 'completed')
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}*/
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FullVaccinationPage extends StatelessWidget {
  final String childId;

  const FullVaccinationPage({super.key, required this.childId});

  // --- Theme Colors ---
  final Color primaryBlue = const Color(0xFF2563EB);
  final Color bgSlate = const Color(0xFFF8FAFC);
  final Color successGreen = const Color(0xFF10B981);
  final Color warningOrange = const Color(0xFFF59E0B);
  final Color textDark = const Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSlate,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Vaccination History",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryBlue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vaccinations')
            .where('childId', isEqualTo: childId.toString().trim())
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryBlue));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.HistoryEdu, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "No vaccination records found",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          // Sorting logic (Latest first)
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            DateTime ad = _safeParseDate(aData['date']);
            DateTime bd = _safeParseDate(bData['date']);

            return bd.compareTo(ad);
          });

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final v = docs[index].data() as Map<String, dynamic>;
              bool isDone = v['status']?.toString().toLowerCase() == 'completed';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        // Left status indicator bar
                        Container(
                          width: 6,
                          color: isDone ? successGreen : warningOrange,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Circular Vaccine Icon
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (isDone ? successGreen : warningOrange).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.vaccines_outlined,
                                    color: isDone ? successGreen : warningOrange,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Text Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${v['vaccineType'] ?? 'Unknown Vaccine'}",
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Dose: ${v['dose'] ?? '-'}",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.event_available, size: 14, color: Colors.grey.shade400),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(v['date']),
                                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Status Label
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isDone ? Icons.check_circle : Icons.pending_actions,
                                      color: isDone ? successGreen : warningOrange,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isDone ? "DONE" : "PENDING",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isDone ? successGreen : warningOrange,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- Helper Methods ---
  DateTime _safeParseDate(dynamic date) {
    if (date is Timestamp) return date.toDate();
    if (date == null) return DateTime(2000);
    return DateTime.tryParse(date.toString()) ?? DateTime(2000);
  }

  String _formatDate(dynamic date) {
    if (date == null) return "Not scheduled";
    DateTime dt = _safeParseDate(date);
    // Simple format: 26 Apr 2026
    List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
  }
}