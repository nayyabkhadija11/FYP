/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vaccination_entry.dart';
import 'child_registration.dart';

class VaccinatorScreen extends StatelessWidget {
  const VaccinatorScreen({super.key});

  // Function to delete a record
  Future<void> _deleteRecord(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance.collection('vaccinations').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Record deleted successfully"), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('children').snapshots(),
        builder: (context, childSnapshot) {
          
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('vaccinations').snapshots(),
            builder: (context, vacSnapshot) {
              
              int completed = 0;
              int refused = 0;
              int absent = 0;
              int targetCount = childSnapshot.hasData ? childSnapshot.data!.docs.length : 0;

              if (vacSnapshot.hasData) {
                for (var doc in vacSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  String status = (data['status'] ?? "").toString().toLowerCase();
                  if (status == "completed") completed++;
                  else if (status == "refused") refused++;
                  else if (status == "absent") absent++;
                }
              }

              return Column(
                children: [
                  _buildHeader(context),

                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildStatCard("Vaccinated", completed, Colors.green, Icons.check_circle_outline),
                          _buildStatCard("Refused", refused, Colors.red, Icons.cancel_outlined),
                          _buildStatCard("Absent", absent, Colors.orange, Icons.people_outline),
                          _buildStatCard("Target", targetCount, Colors.blue, Icons.assignment_outlined),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(child: _actionButton(context, "Scan QR Code", Icons.qr_code_scanner, const Color(0xFF1D4ED8), const VaccinationEntryPage())),
                        const SizedBox(width: 12),
                        Expanded(child: _actionButton(context, "Register Child", Icons.add, const Color(0xFF059669), const ChildRegistrationPage())),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  Expanded(
                    child: vacSnapshot.hasData 
                      ? ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: vacSnapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final doc = vacSnapshot.data!.docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: const CircleAvatar(backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.person)),
                                title: Text(data['childName'] ?? "Unknown Child", style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("Vaccine: ${data['vaccineType'] ?? 'N/A'}\nStatus: ${data['status'] ?? 'N/A'}"),
                                
                                // UPDATED: Trailing ab clickable delete button hai
                                trailing: IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.redAccent),
                                  onPressed: () {
                                    // Delete confirmation dialog
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text("Delete Record?"),
                                        content: const Text("Are you sure you want to remove this vaccination entry?"),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("No")),
                                          TextButton(
                                            onPressed: () {
                                              _deleteRecord(context, doc.id);
                                              Navigator.pop(ctx);
                                            }, 
                                            child: const Text("Yes, Delete", style: TextStyle(color: Colors.red))
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        )
                      : const Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // Header, StatCard, and ActionButton design methods (remain the same as your previous code)
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF0066FF), Color(0xFF00B16A)]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
          const Text("Vaccinator Dashboard", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const Text("Lahore, Punjab", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      width: 150, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("$count", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Icon(icon, color: color),
        ]),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.black54, fontSize: 14)),
      ]),
    );
  }

  Widget _actionButton(BuildContext context, String text, IconData icon, Color color, Widget page) {
    return ElevatedButton(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8), Flexible(child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))]),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vaccination_entry.dart';
import 'child_registration.dart';

class VaccinatorScreen extends StatelessWidget {
  const VaccinatorScreen({super.key});

