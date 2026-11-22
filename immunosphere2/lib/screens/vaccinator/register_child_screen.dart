/*import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/notification_writer.dart';

class RegisterChildScreen extends StatefulWidget {
  const RegisterChildScreen({Key? key}) : super(key: key);

  @override
  State<RegisterChildScreen> createState() => _RegisterChildScreenState();
}

class _RegisterChildScreenState extends State<RegisterChildScreen> {
  final _formKey = GlobalKey<FormState>();

  static const Color primaryGreen = Color(0xFF0E9F6E);

  final _nameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _villageController = TextEditingController();
  final _houseAddressController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedDistrict;
  String? _selectedTehsil;
  bool _isLoading = false;
  bool _dateError = false;

  // GPS location capture ke liye — household ko map par plot karne ke
  // liye zaroori hai, kyunke text address se map par pin nahi lagai ja
  // sakti.
  double? _latitude;
  double? _longitude;
  bool _isFetchingLocation = false;
  bool _locationError = false;

  // -----------------------------------------------------------------
  // Punjab Districts -> Tehsils map
  // -----------------------------------------------------------------
  static const Map<String, List<String>> _punjabDistrictTehsils = {
    'Attock': ['Attock', 'Hasan Abdal', 'Hazro', 'Jand', 'Pindi Gheb', 'Fateh Jang'],
    'Bahawalnagar': ['Bahawalnagar', 'Chishtian', 'Fort Abbas', 'Haroonabad', 'Minchinabad'],
    'Bahawalpur': ['Bahawalpur City', 'Bahawalpur Saddar', 'Ahmedpur East', 'Hasilpur', 'Khairpur Tamewali', 'Yazman'],
    'Bhakkar': ['Bhakkar', 'Darya Khan', 'Kaloorkot', 'Mankera'],
    'Chakwal': ['Chakwal', 'Choa Saidan Shah', 'Kallar Kahar', 'Talagang'],
    'Chiniot': ['Chiniot', 'Bhawana', 'Lalian'],
    'Dera Ghazi Khan': ['Dera Ghazi Khan', 'Taunsa', 'Kot Chutta'],
    'Faisalabad': ['Faisalabad City', 'Faisalabad Sadar', 'Jaranwala', 'Samundri', 'Tandlianwala', 'Chak Jhumra'],
    'Gujranwala': ['Gujranwala City', 'Gujranwala Saddar', 'Kamoke', 'Nowshera Virkan', 'Wazirabad'],
    'Gujrat': ['Gujrat', 'Kharian', 'Sarai Alamgir'],
    'Hafizabad': ['Hafizabad', 'Pindi Bhattian'],
    'Jhang': ['Jhang', 'Ahmadpur Sial', 'Shorkot', '18 Hazari'],
    'Jhelum': ['Jhelum', 'Dina', 'Pind Dadan Khan', 'Sohawa'],
    'Kasur': ['Kasur', 'Chunian', 'Kot Radha Kishan', 'Pattoki'],
    'Khanewal': ['Khanewal', 'Jahanian', 'Kabirwala', 'Mian Channu'],
    'Khushab': ['Khushab', 'Naushera', 'Noorpur Thal', 'Quaidabad'],
    'Lahore': ['Aziz Bhatti', 'Data Ganj Baksh', 'Gulberg', 'Model Town', 'Nishtar', 'Ravi', 'Samanabad', 'Shalimar', 'Wagha'],
    'Layyah': ['Layyah', 'Chaubara', 'Karor Lal Esan'],
    'Lodhran': ['Lodhran', 'Dunyapur', 'Kahror Pakka'],
    'Mandi Bahauddin': ['Mandi Bahauddin', 'Malikwal', 'Phalia'],
    'Mianwali': ['Mianwali', 'Isakhel', 'Piplan'],
    'Multan': ['Multan City', 'Multan Saddar', 'Shujabad', 'Jalalpur Pirwala'],
    'Muzaffargarh': ['Muzaffargarh', 'Alipur', 'Jatoi', 'Kot Addu'],
    'Nankana Sahib': ['Nankana Sahib', 'Sangla Hill', 'Shahkot'],
    'Narowal': ['Narowal', 'Shakargarh', 'Zafarwal'],
    'Okara': ['Okara', 'Depalpur', 'Renala Khurd'],
    'Pakpattan': ['Pakpattan', 'Arifwala'],
    'Rahim Yar Khan': ['Rahim Yar Khan', 'Khanpur', 'Liaquatpur', 'Sadiqabad'],
    'Rajanpur': ['Rajanpur', 'Jampur', 'Rojhan'],
    'Rawalpindi': ['Rawalpindi', 'Gujar Khan', 'Kahuta', 'Kallar Syedan', 'Kotli Sattian', 'Murree', 'Taxila'],
    'Sahiwal': ['Sahiwal', 'Chichawatni'],
    'Sargodha': ['Sargodha', 'Bhalwal', 'Kot Momin', 'Sahiwal (Sargodha)', 'Shahpur', 'Sillanwali'],
    'Sheikhupura': ['Sheikhupura', 'Ferozewala', 'Muridke', 'Sharaqpur'],
    'Sialkot': ['Sialkot', 'Daska', 'Pasrur', 'Sambrial'],
    'Toba Tek Singh': ['Toba Tek Singh', 'Gojra', 'Kamalia', 'Pirmahal'],
    'Vehari': ['Vehari', 'Burewala', 'Mailsi'],
  };

  List<String> get _tehsilOptions =>
      _selectedDistrict != null ? _punjabDistrictTehsils[_selectedDistrict!] ?? [] : [];

  String _generateChildId() {
    final random = Random();
    final number = random.nextInt(900000) + 100000;
    return 'CH-$number';
  }

  // Dynamic Age Formatter (Handles Months and Years accurately)
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

  // NEW: household ka GPS location capture karta hai — yeh location
  // baad mein Campaign Map screen par household ki pin lagane ke liye
  // use hoti hai. Address text se map par accurately pin nahi lagai ja
  // sakti, isliye yeh field zaroori hai.
  Future<void> _captureLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location/GPS band hai, pehle usay on karein.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission nahi di gai. Settings se allow karein.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationError = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location capture nahi ho saki: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _registerChild() async {
    if (_selectedDate == null) {
      setState(() => _dateError = true);
    }
    if (_latitude == null || _longitude == null) {
      setState(() => _locationError = true);
    }

    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedGender == null ||
        _selectedDistrict == null ||
        _selectedTehsil == null ||
        _latitude == null ||
        _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields correctly.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final childId = _generateChildId();
      final formattedAge = _calculateFormattedAge(_selectedDate!);
      final childName = _nameController.text.trim();
      final villageName = _villageController.text.trim().isNotEmpty
          ? _villageController.text.trim()
          : 'N/A';
      final houseAddress = _houseAddressController.text.trim();
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final parentCnic = _cnicController.text.replaceAll('-', '').trim();

      final String fullAddress = [
        if (houseAddress.isNotEmpty) houseAddress,
        villageName,
        _selectedTehsil,
        _selectedDistrict,
      ].where((part) => part != null && part.toString().trim().isNotEmpty).join(', ');

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
        'district': _selectedDistrict,
        'tehsil': _selectedTehsil,
        'village': villageName,
        'houseAddress': houseAddress,
        'address': fullAddress,
        'latitude': _latitude,
        'longitude': _longitude,
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

      // NEW: parent ko "Child Registered" notification (Cloud Functions
      // ke baghair, app khud `notifications` me doc likhti hai)
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
          backgroundColor: const Color(0xFF10B981),
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
    _nameController.dispose();
    _motherNameController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _villageController.dispose();
    _houseAddressController.dispose();
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

                const Text('District *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedDistrict,
                  decoration: _inputDecoration('Select district', icon: Icons.location_city_outlined),
                  isExpanded: true,
                  items: _punjabDistrictTehsils.keys
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedDistrict = val;
                      _selectedTehsil = null;
                    });
                  },
                  validator: (v) => v == null ? 'Please select district' : null,
                ),
                const SizedBox(height: 16),

                const Text('Tehsil *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedTehsil,
                  decoration: _inputDecoration('Select tehsil', icon: Icons.map_outlined),
                  isExpanded: true,
                  items: _tehsilOptions
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: _selectedDistrict == null
                      ? null
                      : (val) => setState(() => _selectedTehsil = val),
                  validator: (v) => v == null ? 'Please select tehsil' : null,
                ),
                const SizedBox(height: 16),

                const Text('Village / Mohallah *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _villageController,
                  decoration: _inputDecoration('Enter village or mohallah name', icon: Icons.home_outlined),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter village or mohallah' : null,
                ),
                const SizedBox(height: 16),

                const Text('House No. / Street Address *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _houseAddressController,
                  decoration: _inputDecoration('Enter house no. / street address', icon: Icons.house_outlined),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Please enter house number / street address'
                      : null,
                ),
                const SizedBox(height: 16),

                // NEW: GPS location capture — is se household ko Campaign
                // Map screen par asal position par pin lagana mumkin hota
                // hai. Bina is ke, sirf text address se map par pin nahi
                // dikhai ja sakti.
                const Text('Household GPS Location *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: _locationError ? Colors.red : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.my_location_outlined, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _latitude == null || _longitude == null
                              ? 'Location abhi capture nahi hui'
                              : '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                          style: TextStyle(
                            color: _latitude == null ? Colors.grey : Colors.black,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _isFetchingLocation ? null : _captureLocation,
                        icon: _isFetchingLocation
                            ? const SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: primaryGreen),
                              )
                            : const Icon(Icons.gps_fixed, size: 16, color: primaryGreen),
                        label: Text(
                          _latitude == null ? 'Capture' : 'Re-capture',
                          style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_locationError)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 12),
                    child: Text('Household ki GPS location capture karna zaroori hai',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
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
} */
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/notification_writer.dart';

