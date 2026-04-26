import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChildListScreen extends StatelessWidget {
  const ChildListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registered Children"),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("children")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(data["name"] ?? ""),
                  subtitle: Text(
                    "CNIC: ${data["cnic"]}\nDistrict: ${data["district"]}",
                  ),
                  trailing: Text(data["gender"] ?? ""),
                ),
              );
            },
          );
        },
      ),
    );
  }
}