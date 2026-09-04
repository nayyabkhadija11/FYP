/*import 'package:flutter/material.dart';

// ==========================================
// 1. CREATE CAMPAIGN SCREEN (Wizard Form)
// ==========================================
class CreateCampaignScreen extends StatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  State<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends State<CreateCampaignScreen> {
  static const Color primaryGreen = Color(0xFF006837);
  int _currentStep = 1;

  final _nameController = TextEditingController(text: "National Polio Campaign");
  String _campaignType = "Polio";
  String _selectedArea = "Mohallah A, Jand";
  String _teamName = "Team A";

  final List<String> _selectedVaccinators = ["Ahmed Khan", "Fatima Noor", "Usman Tahir"];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Create Campaign",
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                int stepNum = index + 1;
                bool isActive = _currentStep >= stepNum;
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: isActive ? primaryGreen : Colors.grey.shade300,
                      child: Text(
                        "$stepNum",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    if (stepNum < 5)
                      Container(
                        width: 24,
                        height: 2,
                        color: _currentStep > stepNum ? primaryGreen : Colors.grey.shade300,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                  ],
                );
              }),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildStepContent(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _onContinuePressed,
                    child: Text(
                      _currentStep == 5 ? "Confirm & Create Campaign" : "Continue",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                if (_currentStep == 5) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => setState(() => _currentStep = 1),
                    child: const Text("Edit Details", style: TextStyle(color: Colors.black87)),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _step1Info();
      case 2:
        return _step2TargetArea();
      case 3:
        return _step3ChildrenInArea();
      case 4:
        return _step4AssignTeam();
      case 5:
        return _step5Review();
      default:
        return Container();
    }
  }

  Widget _step1Info() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.calendar_today, size: 50, color: primaryGreen),
        ),
        const SizedBox(height: 12),
        const Text("Campaign Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Text("Fill in the basic information to get started.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 24),
        const Align(alignment: Alignment.centerLeft, child: Text("Campaign Name", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
        ),
        const SizedBox(height: 16),
        const Align(alignment: Alignment.centerLeft, child: Text("Campaign Type", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _campaignType,
          items: ["Polio", "Routine Immunization", "Sub National Drive"]
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => setState(() => _campaignType = val!),
          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
        ),
      ],
    );
  }

  Widget _step2TargetArea() {
    final areas = [
      {'name': 'Mohallah A, Jand', 'children': '128 (0-5 Years)'},
      {'name': 'Mohallah B, Jand', 'children': '80 (0-5 Years)'},
      {'name': 'UC-08, Jand', 'children': '110 (0-5 Years)'},
      {'name': 'THQ City, Jand', 'children': '130 (0-5 Years)'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: Text("Target Area", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        const Center(child: Text("Select the area where this campaign will be conducted.", style: TextStyle(color: Colors.grey, fontSize: 12))),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: "Search area...",
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),
        ...areas.map((area) => RadioListTile<String>(
              value: area['name']!,
              groupValue: _selectedArea,
              activeColor: primaryGreen,
              title: Text(area['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text("Total Children: ${area['children']}", style: const TextStyle(fontSize: 11)),
              onChanged: (val) => setState(() => _selectedArea = val!),
            )),
      ],
    );
  }

  Widget _step3ChildrenInArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: Text("Children in Area", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        Center(child: Text("Area: $_selectedArea", style: const TextStyle(color: Colors.grey, fontSize: 12))),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _countCard("Total Children", "128", primaryGreen)),
            const SizedBox(width: 12),
            Expanded(child: _countCard("Total Households", "80", Colors.blue)),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: "Search child or household...",
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 12),
        _childTile("Ali Ahmad", "UC-08-001", "01 Jan 2021"),
        _childTile("Zainab Fatima", "UC-08-002", "10 Feb 2021"),
        _childTile("Hammad Ali", "UC-08-003", "20 Nov 2020"),
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton(
            onPressed: () {},
            child: const Text("View All (128 Children)", style: TextStyle(color: primaryGreen)),
          ),
        )
      ],
    );
  }

  Widget _step4AssignTeam() {
    final list = [
      {'name': 'Ahmed Khan', 'bhu': 'BHU-001 • Area: Mohallah A, Jand'},
      {'name': 'Fatima Noor', 'bhu': 'BHU-002 • Area: Mohallah A, Jand'},
      {'name': 'Usman Tahir', 'bhu': 'BHU-003 • Area: Mohallah A, Jand'},
      {'name': 'Hammad Ali', 'bhu': 'BHU-003 • Area: Mohallah A, Jand'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: Text("Assign Vaccinators / Team", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        const Center(child: Text("Select the vaccinators / team for this campaign.", style: TextStyle(color: Colors.grey, fontSize: 12))),
        const SizedBox(height: 16),
        const Align(alignment: Alignment.centerLeft, child: Text("Team Name (Optional)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: _teamName),
          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
        ),
        const SizedBox(height: 16),
        const Text("Select Vaccinators", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        ...list.map((v) {
          bool selected = _selectedVaccinators.contains(v['name']);
          return CheckboxListTile(
            value: selected,
            activeColor: primaryGreen,
            title: Text(v['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(v['bhu']!, style: const TextStyle(fontSize: 10)),
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedVaccinators.add(v['name']!);
                } else {
                  _selectedVaccinators.remove(v['name']!);
                }
              });
            },
          );
        }),
      ],
    );
  }

  Widget _step5Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: Text("Review & Confirm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        const Center(child: Text("Review the campaign details before creating.", style: TextStyle(color: Colors.grey, fontSize: 12))),
        const SizedBox(height: 20),
        _summaryRow(Icons.campaign, "Campaign Name", _nameController.text),
        _summaryRow(Icons.category, "Campaign Type", _campaignType),
        _summaryRow(Icons.location_on, "Target Area", _selectedArea),
        _summaryRow(Icons.date_range, "Duration", "10 Aug – 15 Aug 2026"),
        _summaryRow(Icons.group, "Team", "$_teamName (${_selectedVaccinators.length} Vaccinators)"),
        _summaryRow(Icons.home, "Total Households", "80"),
        _summaryRow(Icons.child_care, "Total Children (0-5 Years)", "128"),
      ],
    );
  }

  void _onContinuePressed() {
    if (_currentStep < 5) {
      setState(() => _currentStep++);
    } else {
      // Step 5 Complete -> Open Success Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CampaignStartedScreen(
            campaignName: _nameController.text,
            targetArea: _selectedArea,
            duration: "10 Aug – 15 Aug 2026",
            team: "$_teamName (${_selectedVaccinators.length} Vaccinators)",
            totalChildren: "128",
          ),
        ),
      );
    }
  }

  Widget _countCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _childTile(String name, String id, String dob) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(backgroundColor: primaryGreen, radius: 16, child: Icon(Icons.person, color: Colors.white, size: 18)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text("$id • DOB: $dob", style: const TextStyle(fontSize: 11)),
    );
  }

  Widget _summaryRow(IconData icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primaryGreen),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}

// ==========================================
// 2. CAMPAIGN STARTED SCREEN (Success Screen)
// ==========================================
class CampaignStartedScreen extends StatelessWidget {
  final String campaignName;
  final String targetArea;
  final String duration;
  final String team;
  final String totalChildren;

  const CampaignStartedScreen({
    super.key,
    this.campaignName = "National Polio Campaign",
    this.targetArea = "Mohallah A, Jand",
    this.duration = "10 Aug – 15 Aug 2026",
    this.team = "Team A (4 Vaccinators)",
    this.totalChildren = "128",
  });

  static const Color primaryGreen = Color(0xFF006837);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.campaign,
                  size: 70,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Campaign Started\nSuccessfully!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Vaccinators can now start marking\nvaccinations.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _infoRow("Campaign Name", campaignName),
                    _infoRow("Target Area", targetArea),
                    _infoRow("Duration", duration),
                    _infoRow("Team", team),
                    _infoRow("Total Children", totalChildren, isLast: true),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // Navigate back to Overview / Campaigns Screen
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text(
                    "Go to Overview",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
} */
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/campaign_stepper.dart';
import 'select_target_area_screen.dart';