class RegisterChildScreen extends StatefulWidget {
  const RegisterChildScreen({Key? key}) : super(key: key);

  @override
  State<RegisterChildScreen> createState() => _RegisterChildScreenState();
}

class _RegisterChildScreenState extends State<RegisterChildScreen> {
  final _formKey = GlobalKey<FormState>();

  // CHANGED: deep green (pehle 0xFF0E9F6E tha)
  static const Color primaryGreen = Color(0xFF065F46);

  final _nameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _houseAddressController = TextEditingController();
  final _villageController = TextEditingController(); // Attock ke bahar ke areas ke liye

  DateTime? _selectedDate;
  String? _selectedGender;
  // Default Attock hai (DHQ Attock vaccination center), lekin user badal sakta hai.
  String? _selectedDistrict = 'Attock';
  String? _selectedTehsil = 'Attock';
  // NEW: Attock ki colonies dropdown ke liye
  String? _selectedColony;
  bool _isLoading = false;
  bool _dateError = false;

  // GPS location capture ke liye — household ko map par plot karne ke
  // liye zaroori hai, kyunke text address se map par pin nahi lagai ja
  // sakti.
  double? _latitude;
  double? _longitude;
  bool _locationError = false;
  // Ghar ki location ab sirf map par pin se aati hai
  final MapController _mapController = MapController();

