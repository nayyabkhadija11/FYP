import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../services/notification_writer.dart';

class RegisterChildScreen extends StatefulWidget {
  const RegisterChildScreen({Key? key}) : super(key: key);

  @override
  State<RegisterChildScreen> createState() => _RegisterChildScreenState();
}

class _RegisterChildScreenState extends State<RegisterChildScreen> {
  final _formKey = GlobalKey<FormState>();

  static const Color primaryGreen = Color(0xFF065F46);

  // Health center DHQ Attock hai, is liye district/tehsil fix hain
  static const String _healthCenter = 'DHQ Attock';
  static const String _district = 'Attock';
  static const String _tehsil = 'Attock';

  final _nameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _houseAddressController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedColony;
  bool _isLoading = false;
  bool _dateError = false;

  double? _latitude;
  double? _longitude;
  final MapController _mapController = MapController();

  // Auto geocoding state
  bool _isGeocoding = false;
  String? _geocodeMessage;
  Timer? _geocodeDebounce;
  int _geocodeRequestId = 0;

  static const List<String> _attockColonies = [
    'Farooq-e-Azam Colony',
    'Peoples Colony',
    'Dar-ul-Islam Colony',
    'Mehrpura Sharqi',
    'Mehrpura Gharbi',
    'Madni Colony',
    'Awan Sharif',
    'Khattak Colony',
    'Hamza Town',
    'New Town',
  ];

  static const LatLng _attockCenter = LatLng(33.7667, 72.3609);
  static const Map<String, LatLng> _colonyCenters = {
    'Farooq-e-Azam Colony': _attockCenter,
    'Peoples Colony': _attockCenter,
    'Dar-ul-Islam Colony': _attockCenter,
    'Mehrpura Sharqi': _attockCenter,
    'Mehrpura Gharbi': _attockCenter,
    'Madni Colony': _attockCenter,
    'Awan Sharif': _attockCenter,
    'Khattak Colony': _attockCenter,
    'Hamza Town': _attockCenter,
    'New Town': _attockCenter,
  };

  String _generateChildId() {
    final random = Random();
    final number = random.nextInt(900000) + 100000;
    return 'CH-$number';
  }

  String _calculateFormattedAge(DateTime dob) {
    final now = DateTime.now();
    int years = now.year - dob.year;
    int months = now.month - dob.month;
    int days = now.day - dob.day;

    if (days < 0) {
      months -= 1;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }

    if (years > 0) {
      return '$years Year${years > 1 ? 's' : ''}${months > 0 ? ' $months Mon' : ''}';
    } else if (months > 0) {
      return '$months Month${months > 1 ? 's' : ''}';
    } else {
      return 'Newborn';
    }
  }

