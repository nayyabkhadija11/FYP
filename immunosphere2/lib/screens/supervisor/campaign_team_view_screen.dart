import 'package:flutter/material.dart';
import '../../services/campaign_service.dart';

class CampaignTeamViewScreen extends StatefulWidget {
  final String campaignId;

  const CampaignTeamViewScreen({super.key, required this.campaignId});

  @override
  State<CampaignTeamViewScreen> createState() => _CampaignTeamViewScreenState();
}

class _CampaignTeamViewScreenState extends State<CampaignTeamViewScreen> {
  static const Color primaryGreen = Color(0xFF006837);
  final CampaignService _campaignService = CampaignService();

  Map<String, List<Map<String, dynamic>>> _groupedChildren = {};
  Map<String, String> _vaccinatorNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final grouped = await _campaignService.getChildrenGroupedByVaccinator(widget.campaignId);
    final vaccinators = await _campaignService.getVaccinatorsByIds(grouped.keys.toList());
    setState(() {
      _groupedChildren = grouped;
      _vaccinatorNames = {for (var v in vaccinators) v['id'] as String: v['name'] as String};
      _isLoading = false;
    });
  }

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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryGreen))
            : TabBarView(
                children: [
                  _buildByVaccinatorTab(),
                  _buildByHouseholdTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildByVaccinatorTab() {
    if (_groupedChildren.isEmpty) {
      return const Center(child: Text('Koi vaccinator assign nahi hua.', style: TextStyle(color: Colors.grey)));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _groupedChildren.entries.map((entry) {
        final name = _vaccinatorNames[entry.key] ?? entry.key;
        final children = entry.value;
        final houses = children.map((c) => c['houseAddress']).where((h) => (h as String).isNotEmpty).toSet();
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: primaryGreen, child: Icon(Icons.person, color: Colors.white)),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text("${houses.length} Households • ${children.length} Children",
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildByHouseholdTab() {
    final Map<String, List<String>> byHouse = {};
    _groupedChildren.forEach((vaccinatorId, children) {
      final vName = _vaccinatorNames[vaccinatorId] ?? vaccinatorId;
      for (var c in children) {
        final house = (c['houseAddress'] as String).isEmpty ? 'Unknown' : c['houseAddress'] as String;
        byHouse.putIfAbsent(house, () => []);
        byHouse[house]!.add(vName);
      }
    });

    if (byHouse.isEmpty) {
      return const Center(child: Text('Koi household data nahi mila.', style: TextStyle(color: Colors.grey)));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: byHouse.entries.map((entry) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: ListTile(
            title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text("Vaccinator: ${entry.value.first}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
            trailing: Text('${entry.value.length}', style: const TextStyle(color: primaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        );
      }).toList(),
    );
  }
} 