import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/campaign_stepper.dart';
import 'select_target_area_screen.dart';

class CreateCampaignScreen extends StatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  State<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends State<CreateCampaignScreen> {
  static const Color primaryGreen = Color(0xFF006837);

  final _nameController = TextEditingController();
  String _campaignType = "Polio";
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? (_startDate ?? DateTime.now()));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _onContinuePressed() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campaign name likhna zaroori hai')),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start aur End date select karein')),
      );
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date, Start date se pehle nahi ho sakti')),
      );
      return;
    }

    final campaignData = <String, dynamic>{
      'name': _nameController.text.trim(),
      'type': _campaignType,
      'startDate': _startDate,
      'endDate': _endDate,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectTargetAreaScreen(campaignData: campaignData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Create Campaign",
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const CampaignStepper(currentStep: 1),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _step1Info(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                  "Continue",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step1Info() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.calendar_today, size: 50, color: primaryGreen),
        ),
        const SizedBox(height: 12),
        const Text("Campaign Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Text("Fill in the basic information to get started.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 24),
        const Align(alignment: Alignment.centerLeft, child: Text("Campaign Name", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: "e.g. National Polio Campaign",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),
        const Align(alignment: Alignment.centerLeft, child: Text("Campaign Type", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _campaignType,
          items: ["Polio", "Routine Immunization", "Sub National Drive"]
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => setState(() => _campaignType = val!),
          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _datePickerField(
                label: "Start Date",
                date: _startDate,
                onTap: () => _pickDate(isStart: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _datePickerField(
                label: "End Date",
                date: _endDate,
                onTap: () => _pickDate(isStart: false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _datePickerField({required String label, required DateTime? date, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null ? DateFormat('dd MMM yyyy').format(date) : "Select",
                  style: TextStyle(fontSize: 13, color: date != null ? Colors.black : Colors.grey.shade500),
                ),
                const Icon(Icons.calendar_month, size: 18, color: primaryGreen),
              ],
            ),
          ),
        ),
      ],
    );
  }
}