/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class ReminderPage extends StatelessWidget {
  final String motherCNIC;

  const ReminderPage({super.key, required this.motherCNIC});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Vaccination Reminders",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vaccinations')
            .where('motherCNIC', isEqualTo: motherCNIC)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No reminders found"));
          }

          final docs = snapshot.data!.docs;

          // 🔥 REAL REMINDER LOGIC (ADDED HERE)
          for (var doc in docs) {
            final v = doc.data() as Map<String, dynamic>;

            String vaccine = v['vaccineType'] ?? '';
            String dose = v['doseNumber'] ?? v['dose'] ?? '';
            String dueDate = v['dueDate'] ?? '';

            if (vaccine.isNotEmpty && dueDate.isNotEmpty) {
              showNotification(
                "Vaccination Reminder",
                "$vaccine $dose is due on $dueDate",
              );
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Text(
                  "Upcoming Vaccinations",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  "Schedule and plan ahead for your children's vaccines",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemBuilder: (context, index) {
                    final v = docs[index].data() as Map<String, dynamic>;

                    bool isUrgent = v['status'] == 'urgent';
                    Color mainColor = isUrgent ? Colors.red : Colors.blue;
                    Color bgColor = isUrgent
                        ? const Color(0xFFFFEBEE)
                        : const Color(0xFFE3F2FD);

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: mainColor.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // HEADER
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isUrgent ? Icons.error_outline : Icons.calendar_today_outlined,
                                    color: mainColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    v['childName'] ?? 'Child',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),

                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: mainColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isUrgent ? "urgent" : "upcoming",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Padding(
                            padding: const EdgeInsets.only(left: 35),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${v['vaccineType'] ?? 'OPV'} - ${v['doseNumber'] ?? v['dose'] ?? ''}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "Due: ${v['dueDate'] ?? 'Not set'}",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black.withOpacity(0.5),
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
              ),
            ],
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class ReminderPage extends StatelessWidget {
  final String motherCNIC;

  const ReminderPage({super.key, required this.motherCNIC});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Vaccination Reminders",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vaccinations')
            .where('motherCNIC', isEqualTo: motherCNIC)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No reminders found"));
          }

          final allDocs = snapshot.data!.docs;

          // 🔥 FILTER ONLY UPCOMING (REMOVE COMPLETED)
          final docs = allDocs.where((doc) {
            final v = doc.data() as Map<String, dynamic>;
            String status = (v['status'] ?? '').toString().toLowerCase();
            return status != 'completed';
          }).toList();

          // 🔔 NOTIFICATION LOGIC (ONLY UPCOMING)
          for (var doc in docs) {
            final v = doc.data() as Map<String, dynamic>;

            String vaccine = (v['vaccineType'] ?? '').toString();
            String dose = (v['doseNumber'] ?? v['dose'] ?? '').toString();
            String dueDate = (v['dueDate'] ?? '').toString();
            String status = (v['status'] ?? '').toString().toLowerCase();

            if (vaccine.isNotEmpty &&
                (status == 'upcoming' || status == 'pending' || status == '')) {
              showNotification(
                "Vaccination Reminder",
                "$vaccine $dose is due on $dueDate",
              );
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Text(
                  "Upcoming Vaccinations",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  "Schedule and plan ahead for your children's vaccines",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemBuilder: (context, index) {
                    final v = docs[index].data() as Map<String, dynamic>;

                    bool isUrgent = v['status'] == 'urgent';
                    Color mainColor = isUrgent ? Colors.red : Colors.blue;
                    Color bgColor = isUrgent
                        ? const Color(0xFFFFEBEE)
                        : const Color(0xFFE3F2FD);

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: mainColor.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isUrgent
                                        ? Icons.error_outline
                                        : Icons.calendar_today_outlined,
                                    color: mainColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    v['childName'] ?? 'Child',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: mainColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isUrgent ? "urgent" : "upcoming",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Padding(
                            padding: const EdgeInsets.only(left: 35),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${v['vaccineType'] ?? 'OPV'} - ${v['doseNumber'] ?? v['dose'] ?? ''}",
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "Due: ${v['dueDate'] ?? 'Not set'}",
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.5),
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
              ),
            ],
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderPage extends StatefulWidget {
  final String motherCNIC;

  const ReminderPage({super.key, required this.motherCNIC});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {

  bool _shown = false;

  // 🔔 IN-APP REMINDER FUNCTION
  void showInAppReminder(List<QueryDocumentSnapshot> docs, BuildContext context) {
    if (_shown) return;

    for (var doc in docs) {
      final v = doc.data() as Map<String, dynamic>;

      String status = (v['status'] ?? '').toString().toLowerCase();
      String vaccine = (v['vaccineType'] ?? '').toString();
      String dose = (v['doseNumber'] ?? '').toString();
      String dueDate = (v['dueDate'] ?? '').toString();

      // 🔥 only upcoming / pending
      if (status == 'upcoming' || status == 'pending') {

        Future.delayed(const Duration(milliseconds: 500), () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("🔔 Vaccination Reminder"),
              content: Text("$vaccine $dose is due on $dueDate"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                )
              ],
            ),
          );
        });

        _shown = true;
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "Vaccination Reminders",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vaccinations')
            .where('motherCNIC', isEqualTo: widget.motherCNIC)
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No reminders found"));
          }

          final allDocs = snapshot.data!.docs;

          // ❌ REMOVE COMPLETED
          final docs = allDocs.where((doc) {
            final v = doc.data() as Map<String, dynamic>;
            String status = (v['status'] ?? '').toString().toLowerCase();
            return status != 'complete';
          }).toList();

          // 🔔 IN-APP REMINDER CALL
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showInAppReminder(docs, context);
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Text(
                  "Upcoming Vaccinations",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  "Schedule and plan ahead for your children's vaccines",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {

                    final v = docs[index].data() as Map<String, dynamic>;

                    String status = (v['status'] ?? '').toString().toLowerCase();

                    Color color = status == 'urgent'
                        ? Colors.red
                        : Colors.blue;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: color.withOpacity(0.2)),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [

                              Text(
                                v['childName'] ?? 'Child',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),

                            ],
                          ),

                          const SizedBox(height: 10),

                          Text(
                            "${v['vaccineType'] ?? ''} - ${v['doseNumber'] ?? ''}",
                            style: const TextStyle(color: Colors.black87),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            "Due: ${v['dueDate'] ?? ''}",
                            style: const TextStyle(color: Colors.grey),
                          ),

                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}*/
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderPage extends StatefulWidget {
  final String motherCNIC;

  const ReminderPage({super.key, required this.motherCNIC});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {

  bool _shown = false;

  // 🔔 IN-APP REMINDER
  void showInAppReminder(List<QueryDocumentSnapshot> docs, BuildContext context) {
    if (_shown) return;

    for (var doc in docs) {
      final v = doc.data() as Map<String, dynamic>;

      String status = (v['status'] ?? '').toString().toLowerCase();
      String vaccine = (v['vaccineType'] ?? '').toString();
      String dose = (v['doseNumber'] ?? '').toString();

      dynamic due = v['dueDate'];

      String dueText;

      if (due == null) {
        dueText = "Not Set";
      } else {
        DateTime date = (due as Timestamp).toDate();
        dueText =
            "${date.day.toString().padLeft(2, '0')}-"
            "${date.month.toString().padLeft(2, '0')}-"
            "${date.year}";
      }

      if (status == 'upcoming' || status == 'pending') {

        Future.delayed(const Duration(milliseconds: 500), () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("🔔 Vaccination Reminder"),
              content: Text("$vaccine $dose is due on $dueText"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                )
              ],
            ),
          );
        });

        _shown = true;
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "Vaccination Reminders",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vaccinations')
            .where('motherCNIC', isEqualTo: widget.motherCNIC)
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No reminders found"));
          }

          final allDocs = snapshot.data!.docs;

          // ❌ REMOVE COMPLETED
          final docs = allDocs.where((doc) {
            final v = doc.data() as Map<String, dynamic>;
            String status = (v['status'] ?? '').toString().toLowerCase();
            return status != 'complete';
          }).toList();

          // 🔔 CALL REMINDER
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showInAppReminder(docs, context);
          });

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {

              final v = docs[index].data() as Map<String, dynamic>;

              String status = (v['status'] ?? '').toString().toLowerCase();

              Color color = status == 'urgent'
                  ? Colors.red
                  : Colors.blue;

              // 🔥 SAFE DATE HANDLING
              dynamic due = v['dueDate'];

              String dueText;

              if (due == null) {
                dueText = "Not Set";
              } else {
                DateTime date = (due as Timestamp).toDate();
                dueText =
                    "${date.day.toString().padLeft(2, '0')}-"
                    "${date.month.toString().padLeft(2, '0')}-"
                    "${date.year}";
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        Text(
                          v['childName'] ?? 'Child',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),

                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "${v['vaccineType'] ?? ''} - ${v['doseNumber'] ?? ''}",
                      style: const TextStyle(color: Colors.black87),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      "Due: $dueText",
                      style: const TextStyle(color: Colors.grey),
                    ),

                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}