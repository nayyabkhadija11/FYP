import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    home: VaccinatorDashboard(),
    debugShowCheckedModeBanner: false,
  ));
}

// --- 1. VACCINATOR DASHBOARD ---

class VaccinatorDashboard extends StatefulWidget {
  const VaccinatorDashboard({super.key});

  @override
  State<VaccinatorDashboard> createState() => _VaccinatorDashboardState();
}

class _VaccinatorDashboardState extends State<VaccinatorDashboard> {
  int activeTab = 0; 
  
  final List<Map<String, dynamic>> activities = [
    {"name": "Ali Hassan", "status": "completed", "age": "2 years", "vaccine": "OPV-3", "id": "CH001", "time": "10:45 AM"},
    {"name": "Fatima Khan", "status": "completed", "age": "6 months", "vaccine": "Pentavalent-1", "id": "CH002", "time": "10:30 AM"},
    {"name": "Ahmed Raza", "status": "refused", "age": "1 year", "vaccine": "Measles-1", "id": "CH003", "time": "10:15 AM"},
  ];

  final List<Map<String, dynamic>> pending = [
    {"name": "Zainab Ali", "status": "pending", "age": "3 months", "vaccine": "OPV-2", "id": "CH004", "time": "Waiting"},
    {"name": "Usman Sheikh", "status": "pending", "age": "5 months", "vaccine": "PCV-1", "id": "CH005", "time": "Waiting"},
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> currentList = activeTab == 0 ? activities : pending;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildStatCard("127", "Vaccinated", Colors.green, Icons.check_circle_outline),
                      _buildStatCard("8", "Refused", Colors.red, Icons.cancel_outlined),
                      _buildStatCard("15", "Absent", Colors.orange, Icons.people_outline),
                      _buildStatCard("200", "Target", Colors.blue, Icons.assignment_outlined),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildActionButton("Record Vaccination", const Color(0xFF1D4ED8), Icons.qr_code_scanner, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const VaccinationEntryScreen()));
                      }),
                      const SizedBox(width: 12),
                      _buildActionButton("Register Child", const Color(0xFF059669), Icons.add, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ChildRegistrationScreen()));
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTabToggle(),
                  const SizedBox(height: 16),
                  _buildSearchField(),
                  const SizedBox(height: 16),
                  ...currentList.map((item) => _buildActivityCard(item)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _tabItem("Recent Activity", 0),
          _tabItem("Pending (${pending.length})", 1),
        ],
      ),
    );
  }

  Widget _tabItem(String title, int index) {
    bool isActive = activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
          ),
          child: Center(child: Text(title, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? Colors.black : Colors.grey))),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 30),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF059669)])),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.menu, color: Colors.white),
              _buildOnlineStatus(),
            ],
          ),
          const SizedBox(height: 10),
          const Text("Vaccinator Dashboard", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const Row(children: [Icon(Icons.location_on, color: Colors.white70, size: 16), Text(" Lahore, Punjab", style: TextStyle(color: Colors.white70))]),
        ],
      ),
    );
  }

  Widget _buildOnlineStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: const Row(children: [Icon(Icons.wifi, color: Colors.white, size: 16), SizedBox(width: 4), Text("Online", style: TextStyle(color: Colors.white, fontSize: 12))]),
    );
  }

  Widget _buildStatCard(String val, String lab, Color col, IconData ic) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(val, style: TextStyle(fontWeight: FontWeight.bold, color: col, fontSize: 16)), Icon(ic, color: col, size: 18)]),
          Text(lab, style: const TextStyle(fontSize: 10, color: Colors.grey))
        ]),
      ),
    );
  }

  Widget _buildActionButton(String title, Color col, IconData ic, VoidCallback tap) {
    return Expanded(
      child: InkWell(
        onTap: tap,
        child: Container(
          height: 80,
          decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(12)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(ic, color: Colors.white), const SizedBox(height: 4), Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11))]),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: "Search children...", prefixIcon: const Icon(Icons.search),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withOpacity(0.05))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text("${data['age']} • ${data['vaccine']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text("ID: ${data['id']} • ${data['time']}", style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ]),
          _buildStatusBadge(data['status']),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color col = status == 'completed' ? Colors.black : (status == 'pending' ? Colors.orange : Colors.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}

// --- 2. VACCINATION ENTRY SCREEN (FROM IMAGES) ---

class VaccinationEntryScreen extends StatefulWidget {
  const VaccinationEntryScreen({super.key});

  @override
  State<VaccinationEntryScreen> createState() => _VaccinationEntryScreenState();
}

class _VaccinationEntryScreenState extends State<VaccinationEntryScreen> {
  String? selectedVaccine;
  String? selectedDose;
  String? selectedStatus;
  final notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildChildSummaryCard(),
                  const SizedBox(height: 16),
                  _buildLocationCard(),
                  const SizedBox(height: 16),
                  _buildVaccinationDetailsForm(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 10, bottom: 20),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF059669)])),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Vaccination Entry", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text("Record vaccination for child", style: TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _buildChildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: const Border(left: BorderSide(color: Color(0xFF2563EB), width: 4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Ali Hassan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text("ID: CH008 • Age: 2 years", style: TextStyle(color: Colors.grey, fontSize: 13)),
          ]),
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)), child: const Text("CH008", style: TextStyle(fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 16),
        const Text("Mother CNIC", style: TextStyle(color: Colors.grey, fontSize: 12)),
        const Text("35202-1234567-8", style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        const Text("Last Vaccination", style: TextStyle(color: Colors.grey, fontSize: 12)),
        const Text("OPV-2 on 2026-02-15", style: TextStyle(fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Current Location", style: TextStyle(fontWeight: FontWeight.bold)),
        const Text("GPS coordinates captured automatically", style: TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [
            Icon(Icons.location_on, color: Color(0xFF2563EB), size: 20),
            SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Street 5, Block C, Lahore", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              Text("Lat: 31.5204, Lng: 74.3587", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ]),
          ]),
        )
      ]),
    );
  }

  Widget _buildVaccinationDetailsForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Vaccination Details", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _formLabel("Vaccine Type *"), _buildDropdown("Select vaccine", ["OPV", "IPV", "Pentavalent"], selectedVaccine, (v) => setState(() => selectedVaccine = v)),
        _formLabel("Dose Number *"), _buildDropdown("Select dose", ["Dose 1", "Dose 2", "Booster"], selectedDose, (v) => setState(() => selectedDose = v)),
        _formLabel("Status *"), _buildDropdown("Select status", ["Administered", "Refused"], selectedStatus, (v) => setState(() => selectedStatus = v)),
        _formLabel("Notes (Optional)"),
        TextField(controller: notesController, maxLines: 2, decoration: InputDecoration(hintText: "Add notes...", filled: true, fillColor: const Color(0xFFF9FAFB), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
        const SizedBox(height: 20),
        OutlinedButton.icon(style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)), onPressed: () {}, icon: const Icon(Icons.camera_alt), label: const Text("Upload Vaccination Card Photo")),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel"))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007BFF)), onPressed: () => Navigator.pop(context), child: const Text("Submit Record", style: TextStyle(color: Colors.white)))),
        ]),
      ]),
    );
  }

  Widget _formLabel(String l) => Padding(padding: const EdgeInsets.only(top: 12, bottom: 4), child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)));
  
  Widget _buildDropdown(String hint, List<String> items, String? val, Function(String?) onChange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, value: val, hint: Text(hint), items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChange)),
    );
  }
}