  // NEW: Attock ki colonies
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

  // NEW: Attock city ka center aur har colony ka center. Colony select
  // karte hi map yahan move hota hai.
  // TODO: har colony ke asal coordinates yahan daal dein (Google Maps /
  // OpenStreetMap par colony ke beech mein long-press karke lat,lng copy
  // karein). Jab tak alag coordinates nahi daale, map Attock city center
  // par hi khulega.
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

  // -----------------------------------------------------------------
  // Punjab Districts -> Tehsils map
  // -----------------------------------------------------------------
  static const Map<String, List<String>> _punjabDistrictTehsils = {
    'Attock': ['Attock', 'Hasan Abdal', 'Hazro', 'Jand', 'Pindi Gheb', 'Fateh Jang'],
    'Bahawalnagar': ['Bahawalnagar', 'Chishtian', 'Fort Abbas', 'Haroonabad', 'Minchinabad'],
    'Bahawalpur': ['Bahawalpur City', 'Bahawalpur Saddar', 'Ahmedpur East', 'Hasilpur', 'Khairpur Tamewali', 'Yazman'],
    'Bhakkar': ['Bhakkar', 'Darya Khan', 'Kaloorkot', 'Mankera'],
    'Chakwal': ['Chakwal', 'Choa Saidan Shah', 'Kallar Kahar', 'Talagang'],
    'Chiniot': ['Chiniot', 'Bhawana', 'Lalian'],
    'Dera Ghazi Khan': ['Dera Ghazi Khan', 'Taunsa', 'Kot Chutta'],
    'Faisalabad': ['Faisalabad City', 'Faisalabad Sadar', 'Jaranwala', 'Samundri', 'Tandlianwala', 'Chak Jhumra'],
    'Gujranwala': ['Gujranwala City', 'Gujranwala Saddar', 'Kamoke', 'Nowshera Virkan', 'Wazirabad'],
    'Gujrat': ['Gujrat', 'Kharian', 'Sarai Alamgir'],
    'Hafizabad': ['Hafizabad', 'Pindi Bhattian'],
    'Jhang': ['Jhang', 'Ahmadpur Sial', 'Shorkot', '18 Hazari'],
    'Jhelum': ['Jhelum', 'Dina', 'Pind Dadan Khan', 'Sohawa'],
    'Kasur': ['Kasur', 'Chunian', 'Kot Radha Kishan', 'Pattoki'],
    'Khanewal': ['Khanewal', 'Jahanian', 'Kabirwala', 'Mian Channu'],
    'Khushab': ['Khushab', 'Naushera', 'Noorpur Thal', 'Quaidabad'],
    'Lahore': ['Aziz Bhatti', 'Data Ganj Baksh', 'Gulberg', 'Model Town', 'Nishtar', 'Ravi', 'Samanabad', 'Shalimar', 'Wagha'],
    'Layyah': ['Layyah', 'Chaubara', 'Karor Lal Esan'],
    'Lodhran': ['Lodhran', 'Dunyapur', 'Kahror Pakka'],
    'Mandi Bahauddin': ['Mandi Bahauddin', 'Malikwal', 'Phalia'],
    'Mianwali': ['Mianwali', 'Isakhel', 'Piplan'],
    'Multan': ['Multan City', 'Multan Saddar', 'Shujabad', 'Jalalpur Pirwala'],
    'Muzaffargarh': ['Muzaffargarh', 'Alipur', 'Jatoi', 'Kot Addu'],
    'Nankana Sahib': ['Nankana Sahib', 'Sangla Hill', 'Shahkot'],
    'Narowal': ['Narowal', 'Shakargarh', 'Zafarwal'],
    'Okara': ['Okara', 'Depalpur', 'Renala Khurd'],
    'Pakpattan': ['Pakpattan', 'Arifwala'],
    'Rahim Yar Khan': ['Rahim Yar Khan', 'Khanpur', 'Liaquatpur', 'Sadiqabad'],
    'Rajanpur': ['Rajanpur', 'Jampur', 'Rojhan'],
    'Rawalpindi': ['Rawalpindi', 'Gujar Khan', 'Kahuta', 'Kallar Syedan', 'Kotli Sattian', 'Murree', 'Taxila'],
    'Sahiwal': ['Sahiwal', 'Chichawatni'],
    'Sargodha': ['Sargodha', 'Bhalwal', 'Kot Momin', 'Sahiwal (Sargodha)', 'Shahpur', 'Sillanwali'],
    'Sheikhupura': ['Sheikhupura', 'Ferozewala', 'Muridke', 'Sharaqpur'],
    'Sialkot': ['Sialkot', 'Daska', 'Pasrur', 'Sambrial'],
    'Toba Tek Singh': ['Toba Tek Singh', 'Gojra', 'Kamalia', 'Pirmahal'],
    'Vehari': ['Vehari', 'Burewala', 'Mailsi'],
  };

