import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class VaccinationEntryScreen extends StatefulWidget {
  final Map<String, dynamic>? childData;

  const VaccinationEntryScreen({Key? key, this.childData}) : super(key: key);

  @override
  State<VaccinationEntryScreen> createState() => _VaccinationEntryScreenState();
}

class _VaccinationEntryScreenState extends State<VaccinationEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedChildDocId;
  
  String? _selectedVaccine;
  String? _selectedDose;
  DateTime? _selectedDate; 
  
  String _status = "Vaccinated";
  bool _isLoading = false;

  final TextEditingController _remarksController = TextEditingController();

  final List<String> _vaccineOptions = [
    'BCG',
    'OPV-0',
    'OPV-1',
    'OPV-2',
    'OPV-3',
    'Pentavalent-1',
    'Pentavalent-2',
    'Pentavalent-3',
    'PCV-1',
    'PCV-2',
    'PCV-3',
    'Rotavirus-1',
    'Rotavirus-2',
    'IPV-1',
    'IPV-2',
    'Measles-Rubella (MR-1)',
    'Measles-Rubella (MR-2)',
    'TCV (Typhoid)',
  ];

  final List<String> _doseOptions = ["Dose 1", "Dose 2", "Dose 3", "Booster"];

  @override
  void initState() {
    super.initState();
    if (widget.childData != null) {
      _selectedChildDocId = widget.childData!['docId'] ?? 
                             widget.childData!['id'] ?? 
                             widget.childData!['regNo'];
    }
  }

  String _formatDateSafely(dynamic dateVal) {
    if (dateVal == null) return 'Select Date';
    if (dateVal is Timestamp) {
      return DateFormat('dd MMM yyyy').format(dateVal.toDate());
    } else if (dateVal is DateTime) {
      return DateFormat('dd MMM yyyy').format(dateVal);
    } else if (dateVal is String) {
      return dateVal;
    }
    return dateVal.toString();
  }

  String _calculateNextDueVaccine(String currentVaccine) {
    switch (currentVaccine) {
      case 'BCG':
      case 'OPV-0':
        return '6 Weeks: Pentavalent-1, PCV-1, OPV-1, Rotavirus-1';

      case 'Pentavalent-1':
      case 'PCV-1':
      case 'OPV-1':
      case 'Rotavirus-1':
        return '10 Weeks: Pentavalent-2, PCV-2, OPV-2, Rotavirus-2';

      case 'Pentavalent-2':
      case 'PCV-2':
      case 'OPV-2':
      case 'Rotavirus-2':
        return '14 Weeks: Pentavalent-3, PCV-3, OPV-3, IPV-1';

      case 'Pentavalent-3':
      case 'PCV-3':
      case 'OPV-3':
      case 'IPV-1':
        return '9 Months: Measles-Rubella (MR-1), TCV';

      case 'Measles-Rubella (MR-1)':
      case 'MR-1':
      case 'TCV':
        return '15 Months: Measles-Rubella (MR-2), IPV-2';

      case 'Measles-Rubella (MR-2)':
      case 'MR-2':
      case 'IPV-2':
        return 'All Routine Vaccines Completed';

      default:
        return 'Routine Checkup';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF5C33CF)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveVaccinationRecord() async {
    if (_selectedChildDocId == null || _selectedChildDocId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a child'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedVaccine == null || _selectedDose == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Vaccine, Dose and Date'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final WriteBatch batch = FirebaseFirestore.instance.batch();

      String mappedStatus = 'vaccinated';
      if (_status == 'Refused') mappedStatus = 'refused';

      DocumentReference newVaccinationRef = FirebaseFirestore.instance.collection('vaccinations').doc();
      batch.set(newVaccinationRef, {
        'vaccinationId': newVaccinationRef.id,
        'childId': _selectedChildDocId,
        'vaccineName': _selectedVaccine,
        'dose': _selectedDose,
        'administeredDate': Timestamp.fromDate(_selectedDate!),
        'formattedDate': DateFormat('dd MMM yyyy').format(_selectedDate!),
        'status': mappedStatus,
        'remarks': _remarksController.text.trim(),
        'administeredBy': user?.uid ?? 'health_worker',
        'createdAt': FieldValue.serverTimestamp(),
      });

      DocumentReference newTaskRef = FirebaseFirestore.instance.collection('vaccination_tasks').doc();
      batch.set(newTaskRef, {
        'taskId': newTaskRef.id,
        'childId': _selectedChildDocId,
        'vaccineName': _selectedVaccine,
        'status': mappedStatus,
        'dueDate': Timestamp.fromDate(_selectedDate!),
        'administeredDate': FieldValue.serverTimestamp(),
        'administeredBy': user?.uid ?? 'health_worker',
      });

      DocumentReference childRef = FirebaseFirestore.instance.collection('children').doc(_selectedChildDocId);
      
      Map<String, dynamic> childUpdate = {
        'lastVaccine': _selectedVaccine,
        'status': mappedStatus == 'vaccinated' ? 'Vaccinated' : 'Refused',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (mappedStatus == 'vaccinated' && _selectedVaccine != null) {
        childUpdate['nextDue'] = _calculateNextDueVaccine(_selectedVaccine!);
      }

      batch.update(childRef, childUpdate);

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vaccination record saved successfully!'),
            backgroundColor: Color(0xFF10B981),
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
  void dispose() {
    _remarksController.dispose();
    super.dispose();
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CHILD SELECTOR (Filtered using 'registeredBy')
              const Text('Child *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 6),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('children')
                    .where('registeredBy', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: LinearProgressIndicator(color: Color(0xFF5C33CF)));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'No children registered by you yet.',
                        style: TextStyle(fontSize: 12, color: Colors.redAccent),
                      ),
                    );
                  }

                  var childDocs = snapshot.data!.docs;
                  bool containsSelected = childDocs.any((doc) => doc.id == _selectedChildDocId);
                  String? validSelectedId = containsSelected ? _selectedChildDocId : null;

                  return DropdownButtonFormField<String>(
                    value: validSelectedId,
                    hint: const Text('Select Child', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    decoration: _dropdownDecoration(),
                    items: childDocs.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String childName = data['fullName'] ?? data['name'] ?? 'Unknown Child';
                      String regNo = data['regNo'] ?? (doc.id.length >= 6 ? doc.id.substring(0, 6).toUpperCase() : doc.id);
                      
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text('$childName ($regNo)', style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedChildDocId = val),
                  );
                },
              ),
              const SizedBox(height: 16),

              // VACCINE SELECTOR
              const Text('Vaccine *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedVaccine,
                hint: const Text('Select Vaccine', style: TextStyle(fontSize: 13, color: Colors.grey)),
                decoration: _dropdownDecoration(),
                items: _vaccineOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) => setState(() => _selectedVaccine = val),
              ),
              const SizedBox(height: 16),

              // DOSE SELECTOR
              const Text('Dose *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedDose,
                hint: const Text('Select Dose', style: TextStyle(fontSize: 13, color: Colors.grey)),
                decoration: _dropdownDecoration(),
                items: _doseOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) => setState(() => _selectedDose = val),
              ),
              const SizedBox(height: 16),

              // DATE PICKER
              const Text('Date *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
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
                        _formatDateSafely(_selectedDate),
                        style: TextStyle(
                          fontSize: 13,
                          color: _selectedDate == null ? Colors.grey : Colors.black87,
                        ),
                      ),
                      const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // STATUS SELECTION
              const Text('Status *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatusOption('Vaccinated', const Color(0xFF10B981)),
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
                  backgroundColor: const Color(0xFF5C33CF),
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