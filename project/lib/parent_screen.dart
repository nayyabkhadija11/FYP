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

  // ================= REAL AGE CALCULATION (FIXED) =================
  String calculateAge(dynamic dob) {
    if (dob == null) return "N/A";

    DateTime birthDate;

    if (dob is Timestamp) {
      birthDate = dob.toDate();
    } else {
      try {
        birthDate = DateTime.parse(dob.toString());
      } catch (e) {
        return "N/A";
      }
    }

    final now = DateTime.now();
    final difference = now.difference(birthDate);

    int days = difference.inDays;

    if (days < 0) return "N/A";

    if (days < 7) {
      return "$days days";
    } else if (days < 30) {
      return "${(days / 7).floor()} weeks";
    } else if (days < 365) {
      return "${(days / 30).floor()} months";
    } else {
      return "${(days / 365).floor()} years";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Parent Portal",
            style: TextStyle(color: Colors.white)),
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
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: "Notification"),
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
              child: const Text("Search",
                  style: TextStyle(color: Colors.white)),
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

                          String name = data['name'] ?? "No Name";
                          String district = data['district'] ?? "N/A";
                          String motherCNIC = data['motherCNIC'] ?? "N/A";

                          String age = calculateAge(data['dob']);

                          String dob = "N/A";
                          if (data['dob'] != null) {
                            if (data['dob'] is Timestamp) {
                              dob = (data['dob'] as Timestamp)
                                  .toDate()
                                  .toString()
                                  .split(' ')[0];
                            } else {
                              dob = data['dob'].toString();
                            }
                          }

                          return Card(
                            child: ListTile(
                              title: Text(name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Age: $age"),
                                  Text("DOB: $dob"),
                                  Text("District: $district"),
                                  Text("Mother CNIC: $motherCNIC"),
                                ],
                              ),
                              trailing: ElevatedButton(
                                child: const Text("View"),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialP
                                    pageRoute(
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

// ================= CHILD DETAIL PAGE =================
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

  Future<void> loadVaccines() async {
    final childId =
        widget.data['childId'] ?? widget.data['childID'] ?? widget.data['id'];

    final snap = await FirebaseFirestore.instance
        .collection('vaccinations')
        .where('childId', isEqualTo: childId)
        .get();

    int t = snap.docs.length;
    int c = 0;
    Map<String, dynamic>? next;

    for (var doc in snap.docs) {
      final d = doc.data();

      if ((d['status'] ?? '').toString().toLowerCase() == 'completed') {
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

  // SAME AGE FUNCTION HERE
  String calculateAge(dynamic dob) {
    if (dob == null) return "N/A";

    DateTime birthDate;

    if (dob is Timestamp) {
      birthDate = dob.toDate();
    } else {
      try {
        birthDate = DateTime.parse(dob.toString());
      } catch (e) {
        return "N/A";
      }
    }

    final now = DateTime.now();
    final difference = now.difference(birthDate);

    int days = difference.inDays;

    if (days < 7) return "$days days";
    if (days < 30) return "${(days / 7).floor()} weeks";
    if (days < 365) return "${(days / 30).floor()} months";
    return "${(days / 365).floor()} years";
  }

  @override
  Widget build(BuildContext context) {
    double progress = total == 0 ? 0 : completed / total;

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
            width: double.infinity,
            color: Colors.blue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Child Details",
                    style: TextStyle(color: Colors.white, fontSize: 24)),
                Text("Name: ${widget.data['name'] ?? ''}",
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Age: ${calculateAge(widget.data['dob'])}"),
                Text("DOB: ${widget.data['dob'] ?? 'Not set'}"),
                Text("District: ${widget.data['district'] ?? 'Not set'}"),
                Text("Mother CNIC: ${widget.data['motherCNIC'] ?? 'Not set'}"),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Vaccination Progress"),
                    Text("$completed/$total"),
                  ],
                ),

                LinearProgressIndicator(value: progress),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.orange.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Next Vaccine"),
                      Text(nextVaccine?['vaccineType'] ?? "None"),
                      Text(nextVaccine?['date'] ?? "Not scheduled"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reminder_page.dart';
import 'notification_page.dart';
import 'child_detail_page.dart'; // ✅ ADD THIS

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

  String calculateAge(dynamic dob) {
    if (dob == null) return "N/A";

    DateTime birthDate;

    if (dob is Timestamp) {
      birthDate = dob.toDate();
    } else {
      try {
        birthDate = DateTime.parse(dob.toString());
      } catch (e) {
        return "N/A";
      }
    }

    final now = DateTime.now();
    final difference = now.difference(birthDate);
    int days = difference.inDays;

    if (days < 0) return "N/A";

    if (days < 7) return "$days days";
    if (days < 30) return "${(days / 7).floor()} weeks";
    if (days < 365) return "${(days / 30).floor()} months";
    return "${(days / 365).floor()} years";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Parent Portal", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF004AAD),
      ),
      body: IndexedStack(
        index: currentIndex,
        children: [
          searchChildPage(),
           ReminderPage(motherCNIC: searchCNIC),
           NotificationPage(),
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
                backgroundColor: const Color(0xFF004AAD),
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

                          String name = data['name'] ?? "No Name";
                          String district = data['district'] ?? "N/A";
                          String motherCNIC = data['motherCNIC'] ?? "N/A";

                          String age = calculateAge(data['dob']);

                          String dob = "N/A";
                          if (data['dob'] != null) {
                            if (data['dob'] is Timestamp) {
                              dob = (data['dob'] as Timestamp)
                                  .toDate()
                                  .toString()
                                  .split(' ')[0];
                            } else {
                              dob = data['dob'].toString();
                            }
                          }

                          return Card(
                            child: ListTile(
                              title: Text(name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Age: $age"),
                                  Text("DOB: $dob"),
                                  Text("District: $district"),
                                  Text("Mother CNIC: $motherCNIC"),
                                ],
                              ),
                              trailing: ElevatedButton(
                                child: const Text("View"),
                                onPressed: () {
                                  // ✅ FIXED NAVIGATION
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
}*/
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ InputFormatter ke liye zaroori hai
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reminder_page.dart';
import 'notification_page.dart';
import 'child_detail_page.dart';

class ParentScreen extends StatefulWidget {
  const ParentScreen({super.key});

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  int currentIndex = 0;
  final TextEditingController cnicController = TextEditingController();
  String searchCNIC = "";

  // CNIC format validation check
  void search() {
    String input = cnicController.text.trim();
    if (input.length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter complete 13-digit CNIC")),
      );
      return;
    }
    setState(() {
      searchCNIC = input;
    });
  }

  String calculateAge(dynamic dob) {
    if (dob == null) return "N/A";
    DateTime birthDate;
    if (dob is Timestamp) {
      birthDate = dob.toDate();
    } else {
      try {
        birthDate = DateTime.parse(dob.toString());
      } catch (e) {
        return "N/A";
      }
    }
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    int days = difference.inDays;
    if (days < 0) return "N/A";
    if (days < 7) return "$days days";
    if (days < 30) return "${(days / 7).floor()} weeks";
    if (days < 365) return "${(days / 30).floor()} months";
    return "${(days / 365).floor()} years";
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF004AAD);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Parent Portal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
      ),
      body: IndexedStack(
        index: currentIndex,
        children: [
          searchChildPage(),
          ReminderPage(motherCNIC: searchCNIC),
          const NotificationPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: primaryBlue,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Track Vaccination Status",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 15),
          
          // --- FORMATTED CNIC TEXTFIELD ---
          TextField(
            controller: cnicController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CnicInputFormatter(), // Custom Formatter niche define kiya hai
            ],
            decoration: InputDecoration(
              hintText: "12345-1234567-1",
              labelText: "Mother CNIC",
              prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF004AAD)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: search,
              icon: const Icon(Icons.search, color: Colors.white),
              label: const Text("SEARCH CHILD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004AAD),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 25),

          Expanded(
            child: searchCNIC.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.child_care, size: 80, color: Colors.black12),
                        Text("Search your child using Mother's CNIC", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('children')
                        .where('motherCNIC', isEqualTo: searchCNIC)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) return const Center(child: Text("No records found for this CNIC."));

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          String name = data['name'] ?? "No Name";
                          String age = calculateAge(data['dob']);
                          
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF004AAD).withOpacity(0.1),
                                child: const Icon(Icons.person, color: Color(0xFF004AAD)),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                              subtitle: Text("Age: $age\nMother CNIC: ${data['motherCNIC']}"),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004AAD)),
                                child: const Text("View Detail", style: TextStyle(color: Colors.white)),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => ChildDetailPage(data: data)),
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

// 🔥 CUSTOM CNIC FORMATTER CLASS
class CnicInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;

    if (newValue.selection.baseOffset == 0) return newValue;

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonDashIndex = i + 1;
      if (nonDashIndex == 5 || nonDashIndex == 12) {
        if (i != text.length - 1) {
          buffer.write('-');
        }
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}