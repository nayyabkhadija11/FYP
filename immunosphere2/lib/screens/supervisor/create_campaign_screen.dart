import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'select_target_area_screen.dart'; 

class CreateCampaignScreen extends StatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  State<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends State<CreateCampaignScreen> {
  final _nameController = TextEditingController(text: 'National Polio Campaign');
  final _descriptionController = TextEditingController();
  
  String _selectedType = 'Polio';
  String _selectedTargetArea = 'Mohallah A, Jand';
  
  final String _selectedVaccine = 'OPV (Polio Drops)';
  final String _selectedDose = 'Dose 1';
  final String _selectedHealthCenter = 'THQ Hospital Jand';

  String _status = 'active';

  DateTime _startDate = DateTime(2026, 8, 10);
  DateTime _endDate = DateTime(2026, 8, 15);

  final List<String> _targetAreaOptions = [
    'Mohallah A, Jand', 
    'Mohallah B, Jand', 
    'Kot Gulla', 
    'Jand Central',
    'New Town Jand'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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

  Future<void> _goToNextStep() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter campaign name')),
      );
      return;
    }

    final campaignData = {
      'name': _nameController.text.trim(),
      'type': _selectedType,
      'vaccine': _selectedVaccine,
      'dose': _selectedDose,
      'targetArea': _selectedTargetArea,
      'targetVillage': 'Kot Gulla',
      'totalHouses': 80, 
      'totalChildren': 128, 
      'startDate': _startDate,
      'endDate': _endDate,
      'description': _descriptionController.text.trim(),
      'healthCenter': _selectedHealthCenter,
      'status': _status.toLowerCase(),
    };

    final updatedTargetArea = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectTargetAreaScreen(campaignData: campaignData),
      ),
    );

    if (!mounted) return;

    if (updatedTargetArea != null && updatedTargetArea is String) {
      setState(() {
        if (!_targetAreaOptions.contains(updatedTargetArea)) {
          _targetAreaOptions.add(updatedTargetArea);
        }
        _selectedTargetArea = updatedTargetArea;
      });
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
            const Text(
              'Campaign Information',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF231B92),
              ),
            ),
            const SizedBox(height: 16),

            // Campaign Name
            const Text('Campaign Name',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
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
            const SizedBox(height: 16),

            // Campaign Type Dropdown
            const Text('Campaign Type',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
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
                  items: ['Polio', 'Routine', 'Measles', 'COVID-19'].map<DropdownMenuItem<String>>((type) {
                    return DropdownMenuItem<String>(value: type, child: Text(type, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status Selection Dropdown
            const Text('Status',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _status,
                  isExpanded: true,
                  items: ['active', 'pending', 'completed'].map<DropdownMenuItem<String>>((statusOption) {
                    return DropdownMenuItem<String>(
                      value: statusOption, 
                      child: Text(
                        statusOption[0].toUpperCase() + statusOption.substring(1),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _status = val!),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Start Date & End Date Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _selectDate(context, true),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                          ),
                          child: Text(
                            DateFormat('d MMM yyyy').format(_startDate),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
                      const Text('End Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _selectDate(context, false),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                          ),
                          child: Text(
                            DateFormat('d MMM yyyy').format(_endDate),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Target Area Dropdown
            const Text('Target Area',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _targetAreaOptions.contains(_selectedTargetArea) ? _selectedTargetArea : _targetAreaOptions.first,
                  isExpanded: true,
                  items: _targetAreaOptions.map<DropdownMenuItem<String>>((area) {
                    return DropdownMenuItem<String>(value: area, child: Text(area, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedTargetArea = val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description (Optional)
            const Text('Description (Optional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Add description...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 30),

            // Next / Proceed Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _goToNextStep,
                child: const Text(
                  'Next: Select Target Area',
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