import 'package:flutter/material.dart';

class ParentPortal extends StatefulWidget {
  const ParentPortal({super.key});

  @override
  State<ParentPortal> createState() => _ParentPortalState();
}

class _ParentPortalState extends State<ParentPortal> {
  int selectedTab = 0; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Column(
        children: [
          // 1. HEADER SECTION
          Container(
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Icon(Icons.notifications_active, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 10),
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

          // 2. SCROLLABLE CONTENT
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  
                  // REMOVED 'const' from these custom widgets to prevent compiler error
                  ChildCard(
                    name: "Ali Hassan",
                    id: "CH001",
                    age: "2 years",
                    progress: 0.85, 
                    progressLabel: "12/14",
                    nextVaccine: "Measles-2",
                    dueDate: "2026-05-10",
                    daysLeft: 19,
                  ),
                  ChildCard(
                    name: "Fatima Hassan",
                    id: "CH002",
                    age: "6 months",
                    progress: 0.6, 
                    progressLabel: "6/10",
                    nextVaccine: "OPV-3",
                    dueDate: "2026-04-28",
                    daysLeft: 7,
                  ),

                  // TAB SECTION
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          _buildTabButton("Reminders", 0),
                          _buildTabButton("Notifications", 1),
                          _buildTabButton("Education", 2),
                        ],
                      ),
                    ),
                  ),

                  // LIST CONTENT
                  if (selectedTab == 0) ...[
                    ReminderTile(
                      name: "Fatima Hassan",
                      vaccine: "OPV-3",
                      date: "2026-04-28",
                      isUrgent: true,
                    ),
                    ReminderTile(
                      name: "Ali Hassan",
                      vaccine: "Measles-2",
                      date: "2026-05-10",
                      isUrgent: false,
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Text("No items found."),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    bool isSelected = selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(title, style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.grey,
            )),
          ),
        ),
      ),
    );
  }
}

// --- SUPPORTING WIDGETS (Constructor marked 'const' for performance) ---

class ChildCard extends StatelessWidget {
  final String name, id, age, progressLabel, nextVaccine, dueDate;
  final double progress;
  final int daysLeft;

  const ChildCard({
    super.key, required this.name, required this.id, required this.age,
    required this.progress, required this.progressLabel,
    required this.nextVaccine, required this.dueDate, required this.daysLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("ID: $id • $age", style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress, color: Colors.black, backgroundColor: Colors.grey[200]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(10)),
              child: Text("Next: $nextVaccine due on $dueDate", style: const TextStyle(color: Colors.brown, fontSize: 12)),
            )
          ],
        ),
      ),
    );
  }
}

class ReminderTile extends StatelessWidget {
  final String name, vaccine, date;
  final bool isUrgent;

  const ReminderTile({super.key, required this.name, required this.vaccine, required this.date, required this.isUrgent});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(isUrgent ? Icons.error : Icons.calendar_today, color: isUrgent ? Colors.red : Colors.blue),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("$vaccine • Due: $date"),
      trailing: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: isUrgent ? Colors.red : Colors.black, borderRadius: BorderRadius.circular(5)),
        child: Text(isUrgent ? "URGENT" : "UPCOMING", style: const TextStyle(color: Colors.white, fontSize: 10)),
      ),
    );
  }
}