  List<String> get _tehsilOptions =>
      _selectedDistrict != null ? _punjabDistrictTehsils[_selectedDistrict!] ?? [] : [];

  String _generateChildId() {
    final random = Random();
    final number = random.nextInt(900000) + 100000;
    return 'CH-$number';
  }

  // Dynamic Age Formatter (Handles Months and Years accurately)
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

  // Colonies ki dropdown sirf Attock district + Attock tehsil ke liye hai.
  bool get _isAttockCity => _selectedDistrict == 'Attock' && _selectedTehsil == 'Attock';

  void _clearPin() {
    _latitude = null;
    _longitude = null;
  }

  // District badalne par tehsil/colony reset hoti hai; Attock ho to map
  // Attock par move hota hai.
  void _onDistrictChanged(String? district) {
    setState(() {
      _selectedDistrict = district;
      _selectedTehsil = null;
      _selectedColony = null;
      _villageController.clear();
      _clearPin();
    });
    if (district == 'Attock') {
      _mapController.move(_attockCenter, 13.0);
    }
  }

  // Tehsil "Attock" select ho to Attock city ka map aata hai.
  void _onTehsilChanged(String? tehsil) {
    setState(() {
      _selectedTehsil = tehsil;
      _selectedColony = null;
      _villageController.clear();
      _clearPin();
    });
    if (_selectedDistrict == 'Attock' && tehsil == 'Attock') {
      _mapController.move(_attockCenter, 14.0);
    }
  }

  // Colony select hone par map us colony par move hota hai aur purani pin
  // hata di jati hai (taake pin galat colony mein na rahe).
  void _onColonyChanged(String? colony) {
    setState(() {
      _selectedColony = colony;
      _clearPin();
    });
    if (colony != null) {
      _mapController.move(_colonyCenters[colony] ?? _attockCenter, 16.0);
    }
  }

