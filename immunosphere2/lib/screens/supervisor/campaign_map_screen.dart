/*import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// APNI HOUSEHOLD DETAILS SCREEN KO YAHAN IMPORT KAREIN
import 'household_details_screen.dart'; 

class CampaignMapScreen extends StatefulWidget {
  const CampaignMapScreen({Key? key}) : super(key: key);

  @override
  State<CampaignMapScreen> createState() => _CampaignMapScreenState();
}

class _CampaignMapScreenState extends State<CampaignMapScreen> {
  static const Color primaryThemeGreen = Color(0xFF00563B);

  // Default initial position (Jand Town)
  static const LatLng _initialPosition = LatLng(33.4315, 72.0186);

  // Selected household set to null so bottom sheet is HIDDEN by default
  Map<String, dynamic>? selectedHousehold;

  // Households with GPS coordinates
  final List<Map<String, dynamic>> households = [
    {
      'id': 'HH-00015',
      'houseNo': 'House #15',
      'address': 'Mohallah A, Jand',
      'totalChildren': 2,
      'vaccinated': 1,
      'pending': 1,
      'status': 'Pending',
      'assignedVaccinator': 'Fatima Noor (VAC002)',
      'lastVisit': '11 Aug 2026, 10:30 AM',
      'location': const LatLng(33.4320, 72.0190),
    },
    {
      'id': 'HH-00016',
      'houseNo': 'House #16',
      'address': 'Mohallah A, Jand',
      'totalChildren': 3,
      'vaccinated': 3,
      'pending': 0,
      'status': 'Completed',
      'assignedVaccinator': 'Ahmed Khan (VAC001)',
      'lastVisit': '11 Aug 2026, 11:15 AM',
      'location': const LatLng(33.4310, 72.0180),
    },
    {
      'id': 'HH-00017',
      'houseNo': 'House #17',
      'address': 'Mohallah B, Jand',
      'totalChildren': 1,
      'vaccinated': 0,
      'pending': 1,
      'status': 'Pending',
      'assignedVaccinator': 'Usman Tahir (VAC003)',
      'lastVisit': '11 Aug 2026, 12:00 PM',
      'location': const LatLng(33.4330, 72.0175),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryThemeGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Campaign Map',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),
      body: Stack(
        children: [
          // 1. FREE INTERACTIVE MAP
          FlutterMap(
            options: MapOptions(
              initialCenter: _initialPosition,
              initialZoom: 15.0,
              onTap: (_, __) {
                setState(() {
                  selectedHousehold = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.immunosphere',
              ),
              MarkerLayer(
                markers: households.map((house) {
                  final bool isPending = house['status'] == 'Pending';
                  return Marker(
                    width: 45.0,
                    height: 45.0,
                    point: house['location'],
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedHousehold = house;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 6,
                            )
                          ],
                        ),
                        child: Icon(
                          Icons.home,
                          color: isPending
                              ? Colors.orange.shade800
                              : primaryThemeGreen,
                          size: 26,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // 2. Top Campaign Overview Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildCampaignStatsCard(),
          ),

          // 3. Bottom House Details Sheet
          if (selectedHousehold != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildHouseholdDetailsCard(selectedHousehold!),
            ),
        ],
      ),
    );
  }

  Widget _buildCampaignStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'National Polio Campaign (Aug 2026)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                      color: primaryThemeGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '10 Aug 2026 – 15 Aug 2026 • Mohallah A, Jand',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('128', 'Children'),
              _statItem('80', 'Households'),
              _statItem('4', 'Vaccinators'),
              _statItem('75%', 'Coverage'),
            ],
          )
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryThemeGreen),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildHouseholdDetailsCard(Map<String, dynamic> house) {
    final bool isPending = house['status'] == 'Pending';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                house['houseNo'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  house['status'],
                  style: TextStyle(
                    color: isPending
                        ? Colors.orange.shade800
                        : primaryThemeGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _detailRow(Icons.pin_outlined, 'Household ID', house['id']),
          _detailRow(Icons.location_on_outlined, 'Address', house['address']),
          _detailRow(
              Icons.face_outlined, 'Total Children', '${house['totalChildren']}'),
          _detailRow(
              Icons.check_circle_outline, 'Vaccinated', '${house['vaccinated']}'),
          _detailRow(
              Icons.hourglass_empty_outlined, 'Pending', '${house['pending']}'),
          _detailRow(Icons.person_outline, 'Assigned Vaccinator',
              house['assignedVaccinator']),
          _detailRow(
              Icons.access_time_outlined, 'Last Visit', house['lastVisit']),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryThemeGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // VIEW DETAILS NAVIGATION WORKING CODE
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Agar aapki screen parameter nahi leti toh simply:
                    // builder: (context) => const HouseholdDetailsScreen(),
                    builder: (context) => const HouseholdDetailsScreen(),
                  ),
                );
              },
              child: const Text(
                'View Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
        ],
      ),
    );
  }
} */
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/campaign_service.dart';
import 'household_details_screen.dart';

