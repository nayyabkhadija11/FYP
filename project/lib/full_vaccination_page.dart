import 'package:flutter/material.dart';
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
}