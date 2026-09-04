/*import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/campaign_model.dart';
import '../../services/campaign_service.dart';
import '../../widgets/campaign_stepper.dart';
import 'campaign_ready_screen.dart';

class CampaignPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> campaignData;

  const CampaignPreviewScreen({super.key, required this.campaignData});

  @override
  State<CampaignPreviewScreen> createState() => _CampaignPreviewScreenState();
}

class _CampaignPreviewScreenState extends State<CampaignPreviewScreen> {
  static const Color primaryGreen = Color(0xFF006837);
  final CampaignService _campaignService = CampaignService();

  List<Map<String, dynamic>> _vaccinators = [];
  bool _isLoadingVaccinators = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadVaccinatorNames();
  }

  Future<void> _loadVaccinatorNames() async {
    final ids = List<String>.from(widget.campaignData['vaccinatorIds'] ?? []);
    final list = await _campaignService.getVaccinatorsByIds(ids);
    setState(() {
      _vaccinators = list;
      _isLoadingVaccinators = false;
    });
  }

  Future<void> _onConfirmPressed() async {
    setState(() => _isSubmitting = true);
    try {
      final data = widget.campaignData;

      final campaign = CampaignModel(
        id: '',
        name: data['name'] ?? 'Untitled Campaign',
        type: data['type'] ?? 'Polio',
        startDate: data['startDate'] as DateTime,
        endDate: data['endDate'] as DateTime,
        targetAreas: List<String>.from(data['selectedAreas'] ?? []),
        status: 'active',
        teamName: data['teamName'] ?? '',
        vaccinatorIds: List<String>.from(data['vaccinatorIds'] ?? []),
        totalChildren: data['totalChildren'] ?? 0,
        totalHouseholds: data['totalHouseholds'] ?? 0,
        createdAt: DateTime.now(),
      );

      final assignment = Map<String, List<String>>.from(
        (data['assignment'] as Map).map(
          (key, value) => MapEntry(key as String, List<String>.from(value)),
        ),
      );

      await _campaignService.createCampaign(campaign: campaign, assignment: assignment);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CampaignReadyScreen(
            campaignName: campaign.name,
            targetArea: campaign.targetAreas.join(', '),
            duration:
                '${DateFormat('dd MMM').format(campaign.startDate)} – ${DateFormat('dd MMM yyyy').format(campaign.endDate)}',
            team: '${campaign.teamName.isEmpty ? "Team" : campaign.teamName} (${campaign.vaccinatorIds.length} Vaccinators)',
            totalChildren: '${campaign.totalChildren}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Campaign create nahi ho saki: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.campaignData;
    final startDate = data['startDate'] as DateTime?;
    final endDate = data['endDate'] as DateTime?;
    final durationStr = (startDate != null && endDate != null)
        ? '${DateFormat('dd MMM').format(startDate)} – ${DateFormat('dd MMM yyyy').format(endDate)}'
        : '—';
    final areas = List<String>.from(data['selectedAreas'] ?? []);
    final teamName = (data['teamName'] as String?)?.isNotEmpty == true ? data['teamName'] : 'Team';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Create Campaign",
            style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
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
          const CampaignStepper(currentStep: 5),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text("Review & Confirm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const Center(
                    child: Text("Review the campaign details before creating.",
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                  const SizedBox(height: 20),
                  _summaryRow(Icons.campaign, "Campaign Name", data['name'] ?? '—'),
                  _summaryRow(Icons.category, "Campaign Type", data['type'] ?? '—'),
                  _summaryRow(Icons.location_on, "Target Area", areas.join(', ')),
                  _summaryRow(Icons.date_range, "Duration", durationStr),
                  _summaryRow(Icons.group, "Team", "$teamName (${data['vaccinatorIds']?.length ?? 0} Vaccinators)"),
                  _summaryRow(Icons.home, "Total Households", "${data['totalHouseholds'] ?? 0}"),
                  _summaryRow(Icons.child_care, "Total Children (0-5 Years)", "${data['totalChildren'] ?? 0}"),
                  const SizedBox(height: 16),
                  const Text("Assigned Vaccinators", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  if (_isLoadingVaccinators)
                    const Center(child: CircularProgressIndicator(color: primaryGreen))
                  else
                    ..._vaccinators.map((v) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(backgroundColor: primaryGreen, child: Icon(Icons.person, color: Colors.white)),
                          title: Text(v['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(v['employeeId'], style: const TextStyle(fontSize: 11)),
                        )),
                ],
              ),
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
                    onPressed: _isSubmitting ? null : _onConfirmPressed,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text("Confirm & Create Campaign",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text("Edit Details", style: TextStyle(color: Colors.black87)),
                ),
              ],
            ),
          ),
        ],
      ),
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
} */
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/campaign_model.dart';
import '../../services/campaign_service.dart';
import '../../widgets/campaign_stepper.dart';
import 'campaign_ready_screen.dart';

class CampaignPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> campaignData;

  const CampaignPreviewScreen({super.key, required this.campaignData});

  @override
  State<CampaignPreviewScreen> createState() => _CampaignPreviewScreenState();
}

class _CampaignPreviewScreenState extends State<CampaignPreviewScreen> {
  static const Color primaryGreen = Color(0xFF006837);
  final CampaignService _campaignService = CampaignService();

  List<Map<String, dynamic>> _vaccinators = [];
  bool _isLoadingVaccinators = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadVaccinatorNames();
  }

  Future<void> _loadVaccinatorNames() async {
    final ids = List<String>.from(widget.campaignData['vaccinatorIds'] ?? []);
    final list = await _campaignService.getVaccinatorsByIds(ids);
    setState(() {
      _vaccinators = list;
      _isLoadingVaccinators = false;
    });
  }

  Future<void> _onConfirmPressed() async {
    setState(() => _isSubmitting = true);
    try {
      final data = widget.campaignData;

      // NEW: current logged-in supervisor ka UID save kar rahe hain,
      // taake Reports/Campaign Report screen sirf isi supervisor ki
      // banai hui campaigns dropdown mein dikha sake.
      final supervisorId = FirebaseAuth.instance.currentUser?.uid ?? '';

      final campaign = CampaignModel(
        id: '',
        name: data['name'] ?? 'Untitled Campaign',
        type: data['type'] ?? 'Polio',
        startDate: data['startDate'] as DateTime,
        endDate: data['endDate'] as DateTime,
        targetAreas: List<String>.from(data['selectedAreas'] ?? []),
        status: 'active',
        teamName: data['teamName'] ?? '',
        vaccinatorIds: List<String>.from(data['vaccinatorIds'] ?? []),
        totalChildren: data['totalChildren'] ?? 0,
        totalHouseholds: data['totalHouseholds'] ?? 0,
        supervisorId: supervisorId,
        createdAt: DateTime.now(),
      );

      final assignment = Map<String, List<String>>.from(
        (data['assignment'] as Map).map(
          (key, value) => MapEntry(key as String, List<String>.from(value)),
        ),
      );

      await _campaignService.createCampaign(campaign: campaign, assignment: assignment);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CampaignReadyScreen(
            campaignName: campaign.name,
            targetArea: campaign.targetAreas.join(', '),
            duration:
                '${DateFormat('dd MMM').format(campaign.startDate)} – ${DateFormat('dd MMM yyyy').format(campaign.endDate)}',
            team: '${campaign.teamName.isEmpty ? "Team" : campaign.teamName} (${campaign.vaccinatorIds.length} Vaccinators)',
            totalChildren: '${campaign.totalChildren}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Campaign create nahi ho saki: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.campaignData;
    final startDate = data['startDate'] as DateTime?;
    final endDate = data['endDate'] as DateTime?;
    final durationStr = (startDate != null && endDate != null)
        ? '${DateFormat('dd MMM').format(startDate)} – ${DateFormat('dd MMM yyyy').format(endDate)}'
        : '—';
    final areas = List<String>.from(data['selectedAreas'] ?? []);
    final teamName = (data['teamName'] as String?)?.isNotEmpty == true ? data['teamName'] : 'Team';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Create Campaign",
            style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
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
          const CampaignStepper(currentStep: 5),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text("Review & Confirm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const Center(
                    child: Text("Review the campaign details before creating.",
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                  const SizedBox(height: 20),
                  _summaryRow(Icons.campaign, "Campaign Name", data['name'] ?? '—'),
                  _summaryRow(Icons.category, "Campaign Type", data['type'] ?? '—'),
                  _summaryRow(Icons.location_on, "Target Area", areas.join(', ')),
                  _summaryRow(Icons.date_range, "Duration", durationStr),
                  _summaryRow(Icons.group, "Team", "$teamName (${data['vaccinatorIds']?.length ?? 0} Vaccinators)"),
                  _summaryRow(Icons.home, "Total Households", "${data['totalHouseholds'] ?? 0}"),
                  _summaryRow(Icons.child_care, "Total Children (0-5 Years)", "${data['totalChildren'] ?? 0}"),
                  const SizedBox(height: 16),
                  const Text("Assigned Vaccinators", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  if (_isLoadingVaccinators)
                    const Center(child: CircularProgressIndicator(color: primaryGreen))
                  else
                    ..._vaccinators.map((v) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(backgroundColor: primaryGreen, child: Icon(Icons.person, color: Colors.white)),
                          title: Text(v['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(v['employeeId'], style: const TextStyle(fontSize: 11)),
                        )),
                ],
              ),
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
                    onPressed: _isSubmitting ? null : _onConfirmPressed,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text("Confirm & Create Campaign",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text("Edit Details", style: TextStyle(color: Colors.black87)),
                ),
              ],
            ),
          ),
        ],
      ),
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