  Future<void> _registerChild() async {
    if (_selectedDate == null) {
      setState(() => _dateError = true);
    }
    if (_latitude == null || _longitude == null) {
      setState(() => _locationError = true);
    }

    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedGender == null ||
        _selectedDistrict == null ||
        _selectedTehsil == null ||
        _latitude == null ||
        _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields correctly.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final childId = _generateChildId();
      final formattedAge = _calculateFormattedAge(_selectedDate!);
      final childName = _nameController.text.trim();
      // CHANGED: colony dropdown se aati hai. Firestore field ka naam
      // 'village' hi rakha hai taake baqi screens/reports na tootein.
      final villageName = _isAttockCity
          ? (_selectedColony ?? 'N/A')
          : (_villageController.text.trim().isNotEmpty ? _villageController.text.trim() : 'N/A');
      final houseAddress = _houseAddressController.text.trim();
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final parentCnic = _cnicController.text.replaceAll('-', '').trim();

      final String fullAddress = [
        if (houseAddress.isNotEmpty) houseAddress,
        villageName,
        _selectedTehsil,
        _selectedDistrict,
      ].where((part) => part != null && part.toString().trim().isNotEmpty).join(', ');

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
        'district': _selectedDistrict,
        'tehsil': _selectedTehsil,
        'village': villageName,
        'houseAddress': houseAddress,
        'address': fullAddress,
        'latitude': _latitude,
        'longitude': _longitude,
        'locationSource': 'map_pin',
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

      // NEW: parent ko "Child Registered" notification (Cloud Functions
      // ke baghair, app khud `notifications` me doc likhti hai)
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
    _nameController.dispose();
    _motherNameController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _houseAddressController.dispose();
    _villageController.dispose();
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

                const Text('District *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedDistrict,
                  decoration: _inputDecoration('Select district', icon: Icons.location_city_outlined),
                  isExpanded: true,
                  items: _punjabDistrictTehsils.keys
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: _onDistrictChanged,
                  validator: (v) => v == null ? 'Please select district' : null,
                ),
                const SizedBox(height: 16),

                const Text('Tehsil *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedTehsil,
                  decoration: _inputDecoration('Select tehsil', icon: Icons.map_outlined),
                  isExpanded: true,
                  items: _tehsilOptions
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: _selectedDistrict == null ? null : _onTehsilChanged,
                  validator: (v) => v == null ? 'Please select tehsil' : null,
                ),
                const SizedBox(height: 16),

                // Attock city: colonies ki dropdown. Baqi areas: free text.
                const Text('Village / Mohallah *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                if (_isAttockCity)
                  DropdownButtonFormField<String>(
                    value: _selectedColony,
                    decoration: _inputDecoration('Select village or mohallah', icon: Icons.home_outlined),
                    isExpanded: true,
                    items: _attockColonies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: _onColonyChanged,
                    validator: (v) => v == null ? 'Please select village or mohallah' : null,
                  )
                else
                  TextFormField(
                    controller: _villageController,
                    decoration: _inputDecoration('Enter village or mohallah name', icon: Icons.home_outlined),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter village or mohallah' : null,
                  ),
                const SizedBox(height: 16),

                const Text('House No. / Street Address *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _houseAddressController,
                  decoration: _inputDecoration('Enter house no. / street address', icon: Icons.house_outlined),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Please enter house number / street address'
                      : null,
                ),
                const SizedBox(height: 16),

                // CHANGED: Capture button hata diya. Ab colony select karte hi
                // map us colony par khulta hai, aur vaccinator ghar par ek tap
                // se pin laga deta hai. Yehi location supervisor ke Campaign
                // Map par household ki position banti hai.
                const Text('Household Location *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  _isAttockCity && _selectedColony == null
                      ? 'Select a colony first, then tap the house location on the map.'
                      : 'Zoom in on the map and tap the house location.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    border: Border.all(color: _locationError ? Colors.red : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _attockCenter,
                      initialZoom: 14.0,
                      onTap: (_, point) {
                        if (_selectedDistrict == null || _selectedTehsil == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select district and tehsil first.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _latitude = point.latitude;
                          _longitude = point.longitude;
                          _locationError = false;
                        });
                      },
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
                              // icon upar, neeche khali jagah: is se pin ki nok
                              // bilkul tap ki jagah par aati hai
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
                          'Location selected: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                          style: const TextStyle(fontSize: 12, color: primaryGreen),
                        ),
                      ],
                    ),
                  ),
                if (_locationError)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 12),
                    child: Text('Please tap the map to mark the household location',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
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