import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'vaccination_entry.dart';
import 'child_registration.dart';

class VaccinatorScreen extends StatelessWidget {
  const VaccinatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [

          // ================= HEADER =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF059669)],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Vaccinator Dashboard",
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                SizedBox(height: 6),
                Text(
                  "Lahore, Punjab",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ================= BUTTONS =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [

                Expanded(
                  child: _button(
                    context,
                    "Vaccination Entry",
                    Icons.qr_code_scanner,
                    const Color(0xFF2563EB),
                    VaccinationEntryPage(),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _button(
                    context,
                    "Register Child",
                    Icons.add,
                    const Color(0xFF059669),
                    ChildRegistrationPage(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ================= STATS =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vaccinations')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                int completed = 0;
                int refused = 0;
                int absent = 0;

                Map<String, int> vaccineMap = {};

                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;

                  String status = data['status'] ?? "";
                  String vaccine = data['vaccineType'] ?? "Unknown";

                  if (status == "completed") completed++;
                  if (status == "refused") refused++;
                  if (status == "absent") absent++;

                  vaccineMap[vaccine] = (vaccineMap[vaccine] ?? 0) + 1;
                }

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _stat("Completed", completed, Colors.green),
                        _stat("Refused", refused, Colors.red),
                        _stat("Absent", absent, Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: vaccineMap.entries.map((e) {
                        return Chip(label: Text("${e.key}: ${e.value}"));
                      }).toList(),
                    )
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // ================= LIST =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vaccinations')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                        docs[index].data() as Map<String, dynamic>;

                    return Card(
                      child: ListTile(
                        title: Text(data['childName'] ?? ""),
                        subtitle: Text(
                            "${data['vaccineType']} • ${data['status']}"),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= BUTTON =================
  Widget _button(BuildContext context, String text, IconData icon,
      Color color, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  // ================= STATS BOX =================
  Widget _stat(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            "$count",
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(title),
        ],
      ),
    );
  }
}