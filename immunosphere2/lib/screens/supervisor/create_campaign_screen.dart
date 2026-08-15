import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CreateCampaignScreen extends StatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  State<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends State<CreateCampaignScreen> {
  final _nameController = TextEditingController(text: 'National Polio Campaign August 2026');
  final _targetAreaController = TextEditingController(text: 'Jand Central');
  final _targetVillageController = TextEditingController(text: 'Kot Gulla'); // Naya field village ke liye
  final _totalHousesController = TextEditingController(text: '1250');
  final _totalChildrenController = TextEditingController(text: '3400');
  
  final _db = FirebaseFirestore.instance;

  String _selectedType = 'Polio';
  String _selectedVaccine = 'OPV (Polio Drops)';
  String _selectedDose = 'Dose 1';
  String _selectedStatus = 'Active';
  final String _selectedHealthCenter = 'THQ Hospital Jand';

  DateTime _startDate = DateTime(2026, 8, 10);
  DateTime _endDate = DateTime(2026, 8, 15);

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _targetAreaController.dispose();
    _targetVillageController.dispose(); // Controller dispose karna na bhulein
    _totalHousesController.dispose();
    _totalChildrenController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _createCampaign() async {
    if (_nameController.text.trim().isEmpty ||
        _targetAreaController.text.trim().isEmpty ||
        _targetVillageController.text.trim().isEmpty ||
        _totalHousesController.text.trim().isEmpty ||
        _totalChildrenController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final campaignName = _nameController.text.trim();
      final targetArea = _targetAreaController.text.trim();
      final targetVillage = _targetVillageController.text.trim();
      final int totalHouses = int.tryParse(_totalHousesController.text.trim()) ?? 0;
      final int totalChildren = int.tryParse(_totalChildrenController.text.trim()) ?? 0;

      // 1. Campaign create karein Firestore me (Target Village ke sath)
      DocumentReference campaignRef = await _db.collection('campaigns').add({
        'name': campaignName,
        'type': _selectedType,
        'vaccine': _selectedVaccine,
        'dose': _selectedDose,
        'targetArea': targetArea,
        'targetVillage': targetVillage, // Firestore me save hoga
        'totalHouses': totalHouses,
        'totalChildren': totalChildren,
        'startDate': Timestamp.fromDate(_startDate),
        'endDate': Timestamp.fromDate(_endDate),
        'healthCenters': 1,
        'healthCentersList': [_selectedHealthCenter],
        'status': _selectedStatus.toLowerCase(), 
        'progress': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Notification me bhi village mention kar diya hai
      await _db.collection('notifications').add({
        'title': 'New Campaign Created',
        'body': 'A new $_selectedType campaign "$campaignName" ($_selectedDose) targeting $targetArea ($targetVillage) has been created for $_selectedHealthCenter.',
        'campaign_id': campaignRef.id,
        'target_centers': [_selectedHealthCenter],
        'created_at': FieldValue.serverTimestamp(),
        'is_read': false,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campaign created & notification sent to vaccinators!')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
          icon: const Icon(Icons.arrow_back, color: Color(0xFF231B92)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Campaign',
          style: TextStyle(
            color: Color(0xFF231B92),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Campaign Name',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF231B92))),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 14),

            const Text('Target Area',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF231B92))),
            const SizedBox(height: 6),
            TextField(
              controller: _targetAreaController,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'e.g. Jand Central',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 14),

            // Naya Target Village Field
            const Text('Target Village',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF231B92))),
            const SizedBox(height: 6),
            TextField(
              controller: _targetVillageController,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'e.g. Kot Gulla, Mohallah Usman',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Houses', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF231B92))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _totalHousesController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Children', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF231B92))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _totalChildrenController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            const Text('Campaign Type',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF231B92))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  items: ['Polio', 'Routine'].map((type) {
                    return DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
              ),
            ),
            const SizedBox(height: 14),

            const Text('Vaccine',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF231B92))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedVaccine,
                  isExpanded: true,
                  items: ['OPV (Polio Drops)', 'Polio Booster Dose', 'Routine Vaccine'].map((vac) {
                    return DropdownMenuItem(value: vac, child: Text(vac, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedVaccine = val!),
                ),
              ),
            ),
            const SizedBox(height: 14),

            const Text('Dose',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF231B92))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDose,
                  isExpanded: true,
                  items: ['Dose 1', 'Dose 2', 'Dose 3', 'Dose 4', 'Booster Dose'].map((dose) {
                    return DropdownMenuItem(value: dose, child: Text(dose, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedDose = val!),
                ),
              ),
            ),
            const SizedBox(height: 14),

            const Text('Campaign Status',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF231B92))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  isExpanded: true,
                  items: ['Active', 'Completed'].map((status) {
                    return DropdownMenuItem(value: status, child: Text(status, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedStatus = val!),
                ),
              ),
            ),
            const SizedBox(height: 14),

            const Text('Health Center',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF231B92))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.grey.shade50,
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_hospital, size: 16, color: Color(0xFF231B92)),
                  const SizedBox(width: 8),
                  Text(
                    _selectedHealthCenter,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF231B92))),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _selectDate(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('dd MMM yyyy').format(_startDate), style: const TextStyle(fontSize: 13)),
                              const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF231B92)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('End Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF231B92))),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('dd MMM yyyy').format(_endDate), style: const TextStyle(fontSize: 13)),
                              const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF231B92)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF231B92),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _createCampaign,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Create Campaign',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}