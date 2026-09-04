/*import 'package:flutter/material.dart';
import 'campaign_map_screen.dart';

class AssignVaccinatorsScreen extends StatelessWidget {
  const AssignVaccinatorsScreen({super.key});

  static const Color primaryGreen = Color(0xFF006837);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text(
            "Team Assignment Details",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: primaryGreen,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "By Vaccinator"),
              Tab(text: "By Household"),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  _buildByVaccinatorTab(context),
                  _buildByHouseholdTab(context),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: primaryGreen, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.map_outlined, color: primaryGreen),
                label: const Text("View on Map", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CampaignMapScreen()),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  // Screen 1: By Vaccinator List
  Widget _buildByVaccinatorTab(BuildContext context) {
    final vaccinators = [
      {"name": "Ahmed Khan", "id": "VAC001", "houses": "50", "kids": "64"},
      {"name": "Fatima Noor", "id": "VAC002", "houses": "45", "kids": "62"},
      {"name": "Usman Tahir", "id": "VAC003", "houses": "40", "kids": "58"},
      {"name": "Sana Ullah", "id": "VAC004", "houses": "35", "kids": "45"},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vaccinators.length,
      itemBuilder: (context, index) {
        final item = vaccinators[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: primaryGreen,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text("${item['name']} (${item['id']})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text("${item['houses']} Households • ${item['kids']} Children", style: const TextStyle(fontSize: 11, color: Colors.grey)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {},
          ),
        );
      },
    );
  }

  // Screen 2: By Household List
  Widget _buildByHouseholdTab(BuildContext context) {
    final households = [
      {"house": "House #12", "vaccinator": "Ahmed Khan", "kids": "2 Children"},
      {"house": "House #15", "vaccinator": "Fatima Noor", "kids": "1 Child"},
      {"house": "House #18", "vaccinator": "Ahmed Khan", "kids": "2 Children"},
      {"house": "House #21", "vaccinator": "Usman Tahir", "kids": "1 Child"},
      {"house": "House #25", "vaccinator": "Sana Ullah", "kids": "2 Children"},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: households.length,
      itemBuilder: (context, index) {
        final item = households[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: ListTile(
            title: Text(item['house']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text("Vaccinator: ${item['vaccinator']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item['kids']!, style: const TextStyle(color: primaryGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            onTap: () {},
          ),
        );
      },
    );
  }
} */
/*import 'package:flutter/material.dart';
import '../../services/campaign_service.dart';
import '../../widgets/campaign_stepper.dart';
import 'campaign_preview_screen.dart';

class AssignVaccinatorsScreen extends StatefulWidget {
  final Map<String, dynamic> campaignData;

  const AssignVaccinatorsScreen({super.key, required this.campaignData});

  @override
  State<AssignVaccinatorsScreen> createState() => _AssignVaccinatorsScreenState();
}

class _AssignVaccinatorsScreenState extends State<AssignVaccinatorsScreen> {
  static const Color primaryGreen = Color(0xFF006837);
  final CampaignService _campaignService = CampaignService();
  final TextEditingController _teamNameController = TextEditingController();

  List<Map<String, dynamic>> _vaccinators = [];
  final List<String> _selectedVaccinatorIds = [];
  bool _isLoading = true;
  String? _error;

  List<String> get _childIds => List<String>.from(widget.campaignData['childIds'] ?? []);

  @override
  void initState() {
    super.initState();
    _loadVaccinators();
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  Future<void> _loadVaccinators() async {
    try {
      final list = await _campaignService.getVaccinators();
      setState(() {
        _vaccinators = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Vaccinators load nahi ho sakay: $e';
        _isLoading = false;
      });
    }
  }

  void _onContinuePressed() {
    if (_selectedVaccinatorIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kam se kam ek vaccinator select karein')),
      );
      return;
    }

    final assignment = _campaignService.divideChildrenAmongVaccinators(
      _childIds,
      _selectedVaccinatorIds,
    );

    widget.campaignData['teamName'] = _teamNameController.text.trim().isEmpty
        ? null
        : _teamNameController.text.trim();
    widget.campaignData['vaccinatorIds'] = List<String>.from(_selectedVaccinatorIds);
    widget.campaignData['assignment'] = assignment;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CampaignPreviewScreen(campaignData: widget.campaignData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalChildren = _childIds.length;
    final selectedCount = _selectedVaccinatorIds.length;
    final perVaccinator = selectedCount == 0 ? 0 : (totalChildren / selectedCount).ceil();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Campaign',
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const CampaignStepper(currentStep: 4),
          const Divider(height: 1),
          Expanded(child: _buildBody(totalChildren, selectedCount, perVaccinator)),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
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

  Widget _buildBody(int totalChildren, int selectedCount, int perVaccinator) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryGreen));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text("Assign Vaccinators / Team", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const Center(
            child: Text("Select the vaccinators / team for this campaign.",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Team Name (Optional)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _teamNameController,
            decoration: InputDecoration(
              hintText: "e.g. Team A",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          if (selectedCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$totalChildren bachay $selectedCount vaccinators mein divide hongay (~$perVaccinator har ek ko)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryGreen),
              ),
            ),
          const Text("Select Vaccinators", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          if (_vaccinators.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('Koi vaccinators nahi milay.', style: TextStyle(color: Colors.grey))),
            )
          else
            ..._vaccinators.map((v) {
              final id = v['id'] as String;
              final selected = _selectedVaccinatorIds.contains(id);
              return CheckboxListTile(
                value: selected,
                activeColor: primaryGreen,
                title: Text(v['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(
                  "${v['employeeId']}${(v['healthCenter'] as String).isNotEmpty ? ' • ${v['healthCenter']}' : ''}",
                  style: const TextStyle(fontSize: 10),
                ),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedVaccinatorIds.add(id);
                    } else {
                      _selectedVaccinatorIds.remove(id);
                    }
                  });
                },
              );
            }),
        ],
      ),
    );
  }
} */
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/campaign_service.dart';
import '../../widgets/campaign_stepper.dart';
import 'campaign_preview_screen.dart';

