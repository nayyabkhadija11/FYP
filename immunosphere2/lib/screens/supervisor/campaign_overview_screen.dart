/*import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/campaign_model.dart';
import '../../services/campaign_service.dart';
import 'campaign_team_view_screen.dart';
import 'polio_campaign_report_screen.dart';

class CampaignOverviewScreen extends StatefulWidget {
  final String campaignId;

  const CampaignOverviewScreen({super.key, required this.campaignId});

  @override
  State<CampaignOverviewScreen> createState() => _CampaignOverviewScreenState();
}

class _CampaignOverviewScreenState extends State<CampaignOverviewScreen> {
  static const Color primaryGreen = Color(0xFF006837);
  final CampaignService _campaignService = CampaignService();

  CampaignModel? _campaign;
  Map<String, List<Map<String, dynamic>>> _groupedChildren = {};
  List<Map<String, dynamic>> _vaccinators = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final campaign = await _campaignService.getCampaignById(widget.campaignId);
      if (campaign == null) {
        setState(() {
          _error = 'Campaign nahi mila.';
          _isLoading = false;
        });
        return;
      }
      final grouped = await _campaignService.getChildrenGroupedByVaccinator(widget.campaignId);
      final vaccinators = await _campaignService.getVaccinatorsByIds(campaign.vaccinatorIds);

      setState(() {
        _campaign = campaign;
        _groupedChildren = grouped;
        _vaccinators = vaccinators;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Data load nahi ho saka: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Campaign Overview",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final campaign = _campaign!;
    final now = DateTime.now();
    final isCompleted = campaign.status == 'completed' || now.isAfter(campaign.endDate);

    final totalChildren = _groupedChildren.values.fold<int>(0, (sum, list) => sum + list.length);
    final Set<String> allHouses = {};
    for (var list in _groupedChildren.values) {
      for (var c in list) {
        if ((c['houseAddress'] as String).isNotEmpty) allHouses.add(c['houseAddress']);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  campaign.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.grey.shade200 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isCompleted ? "Completed" : "Active",
                  style: TextStyle(
                    color: isCompleted ? Colors.grey.shade700 : primaryGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
          Text(
            '${DateFormat('dd MMM').format(campaign.startDate)} – ${DateFormat('dd MMM yyyy').format(campaign.endDate)} • ${campaign.targetAreas.join(', ')}',
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _statCard("$totalChildren", "Children", primaryGreen),
              _statCard("${allHouses.length}", "Households", Colors.blue),
              _statCard("${campaign.vaccinatorIds.length}", "Vaccinators", Colors.orange),
              _statCard("0%", "Completed", Colors.purple),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Assigned Vaccinators", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          if (_vaccinators.isEmpty)
            const Text('Koi vaccinator assign nahi hua.', style: TextStyle(color: Colors.grey, fontSize: 12))
          else
            ..._vaccinators.map((v) {
              final assignedList = _groupedChildren[v['id']] ?? [];
              final houses = assignedList.map((c) => c['houseAddress']).where((h) => (h as String).isNotEmpty).toSet();
              return _monitorTile(v['name'], '${houses.length}', '${assignedList.length}');
            }),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CampaignTeamViewScreen(campaignId: widget.campaignId),
                      ),
                    );
                  },
                  child: const Text("View Assignment", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PolioCampaignReportScreen(),
                      ),
                    );
                  },
                  child: const Text("Campaign Reports", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _statCard(String num, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(num, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _monitorTile(String name, String houses, String kids) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: primaryGreen,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text("Assigned Households: $houses • Children: $kids", style: const TextStyle(fontSize: 10)),
      ),
    );
  }
} */
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/campaign_model.dart';
import '../../services/campaign_service.dart';
import 'campaign_team_view_screen.dart';
import 'polio_campaign_report_screen.dart';
import 'campaign_map_screen.dart';

class CampaignOverviewScreen extends StatefulWidget {
  final String campaignId;

  const CampaignOverviewScreen({super.key, required this.campaignId});

  @override
  State<CampaignOverviewScreen> createState() => _CampaignOverviewScreenState();
}

class _CampaignOverviewScreenState extends State<CampaignOverviewScreen> {
  static const Color primaryGreen = Color(0xFF006837);
  final CampaignService _campaignService = CampaignService();

  CampaignModel? _campaign;
  Map<String, List<Map<String, dynamic>>> _groupedChildren = {};
  List<Map<String, dynamic>> _vaccinators = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final campaign = await _campaignService.getCampaignById(widget.campaignId);
      if (campaign == null) {
        setState(() {
          _error = 'Campaign nahi mila.';
          _isLoading = false;
        });
        return;
      }
      final grouped = await _campaignService.getChildrenGroupedByVaccinator(widget.campaignId);
      final vaccinators = await _campaignService.getVaccinatorsByIds(campaign.vaccinatorIds);

      setState(() {
        _campaign = campaign;
        _groupedChildren = grouped;
        _vaccinators = vaccinators;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Data load nahi ho saka: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Campaign Overview",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final campaign = _campaign!;
    final now = DateTime.now();
    final isCompleted = campaign.status == 'completed' || now.isAfter(campaign.endDate);

    final totalChildren = _groupedChildren.values.fold<int>(0, (sum, list) => sum + list.length);
    final Set<String> allHouses = {};
    for (var list in _groupedChildren.values) {
      for (var c in list) {
        if ((c['houseAddress'] as String).isNotEmpty) allHouses.add(c['houseAddress']);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  campaign.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.grey.shade200 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isCompleted ? "Completed" : "Active",
                  style: TextStyle(
                    color: isCompleted ? Colors.grey.shade700 : primaryGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
          Text(
            '${DateFormat('dd MMM').format(campaign.startDate)} – ${DateFormat('dd MMM yyyy').format(campaign.endDate)} • ${campaign.targetAreas.join(', ')}',
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _statCard("$totalChildren", "Children", primaryGreen),
              _statCard("${allHouses.length}", "Households", Colors.blue),
              _statCard("${campaign.vaccinatorIds.length}", "Vaccinators", Colors.orange),
              _statCard("0%", "Completed", Colors.purple),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Assigned Vaccinators", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          if (_vaccinators.isEmpty)
            const Text('Koi vaccinator assign nahi hua.', style: TextStyle(color: Colors.grey, fontSize: 12))
          else
            ..._vaccinators.map((v) {
              final assignedList = _groupedChildren[v['id']] ?? [];
              final houses = assignedList.map((c) => c['houseAddress']).where((h) => (h as String).isNotEmpty).toSet();
              return _monitorTile(v['name'], '${houses.length}', '${assignedList.length}');
            }),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CampaignTeamViewScreen(campaignId: widget.campaignId),
                      ),
                    );
                  },
                  child: const Text("View Assignment", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PolioCampaignReportScreen(
                          campaignId: widget.campaignId,
                        ),
                      ),
                    );
                  },
                  child: const Text("Campaign Reports", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // NEW: "View on Map" button — pehle is screen se CampaignMapScreen
          // par jaane ka koi rasta hi nahi tha (aur wo screen khud
          // hardcoded data use kar rahi thi). Ab yeh yahan se real
          // campaignId ke sath khulti hai.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.blue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CampaignMapScreen(campaignId: widget.campaignId),
                  ),
                );
              },
              icon: const Icon(Icons.map_outlined, color: Colors.blue),
              label: const Text("View on Map", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String num, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(num, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _monitorTile(String name, String houses, String kids) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: primaryGreen,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text("Assigned Households: $houses • Children: $kids", style: const TextStyle(fontSize: 10)),
      ),
    );
  }
}