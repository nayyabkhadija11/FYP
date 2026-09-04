/*import 'package:flutter/material.dart';
import 'view_children_screen.dart'; // Apni ViewChildrenScreen ka file name yahan check kar Lein

class SelectTargetAreaScreen extends StatefulWidget {
  final Map<String, dynamic> campaignData;

  const SelectTargetAreaScreen({super.key, required this.campaignData});

  @override
  State<SelectTargetAreaScreen> createState() => _SelectTargetAreaScreenState();
}

class _SelectTargetAreaScreenState extends State<SelectTargetAreaScreen> {
  final List<Map<String, dynamic>> _areas = [
    {'name': 'Mohallah Station', 'children': 115},
    {'name': 'Mohallah Takia', 'children': 90},
    {'name': 'Mohallah Haji Bazar', 'children': 140},
    {'name': 'Mohallah Hussainabad', 'children': 105},
    {'name': 'Mohallah Aminabad', 'children': 85},
    {'name': 'Mohallah Allahabad', 'children': 130},
    {'name': 'Mohallah Gora', 'children': 95},
    {'name': 'Mohallah Baraf Khana', 'children': 120},
  ];

  late List<String> _selectedAreas;

  @override
  void initState() {
    super.initState();
    if (widget.campaignData.containsKey('selectedAreas') && widget.campaignData['selectedAreas'] is List<String>) {
      _selectedAreas = List<String>.from(widget.campaignData['selectedAreas']);
    } else {
      _selectedAreas = ['Mohallah Station']; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF231B92)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Target Area',
          style: TextStyle(
            color: Color(0xFF231B92),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar and Filter section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search area...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.filter_list, color: Colors.grey.shade700, size: 20),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),

          // Area List with Multi-Selection (Checkboxes)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _areas.length,
              itemBuilder: (context, index) {
                final area = _areas[index];
                final areaName = area['name'];
                final isSelected = _selectedAreas.contains(areaName);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedAreas.remove(areaName); 
                      } else {
                        _selectedAreas.add(areaName); 
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF231B92) : Colors.grey.shade300,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                          color: isSelected ? const Color(0xFF231B92) : Colors.grey.shade400,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                areaName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? const Color(0xFF231B92) : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total Children: ${area['children']} (0-5 Years)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Button Section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF231B92),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (_selectedAreas.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least one target area')),
                    );
                    return;
                  }

                  // 1. Total children calculate karein
                  int totalChildrenCount = 0;
                  for (var areaName in _selectedAreas) {
                    var found = _areas.firstWhere((a) => a['name'] == areaName, orElse: () => {'children': 0});
                    totalChildrenCount += (found['children'] as int);
                  }

                  // 2. Combined string banayein (jaise: "Mohallah Station, Mohallah Takia")
                  final targetAreaString = _selectedAreas.join(', ');

                  // 3. Campaign data update karein
                  widget.campaignData['selectedAreas'] = _selectedAreas;
                  widget.campaignData['targetArea'] = targetAreaString;
                  widget.campaignData['totalChildren'] = totalChildrenCount;

                  // 4. CreateCampaignScreen ko target area wapas bhejiye taake wahan select ho jaye,
                  // aur sath hi ViewChildrenScreen par bhi forward move kar jayein
                  Navigator.pop(context, targetAreaString); // Ye CreateCampaignScreen ka target area update karega

                  // Phir ViewChildrenScreen kholne ke liye push karein:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewChildrenScreen(campaignData: widget.campaignData),
                    ),
                  );
                },
                child: const Text(
                  'Done / View Children Screen',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} */