class CreateCampaignScreen extends StatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  State<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends State<CreateCampaignScreen> {
  static const Color primaryGreen = Color(0xFF006837);

  final _nameController = TextEditingController();
  String _campaignType = "Polio";
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? (_startDate ?? DateTime.now()));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _onContinuePressed() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campaign name likhna zaroori hai')),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start aur End date select karein')),
      );
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date, Start date se pehle nahi ho sakti')),
      );
      return;
    }

    final campaignData = <String, dynamic>{
      'name': _nameController.text.trim(),
      'type': _campaignType,
      'startDate': _startDate,
      'endDate': _endDate,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectTargetAreaScreen(campaignData: campaignData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Create Campaign",
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const CampaignStepper(currentStep: 1),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _step1Info(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _onContinuePressed,
                child: const Text(
                  "Continue",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step1Info() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.calendar_today, size: 50, color: primaryGreen),
        ),
        const SizedBox(height: 12),
        const Text("Campaign Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Text("Fill in the basic information to get started.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 24),
        const Align(alignment: Alignment.centerLeft, child: Text("Campaign Name", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: "e.g. National Polio Campaign",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),
        const Align(alignment: Alignment.centerLeft, child: Text("Campaign Type", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _campaignType,
          items: ["Polio", "Routine Immunization", "Sub National Drive"]
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => setState(() => _campaignType = val!),
          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _datePickerField(
                label: "Start Date",
                date: _startDate,
                onTap: () => _pickDate(isStart: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _datePickerField(
                label: "End Date",
                date: _endDate,
                onTap: () => _pickDate(isStart: false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _datePickerField({required String label, required DateTime? date, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null ? DateFormat('dd MMM yyyy').format(date) : "Select",
                  style: TextStyle(fontSize: 13, color: date != null ? Colors.black : Colors.grey.shade500),
                ),
                const Icon(Icons.calendar_month, size: 18, color: primaryGreen),
              ],
            ),
          ),
        ),
      ],
    );
  }
}