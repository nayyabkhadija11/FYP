/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reminder_page.dart';
import 'notification_page.dart';

class ParentScreen extends StatefulWidget {
  const ParentScreen({super.key});

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  int currentIndex = 0;
  final TextEditingController cnicController = TextEditingController();
  String searchCNIC = "";

  String formatCNIC(String cnic) {
    String digits = cnic.replaceAll('-', '').trim();
    if (digits.length != 13) return digits;
    return "${digits.substring(0, 5)}-${digits.substring(5, 12)}-${digits.substring(12)}";
  }

  void search() {
    setState(() {
      searchCNIC = formatCNIC(cnicController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Parent Portal", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: IndexedStack(
        index: currentIndex,
        children: [
          searchChildPage(),
          const ReminderPage(),
          const NotificationPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: "Reminder"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notification"),
        ],
      ),
    );
  }

  Widget searchChildPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: cnicController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Enter Mother CNIC (12345-1234567-1)",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: search,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              child: const Text("Search", style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: searchCNIC.isEmpty
                ? const Center(child: Text("Enter CNIC to search child"))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('children')
                        .where('motherCNIC', isEqualTo: searchCNIC)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) return const Center(child: Text("No child found"));

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          return Card(
                            child: ListTile(
                              title: Text(data['name'] ?? "No Name", style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("Age: ${data['age'] ?? ''} | District: ${data['district'] ?? ''}"),
                              trailing: ElevatedButton(
                                child: const Text("View"),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ChildDetailPage(data: data)),
                                ),
                              ),
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
}

// ================= UPDATED CHILD DETAIL PAGE (MATCHES IMAGE) =================
class ChildDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const ChildDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Column(
        children: [
          // 1. Purple Header Section
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 30),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                  "Parent Portal",
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Track your children's vaccination records",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // 2. Main Info Card
          Transform.translate(
            offset: const Offset(0, -20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Profile Section
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: const Color(0xFFEDE9FE),
                            child: const Icon(Icons.child_care, size: 40, color: Color(0xFF8B5CF6)),
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name'] ?? "Name",
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "ID: ${data['childID'] ?? 'CH001'} • Age: ${data['age'] ?? 'N/A'}",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),

                      // Progress Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text("Vaccination Progress", style: TextStyle(fontWeight: FontWeight.w500)),
                          Text("12/14", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: 12 / 14,
                        backgroundColor: Colors.grey[200],
                        color: Colors.black,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 20),

                      // Next Vaccination Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFEDD5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFFEA580C)),
                                SizedBox(width: 8),
                                Text(
                                  "Next Vaccination Due",
                                  style: TextStyle(color: Color(0xFFEA580C), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Measles-2",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const Text(
                              "2026-05-10 (19 days left)",
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // View Records Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            // Logic for full table or list
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("View Full Records", style: TextStyle(color: Colors.black)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}*/
/*
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reminder_page.dart';
import 'notification_page.dart';

class ParentScreen extends StatefulWidget {
  const ParentScreen({super.key});

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  int currentIndex = 0;
  final TextEditingController cnicController = TextEditingController();
  String searchCNIC = "";

  String formatCNIC(String cnic) {
    String digits = cnic.replaceAll('-', '').trim();
    if (digits.length != 13) return digits;
    return "${digits.substring(0, 5)}-${digits.substring(5, 12)}-${digits.substring(12)}";
  }

  void search() {
    setState(() {
      searchCNIC = formatCNIC(cnicController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Parent Portal", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: IndexedStack(
        index: currentIndex,
        children: [
          searchChildPage(),
          const ReminderPage(),
          const NotificationPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: "Reminder"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notification"),
        ],
      ),
    );
  }

  // ================= SEARCH PAGE =================
  Widget searchChildPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: cnicController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Enter Mother CNIC (12345-1234567-1)",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: search,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              child: const Text("Search", style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: searchCNIC.isEmpty
                ? const Center(child: Text("Enter CNIC to search child"))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('children')
                        .where('motherCNIC', isEqualTo: searchCNIC)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Center(child: Text("No child found"));
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;

                          return Card(
                            child: ListTile(
                              title: Text(data['name'] ?? "No Name"),
                              subtitle: Text(
                                  "Age: ${data['age'] ?? ''} | District: ${data['district'] ?? ''}"),
                              trailing: ElevatedButton(
                                child: const Text("View"),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ChildDetailPage(data: data),
                                    ),
                                  );
                                },
                              ),
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
}

// ================= CHILD DETAIL PAGE (REAL DATA VERSION) =================
class ChildDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;
  const ChildDetailPage({super.key, required this.data});

  @override
  State<ChildDetailPage> createState() => _ChildDetailPageState();
}

class _ChildDetailPageState extends State<ChildDetailPage> {
  int total = 0;
  int completed = 0;
  Map<String, dynamic>? nextVaccine;

  @override
  void initState() {
    super.initState();
    loadVaccines();
  }

  // 🔥 REAL FIRESTORE LOGIC
  Future<void> loadVaccines() async {
    final snap = await FirebaseFirestore.instance
        .collection('vaccinations')
        .where('childId', isEqualTo: widget.data['childID'])
        .get();

    int t = snap.docs.length;
    int c = 0;
    Map<String, dynamic>? next;

    for (var doc in snap.docs) {
      final d = doc.data();

      if (d['status'] == 'Completed') {
        c++;
      } else if (next == null) {
        next = d;
      }
    }

    setState(() {
      total = t;
      completed = c;
      nextVaccine = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    double progress = total == 0 ? 0 : completed / total;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 30),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text("Parent Portal",
                    style: TextStyle(color: Colors.white, fontSize: 28)),
                const Text("Track vaccination records",
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),

          Transform.translate(
            offset: const Offset(0, -20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 35,
                            child: Icon(Icons.child_care),
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.data['name'] ?? "Name"),
                              Text("Age: ${widget.data['age'] ?? ''}"),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 🔥 REAL PROGRESS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Vaccination Progress"),
                          Text("$completed/$total"),
                        ],
                      ),

                      LinearProgressIndicator(value: progress),

                      const SizedBox(height: 20),

                      // 🔥 REAL NEXT VACCINE
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Next Vaccination"),
                            Text(
                              nextVaccine?['vaccineType'] ?? "No upcoming vaccine",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              nextVaccine?['date'] ?? "Not scheduled",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}*/
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reminder_page.dart';
import 'notification_page.dart';

class ParentScreen extends StatefulWidget {
  const ParentScreen({super.key});

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  int currentIndex = 0;
  final TextEditingController cnicController = TextEditingController();
  String searchCNIC = "";

  String formatCNIC(String cnic) {
    String digits = cnic.replaceAll('-', '').trim();
    if (digits.length != 13) return digits;
    return "${digits.substring(0, 5)}-${digits.substring(5, 12)}-${digits.substring(12)}";
  }

  void search() {
    setState(() {
      searchCNIC = formatCNIC(cnicController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Parent Portal", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: IndexedStack(
        index: currentIndex,
        children: [
          searchChildPage(),
          const ReminderPage(),
          const NotificationPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: "Reminder"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notification"),
        ],
      ),
    );
  }

  Widget searchChildPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: cnicController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Enter Mother CNIC",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: search,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
              ),
              child: const Text("Search", style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: searchCNIC.isEmpty
                ? const Center(child: Text("Enter CNIC to search child"))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('children')
                        .where('motherCNIC', isEqualTo: searchCNIC)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Center(child: Text("No child found"));
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;

                          return Card(
                            child: ListTile(
                              title: Text(data['name'] ?? "No Name"),
                              subtitle: Text(
                                  "Age: ${data['age'] ?? ''} | District: ${data['district'] ?? ''}"),
                              trailing: ElevatedButton(
                                child: const Text("View"),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ChildDetailPage(data: data),
                                    ),
                                  );
                                },
                              ),
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
}

// ================= CHILD DETAIL PAGE (FIXED PROGRESS LOGIC) =================
class ChildDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const ChildDetailPage({super.key, required this.data});

  bool isCompleted(String status) {
    return status.toLowerCase() == "done" ||
        status.toLowerCase() == "completed" ||
        status.toLowerCase() == "complete";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Column(
        children: [

          // HEADER
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 30),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
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
                  "Parent Portal",
                  style: TextStyle(color: Colors.white, fontSize: 28),
                ),
              ],
            ),
          ),

          Transform.translate(
            offset: const Offset(0, -20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [

                      Text(
                        data['name'] ?? "",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 🔥 REAL TIME PROGRESS CALCULATION
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('vaccinations')
                            .where('childId', isEqualTo: data['childID'])
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }

                          final docs = snapshot.data!.docs;

                          int totalDoses = docs.length;
                          int completedDoses = 0;
                          Map<String, dynamic>? next;

                          for (var d in docs) {
                            final vac = d.data() as Map<String, dynamic>;

                            if (isCompleted(vac['status'] ?? "")) {
                              completedDoses++;
                            } else {
                              next ??= vac;
                            }
                          }

                          double progress =
                              totalDoses == 0 ? 0 : completedDoses / totalDoses;

                          return Column(
                            children: [

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Vaccination Progress"),
                                  Text("$completedDoses/$totalDoses"),
                                ],
                              ),

                              const SizedBox(height: 8),

                              LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                              ),

                              const SizedBox(height: 20),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: next == null
                                    ? const Text("All vaccines completed 🎉")
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Next Vaccination",
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(next['vaccineType'] ?? ""),
                                          Text(next['date'] ?? ""),
                                        ],
                                      ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {},
                          child: const Text("View Full Records"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 