/*import 'package:flutter/material.dart';
import '../../services/campaign_service.dart';
import '../../widgets/campaign_stepper.dart';
import 'view_children_screen.dart';

class SelectTargetAreaScreen extends StatefulWidget {
  final Map<String, dynamic> campaignData;

  const SelectTargetAreaScreen({super.key, required this.campaignData});

  @override
  State<SelectTargetAreaScreen> createState() => _SelectTargetAreaScreenState();
}

class _SelectTargetAreaScreenState extends State<SelectTargetAreaScreen> {
  static const Color primaryGreen = Color(0xFF006837);
  final CampaignService _campaignService = CampaignService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allAreas = [];
  List<Map<String, dynamic>> _filteredAreas = [];
  final List<String> _selectedAreas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAreas();
    _searchController.addListener(_filterAreas);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAreas() async {
    try {
      final areas = await _campaignService.getAreasWithChildCounts();
      setState(() {
        _allAreas = areas;
        _filteredAreas = areas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Areas load nahi ho sakay: $e';
        _isLoading = false;
      });
    }
  }

  void _filterAreas() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredAreas = query.isEmpty
          ? _allAreas
          : _allAreas
              .where((a) => (a['name'] as String).toLowerCase().contains(query))
              .toList();
    });
  }

  void _onContinuePressed() {
    if (_selectedAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kam se kam ek area select karein')),
      );
      return;
    }

    int totalChildrenCount = 0;
    for (var areaName in _selectedAreas) {
      final found = _allAreas.firstWhere(
        (a) => a['name'] == areaName,
        orElse: () => {'children': 0},
      );
      totalChildrenCount += (found['children'] as int);
    }

    widget.campaignData['selectedAreas'] = List<String>.from(_selectedAreas);
    widget.campaignData['targetArea'] = _selectedAreas.join(', ');
    widget.campaignData['totalChildren'] = totalChildrenCount;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewChildrenScreen(campaignData: widget.campaignData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          const CampaignStepper(currentStep: 2),
          const Divider(height: 1),
          const SizedBox(height: 12),
          const Text("Target Area", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              "Select the area(s) where this campaign will be conducted.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search area...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
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
                  'Continue',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryGreen));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    if (_filteredAreas.isEmpty) {
      return const Center(
        child: Text('Koi registered children/areas nahi milay.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredAreas.length,
      itemBuilder: (context, index) {
        final area = _filteredAreas[index];
        final areaName = area['name'] as String;
        final isSelected = _selectedAreas.contains(areaName);

        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedAreas.remove(areaName);
              } else {
                _selectedAreas.add(areaName);
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? primaryGreen : Colors.grey.shade300,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isSelected ? primaryGreen : Colors.grey.shade400,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        areaName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? primaryGreen : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Children: ${area['children']} (0-5 Years)',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} */
import 'package:flutter/material.dart';
import '../../services/campaign_service.dart';
import '../../widgets/campaign_stepper.dart';
import 'view_children_screen.dart';

class SelectTargetAreaScreen extends StatefulWidget {
  final Map<String, dynamic> campaignData;

  const SelectTargetAreaScreen({super.key, required this.campaignData});

  @override
  State<SelectTargetAreaScreen> createState() => _SelectTargetAreaScreenState();
}

class _SelectTargetAreaScreenState extends State<SelectTargetAreaScreen> {
  static const Color primaryGreen = Color(0xFF006837);
  final CampaignService _campaignService = CampaignService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allAreas = [];
  List<Map<String, dynamic>> _filteredAreas = [];
  final List<String> _selectedAreas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAreas();
    _searchController.addListener(_filterAreas);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAreas() async {
    try {
      final areas = await _campaignService.getAreasWithChildCounts();
      setState(() {
        _allAreas = areas;
        _filteredAreas = areas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Areas load nahi ho sakay: $e';
        _isLoading = false;
      });
    }
  }

  void _filterAreas() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredAreas = query.isEmpty
          ? _allAreas
          : _allAreas
              .where((a) => (a['name'] as String).toLowerCase().contains(query))
              .toList();
    });
  }

  // Safely converts children count coming from Firestore/API,
  // chahe wo int, num, String, ya null kisi bhi form main ho.
  int _safeChildrenCount(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  void _onContinuePressed() {
    if (_selectedAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kam se kam ek area select karein')),
      );
      return;
    }

    try {
      int totalChildrenCount = 0;
      for (var areaName in _selectedAreas) {
        final found = _allAreas.firstWhere(
          (a) => a['name'] == areaName,
          orElse: () => {'children': 0},
        );
        totalChildrenCount += _safeChildrenCount(found['children']);
      }

      widget.campaignData['selectedAreas'] = List<String>.from(_selectedAreas);
      widget.campaignData['targetArea'] = _selectedAreas.join(', ');
      widget.campaignData['totalChildren'] = totalChildrenCount;

      debugPrint('Continue -> campaignData: ${widget.campaignData}');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewChildrenScreen(campaignData: widget.campaignData),
        ),
      );
    } catch (e, stack) {
      debugPrint('Continue button error: $e');
      debugPrint('$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          const CampaignStepper(currentStep: 2),
          const Divider(height: 1),
          const SizedBox(height: 12),
          const Text("Target Area", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              "Select the area(s) where this campaign will be conducted.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search area...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
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
                  'Continue',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryGreen));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    if (_filteredAreas.isEmpty) {
      return const Center(
        child: Text('Koi registered children/areas nahi milay.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredAreas.length,
      itemBuilder: (context, index) {
        final area = _filteredAreas[index];
        final areaName = area['name'] as String;
        final isSelected = _selectedAreas.contains(areaName);

        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedAreas.remove(areaName);
              } else {
                _selectedAreas.add(areaName);
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? primaryGreen : Colors.grey.shade300,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isSelected ? primaryGreen : Colors.grey.shade400,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        areaName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? primaryGreen : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Children: ${area['children']} (0-5 Years)',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}