import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderPage extends StatelessWidget {
  const ReminderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vaccinations')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text("No reminders"));
        }

        return ListView(
          children: docs.map((v) {
            final vac = v.data() as Map<String, dynamic>;

            return Card(
              child: ListTile(
                title: Text("💉 ${vac['vaccineType'] ?? ''}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Dose: ${vac['doseType'] ?? vac['doseNumber'] ?? ''}"),
                    Text("Date: ${vac['date'] ?? ''}"),
                    Text("Status: ${vac['status'] ?? ''}"),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}