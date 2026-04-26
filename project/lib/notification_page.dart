import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

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

        return ListView(
          children: docs.map((v) {
            final vac = v.data() as Map<String, dynamic>;

            return ListTile(
              leading: const Icon(Icons.notifications_active, color: Colors.red),
              title: Text(vac['vaccineType'] ?? ''),
              subtitle: Text("📅 ${vac['date'] ?? ''}"),
            );
          }).toList(),
        );
      },
    );
  }
}