// --- 3. CHILD REGISTRATION SCREEN ---

class ChildRegistrationScreen extends StatefulWidget {
  const ChildRegistrationScreen({super.key});

  @override
  State<ChildRegistrationScreen> createState() => _ChildRegistrationScreenState();
}

class _ChildRegistrationScreenState extends State<ChildRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  String? gender;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Child Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Row(children: [
              _mediaBtn("Upload Photo", Icons.camera_alt),
              const SizedBox(width: 12),
              _mediaBtn("Generate QR", Icons.qr_code_2),
            ]),
            _input("Child Name *"), _input("Date of Birth *", icon: Icons.calendar_today),
            const SizedBox(height: 12),
            const Text("Parent Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            _input("Mother Name *"), _input("Father Name *"), _input("Mother CNIC *"), _input("Contact Number *"),
            const SizedBox(height: 30),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel"))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)), onPressed: () => Navigator.pop(context), child: const Text("Register Child", style: TextStyle(color: Colors.white)))),
            ]),
          ]))))),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(padding: const EdgeInsets.only(top: 50, left: 10, bottom: 20), decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF059669)])), child: Row(children: [IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)), const Text("New Registration", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]));
  }

  Widget _mediaBtn(String l, IconData i) => Expanded(child: Container(height: 60, decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(12)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, color: Colors.grey), Text(l, style: const TextStyle(fontSize: 10))])));

  Widget _input(String l, {IconData? icon}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(top: 12, bottom: 4), child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
    TextFormField(decoration: InputDecoration(suffixIcon: icon != null ? Icon(icon, size: 18) : null, filled: true, fillColor: const Color(0xFFF9FAFB), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
  ]);
}