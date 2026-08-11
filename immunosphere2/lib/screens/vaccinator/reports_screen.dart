import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:immunosphere2/helpers/vaccination_status_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedMonthlyToggle = 0; // 0 for Routine, 1 for Polio
  
  // Selected Month State
  DateTime _selectedMonthDate = DateTime.now();
  
  // View All toggle for Daily Activity
  bool _showAllDailyActivities = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- MONTH PICKER FUNCTION ---
  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonthDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'SELECT REPORT MONTH',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5C33CF),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedMonthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Reports & Analytics',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF5C33CF),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF5C33CF),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "Daily"),
            Tab(text: "Weekly"),
            Tab(text: "Monthly"),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('vaccinations').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF5C33CF)));
          }

          final allDocs = snapshot.data?.docs ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildDailyReportTab(allDocs),
              _buildWeeklyReportTab(allDocs),
              _buildMonthlyReportTab(allDocs),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // 1. DAILY REPORT TAB
  // ==========================================
  Widget _buildDailyReportTab(List<QueryDocumentSnapshot> docs) {
    DateTime today = DateTime.now();
    String todayStr = DateFormat('dd MMM yyyy').format(today);

    final todayDocs = docs.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      dynamic dateVal = data['administeredDate'];
      
      if (dateVal is Timestamp) {
        return DateFormat('dd MMM yyyy').format(dateVal.toDate()) == todayStr;
      } else if (dateVal is String) {
        return dateVal.contains(todayStr);
      }
      return false;
    }).toList();

    int routineCount = 0;
    int polioCount = 0;

    List<Map<String, dynamic>> activities = [];

    for (var doc in todayDocs) {
      var data = doc.data() as Map<String, dynamic>;
      String category = (data['category'] ?? 'Routine').toString();
      if (category == 'Polio') {
        polioCount++;
      } else {
        routineCount++;
      }

      String timeStr = "08:00 AM";
      if (data['administeredDate'] is Timestamp) {
        timeStr = DateFormat('hh:mm a').format((data['administeredDate'] as Timestamp).toDate());
      }

      activities.add({
        'time': timeStr,
        'name': data['childName'] ?? 'Child',
        'vaccine': data['vaccineName'] ?? 'Vaccine',
        'color': category == 'Polio' ? Colors.blue : Colors.green,
      });
    }

    final displayedActivities = _showAllDailyActivities 
        ? activities 
        : activities.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Daily Report", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(todayStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const Icon(Icons.more_vert, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard("Total Vaccinated", (routineCount + polioCount).toString(), const Color(0xFF5C33CF)),
                const SizedBox(width: 8),
                _buildStatCard("Routine", routineCount.toString(), Colors.green),
                const SizedBox(width: 8),
                _buildStatCard("Polio", polioCount.toString(), Colors.blue),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Today's Activity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 12),

            activities.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No vaccinations recorded today.', 
                        style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)
                      ),
                    ),
                  )
                : Column(
                    children: displayedActivities.map((act) => _buildActivityItem(
                      act['time'], act['name'], act['vaccine'], act['color']
                    )).toList(),
                  ),

            if (activities.length > 5) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _showAllDailyActivities = !_showAllDailyActivities;
                    });
                  },
                  child: Text(
                    _showAllDailyActivities ? "Show Less" : "View All (${activities.length})",
                    style: const TextStyle(color: Color(0xFF5C33CF), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 2. WEEKLY REPORT TAB
  // ==========================================
  Widget _buildWeeklyReportTab(List<QueryDocumentSnapshot> docs) {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    String weekRange = "${DateFormat('dd MMM').format(startOfWeek)} - ${DateFormat('dd MMM yyyy').format(endOfWeek)}";

    List<String> weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    Map<String, int> routineByDay = {"Mon": 0, "Tue": 0, "Wed": 0, "Thu": 0, "Fri": 0, "Sat": 0, "Sun": 0};
    Map<String, int> polioByDay = {"Mon": 0, "Tue": 0, "Wed": 0, "Thu": 0, "Fri": 0, "Sat": 0, "Sun": 0};

    int weeklyRoutineTotal = 0;
    int weeklyPolioTotal = 0;

    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      dynamic dateVal = data['administeredDate'];

      if (dateVal is Timestamp) {
        DateTime date = dateVal.toDate();
        if (date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            date.isBefore(endOfWeek.add(const Duration(days: 1)))) {
          
          String dayName = DateFormat('EEE').format(date);
          String category = (data['category'] ?? 'Routine').toString();

          if (category == 'Polio') {
            polioByDay[dayName] = (polioByDay[dayName] ?? 0) + 1;
            weeklyPolioTotal++;
          } else {
            routineByDay[dayName] = (routineByDay[dayName] ?? 0) + 1;
            weeklyRoutineTotal++;
          }
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Weekly Report", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(weekRange, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const Icon(Icons.more_vert, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildLegendItem("Routine", Colors.green),
                const SizedBox(width: 16),
                _buildLegendItem("Polio", const Color(0xFF5C33CF)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: weekDays.map((day) {
                  int routineVal = routineByDay[day] ?? 0;
                  int polioVal = polioByDay[day] ?? 0;
                  return _buildBarGroup(day, routineVal.toDouble(), polioVal.toDouble());
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStatCard("Total Vaccinated", (weeklyRoutineTotal + weeklyPolioTotal).toString(), const Color(0xFF5C33CF)),
                const SizedBox(width: 8),
                _buildStatCard("Routine", weeklyRoutineTotal.toString(), Colors.green),
                const SizedBox(width: 8),
                _buildStatCard("Polio", weeklyPolioTotal.toString(), Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 3. MONTHLY REPORT TAB
  // ==========================================
  // FIXED: Routine ke Missed/Pending/Vaccinated/Refused ab EPI schedule
  // (due-date based) logic se live calculate hote hain — Dashboard aur
  // Child Profile jaisi hi calculation — kyunki 'missed' status kabhi
  // Firestore mein literal field ke tor par likha hi nahi jata.
  // Polio tab bilkul pehle jaisa hi (unchanged) hai.
  Widget _buildMonthlyReportTab(List<QueryDocumentSnapshot> docs) {
    bool isRoutine = _selectedMonthlyToggle == 0;
    String selectedMonthText = DateFormat('MMMM yyyy').format(_selectedMonthDate);

    // FIX: Agar selected month abhi future mein hai (aaj se aage), tou
    // us mahine mein kuch bhi "hua" nahi ho sakta — sab kuch 0 hona
    // chahiye jab tak wo mahine waqai shuru na ho. Pehle code future
    // months ke liye bhi "due" doses ko "Pending" gin raha tha, jo
    // September jaise mahine mein bhi galat non-zero numbers de raha tha.
    final now = DateTime.now();
    final isFutureMonth = _selectedMonthDate.year > now.year ||
        (_selectedMonthDate.year == now.year && _selectedMonthDate.month > now.month);

    if (isRoutine && isFutureMonth) {
      return _buildMonthlyReportBody(
        isRoutine: isRoutine,
        selectedMonthText: selectedMonthText,
        totalVaccinated: 0,
        pendingCount: 0,
        missedCount: 0,
        refusedCount: 0,
        vaccineCounts: {},
      );
    }

    if (isRoutine) {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('children').snapshots(),
        builder: (context, childrenSnapshot) {
          final childDocs = childrenSnapshot.data?.docs ?? [];

          List<Map<String, dynamic>> allVaccinationDocs =
              docs.map((d) => d.data() as Map<String, dynamic>).toList();
          final grouped = VaccinationStatusHelper.groupRecordsByChildId(allVaccinationDocs);

          int totalVaccinated = 0;
          int pendingCount = 0;
          int missedCount = 0;
          int refusedCount = 0;
          Map<String, Map<String, int>> vaccineCounts = {};

          for (var childDoc in childDocs) {
            var cdata = childDoc.data() as Map<String, dynamic>;

            // Skip children whose dob is missing/invalid — otherwise
            // parseDob() would default to "today", wrongly making their
            // At Birth doses always show as Pending in the current month.
            if (!VaccinationStatusHelper.hasValidDob(cdata['dob'])) continue;

            DateTime dob = VaccinationStatusHelper.parseDob(cdata['dob']);

            String docId = childDoc.id;
            String regNo = (cdata['regNo'] ?? '').toString();
            List<Map<String, dynamic>> childRecords = [
              ...(grouped[docId] ?? []),
              if (regNo.isNotEmpty) ...(grouped[regNo] ?? []),
            ];

            final doseList = VaccinationStatusHelper.getDoseStatusForMonth(
              dob,
              childRecords,
              selectedMonthText,
            );

            for (var dose in doseList) {
              String vaccine = dose['vaccineName'];
              String status = dose['status'];

              vaccineCounts.putIfAbsent(vaccine, () => {'vac': 0, 'p': 0, 'm': 0, 'r': 0});

              if (status == 'vaccinated') {
                totalVaccinated++;
                vaccineCounts[vaccine]!['vac'] = (vaccineCounts[vaccine]!['vac'] ?? 0) + 1;
              } else if (status == 'refused') {
                refusedCount++;
                vaccineCounts[vaccine]!['r'] = (vaccineCounts[vaccine]!['r'] ?? 0) + 1;
              } else if (status == 'missed') {
                missedCount++;
                vaccineCounts[vaccine]!['m'] = (vaccineCounts[vaccine]!['m'] ?? 0) + 1;
              } else {
                pendingCount++;
                vaccineCounts[vaccine]!['p'] = (vaccineCounts[vaccine]!['p'] ?? 0) + 1;
              }
            }
          }

          return _buildMonthlyReportBody(
            isRoutine: isRoutine,
            selectedMonthText: selectedMonthText,
            totalVaccinated: totalVaccinated,
            pendingCount: pendingCount,
            missedCount: missedCount,
            refusedCount: refusedCount,
            vaccineCounts: vaccineCounts,
          );
        },
      );
    }

    // POLIO TAB — unchanged original logic
    final monthDocs = docs.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      dynamic dateVal = data['administeredDate'];
      if (dateVal is Timestamp) {
        String formatted = DateFormat('MMMM yyyy').format(dateVal.toDate());
        return formatted == selectedMonthText;
      }
      return false;
    }).toList();

    final categoryDocs = monthDocs.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      String category = (data['category'] ?? 'Routine').toString();
      return category == 'Polio';
    }).toList();

    int totalVaccinated = 0;
    int pendingCount = 0;
    int missedCount = 0;
    int refusedCount = 0;

    Map<String, Map<String, int>> vaccineCounts = {};

    for (var doc in categoryDocs) {
      var data = doc.data() as Map<String, dynamic>;
      String status = (data['status'] ?? 'Vaccinated').toString().toLowerCase();
      String vaccine = data['vaccineName'] ?? 'Vaccine';

      vaccineCounts.putIfAbsent(vaccine, () => {'vac': 0, 'p': 0, 'm': 0, 'r': 0});

      if (status == 'vaccinated' || status == 'completed') {
        totalVaccinated++;
        vaccineCounts[vaccine]!['vac'] = (vaccineCounts[vaccine]!['vac'] ?? 0) + 1;
      } else if (status == 'pending') {
        pendingCount++;
        vaccineCounts[vaccine]!['p'] = (vaccineCounts[vaccine]!['p'] ?? 0) + 1;
      } else if (status == 'missed') {
        missedCount++;
        vaccineCounts[vaccine]!['m'] = (vaccineCounts[vaccine]!['m'] ?? 0) + 1;
      } else if (status == 'refused') {
        refusedCount++;
        vaccineCounts[vaccine]!['r'] = (vaccineCounts[vaccine]!['r'] ?? 0) + 1;
      }
    }

    return _buildMonthlyReportBody(
      isRoutine: isRoutine,
      selectedMonthText: selectedMonthText,
      totalVaccinated: totalVaccinated,
      pendingCount: pendingCount,
      missedCount: missedCount,
      refusedCount: refusedCount,
      vaccineCounts: vaccineCounts,
    );
  }

  // Same UI as before — just extracted so both Routine (new calc) and
  // Polio (old calc) can share the exact same layout/design.
  Widget _buildMonthlyReportBody({
    required bool isRoutine,
    required String selectedMonthText,
    required int totalVaccinated,
    required int pendingCount,
    required int missedCount,
    required int refusedCount,
    required Map<String, Map<String, int>> vaccineCounts,
  }) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // WORKING CALENDAR / MONTH SELECTOR
                InkWell(
                  onTap: () => _selectMonth(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF5C33CF)),
                            const SizedBox(width: 8),
                            Text(selectedMonthText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Routine / Polio Toggle
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMonthlyToggle = 0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isRoutine ? const Color(0xFF5C33CF) : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Routine",
                              style: TextStyle(
                                color: isRoutine ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMonthlyToggle = 1),
                          child: Container(
                            decoration: BoxDecoration(
                              color: !isRoutine ? const Color(0xFF5C33CF) : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Polio",
                              style: TextStyle(
                                color: !isRoutine ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRoutine ? "Routine Vaccination Summary" : "Polio Campaign Summary",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isRoutine ? Colors.green.shade700 : const Color(0xFF5C33CF),
                        ),
                      ),
                      const Divider(height: 20),
                      _buildSummaryRow(isRoutine ? "Total Routine Vaccinations" : "Total Polio Vaccinations", totalVaccinated.toString(), isRoutine ? Colors.green : const Color(0xFF5C33CF)),
                      _buildSummaryRow(isRoutine ? "Pending (Routine)" : "Pending (Polio)", pendingCount.toString(), Colors.orange),
                      _buildSummaryRow(isRoutine ? "Missed (Routine)" : "Missed (Polio)", missedCount.toString(), Colors.red),
                      _buildSummaryRow(isRoutine ? "Refused (Routine)" : "Refused (Polio)", refusedCount.toString(), Colors.red.shade700),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Breakdown Table
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRoutine ? "Vaccine Wise Breakdown (Routine)" : "Polio Campaign Wise Breakdown",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isRoutine ? Colors.green.shade700 : const Color(0xFF5C33CF),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDynamicTable(vaccineCounts),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
              label: Text(
                isRoutine ? "Download Routine Report (PDF)" : "Download Polio Report (PDF)",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C33CF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildDynamicTable(Map<String, Map<String, int>> vaccineData) {
    if (vaccineData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Center(child: Text("No records found for this period.", style: TextStyle(color: Colors.grey, fontSize: 12))),
      );
    }

    return Table(
      columnWidths: const {0: FlexColumnWidth(2.5)},
      children: [
        const TableRow(children: [
          Text("Vaccine", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
          Text("Vaccinated", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
          Text("Pending", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
          Text("Missed", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
          Text("Refused", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
        ]),
        ...vaccineData.entries.map((entry) => TableRow(children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(entry.key, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
          Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text('${entry.value['vac']}', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold))),
          Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text('${entry.value['p']}', style: const TextStyle(fontSize: 11, color: Colors.orange))),
          Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text('${entry.value['m']}', style: const TextStyle(fontSize: 11, color: Colors.red))),
          Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text('${entry.value['r']}', style: const TextStyle(fontSize: 11, color: Colors.red))),
        ])).toList(),
      ],
    );
  }

  Widget _buildSummaryRow(String title, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String time, String name, String vaccine, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Row(
            children: [
              CircleAvatar(radius: 3, backgroundColor: color),
              const SizedBox(width: 6),
              Text(vaccine, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildBarGroup(String day, double routineCount, double polioCount) {
    double routineHeight = (routineCount * 8).clamp(4.0, 100.0);
    double polioHeight = (polioCount * 8).clamp(4.0, 100.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 8,
              height: routineCount == 0 ? 4 : routineHeight,
              decoration: BoxDecoration(
                color: routineCount == 0 ? Colors.grey.shade300 : Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 3),
            Container(
              width: 8,
              height: polioCount == 0 ? 4 : polioHeight,
              decoration: BoxDecoration(
                color: polioCount == 0 ? Colors.grey.shade300 : const Color(0xFF5C33CF),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
      ],
    );
  }
} 