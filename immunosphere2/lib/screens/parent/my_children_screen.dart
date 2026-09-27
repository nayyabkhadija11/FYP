/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'child_detail_screen.dart';

class MyChildrenScreen extends StatefulWidget {
  final String parentCNIC;

  const MyChildrenScreen({
    Key? key,
    required this.parentCNIC,
  }) : super(key: key);

  @override
  State<MyChildrenScreen> createState() => _MyChildrenScreenState();
}

class _MyChildrenScreenState extends State<MyChildrenScreen> {
  static const Color primaryGreen = Color(0xFF0E9F6E);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Helper to remove dashes from CNIC
  String get _cleanCNIC => widget.parentCNIC.replaceAll('-', '').trim();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'My Children',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // 1. SEARCH BAR
              _buildSearchBar(),
              const SizedBox(height: 16),

              // 2. REAL-TIME FIRESTORE CHILDREN LIST
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('children')
                      .where('cnic', isEqualTo: _cleanCNIC)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: primaryGreen),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Error loading children data.',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    // Client-side search filtering by child name
                    final docs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final String name = (data['childName'] ??
                              data['fullName'] ??
                              data['name'] ??
                              '')
                          .toString()
                          .toLowerCase();

                      return name.contains(_searchQuery);
                    }).toList();

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No matching children found.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final childData =
                            docs[index].data() as Map<String, dynamic>;
                        final String childId = docs[index].id;
                        final String childName = childData['childName'] ??
                            childData['fullName'] ??
                            childData['name'] ??
                            'Child';
                        final dynamic rawDob =
                            childData['dob'] ?? childData['dateOfBirth'];
                        final String ageString = _calculateAge(rawDob);

                        return ChildCard(
                          childId: childId,
                          name: childName,
                          age: ageString,
                          gender: (childData['gender'] ?? 'boy')
                              .toString()
                              .toLowerCase(),
                          firestore: _firestore,
                          primaryGreen: primaryGreen,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value.trim().toLowerCase();
        });
      },
      decoration: InputDecoration(
        hintText: 'Search child by name',
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.child_care, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No children registered yet.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // --- DOB & Age Calculation Helper ---
  String _calculateAge(dynamic rawDob) {
    if (rawDob == null) return 'Age: N/A';

    try {
      DateTime? dob;

      if (rawDob is Timestamp) {
        dob = rawDob.toDate();
      } else if (rawDob is DateTime) {
        dob = rawDob;
      } else if (rawDob is String) {
        if (rawDob.contains('/')) {
          List<String> parts = rawDob.split('/');
          if (parts.length == 3) {
            dob = DateTime.tryParse(
                '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}');
          }
        }
        dob ??= DateTime.tryParse(rawDob);
      }

      if (dob == null) return 'Age: N/A';

      DateTime now = DateTime.now();
      int years = now.year - dob.year;
      int months = now.month - dob.month;

      if (months < 0) {
        years--;
        months += 12;
      }

      if (years > 0) {
        return '$years Year${years > 1 ? 's' : ''}, $months Month${months != 1 ? 's' : ''} old';
      } else {
        return '$months Month${months != 1 ? 's' : ''} old';
      }
    } catch (_) {
      return 'Age: N/A';
    }
  }
}

// Separate Child Card Widget to avoid rebuild overhead & nested Stream Builders state pollution
class ChildCard extends StatelessWidget {
  final String childId;
  final String name;
  final String age;
  final String gender;
  final FirebaseFirestore firestore;
  final Color primaryGreen;

  const ChildCard({
    Key? key,
    required this.childId,
    required this.name,
    required this.age,
    required this.gender,
    required this.firestore,
    required this.primaryGreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('vaccinations')
          .where('childId', isEqualTo: childId)
          .snapshots(),
      builder: (context, recordSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: firestore
              .collection('vaccination_tasks')
              .where('childId', isEqualTo: childId)
              .snapshots(),
          builder: (context, taskSnapshot) {
            int completedCount = 0;
            String nextVaccine = 'All vaccinations up to date!';
            String statusTag = 'Up to date';
            Color statusColor = primaryGreen;
            Color statusBg = const Color(0xFFE5F7ED);

            // Compute completed vaccinations count
            if (recordSnapshot.hasData) {
              completedCount = recordSnapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status =
                    (data['status'] ?? '').toString().toLowerCase().trim();
                final isDoneBool =
                    data['isDone'] == true || data['administered'] == true;
                return status == 'completed' ||
                    status == 'done' ||
                    status == 'administered' ||
                    status == 'given' ||
                    status == 'vaccinated' ||
                    isDoneBool;
              }).length;
            }

            // Compute pending tasks
            if (taskSnapshot.hasData && taskSnapshot.data!.docs.isNotEmpty) {
              final pendingDocs = taskSnapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status =
                    (data['status'] ?? '').toString().toLowerCase().trim();
                return status == 'pending' ||
                    status == 'due' ||
                    status == 'scheduled' ||
                    status == 'duetoday' ||
                    status.isEmpty;
              }).toList();

              if (pendingDocs.isNotEmpty) {
                final nextDoc =
                    pendingDocs.first.data() as Map<String, dynamic>;
                final String vName = nextDoc['vaccineName'] ??
                    nextDoc['vaccines'] ??
                    nextDoc['vaccine'] ??
                    'Vaccine';
                nextVaccine = 'Next: $vName';
                statusTag = 'Due soon';
                statusColor = Colors.red;
                statusBg = const Color(0xFFFEF2F2);
              }
            }