  // Naam compare karne ke liye: lowercase + extra spaces khatam
  String _normalizeName(String s) {
    return s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  // Same CNIC par same naam ka bacha pehle se registered hai?
  Future<bool> _childAlreadyExists(String cnic, String name) async {
    final snap = await FirebaseFirestore.instance
        .collection('children')
        .where('cnic', isEqualTo: cnic)
        .get();
    final target = _normalizeName(name);
    for (final doc in snap.docs) {
      final d = doc.data();
      final existing = _normalizeName((d['fullName'] ?? d['name'] ?? '').toString());
      if (existing == target) return true;
    }
    return false;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateError = false;
      });
    }
  }

  // Colony select hote hi pin foran colony par lag jata hai,
  // phir geocoding se behtar jagah mil jaye to pin wahan chala jata hai.
  void _onColonyChanged(String? colony) {
    if (colony == null) return;
    final c = _colonyCenters[colony] ?? _attockCenter;
    setState(() {
      _selectedColony = colony;
      _latitude = c.latitude;
      _longitude = c.longitude;
      _geocodeMessage = 'Pin set automatically at the selected area.';
    });
    _mapController.move(c, 16.0);
    _scheduleGeocode();
  }

  // User ke likhna band karne ke 1 second baad search karein
  void _scheduleGeocode() {
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(seconds: 1), _geocodeAddress);
  }

  // Address se location dhundta hai (Nominatim / OpenStreetMap)
  Future<void> _geocodeAddress() async {
    final house = _houseAddressController.text.trim();
    final area = _selectedColony ?? '';
    if (area.isEmpty) return;

    final requestId = ++_geocodeRequestId;
    setState(() {
      _isGeocoding = true;
    });

    final queries = <List<dynamic>>[
      if (house.length >= 3)
        ['$house, $area, $_tehsil, $_district, Punjab, Pakistan', 17.0, 'exact'],
      ['$area, $_tehsil, $_district, Punjab, Pakistan', 16.0, 'area'],
      ['$area, $_district, Pakistan', 16.0, 'area'],
    ];

    try {
      for (final q in queries) {
        final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
          'q': q[0] as String,
          'format': 'json',
          'limit': '1',
          'countrycodes': 'pk',
        });
        final response = await http.get(uri, headers: {
          'User-Agent': 'com.example.immunosphere',
        }).timeout(const Duration(seconds: 10));

        if (!mounted || requestId != _geocodeRequestId) return;
        if (response.statusCode != 200) continue;
        final List results = jsonDecode(response.body);
        if (results.isEmpty) continue;

        final lat = double.parse(results[0]['lat']);
        final lon = double.parse(results[0]['lon']);
        final level = q[2] as String;

        setState(() {
          _latitude = lat;
          _longitude = lon;
          _geocodeMessage = level == 'exact'
              ? 'Location found automatically from address.'
              : 'Pin set automatically at the selected area.';
        });
        _mapController.move(LatLng(lat, lon), q[1] as double);
        return;
      }
      // Kuch na mila: colony wala pin (jo pehle se laga hai) hi rehta hai.
    } catch (_) {
      // Internet masla ho to bhi colony wala pin rehta hai.
    } finally {
      if (mounted && requestId == _geocodeRequestId) {
        setState(() => _isGeocoding = false);
      }
    }
  }

  Future<void> _registerChild() async {
    if (_selectedDate == null) {
      setState(() => _dateError = true);
    }

    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedGender == null ||
        _selectedColony == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields correctly.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Pin hamesha auto lagta hai; phir bhi safety ke liye colony ka center
    final fallback = _colonyCenters[_selectedColony] ?? _attockCenter;
    final lat = _latitude ?? fallback.latitude;
    final lng = _longitude ?? fallback.longitude;

    setState(() => _isLoading = true);

    try {
      final childName = _nameController.text.trim();
      final parentCnic = _cnicController.text.replaceAll('-', '').trim();

      // Duplicate check: same CNIC + same child name
      final exists = await _childAlreadyExists(parentCnic, childName);
      if (exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'A child named "$childName" is already registered under this CNIC. Please use a different name.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      final childId = _generateChildId();
      final formattedAge = _calculateFormattedAge(_selectedDate!);
      final villageName = _selectedColony ?? 'N/A';
      final houseAddress = _houseAddressController.text.trim();
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

      final String fullAddress = [
        if (houseAddress.isNotEmpty) houseAddress,
        villageName,
        _tehsil,
        _district,
      ].join(', ');

      final WriteBatch batch = FirebaseFirestore.instance.batch();

      DocumentReference childDocRef = FirebaseFirestore.instance.collection('children').doc(childId);
      batch.set(childDocRef, {
        'regNo': childId,
        'childId': childId,
        'fullName': childName,
        'name': childName,
        'dob': Timestamp.fromDate(_selectedDate!),
        'age': formattedAge,
        'gender': _selectedGender,
        'motherName': _motherNameController.text.trim(),
        'cnic': parentCnic,
        'phoneNumber': _phoneController.text.trim(),
        'district': _district,
        'tehsil': _tehsil,
        'healthCenter': _healthCenter,
        'village': villageName,
        'houseAddress': houseAddress,
        'address': fullAddress,
        'latitude': lat,
        'longitude': lng,
        'locationSource': 'auto_geocode',
        'registeredAt': FieldValue.serverTimestamp(),
        'registeredBy': currentUserId,
        'status': 'Due Today',
        'nextDue': 'BCG, OPV-0, Hep-B',
      });

      DocumentReference taskDocRef = FirebaseFirestore.instance.collection('vaccination_tasks').doc();
      batch.set(taskDocRef, {
        'taskId': taskDocRef.id,
        'childId': childId,
        'childName': childName,
        'cnic': parentCnic,
        'vaccineName': 'BCG, OPV-0, Hep-B (At Birth)',
        'vaccines': 'BCG, OPV-0, Hep-B (At Birth)',
        'village': villageName,
        'ageFormatted': formattedAge,
        'status': 'dueToday',
        'taskType': 'routine',
        'createdAt': FieldValue.serverTimestamp(),
        'administeredBy': currentUserId,
      });

      NotificationWriter.addToBatch(
        batch,
        cnic: parentCnic,
        title: 'Child Registered',
        message: '$childName has been successfully registered for vaccination tracking.',
        childId: childId,
      );

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Child Registered Successfully! ID: $childId'),
          backgroundColor: primaryGreen,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _nameController.dispose();
    _motherNameController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _houseAddressController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Register New Child',
          style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Child Full Name *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration('Enter child full name', icon: Icons.person_outline),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter child name' : null,
                ),
                const SizedBox(height: 16),

                const Text('Date of Birth *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: _dateError ? Colors.red : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedDate == null
                                ? 'Select date of birth'
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            style: TextStyle(color: _selectedDate == null ? Colors.grey : Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_dateError)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 12),
                    child: Text('Date of birth is required', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                const SizedBox(height: 16),

                const Text('Gender *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: _inputDecoration('Select gender', icon: Icons.wc_outlined),
                  items: ['Male', 'Female'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (val) => setState(() => _selectedGender = val),
                  validator: (v) => v == null ? 'Please select gender' : null,
                ),
                const SizedBox(height: 16),

                const Text('Mother / Guardian Name *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _motherNameController,
                  decoration: _inputDecoration('Enter mother or guardian name', icon: Icons.person_outline),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required field' : null,
                ),
                const SizedBox(height: 16),

                const Text('Mother / Guardian CNIC *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _cnicController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13)],
                  decoration: _inputDecoration('13-digit CNIC (without dashes)', icon: Icons.badge_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'CNIC is required';
                    if (v.trim().length != 13) return 'CNIC must be 13 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                const Text('Phone Number *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                  decoration: _inputDecoration('03xxxxxxxxxx', icon: Icons.phone_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Phone number is required';
                    if (v.trim().length != 11) return 'Enter valid 11-digit phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                Row(
                  children: const [
                    Icon(Icons.location_on_outlined, color: primaryGreen, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Address Information',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Health center (fixed)
                const Text('Health Center', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                _readOnlyField(_healthCenter, Icons.local_hospital_outlined),
                const SizedBox(height: 16),

                // District & Tehsil (fixed, DHQ Attock ke mutabiq)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('District', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          _readOnlyField(_district, Icons.location_city_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tehsil', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          _readOnlyField(_tehsil, Icons.map_outlined),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text('Village / Mohallah *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedColony,
                  decoration: _inputDecoration('Select village or mohallah', icon: Icons.home_outlined),
                  isExpanded: true,
                  items: _attockColonies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: _onColonyChanged,
                  validator: (v) => v == null ? 'Please select village or mohallah' : null,
                ),
                const SizedBox(height: 16),

                const Text('House No. / Street Address *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _houseAddressController,
                  onChanged: (_) => _scheduleGeocode(),
                  decoration: _inputDecoration('Enter house no. / street address', icon: Icons.house_outlined),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Please enter house number / street address'
                      : null,
                ),
                const SizedBox(height: 16),

                const Text('Household Location (automatic)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'The pin is placed automatically from the selected area and address.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: const MapOptions(
                      initialCenter: _attockCenter,
                      initialZoom: 14.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.immunosphere',
                      ),
                      if (_latitude != null && _longitude != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 44,
                              height: 88,
                              point: LatLng(_latitude!, _longitude!),
                              child: Column(
                                children: const [
                                  Icon(Icons.location_on, color: Colors.red, size: 44),
                                  SizedBox(height: 44),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (_latitude != null && _longitude != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: primaryGreen),
                        const SizedBox(width: 6),
                        Text(
                          'Location set: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                          style: const TextStyle(fontSize: 12, color: primaryGreen),
                        ),
                      ],
                    ),
                  ),
                if (_isGeocoding)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: primaryGreen),
                        ),
                        SizedBox(width: 8),
                        Text('Finding location...', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  )
                else if (_geocodeMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      _geocodeMessage!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                const SizedBox(height: 32),

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _registerChild,
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.person_add_alt_1, color: Colors.white, size: 20),
                  label: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Register Child', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Sirf dikhane wali (edit na hone wali) field
  Widget _readOnlyField(String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey.shade600) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryGreen)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
    );
  }
}