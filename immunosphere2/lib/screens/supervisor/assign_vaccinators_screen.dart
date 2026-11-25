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
        _error = 'Failed to load vaccinators. $e';
        _isLoading = false;
      });
    }
  }

  void _onContinuePressed() {
    if (_selectedVaccinatorIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one vaccinator.')),
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
                '$totalChildren Children $selectedCount will be distributed (~$perVaccinator among the vaccinators.)',
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
                      ? 'Your Health Center ("$_supervisorHealthCenter") se link koi vaccinator nahi mila.'
                      : 'No vaccinators found.',
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