            const int totalTargetVaccines = 12; // Standard EPI Target Doses
            double progress =
                (completedCount / totalTargetVaccines).clamp(0.0, 1.0);
            String progressText = '${(progress * 100).toInt()}%';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChildDetailScreen(
                      childId: childId,
                      childName: name,
                      childAge: age,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFFE5F7ED),
                          child: Text(
                            gender == 'boy' || gender == 'male' ? '👦' : '👧',
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                age,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          progressText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            nextVaccine,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusTag,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
} */
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:immunosphere2/helpers/epi_schedule_helper.dart';
import 'child_detail_screen.dart';

class MyChildrenScreen extends StatefulWidget {
  final String parentCNIC;

  const MyChildrenScreen({
    Key? key,
    required this.parentCNIC,
  }) : super(key: key);

  @override
  State<MyChildrenScreen> createState() => _MyChildrenScreenState();
}

class _MyChildrenScreenState extends State<MyChildrenScreen> {
  static const Color primaryGreen = Color(0xFF0B4D30);
  static const Color accentGreen = Color(0xFF0E7A45);
  static const Color lightBgGreen = Color(0xFFEBF7F0);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String get _cleanCNIC => widget.parentCNIC.replaceAll('-', '').trim();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GREEN HEADER — ab search bar ko overlap nahi kar raha, sirf
          // title aur "+" icon ke liye jagah hai (reference image jaisa).
          Container(
            width: double.infinity,
            color: primaryGreen,
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'My Children',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),

          // SEARCH BAR — ab poori tarah white background ke andar hai,
          // green header ke sath overlap nahi karti. Isi liye focus/tap
          // par border ab bilkul saaf/consistent dikhta hai, koi
          // "half green half white" glitch nahi.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _buildSearchBar(),
          ),

          // CHILDREN LIST
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('children')
                    .where('cnic', isEqualTo: _cleanCNIC)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: CircularProgressIndicator(color: accentGreen),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Error loading children data.',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final String name = (data['childName'] ??
                            data['fullName'] ??
                            data['name'] ??
                            '')
                        .toString()
                        .toLowerCase();

                    return name.contains(_searchQuery);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No matching children found.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final childData =
                          docs[index].data() as Map<String, dynamic>;
                      final String childId = docs[index].id;
                      final String childName = childData['childName'] ??
                          childData['fullName'] ??
                          childData['name'] ??
                          'Child';
                      final dynamic rawDob =
                          childData['dob'] ?? childData['dateOfBirth'];
                      final String ageString = _calculateAge(rawDob);

                      return ChildCard(
                        childId: childId,
                        name: childName,
                        age: ageString,
                        gender: (childData['gender'] ?? 'boy')
                            .toString()
                            .toLowerCase(),
                        rawDob: rawDob,
                        firestore: _firestore,
                        primaryGreen: accentGreen,
                        lightBgGreen: lightBgGreen,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: _searchController,
        cursorColor: accentGreen,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim().toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search child by name',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: accentGreen, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.child_care, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No children registered yet.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateAge(dynamic rawDob) {
    if (rawDob == null) return 'Age: N/A';

    try {
      DateTime? dob;

      if (rawDob is Timestamp) {
        dob = rawDob.toDate();
      } else if (rawDob is DateTime) {
        dob = rawDob;
      } else if (rawDob is String) {
        if (rawDob.contains('/')) {
          List<String> parts = rawDob.split('/');
          if (parts.length == 3) {
            dob = DateTime.tryParse(
                '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}');
          }
        }
        dob ??= DateTime.tryParse(rawDob);
      }

      if (dob == null) return 'Age: N/A';

      DateTime now = DateTime.now();
      int years = now.year - dob.year;
      int months = now.month - dob.month;

      if (months < 0) {
        years--;
        months += 12;
      }

      if (years > 0) {
        return '$years Year${years > 1 ? 's' : ''}, $months Month${months != 1 ? 's' : ''} old';
      } else {
        return '$months Month${months != 1 ? 's' : ''} old';
      }
    } catch (_) {
      return 'Age: N/A';
    }
  }
}

