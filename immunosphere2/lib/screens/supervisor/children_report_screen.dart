/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Brand Colors
const Color kPrimaryGreen = Color(0xFF005A36);
const Color kLightBgGreen = Color(0xFFF4F8F5);

class ChildrenReportScreen extends StatefulWidget {
  const ChildrenReportScreen({super.key});

  @override
  State<ChildrenReportScreen> createState() => _ChildrenReportScreenState();
}

class _ChildrenReportScreenState extends State<ChildrenReportScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _childrenStream;
  late TabController _tabController;

  // Filter Values
  String selectedCenter = 'BHU Jand';
  String selectedStatus = 'All';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _childrenStream = _db.collection('children').snapshots();
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Children Report',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _childrenStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimaryGreen),
            );
          }

          final docs = snapshot.hasData ? snapshot.data!.docs : [];

          return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
            future: _db.collection('vaccinations').get(),
            builder: (context, vacSnapshot) {
              if (vacSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: kPrimaryGreen),
                );
              }

              final vacDocs =
                  vacSnapshot.hasData ? vacSnapshot.data!.docs : [];

              int totalRegistered = docs.length;
              int fullyVaccinated = 0;
              int pending = 0;
              int missed = 0;
              int refused = 0;

              List<Map<String, dynamic>> childrenList = [];

              for (var doc in docs) {
                final data = doc.data();
                String childId = data['childId']?.toString() ?? doc.id;
                String overallStatus =
                    data['status']?.toString().toLowerCase().trim() ?? '';

                var childVaccines = vacDocs.where((vDoc) {
                  var vData = vDoc.data();
                  return vData['childId']?.toString() == childId ||
                      vData['childId']?.toString() == doc.id;
                }).toList();

                bool isAllVaccinesDone = false;
                bool hasMissedVaccine = false;

                if (childVaccines.isNotEmpty) {
                  bool allDone = childVaccines.every((vDoc) {
                    String vStatus = vDoc
                        .data()['status']
                        ?.toString()
                        .toLowerCase()
                        .trim() ??
                        '';
                    return vStatus == 'vaccinated' || vStatus == 'completed';
                  });
                  if (allDone && childVaccines.length >= 8) {
                    isAllVaccinesDone = true;
                  }

                  hasMissedVaccine = childVaccines.any((vDoc) {
                    String vStatus = vDoc
                        .data()['status']
                        ?.toString()
                        .toLowerCase()
                        .trim() ??
                        '';
                    return vStatus == 'missed';
                  });
                }

                if (overallStatus == 'missed' || hasMissedVaccine) {
                  missed++;
                } else if (overallStatus == 'refused') {
                  refused++;
                } else if (isAllVaccinesDone ||
                    overallStatus == 'fully vaccinated' ||
                    overallStatus == 'completed') {
                  fullyVaccinated++;
                } else {
                  pending++;
                }

                childrenList.add({
                  'docId': doc.id,
                  'name': data['name'] ??
                      data['fullName'] ??
                      data['childName'] ??
                      'Unknown Child',
                  'age': data['age'] ?? data['childAge'] ?? 'Newborn',
                  'area': data['area'] ?? data['address'] ?? 'Jand, Attock',
                  'vaccinator': data['vaccinator'] ?? 'Maryam',
                  'status': data['status'] ?? 'Pending',
                  'dueVaccine': data['dueVaccine'] ?? 'MR',
                  'cnic': data['cnic'] ?? 'N/A',
                  'gender': data['gender'] ?? 'Male',
                  'motherName': data['motherName'] ?? 'N/A',
                  'phone': data['phone'] ?? 'N/A',
                  'raw': data,
                });
              }

              return Column(
                children: [
                  _buildFilterHeader(),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: kPrimaryGreen,
                    indicatorWeight: 3,
                    labelColor: kPrimaryGreen,
                    unselectedLabelColor: Colors.grey.shade600,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(text: "Routine Immunization"),
                      Tab(text: "Polio Campaign History"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRoutineView(
                          totalRegistered: totalRegistered,
                          fullyVaccinated: fullyVaccinated,
                          pending: pending,
                          missed: missed,
                          refused: refused,
                          childrenList: childrenList,
                        ),
                        _buildPolioView(
                          target: totalRegistered,
                          vaccinated: fullyVaccinated,
                          missed: missed,
                          refused: refused,
                          childrenList: childrenList,
                        ),
                      ],
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

  Widget _buildFilterHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFFAFAFA),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: "Health Center",
                  value: selectedCenter,
                  items: ['BHU Jand', 'BHU Attock', 'BHU Rawalpindi'],
                  onChanged: (v) => setState(() => selectedCenter = v!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdown(
                  label: "Status",
                  value: selectedStatus,
                  items: ['All', 'Vaccinated', 'Pending', 'Missed', 'Refused'],
                  onChanged: (v) => setState(() => selectedStatus = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: "Search Child (Name / ID / CNIC)",
                      hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(80, 38),
                  side: const BorderSide(color: kPrimaryGreen),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {},
                icon: const Icon(Icons.filter_list, size: 16, color: kPrimaryGreen),
                label: const Text("Filter", style: TextStyle(color: kPrimaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 2),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoutineView({
    required int totalRegistered,
    required int fullyVaccinated,
    required int pending,
    required int missed,
    required int refused,
    required List<Map<String, dynamic>> childrenList,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Children Summary", style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSummaryCard("Registered\nChildren", "$totalRegistered", null, Colors.black),
                _buildSummaryCard("Fully Vaccinated", "$fullyVaccinated", null, Colors.green),
                _buildSummaryCard("Pending", "$pending", null, Colors.orange),
                _buildSummaryCard("Missed", "$missed", null, Colors.red),
                _buildSummaryCard("Refused", "$refused", null, Colors.red.shade900),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text("Children List", style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          _buildChildrenListView(childrenList, isPolio: false),
        ],
      ),
    );
  }

  Widget _buildPolioView({
    required int target,
    required int vaccinated,
    required int missed,
    required int refused,
    required List<Map<String, dynamic>> childrenList,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Campaign Summary", style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildSummaryCard("Target", "$target", null, kPrimaryGreen)),
              Expanded(child: _buildSummaryCard("Vaccinated", "$vaccinated", null, Colors.green)),
              Expanded(child: _buildSummaryCard("Missed", "$missed", null, Colors.orange)),
              Expanded(child: _buildSummaryCard("Refused", "$refused", null, Colors.red)),
            ],
          ),
          const SizedBox(height: 16),
          const Text("Children Campaign History", style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          _buildChildrenListView(childrenList, isPolio: true),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, String? pct, Color color) {
    return Container(
      width: 85,
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Colors.grey, height: 1.1)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // Scrollable Table view to completely eliminate Red Line overflow
  Widget _buildChildrenListView(List<Map<String, dynamic>> list, {required bool isPolio}) {
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: Text("No records found", style: TextStyle(color: Colors.grey))),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBF9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DataTable(
          headingRowHeight: 36,
          dataRowHeight: 48,
          horizontalMargin: 12,
          columnSpacing: 18,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFEFF5F1)),
          columns: [
            const DataColumn(label: Text("Child Name", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
            const DataColumn(label: Text("Age", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
            const DataColumn(label: Text("Address / Area", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
            const DataColumn(label: Text("Vaccinator", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
            const DataColumn(label: Text("Status", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
            if (!isPolio) const DataColumn(label: Text("Due Vaccine", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
          ],
          rows: list.map((child) {
            String statusText = child['status'].toString();
            Color statusColor = Colors.orange;
            IconData statusIcon = Icons.hourglass_top;

            if (statusText.toLowerCase().contains('vaccin')) {
              statusColor = Colors.green;
              statusIcon = Icons.check_circle_outline;
            } else if (statusText.toLowerCase().contains('refus')) {
              statusColor = Colors.red;
              statusIcon = Icons.cancel_outlined;
            } else if (statusText.toLowerCase().contains('miss')) {
              statusColor = Colors.orange;
              statusIcon = Icons.error_outline;
            }

            return DataRow(
              cells: [
                DataCell(
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChildDetailScreen(childData: child),
                        ),
                      );
                    },
                    child: Text(
                      child['name'],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryGreen,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(child['age'], style: const TextStyle(fontSize: 11))),
                DataCell(Text(child['area'], style: const TextStyle(fontSize: 11))),
                DataCell(Text(child['vaccinator'], style: const TextStyle(fontSize: 11))),
                DataCell(
                  Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ],
                  ),
                ),
                if (!isPolio) DataCell(Text(child['dueVaccine'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// DYNAMIC CHILD DETAIL SCREEN
// -----------------------------------------------------------------------------
class ChildDetailScreen extends StatefulWidget {
  final Map<String, dynamic> childData;

  const ChildDetailScreen({super.key, required this.childData});

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _detailTabController;

  @override
  void initState() {
    super.initState();
    _detailTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _detailTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.childData;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Child Profile Details', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Profile Header Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F8F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: kPrimaryGreen.withOpacity(0.15),
                    child: const Icon(Icons.person, size: 34, color: kPrimaryGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(data['name'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: kPrimaryGreen,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(data['docId'] ?? 'ID', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text("Age: ${data['age']} | Gender: ${data['gender']}", style: const TextStyle(fontSize: 11, color: Colors.black87)),
                        Text("Address: ${data['area']}", style: const TextStyle(fontSize: 11, color: Colors.black87)),
                        Text("CNIC/B-Form: ${data['cnic']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        Text("Mother: ${data['motherName']} | Phone: ${data['phone']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Navigation Tabs
            TabBar(
              controller: _detailTabController,
              indicatorColor: kPrimaryGreen,
              labelColor: kPrimaryGreen,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: "Routine Immunization"),
                Tab(text: "Polio History"),
              ],
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 380,
              child: TabBarView(
                controller: _detailTabController,
                children: [
                  _buildRoutineDetailTable(data),
                  _buildPolioDetailTable(data),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineDetailTable(Map<String, dynamic> data) {
    List<Map<String, dynamic>> routineList = [
      {'vaccine': 'BCG', 'status': 'Given', 'date': 'Completed'},
      {'vaccine': 'OPV-0', 'status': 'Given', 'date': 'Completed'},
      {'vaccine': 'Pentavalent-1', 'status': 'Given', 'date': 'Completed'},
      {'vaccine': 'Pentavalent-2', 'status': data['status'], 'date': data['dueVaccine']},
      {'vaccine': 'PCV-1', 'status': 'Given', 'date': 'Completed'},
      {'vaccine': 'IPV', 'status': 'Pending', 'date': 'Upcoming'},
      {'vaccine': 'MR-1', 'status': 'Pending', 'date': 'Upcoming'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xFFEFF5F1),
            child: const Row(
              children: [
                Expanded(child: Text("Vaccine", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
                Expanded(child: Text("Status", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
                Expanded(child: Text("Schedule / Date", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
              ],
            ),
          ),
          ...routineList.map((row) {
            bool isGiven = row['status'].toString().toLowerCase().contains('given') ||
                           row['status'].toString().toLowerCase().contains('vaccin');
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(row['vaccine'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(isGiven ? Icons.check_circle : Icons.hourglass_bottom, size: 12, color: isGiven ? Colors.green : Colors.orange),
                        const SizedBox(width: 4),
                        Text(row['status'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isGiven ? Colors.green : Colors.orange)),
                      ],
                    ),
                  ),
                  Expanded(child: Text(row['date'], style: const TextStyle(fontSize: 11, color: Colors.grey))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPolioDetailTable(Map<String, dynamic> data) {
    List<Map<String, dynamic>> polioHistory = [
      {'campaign': 'National Polio Campaign', 'date': 'Aug 2026', 'status': data['status'], 'givenBy': data['vaccinator']},
      {'campaign': 'Sub National Polio', 'date': 'Apr 2026', 'status': 'Vaccinated', 'givenBy': 'Maryam'},
      {'campaign': 'SNID Campaign', 'date': 'Jan 2026', 'status': 'Vaccinated', 'givenBy': 'Team A'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xFFEFF5F1),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text("Campaign", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
                Expanded(child: Text("Status", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
                Expanded(child: Text("Given By", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
              ],
            ),
          ),
          ...polioHistory.map((row) {
            bool isVaccinated = row['status'].toString().toLowerCase().contains('vaccin');
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row['campaign'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Text(row['date'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(isVaccinated ? Icons.check_circle : Icons.cancel, size: 12, color: isVaccinated ? Colors.green : Colors.red),
                        const SizedBox(width: 2),
                        Text(row['status'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isVaccinated ? Colors.green : Colors.red)),
                      ],
                    ),
                  ),
                  Expanded(child: Text(row['givenBy'], style: const TextStyle(fontSize: 11))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
} */
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Brand Colors
const Color kPrimaryGreen = Color(0xFF005A36);

// Fixed health center for this supervisor account (display only for now -
// not filtering, since existing children documents don't have this field
// set yet. Once you add 'healthCenter' to children docs, add the filter
// back inside _loadReportData()).
const String kFixedHealthCenter = 'DHQ Attock';

// -----------------------------------------------------------------------------
// Shared Firestore helpers
// -----------------------------------------------------------------------------

/// Resolves a set of user uids (vaccinators / whoever administered a dose)
/// into display names, using the 'users' collection - same pattern as
/// CampaignService.getVaccinatorsByIds in the vaccinator module.
Future<Map<String, String>> resolveUserNames(
    FirebaseFirestore db, Set<String> uids) async {
  final Map<String, String> result = {};
  final list = uids.where((id) => id.trim().isNotEmpty).toSet().toList();

  for (var i = 0; i < list.length; i += 10) {
    final end = (i + 10 > list.length) ? list.length : i + 10;
    final chunk = list.sublist(i, end);
    if (chunk.isEmpty) continue;
    final snap = await db
        .collection('users')
        .where(FieldPath.documentId, whereIn: chunk)
        .get();
    for (var doc in snap.docs) {
      final d = doc.data();
      result[doc.id] = (d['fullName'] ?? d['name'] ?? 'Unknown').toString();
    }
  }
  return result;
}

String formatTimestamp(dynamic val) {
  if (val == null) return '';
  if (val is Timestamp) return DateFormat('dd MMM yyyy').format(val.toDate());
  if (val is String) return val;
  return val.toString();
}

// -----------------------------------------------------------------------------
// CHILDREN REPORT SCREEN
// -----------------------------------------------------------------------------
class ChildrenReportScreen extends StatefulWidget {
  const ChildrenReportScreen({super.key});

  @override
  State<ChildrenReportScreen> createState() => _ChildrenReportScreenState();
}

class _ChildrenReportScreenState extends State<ChildrenReportScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late TabController _tabController;
  late Future<_ReportData> _reportFuture;

  String selectedStatus = 'All';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _reportFuture = _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _reportFuture = _loadReportData();
    });
  }

  // Pulls together everything needed for both tabs in one go:
  // children docs, their routine vaccination records, their polio campaign
  // assignment records, the related campaigns, and vaccinator names.
  Future<_ReportData> _loadReportData() async {
    final childrenSnap = await _db.collection('children').get();
    final childDocs = childrenSnap.docs;

    final vaccinationsSnap = await _db.collection('vaccinations').get();
    final assignmentsSnap = await _db.collection('campaign_assignments').get();

    // Group routine vaccination records by childId
    final Map<String, List<Map<String, dynamic>>> routineByChild = {};
    final Set<String> vaccinatorUids = {};
    for (var doc in vaccinationsSnap.docs) {
      final d = doc.data();
      final childId = (d['childId'] ?? '').toString();
      if (childId.isEmpty) continue;
      routineByChild.putIfAbsent(childId, () => []).add(d);
      final by = (d['administeredBy'] ?? '').toString();
      if (by.isNotEmpty) vaccinatorUids.add(by);
    }

    // Group polio campaign assignments by childId, keep ALL (not just latest)
    // since a child can appear in multiple campaigns.
    final Map<String, List<Map<String, dynamic>>> assignmentsByChild = {};
    final Set<String> campaignIds = {};
    for (var doc in assignmentsSnap.docs) {
      final d = Map<String, dynamic>.from(doc.data());
      d['assignmentDocId'] = doc.id;
      final childId = (d['childId'] ?? '').toString();
      if (childId.isEmpty) continue;
      assignmentsByChild.putIfAbsent(childId, () => []).add(d);
      final vId = (d['vaccinatorId'] ?? '').toString();
      if (vId.isNotEmpty) vaccinatorUids.add(vId);
      final cId = (d['campaignId'] ?? '').toString();
      if (cId.isNotEmpty) campaignIds.add(cId);
    }

    // Fetch campaign titles/dates for the campaigns referenced above
    final Map<String, Map<String, dynamic>> campaignsById = {};
    final campaignIdList = campaignIds.toList();
    for (var i = 0; i < campaignIdList.length; i += 10) {
      final end = (i + 10 > campaignIdList.length) ? campaignIdList.length : i + 10;
      final chunk = campaignIdList.sublist(i, end);
      if (chunk.isEmpty) continue;
      final snap = await _db
          .collection('campaigns')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (var doc in snap.docs) {
        campaignsById[doc.id] = doc.data();
      }
    }

    final userNames = await resolveUserNames(_db, vaccinatorUids);

    return _ReportData(
      children: childDocs,
      routineByChild: routineByChild,
      assignmentsByChild: assignmentsByChild,
      campaignsById: campaignsById,
      userNames: userNames,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Children Report',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: FutureBuilder<_ReportData>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryGreen));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;

          // ---------------- Build ROUTINE list + summary ----------------
          int totalRegistered = data.children.length;
          int fullyVaccinated = 0;
          int pending = 0;
          int refused = 0;

          List<Map<String, dynamic>> routineChildren = [];

          for (var doc in data.children) {
            final c = doc.data();
            final childId = doc.id;
            final overallStatus = (c['status'] ?? 'Due Today').toString();

            if (overallStatus.toLowerCase() == 'vaccinated') {
              fullyVaccinated++;
            } else if (overallStatus.toLowerCase() == 'refused') {
              refused++;
            } else {
              pending++;
            }

            // Most recent routine vaccination record for this child, if any
            final records = List<Map<String, dynamic>>.from(data.routineByChild[childId] ?? []);
            records.sort((a, b) {
              final da = a['administeredDate'];
              final dbb = b['administeredDate'];
              if (da is Timestamp && dbb is Timestamp) return dbb.compareTo(da);
              return 0;
            });
            final latest = records.isNotEmpty ? records.first : null;
            final vaccinatorUid = (latest?['administeredBy'] ?? '').toString();
            final vaccinatorName = data.userNames[vaccinatorUid] ??
                (records.isNotEmpty ? 'Unknown' : 'Not vaccinated yet');

            routineChildren.add({
              'docId': childId,
              'name': c['fullName'] ?? c['name'] ?? 'Unknown Child',
              'age': c['age'] ?? 'Newborn',
              'area': c['address'] ?? '',
              'vaccinator': vaccinatorName,
              'status': overallStatus == 'Due Today' ? 'Pending' : overallStatus,
              'dueVaccine': c['nextDue'] ?? '',
              'cnic': c['cnic'] ?? 'N/A',
              'gender': c['gender'] ?? 'N/A',
              'motherName': c['motherName'] ?? 'N/A',
              'phone': c['phoneNumber'] ?? 'N/A',
            });
          }

          // Note: "Missed" isn't tracked anywhere for routine doses in the
          // current Firestore data model (only vaccinated/refused records
          // exist), so it's kept at 0 here rather than guessing.
          const int missedRoutine = 0;

          // ---------------- Build POLIO list + summary (from campaign_assignments) ----------------
          List<Map<String, dynamic>> polioChildren = [];
          int polioTarget = 0;
          int polioVaccinated = 0;
          int polioMissed = 0;
          int polioRefused = 0;

          for (var doc in data.children) {
            final c = doc.data();
            final childId = doc.id;
            final assignments = List<Map<String, dynamic>>.from(data.assignmentsByChild[childId] ?? []);
            if (assignments.isEmpty) continue; // not part of any polio campaign

            // Use the most recent assignment for this child in the list/summary
            assignments.sort((a, b) {
              final da = a['assignedAt'];
              final dbb = b['assignedAt'];
              if (da is Timestamp && dbb is Timestamp) return dbb.compareTo(da);
              return 0;
            });
            final latest = assignments.first;
            final status = (latest['status'] ?? 'Pending').toString();

            polioTarget++;
            if (status == 'Vaccinated') polioVaccinated++;
            if (status == 'Missed') polioMissed++;
            if (status == 'Refused') polioRefused++;

            final vaccinatorUid = (latest['vaccinatorId'] ?? '').toString();
            final vaccinatorName = data.userNames[vaccinatorUid] ?? 'Unknown';

            polioChildren.add({
              'docId': childId,
              'name': c['fullName'] ?? c['name'] ?? 'Unknown Child',
              'age': c['age'] ?? 'Newborn',
              'area': latest['address'] ?? c['address'] ?? '',
              'vaccinator': vaccinatorName,
              'status': status,
            });
          }

          // Apply status filter + search (shared control, applies to whichever tab is active)
          List<Map<String, dynamic>> filterList(List<Map<String, dynamic>> list) {
            return list.where((child) {
              bool matchesStatus = selectedStatus == 'All' ||
                  child['status'].toString().toLowerCase() == selectedStatus.toLowerCase();
              final q = searchController.text.toLowerCase();
              bool matchesSearch = q.isEmpty ||
                  child['name'].toString().toLowerCase().contains(q) ||
                  child['docId'].toString().toLowerCase().contains(q) ||
                  (child['cnic']?.toString().toLowerCase().contains(q) ?? false);
              return matchesStatus && matchesSearch;
            }).toList();
          }

          return Column(
            children: [
              _buildFilterHeader(),
              TabBar(
                controller: _tabController,
                indicatorColor: kPrimaryGreen,
                indicatorWeight: 3,
                labelColor: kPrimaryGreen,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: "Routine Immunization"),
                  Tab(text: "Polio Campaign History"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRoutineView(
                      totalRegistered: totalRegistered,
                      fullyVaccinated: fullyVaccinated,
                      pending: pending,
                      missed: missedRoutine,
                      refused: refused,
                      childrenList: filterList(routineChildren),
                    ),
                    _buildPolioView(
                      target: polioTarget,
                      vaccinated: polioVaccinated,
                      missed: polioMissed,
                      refused: polioRefused,
                      childrenList: filterList(polioChildren),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFFAFAFA),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildFixedHealthCenterBox()),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdown(
                  label: "Status",
                  value: selectedStatus,
                  items: const ['All', 'Vaccinated', 'Pending', 'Missed', 'Refused'],
                  onChanged: (v) => setState(() => selectedStatus = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: "Search Child (Name / ID / CNIC)",
                      hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(80, 38),
                  side: const BorderSide(color: kPrimaryGreen),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 16, color: kPrimaryGreen),
                label: const Text("Refresh", style: TextStyle(color: kPrimaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFixedHealthCenterBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Health Center", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 2),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          alignment: Alignment.centerLeft,
          child: const Text(kFixedHealthCenter,
              style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 2),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoutineView({
    required int totalRegistered,
    required int fullyVaccinated,
    required int pending,
    required int missed,
    required int refused,
    required List<Map<String, dynamic>> childrenList,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Children Summary", style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSummaryCard("Registered\nChildren", "$totalRegistered", Colors.black),
                _buildSummaryCard("Fully Vaccinated", "$fullyVaccinated", Colors.green),
                _buildSummaryCard("Pending", "$pending", Colors.orange),
                _buildSummaryCard("Missed", "$missed", Colors.red),
                _buildSummaryCard("Refused", "$refused", Colors.red.shade900),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text("Children List", style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          _buildChildrenListView(childrenList, isPolio: false),
        ],
      ),
    );
  }

  Widget _buildPolioView({
    required int target,
    required int vaccinated,
    required int missed,
    required int refused,
    required List<Map<String, dynamic>> childrenList,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Campaign Summary", style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildSummaryCard("Target", "$target", kPrimaryGreen)),
              Expanded(child: _buildSummaryCard("Vaccinated", "$vaccinated", Colors.green)),
              Expanded(child: _buildSummaryCard("Missed", "$missed", Colors.orange)),
              Expanded(child: _buildSummaryCard("Refused", "$refused", Colors.red)),
            ],
          ),
          const SizedBox(height: 16),
          const Text("Children Campaign History", style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          _buildChildrenListView(childrenList, isPolio: true),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      width: 85,
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Colors.grey, height: 1.1)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildChildrenListView(List<Map<String, dynamic>> list, {required bool isPolio}) {
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Text(
            isPolio ? "No polio campaign records found" : "No records found",
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBF9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DataTable(
          headingRowHeight: 36,
          dataRowHeight: 48,
          horizontalMargin: 12,
          columnSpacing: 18,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFEFF5F1)),
          columns: [
            const DataColumn(label: Text("Child Name", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
            const DataColumn(label: Text("Age", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
            const DataColumn(label: Text("Address / Area", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
            const DataColumn(label: Text("Vaccinator", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
            const DataColumn(label: Text("Status", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
            if (!isPolio) const DataColumn(label: Text("Due Vaccine", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
          ],
          rows: list.map((child) {
            String statusText = child['status'].toString();
            Color statusColor = Colors.orange;
            IconData statusIcon = Icons.hourglass_top;

            if (statusText.toLowerCase().contains('vaccin')) {
              statusColor = Colors.green;
              statusIcon = Icons.check_circle_outline;
            } else if (statusText.toLowerCase().contains('refus')) {
              statusColor = Colors.red;
              statusIcon = Icons.cancel_outlined;
            } else if (statusText.toLowerCase().contains('miss')) {
              statusColor = Colors.orange;
              statusIcon = Icons.error_outline;
            }

            return DataRow(
              cells: [
                DataCell(
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChildDetailScreen(childData: child)),
                      );
                    },
                    child: Text(
                      child['name'],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryGreen,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(child['age'].toString(), style: const TextStyle(fontSize: 11))),
                DataCell(Text(child['area'].toString(), style: const TextStyle(fontSize: 11))),
                DataCell(Text(child['vaccinator'].toString(), style: const TextStyle(fontSize: 11))),
                DataCell(
                  Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                    ],
                  ),
                ),
                if (!isPolio) DataCell(Text(child['dueVaccine']?.toString() ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// Simple bundle to pass all fetched data from _loadReportData to build()
class _ReportData {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> children;
  final Map<String, List<Map<String, dynamic>>> routineByChild;
  final Map<String, List<Map<String, dynamic>>> assignmentsByChild;
  final Map<String, Map<String, dynamic>> campaignsById;
  final Map<String, String> userNames;

  _ReportData({
    required this.children,
    required this.routineByChild,
    required this.assignmentsByChild,
    required this.campaignsById,
    required this.userNames,
  });
}

// -----------------------------------------------------------------------------
// CHILD DETAIL SCREEN - real per-child routine + polio history
// -----------------------------------------------------------------------------
class ChildDetailScreen extends StatefulWidget {
  final Map<String, dynamic> childData;

  const ChildDetailScreen({super.key, required this.childData});

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _detailTabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _detailTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _detailTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.childData;
    final String childId = data['docId'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Child Profile Details', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F8F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: kPrimaryGreen.withOpacity(0.15),
                    child: const Icon(Icons.person, size: 34, color: kPrimaryGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(data['name'].toString(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: kPrimaryGreen, borderRadius: BorderRadius.circular(4)),
                              child: Text(childId, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text("Age: ${data['age']} | Gender: ${data['gender']}", style: const TextStyle(fontSize: 11, color: Colors.black87)),
                        Text("Address: ${data['area'] ?? ''}", style: const TextStyle(fontSize: 11, color: Colors.black87)),
                        Text("CNIC/B-Form: ${data['cnic']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        Text("Mother: ${data['motherName']} | Phone: ${data['phone']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _detailTabController,
              indicatorColor: kPrimaryGreen,
              labelColor: kPrimaryGreen,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: "Routine Immunization"),
                Tab(text: "Polio History"),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 380,
              child: TabBarView(
                controller: _detailTabController,
                children: [
                  _buildRoutineDetailTable(childId),
                  _buildPolioDetailTable(childId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Real routine doses for this child from 'vaccinations' collection
  Widget _buildRoutineDetailTable(String childId) {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: _db.collection('vaccinations').where('childId', isEqualTo: childId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kPrimaryGreen));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final rows = snapshot.data?.docs ?? [];
        // newest first
        final sorted = List.of(rows)
          ..sort((a, b) {
            final da = a.data()['administeredDate'];
            final dbb = b.data()['administeredDate'];
            if (da is Timestamp && dbb is Timestamp) return dbb.compareTo(da);
            return 0;
          });

        if (sorted.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "No routine immunization records found yet.\nDoses will appear here once the vaccinator logs them.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBF9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                color: const Color(0xFFEFF5F1),
                child: const Row(
                  children: [
                    Expanded(child: Text("Vaccine", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
                    Expanded(child: Text("Status", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
                    Expanded(child: Text("Date", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
                  ],
                ),
              ),
              ...sorted.map((doc) {
                final v = doc.data();
                final vaccine = '${v['vaccineName'] ?? 'N/A'}${v['dose'] != null ? ' (${v['dose']})' : ''}';
                final rawStatus = (v['status'] ?? 'pending').toString();
                final status = rawStatus == 'vaccinated'
                    ? 'Given'
                    : rawStatus == 'refused'
                        ? 'Refused'
                        : rawStatus;
                final date = v['formattedDate']?.toString() ?? formatTimestamp(v['administeredDate']);

                final isGiven = rawStatus == 'vaccinated';
                final isRefused = rawStatus == 'refused';

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                  child: Row(
                    children: [
                      Expanded(child: Text(vaccine, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              isGiven ? Icons.check_circle : (isRefused ? Icons.cancel : Icons.hourglass_bottom),
                              size: 12,
                              color: isGiven ? Colors.green : (isRefused ? Colors.red : Colors.orange),
                            ),
                            const SizedBox(width: 4),
                            Text(status,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isGiven ? Colors.green : (isRefused ? Colors.red : Colors.orange))),
                          ],
                        ),
                      ),
                      Expanded(child: Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey))),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // Real polio campaign history for this child from 'campaign_assignments'
  Widget _buildPolioDetailTable(String childId) {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: _db.collection('campaign_assignments').where('childId', isEqualTo: childId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kPrimaryGreen));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final rows = snapshot.data?.docs ?? [];
        final sorted = List.of(rows)
          ..sort((a, b) {
            final da = a.data()['assignedAt'];
            final dbb = b.data()['assignedAt'];
            if (da is Timestamp && dbb is Timestamp) return dbb.compareTo(da);
            return 0;
          });

        if (sorted.isEmpty) {
          return const Center(
            child: Text("No polio campaign records found for this child", style: TextStyle(color: Colors.grey, fontSize: 12)),
          );
        }

        // Resolve campaign names + vaccinator names for whatever shows up here
        final campaignIds = sorted.map((d) => (d.data()['campaignId'] ?? '').toString()).where((s) => s.isNotEmpty).toSet();
        final vaccinatorIds = sorted.map((d) => (d.data()['vaccinatorId'] ?? '').toString()).where((s) => s.isNotEmpty).toSet();

        return FutureBuilder<List<dynamic>>(
          future: Future.wait([
            _fetchCampaignNames(campaignIds),
            resolveUserNames(_db, vaccinatorIds),
          ]),
          builder: (context, metaSnapshot) {
            if (metaSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: kPrimaryGreen));
            }
            final campaignNames = metaSnapshot.data?[0] as Map<String, String>? ?? {};
            final vaccinatorNames = metaSnapshot.data?[1] as Map<String, String>? ?? {};

            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FBF9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    color: const Color(0xFFEFF5F1),
                    child: const Row(
                      children: [
                        Expanded(flex: 2, child: Text("Campaign", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
                        Expanded(child: Text("Status", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
                        Expanded(child: Text("Given By", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryGreen))),
                      ],
                    ),
                  ),
                  ...sorted.map((doc) {
                    final v = doc.data();
                    final campaignId = (v['campaignId'] ?? '').toString();
                    final campaign = campaignNames[campaignId] ?? 'Polio Campaign';
                    final date = formatTimestamp(v['assignedAt']);
                    final status = (v['status'] ?? 'Pending').toString();
                    final givenBy = vaccinatorNames[(v['vaccinatorId'] ?? '').toString()] ?? 'N/A';

                    final isVaccinated = status == 'Vaccinated';
                    final isRefused = status == 'Refused';

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(campaign, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                Text(date, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  isVaccinated ? Icons.check_circle : (isRefused ? Icons.cancel : Icons.error_outline),
                                  size: 12,
                                  color: isVaccinated ? Colors.green : (isRefused ? Colors.red : Colors.orange),
                                ),
                                const SizedBox(width: 2),
                                Text(status,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isVaccinated ? Colors.green : (isRefused ? Colors.red : Colors.orange))),
                              ],
                            ),
                          ),
                          Expanded(child: Text(givenBy, style: const TextStyle(fontSize: 11))),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, String>> _fetchCampaignNames(Set<String> campaignIds) async {
    final Map<String, String> result = {};
    final list = campaignIds.toList();
    for (var i = 0; i < list.length; i += 10) {
      final end = (i + 10 > list.length) ? list.length : i + 10;
      final chunk = list.sublist(i, end);
      if (chunk.isEmpty) continue;
      final snap = await _db.collection('campaigns').where(FieldPath.documentId, whereIn: chunk).get();
      for (var doc in snap.docs) {
        final d = doc.data();
        result[doc.id] = (d['title'] ?? d['campaignName'] ?? d['name'] ?? 'Polio Campaign').toString();
      }
    }
    return result;
  }
}