/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChildDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const ChildDetailPage({super.key, required this.data});

  @override
  State<ChildDetailPage> createState() => _ChildDetailPageState();
}

class _ChildDetailPageState extends State<ChildDetailPage> {
  int total = 36;
  int completed = 0;
  Map<String, dynamic>? nextVaccine;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadVaccines();
  }

  Future<void> loadVaccines() async {
    // ✅ FIX: proper childId extraction
    final childId =
        widget.data['childId'] ?? widget.data['childID'] ?? widget.data['id'];

    try {
      final snap = await FirebaseFirestore.instance
          .collection('vaccinations')
          .where('childId', isEqualTo: childId)
          .get();

      int completedCount = 0;
      List<Map<String, dynamic>> allVaccines = [];

      for (var doc in snap.docs) {
        final d = doc.data();

        if ((d['status'] ?? '').toString().toLowerCase() == 'completed') {
          completedCount++;
        }

        allVaccines.add(d);
      }

      // ==============================
      // ✅ FIXED NEXT VACCINE LOGIC
      // ==============================

      Map<String, List<Map<String, dynamic>>> grouped = {};

      for (var v in allVaccines) {
        String type = (v['vaccineType'] ?? '').toString();
        grouped.putIfAbsent(type, () => []);
        grouped[type]!.add(v);
      }

      grouped.forEach((key, list) {
        list.sort((a, b) {
          int d1 = int.tryParse(a['dose'].toString()) ?? 0;
          int d2 = int.tryParse(b['dose'].toString()) ?? 0;
          return d1.compareTo(d2);
        });
      });

      Map<String, dynamic>? next;

      for (var entry in grouped.entries) {
        for (var v in entry.value) {
          if ((v['status'] ?? '').toString().toLowerCase() != 'completed') {
            next = v;
            break;
          }
        }
        if (next != null) break;
      }

      setState(() {
        completed = completedCount;
        nextVaccine = next;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error loading vaccines: $e");
    }
  }

  DateTime _parseDate(dynamic date) {
    if (date is Timestamp) return date.toDate();
    try {
      return DateTime.parse(date.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  String calculateAge(dynamic dob) {
    if (dob == null) return "N/A";
    DateTime birthDate = _parseDate(dob);
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    int days = difference.inDays;

    if (days < 7) return "$days days";
    if (days < 30) return "${(days / 7).floor()} weeks";
    if (days < 365) return "${(days / 30).floor()} months";
    return "${(days / 365).floor()} years";
  }

  String formatDate(dynamic date) {
    if (date == null) return "Not set";
    DateTime dt = _parseDate(date);
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  String calculateDaysLeft(dynamic dueDate) {
    if (dueDate == null) return "";
    DateTime scheduled = _parseDate(dueDate);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(scheduled.year, scheduled.month, scheduled.day);

    final difference = target.difference(today).inDays;

    if (difference == 0) return "Due Today";
    if (difference < 0) return "${difference.abs()} days overdue";
    return "$difference days left";
  }

  @override
  Widget build(BuildContext context) {
    double progress = total == 0 ? 0 : completed / total;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Child Details",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "Name: ${widget.data['name'] ?? 'N/A'}",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text("Age: ${calculateAge(widget.data['dob'])}",
                      style: const TextStyle(fontSize: 16)),
                  Text("DOB: ${formatDate(widget.data['dob'])}",
                      style: const TextStyle(fontSize: 16)),
                  Text("District: ${widget.data['district'] ?? 'Not set'}",
                      style: const TextStyle(fontSize: 16)),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Vaccination Progress",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("$completed/$total"),
                    ],
                  ),

                  const SizedBox(height: 8),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5EC),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFFFFE0C2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Next Vaccination Due",
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        if (nextVaccine != null) ...[
                          Text(
                            "${nextVaccine?['vaccineType'] ?? 'Unknown'} - Dose ${nextVaccine?['dose'] ?? '-'}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF455A64),
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            nextVaccine?['date'] != null
                                ? "${formatDate(nextVaccine!['date'])} (${calculateDaysLeft(nextVaccine!['date'])})"
                                : "No date set",
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF607D8B),
                            ),
                          ),
                        ] else ...[
                          const Text(
                              "No upcoming vaccinations scheduled."),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'full_vaccination_page.dart';

class ChildDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const ChildDetailPage({super.key, required this.data});

  @override
  State<ChildDetailPage> createState() => _ChildDetailPageState();
}

class _ChildDetailPageState extends State<ChildDetailPage> {
  int total = 36;
  int completed = 0;
  Map<String, dynamic>? nextVaccine;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadVaccines();
  }

  Future<void> loadVaccines() async {
    final motherCNIC =
        widget.data['motherCNIC'] ?? widget.data['motherCNIC'] ?? widget.data['motherCNIC'];

    try {
      final snap = await FirebaseFirestore.instance
          .collection('vaccinations')
          .where('motherCNIC', isEqualTo: motherCNIC)
          .get();

      int completedCount = 0;
      List<Map<String, dynamic>> allVaccines = [];

      for (var doc in snap.docs) {
        final d = doc.data();

        if ((d['status'] ?? '').toString().toLowerCase() == 'completed') {
          completedCount++;
        }

        allVaccines.add(d);
      }

      Map<String, List<Map<String, dynamic>>> grouped = {};

      for (var v in allVaccines) {
        String type = (v['vaccineType'] ?? '').toString();
        grouped.putIfAbsent(type, () => []);
        grouped[type]!.add(v);
      }

      grouped.forEach((key, list) {
        list.sort((a, b) {
          int d1 = int.tryParse(a['dose'].toString()) ?? 0;
          int d2 = int.tryParse(b['dose'].toString()) ?? 0;
          return d1.compareTo(d2);
        });
      });

      Map<String, dynamic>? next;

      for (var entry in grouped.entries) {
        for (var v in entry.value) {
          if ((v['status'] ?? '').toString().toLowerCase() != 'completed') {
            next = v;
            break;
          }
        }
        if (next != null) break;
      }

      setState(() {
        completed = completedCount;
        nextVaccine = next;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error loading vaccines: $e");
    }
  }

  DateTime _parseDate(dynamic date) {
    if (date is Timestamp) return date.toDate();
    try {
      return DateTime.parse(date.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  String calculateAge(dynamic dob) {
    if (dob == null) return "N/A";
    DateTime birthDate = _parseDate(dob);
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    int days = difference.inDays;

    if (days < 7) return "$days days";
    if (days < 30) return "${(days / 7).floor()} weeks";
    if (days < 365) return "${(days / 30).floor()} months";
    return "${(days / 365).floor()} years";
  }

  String formatDate(dynamic date) {
    if (date == null) return "Not set";
    DateTime dt = _parseDate(date);
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  String calculateDaysLeft(dynamic dueDate) {
    if (dueDate == null) return "";
    DateTime scheduled = _parseDate(dueDate);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(scheduled.year, scheduled.month, scheduled.day);

    final difference = target.difference(today).inDays;

    if (difference == 0) return "Due Today";
    if (difference < 0) return "${difference.abs()} days overdue";
    return "$difference days left";
  }

  @override
  Widget build(BuildContext context) {
    double progress = total == 0 ? 0 : completed / total;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Child Details",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "Name: ${widget.data['name'] ?? 'N/A'}",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text("Age: ${calculateAge(widget.data['dob'])}"),
                  Text("DOB: ${formatDate(widget.data['dob'])}"),
                  Text("District: ${widget.data['district'] ?? 'Not set'}"),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Vaccination Progress",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("$completed/$total"),
                    ],
                  ),

                  const SizedBox(height: 8),

                  LinearProgressIndicator(value: progress),

                  const SizedBox(height: 30),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Text(
                          "Next Vaccination Due",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),

                        const SizedBox(height: 12),

                        if (nextVaccine != null) ...[
                          Text(
                            "${nextVaccine!['vaccineType']} - Dose ${nextVaccine!['dose']}",
                          ),
                          Text(
                            nextVaccine!['date'] != null
                                ? "${formatDate(nextVaccine!['date'])} (${calculateDaysLeft(nextVaccine!['date'])})"
                                : "No date set",
                          ),
                        ] else ...[
                          const Text("No upcoming vaccinations scheduled."),
                        ],

                        const SizedBox(height: 20),

                        ElevatedButton.icon(
                          icon: const Icon(Icons.list),
                          label: const Text("View Full Vaccination Details"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullVaccinationPage(
                                  childId: widget.data['motherCNIC'] ??
                                      widget.data['motherCNIC'] ??
                                      widget.data['motherCNIC'],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class FullVaccinationPage extends StatelessWidget {
  final String childId;

  const FullVaccinationPage({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Vaccination Records"),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vaccinations')
            .where('motherCNIC', isEqualTo: motherCNIC)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No records found"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final v = docs[index].data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.vaccines),
                  title: Text("${v['vaccineType'] ?? 'Unknown'}"),
                  subtitle: Text("Dose: ${v['dose'] ?? '-'}"),
                  trailing: Text(
                    (v['status'] ?? 'pending').toString(),
                    style: TextStyle(
                      color: (v['status'] == 'completed')
                          ? Colors.green
                          : Colors.orange,
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
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChildDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const ChildDetailPage({super.key, required this.data});

  @override
  State<ChildDetailPage> createState() => _ChildDetailPageState();
}

class _ChildDetailPageState extends State<ChildDetailPage> {
  int total = 36;
  int completed = 0;
  Map<String, dynamic>? nextVaccine;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadVaccines();
  }

  Future<void> loadVaccines() async {
    final motherCNIC = widget.data['motherCNIC'];

    try {
      final snap = await FirebaseFirestore.instance
          .collection('vaccinations')
          .where('motherCNIC', isEqualTo: motherCNIC)
          .get();

      int completedCount = 0;
      List<Map<String, dynamic>> allVaccines = [];

      for (var doc in snap.docs) {
        final d = doc.data();

        if ((d['status'] ?? '').toString().toLowerCase() == 'completed') {
          completedCount++;
        }

        allVaccines.add(d);
      }

      Map<String, List<Map<String, dynamic>>> grouped = {};

      for (var v in allVaccines) {
        String type = (v['vaccineType'] ?? '').toString();
        grouped.putIfAbsent(type, () => []);
        grouped[type]!.add(v);
      }

      grouped.forEach((key, list) {
        list.sort((a, b) {
          int d1 = int.tryParse(a['dose'].toString()) ?? 0;
          int d2 = int.tryParse(b['dose'].toString()) ?? 0;
          return d1.compareTo(d2);
        });
      });

      Map<String, dynamic>? next;

      for (var entry in grouped.entries) {
        for (var v in entry.value) {
          if ((v['status'] ?? '').toString().toLowerCase() != 'completed') {
            next = v;
            break;
          }
        }
        if (next != null) break;
      }

      setState(() {
        completed = completedCount;
        nextVaccine = next;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error loading vaccines: $e");
    }
  }

  DateTime _parseDate(dynamic date) {
    if (date is Timestamp) return date.toDate();
    try {
      return DateTime.parse(date.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  String calculateAge(dynamic dob) {
    if (dob == null) return "N/A";
    DateTime birthDate = _parseDate(dob);
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    int days = difference.inDays;

    if (days < 7) return "$days days";
    if (days < 30) return "${(days / 7).floor()} weeks";
    if (days < 365) return "${(days / 30).floor()} months";
    return "${(days / 365).floor()} years";
  }

  String formatDate(dynamic date) {
    if (date == null) return "Not set";
    DateTime dt = _parseDate(date);
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  String calculateDaysLeft(dynamic dueDate) {
    if (dueDate == null) return "";
    DateTime scheduled = _parseDate(dueDate);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(scheduled.year, scheduled.month, scheduled.day);

    final difference = target.difference(today).inDays;

    if (difference == 0) return "Due Today";
    if (difference < 0) return "${difference.abs()} days overdue";
    return "$difference days left";
  }

  @override
  Widget build(BuildContext context) {
    double progress = total == 0 ? 0 : completed / total;

    final motherCNIC = widget.data['motherCNIC'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Child Details",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Name: ${widget.data['name'] ?? 'N/A'}",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text("Age: ${calculateAge(widget.data['dob'])}"),
                  Text("DOB: ${formatDate(widget.data['dob'])}"),
                  Text("District: ${widget.data['district'] ?? 'Not set'}"),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Vaccination Progress",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("$completed/$total"),
                    ],
                  ),

                  const SizedBox(height: 8),

                  LinearProgressIndicator(value: progress),

                  const SizedBox(height: 30),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Next Vaccination Due",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),

                        const SizedBox(height: 12),

                        if (nextVaccine != null) ...[
                          Text(
                            "${nextVaccine!['vaccineType']} - Dose ${nextVaccine!['dose']}",
                          ),
                          Text(
                            nextVaccine!['date'] != null
                                ? "${formatDate(nextVaccine!['date'])} (${calculateDaysLeft(nextVaccine!['date'])})"
                                : "No date set",
                          ),
                        ] else ...[
                          const Text("No upcoming vaccinations scheduled."),
                        ],

                        const SizedBox(height: 20),

                        ElevatedButton.icon(
                          icon: const Icon(Icons.list),
                          label: const Text("View Full Vaccination Details"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    FullVaccinationPage(motherCNIC: motherCNIC),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class FullVaccinationPage extends StatelessWidget {
  final String motherCNIC;

  const FullVaccinationPage({super.key, required this.motherCNIC});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Vaccination Records"),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vaccinations')
            .where('motherCNIC', isEqualTo: motherCNIC)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No records found"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final v = docs[index].data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.vaccines),
                  title: Text("${v['vaccineType'] ?? 'Unknown'}"),
                  subtitle: Text("Dose: ${v['dose'] ?? '-'}"),
                  trailing: Text(
                    (v['status'] ?? 'pending').toString(),
                    style: TextStyle(
                      color: (v['status'] == 'completed')
                          ? Colors.green
                          : Colors.orange,
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
}*/
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChildDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const ChildDetailPage({super.key, required this.data});

  @override
  State<ChildDetailPage> createState() => _ChildDetailPageState();
}

class _ChildDetailPageState extends State<ChildDetailPage> {
  int total = 36;
  int completed = 0;
  Map<String, dynamic>? nextVaccine;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadVaccines();
  }

  Future<void> loadVaccines() async {
    final motherCNIC = widget.data['motherCNIC'];

    try {
      final snap = await FirebaseFirestore.instance
          .collection('vaccinations')
          .where('motherCNIC', isEqualTo: motherCNIC)
          .get();

      int completedCount = 0;
      List<Map<String, dynamic>> allVaccines = [];

      for (var doc in snap.docs) {
        final d = doc.data();

        if ((d['status'] ?? '').toString().toLowerCase().trim() == 'completed') {
          completedCount++;
        }

        allVaccines.add(d);
      }

      Map<String, List<Map<String, dynamic>>> grouped = {};

      for (var v in allVaccines) {
        String type = (v['vaccineType'] ?? '').toString();
        grouped.putIfAbsent(type, () => []);
        grouped[type]!.add(v);
      }

      grouped.forEach((key, list) {
        list.sort((a, b) {
          int d1 = int.tryParse(a['dose']?.toString() ?? a['doseNumber']?.toString() ?? '0') ?? 0;
          int d2 = int.tryParse(b['dose']?.toString() ?? b['doseNumber']?.toString() ?? '0') ?? 0;
          return d1.compareTo(d2);
        });
      });

      Map<String, dynamic>? next;

      for (var entry in grouped.entries) {
        for (var v in entry.value) {
          if ((v['status'] ?? '').toString().toLowerCase().trim() != 'completed') {
            next = v;
            break;
          }
        }
        if (next != null) break;
      }

      setState(() {
        completed = completedCount;
        nextVaccine = next;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error loading vaccines: $e");
    }
  }

  DateTime _parseDate(dynamic date) {
    if (date is Timestamp) return date.toDate();
    try {
      return DateTime.parse(date.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  String calculateAge(dynamic dob) {
    if (dob == null) return "N/A";
    DateTime birthDate = _parseDate(dob);
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    int days = difference.inDays;

    if (days < 7) return "$days days";
    if (days < 30) return "${(days / 7).floor()} weeks";
    if (days < 365) return "${(days / 30).floor()} months";
    return "${(days / 365).floor()} years";
  }

  String formatDate(dynamic date) {
    if (date == null) return "Not set";
    DateTime dt = _parseDate(date);
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  String calculateDaysLeft(dynamic dueDate) {
    if (dueDate == null) return "";
    DateTime scheduled = _parseDate(dueDate);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(scheduled.year, scheduled.month, scheduled.day);

    final difference = target.difference(today).inDays;

    if (difference == 0) return "Due Today";
    if (difference < 0) return "${difference.abs()} days overdue";
    return "$difference days left";
  }

  @override
  Widget build(BuildContext context) {
    double progress = total == 0 ? 0 : completed / total;
    final motherCNIC = widget.data['motherCNIC'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Child Details",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Name: ${widget.data['name'] ?? 'N/A'}",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text("Age: ${calculateAge(widget.data['dob'])}"),
                  Text("DOB: ${formatDate(widget.data['dob'])}"),
                  Text("District: ${widget.data['district'] ?? 'Not set'}"),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Vaccination Progress",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("$completed/$total"),
                    ],
                  ),

                  const SizedBox(height: 8),

                  LinearProgressIndicator(value: progress),

                  const SizedBox(height: 30),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Next Vaccination Due",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),

                        const SizedBox(height: 12),

                        if (nextVaccine != null) ...[
                          Text(
                            "${nextVaccine!['vaccineType']} - Dose ${nextVaccine!['doseNumber'] ?? nextVaccine!['dose'] ?? 'N/A'}",
                          ),
                          Text(
                            nextVaccine!['date'] != null
                                ? "${formatDate(nextVaccine!['date'])} (${calculateDaysLeft(nextVaccine!['date'])})"
                                : "No date set",
                          ),
                        ] else ...[
                          const Text("No upcoming vaccinations scheduled."),
                        ],

                        const SizedBox(height: 20),

                        ElevatedButton.icon(
                          icon: const Icon(Icons.list),
                          label: const Text("View Full Vaccination Details"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    FullVaccinationPage(motherCNIC: motherCNIC),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class FullVaccinationPage extends StatelessWidget {
  final String motherCNIC;

  const FullVaccinationPage({super.key, required this.motherCNIC});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Vaccination Records"),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vaccinations')
            .where('motherCNIC', isEqualTo: motherCNIC)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No records found"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final v = docs[index].data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.vaccines),
                  title: Text("${v['vaccineType'] ?? 'Unknown'}"),
                  subtitle: Text(
                    "Dose: ${v['doseNumber'] ?? v['dose'] ?? 'N/A'}",
                  ),
                  trailing: Text(
                    (v['status'] ?? 'pending').toString(),
                    style: TextStyle(
                      color: (v['status'] == 'completed')
                          ? Colors.green
                          : Colors.orange,
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
}