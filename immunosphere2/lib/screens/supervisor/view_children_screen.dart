/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/campaign_stepper.dart';
import 'assign_vaccinators_screen.dart';

class ViewChildrenScreen extends StatefulWidget {
  final Map<String, dynamic> campaignData;

  const ViewChildrenScreen({super.key, required this.campaignData});

  @override
  State<ViewChildrenScreen> createState() => _ViewChildrenScreenState();
}

class _ViewChildrenScreenState extends State<ViewChildrenScreen> {
  static const Color primaryGreen = Color(0xFF006837);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<String> get _selectedVillages {
    final selected = widget.campaignData['selectedAreas'];
    if (selected is List) return List<String>.from(selected);
    final single = widget.campaignData['targetArea'];
    if (single is String && single.isNotEmpty) {
      return single.split(',').map((e) => e.trim()).toList();
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // campaignData ko build() ke bahar, frame complete hone ke baad update karta hai.
  // Seedha build() ke andar Map mutate karna Flutter main risky practice hai —
  // isse agli screen (AssignVaccinatorsScreen) ko hamesha latest/stable data milta hai.
  void _updateCampaignData({
    required int totalChildren,
    required int totalHouseholds,
    required List<String> childIds,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.campaignData['totalChildren'] = totalChildren;
      widget.campaignData['totalHouseholds'] = totalHouseholds;
      widget.campaignData['childIds'] = childIds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final villages = _selectedVillages;
    final chosenAreaLabel = villages.join(', ');

    if (villages.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Children in Area')),
        body: const Center(child: Text('Koi area select nahi hui.')),
      );
    }

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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // Firestore whereIn max 30 values leta hai — campaign ke liye kaafi hai
        stream: FirebaseFirestore.instance
            .collection('children')
            .where('village', whereIn: villages)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryGreen));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allDocs = snapshot.data?.docs ?? [];

          final filteredDocs = _searchQuery.isEmpty
              ? allDocs
              : allDocs.where((doc) {
                  final data = doc.data();
                  final name = (data['name'] ?? data['fullName'] ?? '').toString().toLowerCase();
                  final house = (data['houseAddress'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) || house.contains(_searchQuery);
                }).toList();

          final totalChildrenCount = allDocs.length;
          final Set<String> uniqueHouseholds = {};
          for (var doc in allDocs) {
            final data = doc.data();
            if (data['houseAddress'] != null) {
              uniqueHouseholds.add(data['houseAddress'].toString());
            }
          }
          final totalHouseholdsCount =
              uniqueHouseholds.isNotEmpty ? uniqueHouseholds.length : totalChildrenCount;

          // Agli screens (Assign Vaccinators, Review) ke liye data taiyar —
          // safely, build khatam hone ke baad
          _updateCampaignData(
            totalChildren: totalChildrenCount,
            totalHouseholds: totalHouseholdsCount,
            childIds: allDocs.map((d) => d.id).toList(),
          );

          return Column(
            children: [
              const CampaignStepper(currentStep: 3),
              const Divider(height: 1),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Area: $chosenAreaLabel',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryGreen),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Children\n(0-5 Years)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text('$totalChildrenCount',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Total Households', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text('$totalHouseholdsCount',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search child or household...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: filteredDocs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'No registered children found in "$chosenAreaLabel".',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final data = filteredDocs[index].data();
                          final childName = data['name'] ?? data['fullName'] ?? 'Unknown Name';
                          final regNo = data['regNo'] ?? data['id'] ?? filteredDocs[index].id.substring(0, 8);
                          final house = data['houseAddress'] ?? 'N/A';
                          final village = data['village'] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: primaryGreen,
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(childName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text('Reg No: $regNo | House: $house', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                      Text('Village: $village', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.white,
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: totalChildrenCount == 0
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AssignVaccinatorsScreen(campaignData: widget.campaignData),
                              ),
                            );
                          },
                    child: const Text(
                      'Next: Assign Vaccinators',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} */
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/campaign_stepper.dart';
import 'assign_vaccinators_screen.dart';

class ViewChildrenScreen extends StatefulWidget {
  final Map<String, dynamic> campaignData;

  const ViewChildrenScreen({super.key, required this.campaignData});

  @override
  State<ViewChildrenScreen> createState() => _ViewChildrenScreenState();
}

class _ViewChildrenScreenState extends State<ViewChildrenScreen> {
  static const Color primaryGreen = Color(0xFF006837);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // AI Insights se campaign banayi ho to sirf risk wale bache (default).
  // Supervisor chahe to "Sab bache lein" dabakar area ke sab bache le sakta hai.
  bool _includeAll = false;

  List<String> get _selectedVillages {
    final selected = widget.campaignData['selectedAreas'];
    if (selected is List) return List<String>.from(selected);
    final single = widget.campaignData['targetArea'];
    if (single is String && single.isNotEmpty) {
      return single.split(',').map((e) => e.trim()).toList();
    }
    return [];
  }

  // AI ne jo bache chune (khali ho to normal campaign: area ke sab bache)
  List<String> get _aiChildIds {
    final raw = widget.campaignData['prefillChildIds'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return [];
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // campaignData ko build() ke bahar, frame complete hone ke baad update karta hai.
  // Seedha build() ke andar Map mutate karna Flutter main risky practice hai —
  // isse agli screen (AssignVaccinatorsScreen) ko hamesha latest/stable data milta hai.
  void _updateCampaignData({
    required int totalChildren,
    required int totalHouseholds,
    required List<String> childIds,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.campaignData['totalChildren'] = totalChildren;
      widget.campaignData['totalHouseholds'] = totalHouseholds;
      widget.campaignData['childIds'] = childIds;
    });
  }

  Widget _aiBanner(bool filterOn, int shown, int areaTotal) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: primaryGreen, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              filterOn
                  ? 'AI ne sirf risk wale $shown bache chune hain. Area ke baqi ${areaTotal - shown} bache is campaign mein shamil nahi.'
                  : 'Area ke sab $areaTotal bache shamil hain.',
              style: const TextStyle(fontSize: 11.5, color: Colors.black87),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _includeAll = !_includeAll),
            child: Text(
              filterOn ? 'Sab bache lein' : 'Sirf AI wale',
              style: const TextStyle(fontSize: 11.5, color: primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final villages = _selectedVillages;
    final chosenAreaLabel = villages.join(', ');

    if (villages.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Children in Area')),
        body: const Center(child: Text('Koi area select nahi hui.')),
      );
    }

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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // Firestore whereIn max 30 values leta hai — campaign ke liye kaafi hai
        stream: FirebaseFirestore.instance
            .collection('children')
            .where('village', whereIn: villages)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryGreen));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final List<QueryDocumentSnapshot<Map<String, dynamic>>> areaDocs =
              snapshot.data?.docs ?? [];

          // AI se aaye hon (aur supervisor ne "Sab bache" nahi chuna) to sirf AI ke bache
          final aiIds = _aiChildIds;
          final bool aiFilterOn = aiIds.isNotEmpty && !_includeAll;
          final Set<String> aiIdSet = aiIds.toSet();
          final List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocs = aiFilterOn
              ? areaDocs.where((d) => aiIdSet.contains(d.id)).toList()
              : areaDocs;

          final filteredDocs = _searchQuery.isEmpty
              ? allDocs
              : allDocs.where((doc) {
                  final data = doc.data();
                  final name = (data['name'] ?? data['fullName'] ?? '').toString().toLowerCase();
                  final house = (data['houseAddress'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) || house.contains(_searchQuery);
                }).toList();

          final totalChildrenCount = allDocs.length;
          final Set<String> uniqueHouseholds = {};
          for (var doc in allDocs) {
            final data = doc.data();
            if (data['houseAddress'] != null) {
              uniqueHouseholds.add(data['houseAddress'].toString());
            }
          }
          final totalHouseholdsCount =
              uniqueHouseholds.isNotEmpty ? uniqueHouseholds.length : totalChildrenCount;

          // Agli screens (Assign Vaccinators, Review) ke liye data taiyar —
          // safely, build khatam hone ke baad
          _updateCampaignData(
            totalChildren: totalChildrenCount,
            totalHouseholds: totalHouseholdsCount,
            childIds: allDocs.map((d) => d.id).toList(),
          );

          return Column(
            children: [
              const CampaignStepper(currentStep: 3),
              const Divider(height: 1),
              if (aiIds.isNotEmpty) _aiBanner(aiFilterOn, allDocs.length, areaDocs.length),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Area: $chosenAreaLabel',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryGreen),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Children\n(0-5 Years)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text('$totalChildrenCount',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Total Households', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text('$totalHouseholdsCount',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search child or household...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: filteredDocs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'No registered children found in "$chosenAreaLabel".',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final data = filteredDocs[index].data();
                          final childName = data['name'] ?? data['fullName'] ?? 'Unknown Name';
                          final regNo = data['regNo'] ?? data['id'] ?? filteredDocs[index].id.substring(0, 8);
                          final house = data['houseAddress'] ?? 'N/A';
                          final village = data['village'] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: primaryGreen,
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(childName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text('Reg No: $regNo | House: $house', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                      Text('Village: $village', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.white,
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: totalChildrenCount == 0
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AssignVaccinatorsScreen(campaignData: widget.campaignData),
                              ),
                            );
                          },
                    child: const Text(
                      'Next: Assign Vaccinators',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}