class AssignVaccinatorsScreen extends StatefulWidget {
  final Map<String, dynamic> campaignData;

  const AssignVaccinatorsScreen({super.key, required this.campaignData});

  @override
  State<AssignVaccinatorsScreen> createState() => _AssignVaccinatorsScreenState();
}

class _AssignVaccinatorsScreenState extends State<AssignVaccinatorsScreen> {
  static const Color primaryGreen = Color(0xFF006837);
  final CampaignService _campaignService = CampaignService();
  final TextEditingController _teamNameController = TextEditingController();

  List<Map<String, dynamic>> _vaccinators = [];
  final List<String> _selectedVaccinatorIds = [];
  bool _isLoading = true;
  String? _error;

  // NEW: logged-in supervisor ka apna health center — sirf display/debug ke
  // liye rakha hai, taake zaroorat par UI par bhi dikha sakein.
  String? _supervisorHealthCenter;

  List<String> get _childIds => List<String>.from(widget.campaignData['childIds'] ?? []);

  @override
  void initState() {
    super.initState();
    _loadVaccinators();
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  Future<void> _loadVaccinators() async {
    try {
      // NEW: pehle logged-in supervisor ka apna health center Firestore se
      // nikalte hain, phir sirf usi health center ke vaccinators load
      // karte hain — taake supervisor sirf apni team ko dekh/assign kar sake.
      final uid = FirebaseAuth.instance.currentUser?.uid;
      String? supervisorHealthCenter;

      if (uid != null) {
        final supervisorDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (supervisorDoc.exists) {
          final data = supervisorDoc.data();
          final center = (data?['healthCenter'] ?? '').toString().trim();
          if (center.isNotEmpty) {
            supervisorHealthCenter = center;
          }
        }
      }

      final list = await _campaignService.getVaccinators(
        healthCenter: supervisorHealthCenter,
      );

      setState(() {
        _vaccinators = list;
        _supervisorHealthCenter = supervisorHealthCenter;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Vaccinators load nahi ho sakay: $e';
        _isLoading = false;
      });
    }
  }

  void _onContinuePressed() {
    if (_selectedVaccinatorIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kam se kam ek vaccinator select karein')),
      );
      return;
    }

    final assignment = _campaignService.divideChildrenAmongVaccinators(
      _childIds,
      _selectedVaccinatorIds,
    );

    widget.campaignData['teamName'] = _teamNameController.text.trim().isEmpty
        ? null
        : _teamNameController.text.trim();
    widget.campaignData['vaccinatorIds'] = List<String>.from(_selectedVaccinatorIds);
    widget.campaignData['assignment'] = assignment;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CampaignPreviewScreen(campaignData: widget.campaignData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalChildren = _childIds.length;
    final selectedCount = _selectedVaccinatorIds.length;
    final perVaccinator = selectedCount == 0 ? 0 : (totalChildren / selectedCount).ceil();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Campaign',
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const CampaignStepper(currentStep: 4),
          const Divider(height: 1),
          Expanded(child: _buildBody(totalChildren, selectedCount, perVaccinator)),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
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

  Widget _buildBody(int totalChildren, int selectedCount, int perVaccinator) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryGreen));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text("Assign Vaccinators / Team", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const Center(
            child: Text("Select the vaccinators / team for this campaign.",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          // NEW: supervisor ko batata hai kis health center ke vaccinators
          // filter ho rahe hain — transparency ke liye.
          if (_supervisorHealthCenter != null && _supervisorHealthCenter!.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "Showing vaccinators from: $_supervisorHealthCenter",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Team Name (Optional)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _teamNameController,
            decoration: InputDecoration(
              hintText: "e.g. Team A",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          if (selectedCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$totalChildren bachay $selectedCount vaccinators mein divide hongay (~$perVaccinator har ek ko)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryGreen),
              ),
            ),
          const Text("Select Vaccinators", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          if (_vaccinators.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  (_supervisorHealthCenter != null && _supervisorHealthCenter!.isNotEmpty)
                      ? 'Aapke health center ("$_supervisorHealthCenter") se link koi vaccinator nahi mila.'
                      : 'Koi vaccinators nahi milay.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ..._vaccinators.map((v) {
              final id = v['id'] as String;
              final selected = _selectedVaccinatorIds.contains(id);
              return CheckboxListTile(
                value: selected,
                activeColor: primaryGreen,
                title: Text(v['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(
                  "${v['employeeId']}${(v['healthCenter'] as String).isNotEmpty ? ' • ${v['healthCenter']}' : ''}",
                  style: const TextStyle(fontSize: 10),
                ),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedVaccinatorIds.add(id);
                    } else {
                      _selectedVaccinatorIds.remove(id);
                    }
                  });
                },
              );
            }),
        ],
      ),
    );
  }
}