class ChildCard extends StatelessWidget {
  final String childId;
  final String name;
  final String age;
  final String gender;
  final dynamic rawDob;
  final FirebaseFirestore firestore;
  final Color primaryGreen;
  final Color lightBgGreen;

  const ChildCard({
    Key? key,
    required this.childId,
    required this.name,
    required this.age,
    required this.gender,
    required this.rawDob,
    required this.firestore,
    required this.primaryGreen,
    required this.lightBgGreen,
  }) : super(key: key);

  DateTime _parseDob(dynamic dobVal) {
    if (dobVal is Timestamp) return dobVal.toDate();
    if (dobVal is DateTime) return dobVal;
    if (dobVal is String && dobVal.trim().isNotEmpty) {
      return DateTime.tryParse(dobVal) ?? DateTime.now();
    }
    return DateTime.now();
  }

  String _normalize(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('vaccinations')
          .where('childId', isEqualTo: childId)
          .snapshots(),
      builder: (context, recordSnapshot) {
        int completedCount = 0;
        List<Map<String, dynamic>> givenRecords = [];

        if (recordSnapshot.hasData) {
          for (var doc in recordSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? '').toString().toLowerCase().trim();
            final isDoneBool = data['isDone'] == true || data['administered'] == true || data['isGiven'] == true;
            final isCompleted = status == 'completed' ||
                status == 'done' ||
                status == 'administered' ||
                status == 'given' ||
                status == 'vaccinated' ||
                isDoneBool;
            if (isCompleted) completedCount++;

            givenRecords.add({
              'vaccineName': (data['vaccineName'] ?? '').toString(),
            });
          }
        }

        // NEW: real EPI-schedule-based "next due" calculation — same
        // logic used on the Home screen — instead of a generic
        // vaccination_tasks lookup. Gives "Next: <vaccine> — Due in
        // X days" exactly like the reference UI.
        final dob = _parseDob(rawDob);
        final schedule = EpiScheduleHelper.generateEpiSchedule(dob);
        final now = DateTime.now();

        String? nextVaccineName;
        DateTime? nextDueDate;

        for (var stage in schedule) {
          final DateTime dueDate = stage['dueDate'];
          final List<String> vaccines = List<String>.from(stage['vaccines']);

          for (var vaccine in vaccines) {
            final targetNorm = _normalize(vaccine);
            final isGiven = givenRecords.any((r) {
              final storedNorm = _normalize(r['vaccineName']);
              return storedNorm == targetNorm ||
                  storedNorm.contains(targetNorm) ||
                  targetNorm.contains(storedNorm);
            });
            if (isGiven) continue;

            final isMissed = now.isAfter(dueDate.add(const Duration(days: 14)));
            if (isMissed) continue;

            if (nextDueDate == null || dueDate.isBefore(nextDueDate)) {
              nextDueDate = dueDate;
              nextVaccineName = vaccine;
            }
          }
        }

        String nextVaccineLabel = 'All vaccinations up to date!';
        String statusTag = 'Up to date';
        Color statusColor = primaryGreen;
        Color statusBg = lightBgGreen;

        if (nextVaccineName != null && nextDueDate != null) {
          nextVaccineLabel = 'Next: $nextVaccineName';
          final daysUntil = nextDueDate.difference(DateTime(now.year, now.month, now.day)).inDays;

          if (daysUntil < 0) {
            statusTag = 'Overdue';
          } else if (daysUntil == 0) {
            statusTag = 'Due Today';
          } else {
            statusTag = 'Due in $daysUntil day${daysUntil != 1 ? 's' : ''}';
          }
          statusColor = const Color(0xFFEF4444);
          statusBg = const Color(0xFFFEF2F2);
        }

        const int totalTargetVaccines = 12;
        double progress = (completedCount / totalTargetVaccines).clamp(0.0, 1.0);
        String progressText = '${(progress * 100).toInt()}%';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChildDetailScreen(
                  childId: childId,
                  childName: name,
                  childAge: age,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: lightBgGreen,
                      child: Text(
                        gender == 'boy' || gender == 'male' ? '👦' : '👧',
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            age,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      progressText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        nextVaccineLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusTag,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}