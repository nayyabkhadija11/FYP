import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class VaccinationEntryScreen extends StatefulWidget {
  final Map<String, dynamic>? childData; // ✅ Added optional childData

  const VaccinationEntryScreen({Key? key, this.childData}) : super(key: key);

  @override
  State<VaccinationEntryScreen> createState() => _VaccinationEntryScreenState();
}

class _VaccinationEntryScreenState extends State<VaccinationEntryScreen> {
  String? _selectedChildId;
  String? _selectedVaccine = "Polio Booster Dose";
  String? _selectedDose = "Booster";
  String _status = "Vaccinated";
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final _remarksController = TextEditingController();

  final List<String> _vaccineOptions = [
    "BCG",
    "OPV 0",
    "Pentavalent 1",
    "Pentavalent 2",
    "Pentavalent 3",
    "Polio Booster Dose",
    "Measles 1",
    "Measles 2"
  ];

  final List<String> _doseOptions = ["Dose 1", "Dose 2", "Dose 3", "Booster"];

  @override
  void initState() {
    super.initState();
    // ✅ Auto-select child ID if passed from previous screen
    if (widget.childData != null) {
      _selectedChildId = widget.childData!['id'] ?? 
                         widget.childData!['childId'] ?? 
                         widget.childData!['docId'];
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF3F51B5)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveVaccinationRecord() async {
    if (_selectedChildId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a child'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('vaccinations').add({
        'childId': _selectedChildId,
        'vaccineName': _selectedVaccine,
        'dose': _selectedDose,
        'administeredDate': DateFormat('dd MMM yyyy').format(_selectedDate),
        'status': _status.toLowerCase(), // 'vaccinated', 'missed', 'refused'
        'remarks': _remarksController.text.trim(),
        'administeredBy': user?.uid ?? 'unknown',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record Saved Successfully!'),
            backgroundColor: Color(0xFF3F51B5),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving record: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Vaccination Entry', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CHILD SELECTOR (Dynamic Firestore Fetch)
            const Text('Child', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 6),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('children').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: LinearProgressIndicator());
                }

                var childDocs = snapshot.data!.docs;

                // Make sure selected ID exists in list to avoid dropdown mismatch errors
                bool containsSelected = childDocs.any((doc) => doc.id == _selectedChildId);
                String? validSelectedId = containsSelected ? _selectedChildId : null;

                return DropdownButtonFormField<String>(
                  value: validSelectedId,
                  hint: const Text('Select Child', style: TextStyle(fontSize: 13)),
                  decoration: _dropdownDecoration(),
                  items: childDocs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String childName = data['fullName'] ?? data['name'] ?? 'Child';
                    String regNo = data['regNo'] ?? doc.id.substring(0, 5);
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text('$childName ($regNo)', style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedChildId = val),
                );
              },
            ),
            const SizedBox(height: 16),

            // VACCINE SELECTOR
            const Text('Vaccine', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedVaccine,
              decoration: _dropdownDecoration(),
              items: _vaccineOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (val) => setState(() => _selectedVaccine = val),
            ),
            const SizedBox(height: 16),

            // DOSE SELECTOR
            const Text('Dose', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedDose,
              decoration: _dropdownDecoration(),
              items: _doseOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (val) => setState(() => _selectedDose = val),
            ),
            const SizedBox(height: 16),

            // DATE PICKER
            const Text('Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // STATUS SELECTION
            const Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusOption('Vaccinated', const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _buildStatusOption('Missed', const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                _buildStatusOption('Refused', const Color(0xFFEF4444)),
              ],
            ),
            const SizedBox(height: 16),

            // REMARKS FIELD
            const Text('Remarks (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 6),
            TextField(
              controller: _remarksController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Enter remarks',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // SAVE BUTTON
            ElevatedButton(
              onPressed: _isLoading ? null : _saveVaccinationRecord,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F51B5),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save Record', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildStatusOption(String label, Color activeColor) {
    final isSelected = _status == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _status = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? activeColor : Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}