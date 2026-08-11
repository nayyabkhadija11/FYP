import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VaccinationScheduleScreen extends StatefulWidget {
  final String? childId;
  final String childName;
  final String? parentCNIC;

  const VaccinationScheduleScreen({
    Key? key,
    this.childId,
    this.childName = 'Ali Ahmad',
    this.parentCNIC,
  }) : super(key: key);

  @override
  State<VaccinationScheduleScreen> createState() =>
      _VaccinationScheduleScreenState();
}

class _VaccinationScheduleScreenState extends State<VaccinationScheduleScreen> {
  int _selectedTabIndex = 0; // 0: Upcoming, 1: Completed
  static const Color primaryGreen = Color(0xFF0E9F6E);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'Vaccination Schedule',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              widget.childName,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // TOGGLE SWITCH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTabButton(title: 'Upcoming', tabIndex: 0),
                    _buildTabButton(title: 'Completed', tabIndex: 1),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // DYNAMIC TIMELINE LIST FROM FIRESTORE
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getScheduleStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Error loading schedule. Please try again.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryGreen),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final status = (d['status'] ?? '').toString().toLowerCase();

                    if (_selectedTabIndex == 0) {
                      return status == 'pending' ||
                          status == 'upcoming' ||
                          status == '';
                    } else {
                      return status == 'completed' ||
                          status == 'administered' ||
                          status == 'done';
                    }
                  }).toList();

                  if (docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;

                      final isFirst = index == 0;
                      final isLast = index == docs.length - 1;

                      final vaccineName = data['vaccineName'] ??
                          data['name'] ??
                          data['vaccine'] ??
                          'Vaccine';

                      String subtitleText;
                      String badgeText;
                      Color badgeColor;
                      Color badgeBg;

                      if (_selectedTabIndex == 0) {
                        final dueDate = _formatDate(
                            data['dueDate'] ?? data['scheduledDate']);
                        subtitleText = 'Due on $dueDate';

                        final isUrgent = data['isUrgent'] ?? false;
                        if (isUrgent) {
                          badgeText = data['urgentLabel'] ?? 'Due Soon';
                          badgeColor = Colors.red;
                          badgeBg = const Color(0xFFFEF2F2);
                        } else {
                          badgeText = 'Upcoming';
                          badgeColor = Colors.blue;
                          badgeBg = const Color(0xFFE0F2FE);
                        }
                      } else {
                        final ageGroup = data['ageGroup'] ?? '';
                        final givenDate = _formatDate(
                            data['administeredDate'] ?? data['givenDate']);
                        subtitleText = ageGroup.isNotEmpty
                            ? '$ageGroup • Given on $givenDate'
                            : 'Given on $givenDate';
                        badgeText = 'Completed';
                        badgeColor = primaryGreen;
                        badgeBg = const Color(0xFFE5F7ED);
                      }

                      return _buildTimelineTile(
                        title: vaccineName,
                        subtitle: subtitleText,
                        badgeText: badgeText,
                        badgeColor: badgeColor,
                        badgeBg: badgeBg,
                        isFirst: isFirst,
                        isLast: isLast,
                      );
                    },
                  );
                },
              ),
            ),

            // FOOTER BANNER
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F7ED),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.shield_outlined, color: primaryGreen, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Keep your child's vaccinations up to date for a healthy future.",
                      style: TextStyle(
                        fontSize: 11,
                        color: primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({required String title, required int tabIndex}) {
    final isSelected = _selectedTabIndex == tabIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = tabIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedTabIndex == 0
                ? Icons.event_available
                : Icons.verified,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            _selectedTabIndex == 0
                ? 'No upcoming vaccinations found.'
                : 'No completed vaccinations recorded yet.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getScheduleStream() {
    Query query = _firestore.collection('vaccine_records');

    if (widget.childId != null && widget.childId!.isNotEmpty) {
      query = query.where('childId', isEqualTo: widget.childId);
    } else if (widget.parentCNIC != null && widget.parentCNIC!.isNotEmpty) {
      query = query.where('parentCNIC', isEqualTo: widget.parentCNIC);
    } else {
      query = query.where('childName', isEqualTo: widget.childName);
    }

    return query.snapshots();
  }

  static String _formatDate(dynamic rawDate) {
    if (rawDate == null) return 'Soon';
    DateTime dt;
    if (rawDate is Timestamp) {
      dt = rawDate.toDate();
    } else if (rawDate is DateTime) {
      dt = rawDate;
    } else {
      return rawDate.toString();
    }

    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return "$day-$month-${dt.year}";
  }

  Widget _buildTimelineTile({
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Line & Bullet Column
          SizedBox(
            width: 24,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast || !isFirst)
                  Positioned(
                    top: isFirst ? 14 : 0,
                    bottom: isLast ? 14 : 0,
                    child: Container(
                      width: 2,
                      color: Colors.grey.shade300,
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Main Details Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}