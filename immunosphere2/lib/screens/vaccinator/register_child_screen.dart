import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegisterChildScreen extends StatefulWidget {
  const RegisterChildScreen({Key? key}) : super(key: key);

  @override
  State<RegisterChildScreen> createState() => _RegisterChildScreenState();
}

class _RegisterChildScreenState extends State<RegisterChildScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _villageController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedGender;
  bool _isLoading = false;
  bool _dateError = false;

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

  Future<void> _registerChild() async {
    if (_selectedDate == null) {
      setState(() => _dateError = true);
    }

    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedGender == null) {
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
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

      final WriteBatch batch = FirebaseFirestore.instance.batch();

      // 1. Save Child Profile Document
      DocumentReference childDocRef = FirebaseFirestore.instance.collection('children').doc(childId);
      batch.set(childDocRef, {
        'regNo': childId,
        'childId': childId,
        'fullName': childName,
        'name': childName,
        'dob': Timestamp.fromDate(_selectedDate!), // Changed to Timestamp for Firestore queries
        'age': formattedAge,
        'gender': _selectedGender,
        'motherName': _motherNameController.text.trim(),
        'cnic': _cnicController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'village': villageName,
        'registeredAt': FieldValue.serverTimestamp(),
        'registeredBy': currentUserId,
        'status': 'Due Today',
        'nextDue': 'BCG, OPV-0, Hep-B',
      });

      // 2. Automatically Create Initial Vaccination Task for Dashboard
      DocumentReference taskDocRef = FirebaseFirestore.instance.collection('vaccination_tasks').doc();
      batch.set(taskDocRef, {
        'taskId': taskDocRef.id,
        'childId': childId,
        'childName': childName,
        'vaccineName': 'BCG, OPV-0, Hep-B (At Birth)',
        'vaccines': 'BCG, OPV-0, Hep-B (At Birth)',
        'village': villageName,
        'ageFormatted': formattedAge,
        'status': 'dueToday',
        'taskType': 'routine',
        'createdAt': FieldValue.serverTimestamp(),
        'administeredBy': currentUserId,
      });

      // Commit both writes atomically
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Register New Child', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // CHILD NAME
                const Text('Child Full Name *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration('Enter child full name'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter child name' : null,
                ),
                const SizedBox(height: 16),

                // DATE OF BIRTH
                const Text('Date of Birth *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: _dateError ? Colors.red : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate == null ? 'Select date of birth' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          style: TextStyle(color: _selectedDate == null ? Colors.grey : Colors.black),
                        ),
                        const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey),
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

                // GENDER DROPDOWN
                const Text('Gender *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: _inputDecoration('Select gender'),
                  items: ['Male', 'Female'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (val) => setState(() => _selectedGender = val),
                  validator: (v) => v == null ? 'Please select gender' : null,
                ),
                const SizedBox(height: 16),

                // MOTHER NAME
                const Text('Mother / Guardian Name *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _motherNameController,
                  decoration: _inputDecoration('Enter mother or guardian name'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required field' : null,
                ),
                const SizedBox(height: 16),

                // MOTHER CNIC
                const Text('Mother / Guardian CNIC *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _cnicController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13)],
                  decoration: _inputDecoration('13-digit CNIC (without dashes)'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'CNIC is required';
                    if (v.trim().length != 13) return 'CNIC must be 13 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // PHONE NUMBER
                const Text('Phone Number *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                  decoration: _inputDecoration('03xxxxxxxxxx'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Phone number is required';
                    if (v.trim().length != 11) return 'Enter valid 11-digit phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // VILLAGE / LOCATION
                const Text('Village / Union Council', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _villageController,
                  decoration: _inputDecoration('Enter village or area name'),
                ),
                const SizedBox(height: 32),

                // SUBMIT BUTTON
                ElevatedButton(
                  onPressed: _isLoading ? null : _registerChild,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C33CF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Register Child', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF5C33CF))),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red)),
    );
  }
}