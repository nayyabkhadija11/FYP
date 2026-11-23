import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:immunosphere2/helpers/epi_schedule_helper.dart';
import 'vaccination_certificates_screen.dart';

class ParentVaccinationHistoryScreen extends StatefulWidget {
  final String parentCNIC;

  const ParentVaccinationHistoryScreen({
    Key? key,
    required this.parentCNIC,
  }) : super(key: key);

  @override
  State<ParentVaccinationHistoryScreen> createState() =>
      _ParentVaccinationHistoryScreenState();
}

class _ParentVaccinationHistoryScreenState extends State<ParentVaccinationHistoryScreen> {
  static const Color darkGreen = Color(0xFF0B4D30);
  static const Color primaryGreen = Color(0xFF0E7A45);
  static const Color lightGreenBg = Color(0xFFE5F7ED);

  String? _selectedChildId;
  String _selectedChildName = '';

  String get _cleanCNIC => widget.parentCNIC.replaceAll('-', '').trim();

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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: darkGreen,
              child: const Center(
                child: Text(
                  'History',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                "View your child's past vaccination records and download certificates.",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('children')
                    .where('cnic', isEqualTo: _cleanCNIC)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: primaryGreen));
                  }
                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'No children registered yet.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ),
                    );
                  }

                  // Default select the first child once loaded
                  if (_selectedChildId == null ||
                      !docs.any((d) => d.id == _selectedChildId)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      final firstData = docs.first.data() as Map<String, dynamic>;
                      setState(() {
                        _selectedChildId = docs.first.id;
                        _selectedChildName = (firstData['fullName'] ?? firstData['name'] ?? 'Child').toString();
                      });
                    });
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 84,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: docs.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 14),
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final name = (data['fullName'] ?? data['name'] ?? 'Child').toString();
                              final gender = (data['gender'] ?? 'Male').toString();
                              final isSelected = doc.id == _selectedChildId;
                              final isMale = gender.toLowerCase() == 'male' || gender.toLowerCase() == 'boy';

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedChildId = doc.id;
                                    _selectedChildName = name;
                                  });
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? primaryGreen : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: lightGreenBg,
                                        child: Text(isMale ? '👦' : '👧', style: const TextStyle(fontSize: 22)),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? primaryGreen : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_selectedChildId != null)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VaccinationCertificatesScreen(
                                    childId: _selectedChildId!,
                                    childName: _selectedChildName,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: lightGreenBg, borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.description_outlined, color: primaryGreen, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Vaccination Certificates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        SizedBox(height: 2),
                                        Text('Download your child\'s certificates', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),

                        if (_selectedChildId != null) _buildStatusBanner(_selectedChildId!),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(String childId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('children').doc(childId).snapshots(),
      builder: (context, childSnap) {
        if (!childSnap.hasData || !childSnap.data!.exists) return const SizedBox.shrink();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('vaccinations')
              .where('childId', isEqualTo: childId)
              .snapshots(),
          builder: (context, vaccSnap) {
            final childData = childSnap.data!.data() as Map<String, dynamic>;
            final dob = _parseDob(childData['dob'] ?? childData['dateOfBirth']);
            final schedule = EpiScheduleHelper.generateEpiSchedule(dob);
            final now = DateTime.now();

            final givenNames = (vaccSnap.data?.docs ?? []).map((d) {
              final data = d.data() as Map<String, dynamic>;
              return _normalize((data['vaccineName'] ?? '').toString());
            }).toList();

            bool hasOverdue = false;
            for (var stage in schedule) {
              final DateTime dueDate = stage['dueDate'];
              final List<String> vaccines = List<String>.from(stage['vaccines']);
              for (var vaccine in vaccines) {
                final targetNorm = _normalize(vaccine);
                final isGiven = givenNames.any((n) => n == targetNorm || n.contains(targetNorm) || targetNorm.contains(n));
                if (!isGiven && now.isAfter(dueDate)) {
                  hasOverdue = true;
                  break;
                }
              }
              if (hasOverdue) break;
            }

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: hasOverdue ? const Color(0xFFFFF7ED) : lightGreenBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    hasOverdue ? Icons.warning_amber_rounded : Icons.shield_outlined,
                    color: hasOverdue ? Colors.orange.shade800 : darkGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasOverdue
                          ? "$_selectedChildName has a vaccination that is overdue."
                          : "$_selectedChildName's vaccination history is up to date.",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasOverdue ? Colors.orange.shade800 : darkGreen,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}