class CampaignMapScreen extends StatefulWidget {
  final String campaignId;

  const CampaignMapScreen({super.key, required this.campaignId});

  @override
  State<CampaignMapScreen> createState() => _CampaignMapScreenState();
}

class _CampaignMapScreenState extends State<CampaignMapScreen> {
  static const Color primaryThemeGreen = Color(0xFF00563B);
  static const LatLng _defaultPosition = LatLng(33.4315, 72.0186); // Jand Town fallback

  final CampaignService _campaignService = CampaignService();

  Map<String, dynamic>? selectedHousehold;
  bool _isLoading = true;
  String? _error;

  String _campaignName = 'Campaign';
  String _dateRangeStr = '';
  bool _isActive = true;

  List<Map<String, dynamic>> _households = []; // sirf wo households jinki GPS location hai
  int _totalChildren = 0;
  int _totalVaccinated = 0;
  int _totalHouseholds = 0; // sab addresses, GPS ho ya na ho
  int _missingLocationHouseholds = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final campaign = await _campaignService.getCampaignById(widget.campaignId);

      final assignmentsSnap = await FirebaseFirestore.instance
          .collection('campaign_assignments')
          .where('campaignId', isEqualTo: widget.campaignId)
          .get();

      final Map<String, List<Map<String, dynamic>>> byAddress = {};
      for (var doc in assignmentsSnap.docs) {
        final data = doc.data();
        final address = (data['address'] ?? '').toString().trim();
        if (address.isEmpty) continue;
        byAddress.putIfAbsent(address, () => []);
        byAddress[address]!.add(data);
      }