  Future<void> _deleteRecord(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('vaccinations')
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Record deleted successfully"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('children').snapshots(),
        builder: (context, childSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('vaccinations').snapshots(),
            builder: (context, vacSnapshot) {

              int completed = 0;
              int refused = 0;
              int absent = 0;

              // ✅ FIX 1: unique vaccinated children only
              Set<String> vaccinatedChildren = {};

              if (vacSnapshot.hasData) {
                for (var doc in vacSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;

                  String status = (data['status'] ?? "").toString().toLowerCase();

                  if (status == "completed") {
                    completed++;

                    // IMPORTANT: childId use karo (recommended)
                    vaccinatedChildren.add(
                      data['childId'] ?? data['childName'] ?? '',
                    );
                  } else if (status == "refused") {
                    refused++;
                  } else if (status == "absent") {
                    absent++;
                  }
                }
              }

              // ✅ FIX 2: real children count
              int totalChildren =
                  childSnapshot.hasData ? childSnapshot.data!.docs.length : 0;

              // ✅ FIX 3: correct target logic
              int targetCount = totalChildren - vaccinatedChildren.length;
              if (targetCount < 0) targetCount = 0;

              return Column(
                children: [
                  _buildHeader(context),

                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildStatCard("Vaccinated", completed, Colors.green, Icons.check_circle_outline),
                          _buildStatCard("Refused", refused, Colors.red, Icons.cancel_outlined),
                          _buildStatCard("Absent", absent, Colors.orange, Icons.people_outline),
                          _buildStatCard("Target", targetCount, Colors.blue, Icons.assignment_outlined),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _actionButton(
                            context,
                            "Scan QR Code",
                            Icons.qr_code_scanner,
                            const Color(0xFF1D4ED8),
                            const VaccinationEntryPage(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _actionButton(
                            context,
                            "Register Child",
                            Icons.add,
                            const Color(0xFF059669),
                            const ChildRegistrationPage(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Recent Activity",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  Expanded(
                    child: vacSnapshot.hasData
                        ? ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: vacSnapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final doc = vacSnapshot.data!.docs[index];
                              final data = doc.data() as Map<String, dynamic>;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFFF1F5F9),
                                    child: Icon(Icons.person),
                                  ),
                                  title: Text(
                                    data['childName'] ?? "Unknown Child",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    "Vaccine: ${data['vaccineType'] ?? 'N/A'}\nStatus: ${data['status'] ?? 'N/A'}",
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.redAccent),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text("Delete Record?"),
                                          content: const Text(
                                              "Are you sure you want to remove this vaccination entry?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text("No"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                _deleteRecord(context, doc.id);
                                                Navigator.pop(ctx);
                                              },
                                              child: const Text(
                                                "Yes, Delete",
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0066FF), Color(0xFF00B16A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            "Vaccinator Dashboard",
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const Text("Lahore, Punjab", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$count",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
              Icon(icon, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.black54, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _actionButton(
      BuildContext context,
      String text,
      IconData icon,
      Color color,
      Widget page,
      ) {
    return ElevatedButton(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          )
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vaccination_entry.dart';
import 'child_registration.dart';

class VaccinatorScreen extends StatelessWidget {
  const VaccinatorScreen({super.key});

  Future<void> _deleteRecord(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('vaccinations')
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Record deleted successfully"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('children').snapshots(),
        builder: (context, childSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('vaccinations').snapshots(),
            builder: (context, vacSnapshot) {

              // ========================
              // DEFAULT SAFE VALUES (IMPORTANT FIX)
              // ========================
              int completed = 0;
              int refused = 0;
              int absent = 0;
              int targetCount = 0;

              Set<String> vaccinatedChildren = {};

              // ========================
              // ONLY PROCESS WHEN DATA IS READY
              // ========================
              if (childSnapshot.hasData && vacSnapshot.hasData) {

                // ----- CHILDREN COUNT -----
                int totalChildren = childSnapshot.data!.docs.length;

                // ----- VACCINATION DATA -----
                for (var doc in vacSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;

                  String status =
                      (data['status'] ?? "").toString().toLowerCase();

                  if (status == "completed") {
                    completed++;

                    vaccinatedChildren.add(
                      data['childId'] ?? data['childName'] ?? '',
                    );
                  } else if (status == "refused") {
                    refused++;
                  } else if (status == "absent") {
                    absent++;
                  }
                }

                // ========================
                // TARGET LOGIC (UNCHANGED LOGIC)
                // ========================
                targetCount = totalChildren - vaccinatedChildren.length;

                if (targetCount < 0) {
                  targetCount = 0;
                }
              }

              return Column(
                children: [
                  _buildHeader(context),

                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildStatCard("Vaccinated", completed, Colors.green, Icons.check_circle_outline),
                          _buildStatCard("Refused", refused, Colors.red, Icons.cancel_outlined),
                          _buildStatCard("Absent", absent, Colors.orange, Icons.people_outline),
                          _buildStatCard("Target", targetCount, Colors.blue, Icons.assignment_outlined),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _actionButton(
                            context,
                            "Scan QR Code",
                            Icons.qr_code_scanner,
                            const Color(0xFF1D4ED8),
                            const VaccinationEntryPage(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _actionButton(
                            context,
                            "Register Child",
                            Icons.add,
                            const Color(0xFF059669),
                            const ChildRegistrationPage(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Recent Activity",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  Expanded(
                    child: vacSnapshot.hasData
                        ? ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: vacSnapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final doc = vacSnapshot.data!.docs[index];
                              final data = doc.data() as Map<String, dynamic>;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFFF1F5F9),
                                    child: Icon(Icons.person),
                                  ),
                                  title: Text(
                                    data['childName'] ?? "Unknown Child",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    "Vaccine: ${data['vaccineType'] ?? 'N/A'}\nStatus: ${data['status'] ?? 'N/A'}",
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.redAccent),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text("Delete Record?"),
                                          content: const Text(
                                              "Are you sure you want to remove this vaccination entry?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text("No"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                _deleteRecord(context, doc.id);
                                                Navigator.pop(ctx);
                                              },
                                              child: const Text(
                                                "Yes, Delete",
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0066FF), Color(0xFF00B16A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            "Vaccinator Dashboard",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text("Lahore, Punjab", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  // ================= STATS CARD =================
  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$count",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Icon(icon, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.black54, fontSize: 14)),
        ],
      ),
    );
  }

  // ================= BUTTON =================
  Widget _actionButton(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    Widget page,
  ) {
    return ElevatedButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          )
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vaccination_entry.dart';
import 'child_registration.dart';

class VaccinatorScreen extends StatelessWidget {
  const VaccinatorScreen({super.key});

  Future<void> _deleteRecord(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('vaccinations')
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Record deleted successfully"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('children').snapshots(),
        builder: (context, childSnapshot) {

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('vaccinations').snapshots(),
            builder: (context, vacSnapshot) {

              // ========================
              // 🔥 IMPORTANT FIX: DON'T CALCULATE UNTIL BOTH STREAMS READY
              // ========================
              if (!childSnapshot.hasData || !vacSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              int completed = 0;
              int refused = 0;
              int absent = 0;

              Set<String> vaccinatedChildren = {};

              int totalChildren = childSnapshot.data!.docs.length;

              for (var doc in vacSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;

                String status =
                    (data['status'] ?? "").toString().toLowerCase();

                if (status == "completed") {
                  completed++;

                  vaccinatedChildren.add(
                    data['childId'] ?? data['childName'] ?? '',
                  );
                } else if (status == "refused") {
                  refused++;
                } else if (status == "absent") {
                  absent++;
                }
              }

              int targetCount =
                  totalChildren - vaccinatedChildren.length;

              if (targetCount < 0) targetCount = 0;

              return Column(
                children: [
                  _buildHeader(context),

                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildStatCard("Vaccinated", completed, Colors.green, Icons.check_circle_outline),
                          _buildStatCard("Refused", refused, Colors.red, Icons.cancel_outlined),
                          _buildStatCard("Absent", absent, Colors.orange, Icons.people_outline),
                          _buildStatCard("Target", targetCount, Colors.blue, Icons.assignment_outlined),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _actionButton(
                            context,
                            "Scan QR Code",
                            Icons.qr_code_scanner,
                            const Color(0xFF1D4ED8),
                            const VaccinationEntryPage(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _actionButton(
                            context,
                            "Register Child",
                            Icons.add,
                            const Color(0xFF059669),
                            const ChildRegistrationPage(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Recent Activity",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: vacSnapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = vacSnapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFF1F5F9),
                              child: Icon(Icons.person),
                            ),
                            title: Text(
                              data['childName'] ?? "Unknown Child",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "Vaccine: ${data['vaccineType'] ?? 'N/A'}\nStatus: ${data['status'] ?? 'N/A'}",
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.redAccent),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Delete Record?"),
                                    content: const Text(
                                        "Are you sure you want to remove this vaccination entry?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text("No"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _deleteRecord(context, doc.id);
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text(
                                          "Yes, Delete",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0066FF), Color(0xFF00B16A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            "Vaccinator Dashboard",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text("Lahore, Punjab", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$count",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Icon(icon, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.black54, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    Widget page,
  ) {
    return ElevatedButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          )
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vaccination_entry.dart';
import 'child_registration.dart';

class VaccinatorScreen extends StatelessWidget {
  const VaccinatorScreen({super.key});

  Future<void> _deleteRecord(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('vaccinations')
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Record deleted successfully"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('children').snapshots(),
        builder: (context, childSnapshot) {

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('vaccinations').snapshots(),
            builder: (context, vacSnapshot) {

              // ================= SAFE DEFAULTS =================
              int completed = 0;
              int refused = 0;
              int absent = 0;

              Set<String> vaccinatedChildren = {};

              // ================= ONLY WHEN DATA EXISTS =================
              if (childSnapshot.hasData && vacSnapshot.hasData) {

                final childrenDocs = childSnapshot.data!.docs;
                final vacDocs = vacSnapshot.data!.docs;

                for (var doc in vacDocs) {
                  final data = doc.data() as Map<String, dynamic>;

                  String status =
                      (data['status'] ?? "").toString().toLowerCase();

                  if (status == "completed") {
                    completed++;

                    vaccinatedChildren.add(
                      data['childId'] ?? data['childName'] ?? '',
                    );
                  } else if (status == "refused") {
                    refused++;
                  } else if (status == "absent") {
                    absent++;
                  }
                }

                // ✅ FIXED TARGET LOGIC (REAL CHILD COUNT ONLY)
                int totalChildren = childrenDocs.length;

                int targetCount =
                    totalChildren - vaccinatedChildren.length;

                if (targetCount < 0) targetCount = 0;

                return _buildUI(
                  context,
                  completed,
                  refused,
                  absent,
                  targetCount,
                  vacSnapshot,
                );
              }

              return const Center(child: CircularProgressIndicator());
            },
          );
        },
      ),
    );
  }

  // ================= UI SEPARATED (NO LOGIC CHANGE) =================
  Widget _buildUI(
    BuildContext context,
    int completed,
    int refused,
    int absent,
    int targetCount,
    AsyncSnapshot<QuerySnapshot> vacSnapshot,
  ) {
    return Column(
      children: [
        _buildHeader(context),

        Transform.translate(
          offset: const Offset(0, -20),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatCard("Vaccinated", completed, Colors.green, Icons.check_circle_outline),
                _buildStatCard("Refused", refused, Colors.red, Icons.cancel_outlined),
                _buildStatCard("Absent", absent, Colors.orange, Icons.people_outline),
                _buildStatCard("Target", targetCount, Colors.blue, Icons.assignment_outlined),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _actionButton(
                  context,
                  "Scan QR Code",
                  Icons.qr_code_scanner,
                  const Color(0xFF1D4ED8),
                  const VaccinationEntryPage(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionButton(
                  context,
                  "Register Child",
                  Icons.add,
                  const Color(0xFF059669),
                  const ChildRegistrationPage(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Recent Activity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vacSnapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = vacSnapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF1F5F9),
                    child: Icon(Icons.person),
                  ),
                  title: Text(
                    data['childName'] ?? "Unknown Child",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Vaccine: ${data['vaccineType'] ?? 'N/A'}\nStatus: ${data['status'] ?? 'N/A'}",
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.redAccent),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Delete Record?"),
                          content: const Text("Are you sure you want to remove this vaccination entry?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("No"),
                            ),
                            TextButton(
                              onPressed: () {
                                _deleteRecord(context, doc.id);
                                Navigator.pop(ctx);
                              },
                              child: const Text(
                                "Yes, Delete",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(BuildContext context) { /* unchanged */ 
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0066FF), Color(0xFF00B16A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            "Vaccinator Dashboard",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text("Lahore, Punjab", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  // ================= STAT CARD =================
  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$count",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Icon(icon, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    Widget page,
  ) {
    return ElevatedButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(text,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          )
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vaccination_entry.dart';
import 'child_registration.dart';

class VaccinatorScreen extends StatelessWidget {
  const VaccinatorScreen({super.key});

  Future<void> _deleteRecord(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('vaccinations')
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Record deleted successfully"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('children').snapshots(),
        builder: (context, childSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('vaccinations').snapshots(),
            builder: (context, vacSnapshot) {

              // ================= SAFE DEFAULTS =================
              int completed = 0;
              int refused = 0;
              int absent = 0;

              Set<String> vaccinatedChildren = {};

              if (!childSnapshot.hasData || !vacSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final childrenDocs = childSnapshot.data!.docs;
              final vacDocs = vacSnapshot.data!.docs;

              // ================= VACCINATION COUNT =================
              for (var doc in vacDocs) {
                final data = doc.data() as Map<String, dynamic>;

                String status = (data['status'] ?? "").toString().toLowerCase();

                String childId = (data['childId'] ?? doc.id).toString();

                if (status == "completed") {
                  completed++;
                  vaccinatedChildren.add(childId);
                } else if (status == "refused") {
                  refused++;
                } else if (status == "absent") {
                  absent++;
                }
              }

              // ================= FIXED TARGET LOGIC =================
              Set<String> allChildren = {};

              for (var doc in childrenDocs) {
                final data = doc.data() as Map<String, dynamic>;

                String id = (data['childId'] ?? doc.id).toString();
                allChildren.add(id);
              }

              // remove vaccinated children
              allChildren.removeAll(vaccinatedChildren);

              int targetCount = allChildren.length;

              if (targetCount < 0) targetCount = 0;

              // ================= UI =================
              return Column(
                children: [
                  _buildHeader(context),

                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildStatCard("Vaccinated", completed, Colors.green, Icons.check_circle_outline),
                          _buildStatCard("Refused", refused, Colors.red, Icons.cancel_outlined),
                          _buildStatCard("Absent", absent, Colors.orange, Icons.people_outline),
                          _buildStatCard("Target", targetCount, Colors.blue, Icons.assignment_outlined),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _actionButton(
                            context,
                            "Scan QR Code",
                            Icons.qr_code_scanner,
                            const Color(0xFF1D4ED8),
                            const VaccinationEntryPage(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _actionButton(
                            context,
                            "Register Child",
                            Icons.add,
                            const Color(0xFF059669),
                            const ChildRegistrationPage(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Recent Activity",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: vacDocs.length,
                      itemBuilder: (context, index) {
                        final doc = vacDocs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFF1F5F9),
                              child: Icon(Icons.person),
                            ),
                            title: Text(
                              data['childName'] ?? "Unknown Child",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "Vaccine: ${data['vaccineType'] ?? 'N/A'}\nStatus: ${data['status'] ?? 'N/A'}",
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.redAccent),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Delete Record?"),
                                    content: const Text(
                                        "Are you sure you want to remove this vaccination entry?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text("No"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _deleteRecord(context, doc.id);
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text(
                                          "Yes, Delete",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0066FF), Color(0xFF00B16A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            "Vaccinator Dashboard",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text("Lahore, Punjab", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  // ================= STAT CARD =================
  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$count",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Icon(icon, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  // ================= BUTTON =================
  Widget _actionButton(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    Widget page,
  ) {
    return ElevatedButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          )
        ],
      ),
    );
  }
}*/
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vaccination_entry.dart';
import 'child_registration.dart';

class VaccinatorScreen extends StatelessWidget {
  const VaccinatorScreen({super.key});

  // Theme Colors based on ImmunoSphere Branding
  static const Color primaryBlue = Color(0xFF004AAD);
  static const Color accentBlue = Color(0xFFEBF2FF);
  static const Color surfaceWhite = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF1E293B);

  Future<void> _deleteRecord(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('vaccinations')
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Record deleted successfully"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceWhite, // Clean background
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('children').snapshots(),
        builder: (context, childSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('vaccinations').snapshots(),
            builder: (context, vacSnapshot) {

              int completed = 0;
              int refused = 0;
              int absent = 0;
              Set<String> vaccinatedChildren = {};

              if (!childSnapshot.hasData || !vacSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: primaryBlue));
              }

              final childrenDocs = childSnapshot.data!.docs;
              final vacDocs = vacSnapshot.data!.docs;

              for (var doc in vacDocs) {
                final data = doc.data() as Map<String, dynamic>;
                String status = (data['status'] ?? "").toString().toLowerCase();
                String childId = (data['childId'] ?? doc.id).toString();

                if (status == "completed") {
                  completed++;
                  vaccinatedChildren.add(childId);
                } else if (status == "refused") {
                  refused++;
                } else if (status == "absent") {
                  absent++;
                }
              }

              Set<String> allChildren = {};
              for (var doc in childrenDocs) {
                final data = doc.data() as Map<String, dynamic>;
                String id = (data['childId'] ?? doc.id).toString();
                allChildren.add(id);
              }

              allChildren.removeAll(vaccinatedChildren);
              int targetCount = allChildren.length;
              if (targetCount < 0) targetCount = 0;

              return Column(
                children: [
                  _buildHeader(context),

                  Transform.translate(
                    offset: const Offset(0, -30),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildStatCard("Vaccinated", completed, const Color(0xFF059669), Icons.verified_user),
                          _buildStatCard("Refused", refused, const Color(0xFFDC2626), Icons.block),
                          _buildStatCard("Absent", absent, const Color(0xFFD97706), Icons.person_off),
                          _buildStatCard("Target", targetCount, primaryBlue, Icons.track_changes),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _actionButton(
                            context,
                            "Vaccination Entry",
                            Icons.qr_code_scanner_rounded,
                            primaryBlue,
                            const VaccinationEntryPage(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _actionButton(
                            context,
                            "Register Child",
                            Icons.person_add_alt_1_rounded,
                            const Color(0xFF004AAD), // Dark contrast button
                            const ChildRegistrationPage(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Recent Activity",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
                      ),
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: vacDocs.length,
                      itemBuilder: (context, index) {
                        final doc = vacDocs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.withOpacity(0.1)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: accentBlue,
                              child: const Icon(Icons.person, color: primaryBlue),
                            ),
                            title: Text(
                              data['childName'] ?? "Unknown Child",
                              style: const TextStyle(fontWeight: FontWeight.w600, color: textDark),
                            ),
                            subtitle: Text(
                              "Vaccine: ${data['vaccineType'] ?? 'N/A'} • ${data['status'] ?? 'N/A'}",
                              style: const TextStyle(color: Colors.black54),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: const Text("Delete Record?"),
                                    content: const Text("This action cannot be undone."),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () {
                                          _deleteRecord(context, doc.id);
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text("Delete", style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 50),
      decoration: const BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 20),
          const Text(
            "Vaccinator Dashboard",
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.white.withOpacity(0.7), size: 14),
              const SizedBox(width: 4),
              Text("Lahore, Punjab", style: TextStyle(color: Colors.white.withOpacity(0.8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: primaryBlue.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            "$count",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark),
          ),
          Text(title, style: const TextStyle(color: Colors.black45, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, String text, IconData icon, Color color, Widget page) {
    return ElevatedButton(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}