      final vaccinatorIds = assignmentsSnap.docs
          .map((d) => (d.data()['vaccinatorId'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      final vaccinators = await _campaignService.getVaccinatorsByIds(vaccinatorIds);
      final vaccinatorNameById = {
        for (var v in vaccinators) v['id'] as String: v['name'] as String
      };

      final List<Map<String, dynamic>> builtHouseholds = [];
      int totalChildren = 0;
      int totalVaccinated = 0;
      int missingLocation = 0;

      byAddress.forEach((address, items) {
        totalChildren += items.length;
        final vaccinated = items.where((c) => c['status'] == 'Vaccinated').length;
        totalVaccinated += vaccinated;

        double? lat;
        double? lng;
        for (var c in items) {
          if (c['latitude'] is num && c['longitude'] is num) {
            lat = (c['latitude'] as num).toDouble();
            lng = (c['longitude'] as num).toDouble();
            break;
          }
        }

        if (lat == null || lng == null) {
          missingLocation++;
          return; // GPS na hone ki wajah se is household ko map par nahi dikha sakte
        }

        final vaccinatorId = (items.first['vaccinatorId'] ?? '').toString();

        builtHouseholds.add({
          'address': address,
          'totalChildren': items.length,
          'vaccinated': vaccinated,
          'pending': items.length - vaccinated,
          'status': vaccinated == items.length ? 'Completed' : 'Pending',
          'assignedVaccinator': vaccinatorNameById[vaccinatorId] ?? 'Unassigned',
          'location': LatLng(lat, lng),
        });
      });

      String dateRange = '';
      if (campaign != null) {
        dateRange =
            '${_fmtDate(campaign.startDate)} – ${_fmtDate(campaign.endDate)}';
      }

      setState(() {
        _campaignName = campaign?.name ?? 'Campaign';
        _dateRangeStr = dateRange;
        _isActive = campaign != null && DateTime.now().isBefore(campaign.endDate) && campaign.status != 'completed';
        _households = builtHouseholds;
        _totalChildren = totalChildren;
        _totalVaccinated = totalVaccinated;
        _totalHouseholds = byAddress.length;
        _missingLocationHouseholds = missingLocation;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Map data load nahi ho saka: $e';
        _isLoading = false;
      });
    }
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryThemeGreen)),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: primaryThemeGreen,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
      );
    }

    final initialCenter =
        _households.isNotEmpty ? _households.first['location'] as LatLng : _defaultPosition;

    final coverage = _totalChildren > 0 ? ((_totalVaccinated / _totalChildren) * 100).round() : 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryThemeGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Campaign Map',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 15.0,
              onTap: (_, __) {
                setState(() => selectedHousehold = null);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.immunosphere',
              ),
              MarkerLayer(
                markers: _households.map((house) {
                  final bool isPending = house['status'] == 'Pending';
                  return Marker(
                    width: 45.0,
                    height: 45.0,
                    point: house['location'] as LatLng,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => selectedHousehold = house);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6),
                          ],
                        ),
                        child: Icon(
                          Icons.home,
                          color: isPending ? Colors.orange.shade800 : primaryThemeGreen,
                          size: 26,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildCampaignStatsCard(coverage),
          ),

          if (_missingLocationHouseholds > 0)
            Positioned(
              top: selectedHousehold != null ? 0 : null,
              bottom: selectedHousehold == null ? 16 : null,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  '$_missingLocationHouseholds household(s) ki GPS location capture nahi hui, is liye map par nahi dikhengi.',
                  style: TextStyle(color: Colors.orange.shade900, fontSize: 11),
                ),
              ),
            ),

          if (selectedHousehold != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildHouseholdDetailsCard(selectedHousehold!),
            ),
        ],
      ),
    );
  }

  Widget _buildCampaignStatsCard(int coverage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _campaignName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _isActive ? Colors.green.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isActive ? 'Active' : 'Completed',
                  style: TextStyle(
                    color: _isActive ? primaryThemeGreen : Colors.grey.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
          if (_dateRangeStr.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(_dateRangeStr, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('$_totalChildren', 'Children'),
              _statItem('$_totalHouseholds', 'Households'),
              _statItem('$coverage%', 'Coverage'),
            ],
          )
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryThemeGreen)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildHouseholdDetailsCard(Map<String, dynamic> house) {
    final bool isPending = house['status'] == 'Pending';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 2)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  house['address'],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending ? Colors.orange.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  house['status'],
                  style: TextStyle(
                    color: isPending ? Colors.orange.shade800 : primaryThemeGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _detailRow(Icons.face_outlined, 'Total Children', '${house['totalChildren']}'),
          _detailRow(Icons.check_circle_outline, 'Vaccinated', '${house['vaccinated']}'),
          _detailRow(Icons.hourglass_empty_outlined, 'Pending', '${house['pending']}'),
          _detailRow(Icons.person_outline, 'Assigned Vaccinator', house['assignedVaccinator']),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryThemeGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HouseholdDetailsScreen(
                      campaignId: widget.campaignId,
                      houseAddress: house['address'] as String,
                      vaccinatorName: house['assignedVaccinator'] as String,
                    ),
                  ),
                );
              },
              child: const Text(
                'View Details',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }
}