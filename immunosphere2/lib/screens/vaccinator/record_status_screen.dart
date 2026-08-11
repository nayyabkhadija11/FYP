/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecordStatusScreen extends StatefulWidget {
  final String assignmentDocId;
  final String childName;
  final String currentStatus;
  final String vaccineGiven;
  final String fingerMark;
  final String remarks;

  const RecordStatusScreen({
    Key? key,
    this.assignmentDocId = '', // Default empty string to handle optional navigation
    required this.childName,
    this.currentStatus = 'Pending',
    this.vaccineGiven = 'OPV Drops',
    this.fingerMark = 'Done',
    this.remarks = '',
  }) : super(key: key);

  @override
  State<RecordStatusScreen> createState() => _RecordStatusScreenState();
}

class _RecordStatusScreenState extends State<RecordStatusScreen> {
  late String _selectedStatus;
  late String _selectedVaccine;
  late String _selectedFingerMark;
  late TextEditingController _remarksController;
  bool _isLoading = false;

  final List<String> _statusOptions = [
    'Vaccinated',
    'House Locked',
    'Refused',
    'Child Not Available',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = _statusOptions.contains(widget.currentStatus) ? widget.currentStatus : 'Vaccinated';
    _selectedVaccine = widget.vaccineGiven;
    _selectedFingerMark = widget.fingerMark;
    _remarksController = TextEditingController(text: widget.remarks);
  }

  Future<void> _saveRecord() async {
    if (widget.assignmentDocId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No document reference found to update!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('campaign_assignments')
          .doc(widget.assignmentDocId)
          .update({
        'status': _selectedStatus,
        'vaccineGiven': _selectedVaccine,
        'fingerMark': _selectedFingerMark,
        'remarks': _remarksController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
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
        title: Text(widget.childName, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Campaign Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: _statusOptions.map((status) {
                  return RadioListTile<String>(
                    activeColor: const Color.fromARGB(255, 0, 191, 92),
                    title: Text(status, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    value: status,
                    groupValue: _selectedStatus,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),
            const Text('Vaccine Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Vaccine Given', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      DropdownButton<String>(
                        value: _selectedVaccine,
                        underline: const SizedBox(),
                        items: ['OPV Drops', 'IPV Injection', 'None']
                            .map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: _selectedStatus == 'Vaccinated' 
                          ? (val) => setState(() => _selectedVaccine = val!) 
                          : null,
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Finger Mark', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      DropdownButton<String>(
                        value: _selectedFingerMark,
                        underline: const SizedBox(),
                        items: ['Done', 'Not Done']
                            .map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: _selectedStatus == 'Vaccinated' 
                          ? (val) => setState(() => _selectedFingerMark = val!) 
                          : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text('Remarks (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _remarksController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter reason if House Locked, Refused, or Child Not Available...',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                fillColor: const Color(0xFFF8F9FA),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
            ),

            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _saveRecord,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Record', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
} */
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecordStatusScreen extends StatefulWidget {
  final String assignmentDocId;
  final String childName;
  final String currentStatus;
  final String vaccineGiven;
  final String fingerMark;
  final String remarks;

  const RecordStatusScreen({
    Key? key,
    this.assignmentDocId = '', // Default empty string to handle optional navigation
    required this.childName,
    this.currentStatus = 'Pending',
    this.vaccineGiven = 'OPV Drops',
    this.fingerMark = 'Done',
    this.remarks = '',
  }) : super(key: key);

  @override
  State<RecordStatusScreen> createState() => _RecordStatusScreenState();
}

class _RecordStatusScreenState extends State<RecordStatusScreen> {
  late String _selectedStatus;
  String? _selectedVaccine; // Empty/Nullable for unfilled initial state
  String? _selectedFingerMark; // Empty/Nullable for unfilled initial state
  late TextEditingController _remarksController;
  bool _isLoading = false;

  final List<String> _statusOptions = [
    'Vaccinated',
    'House Locked',
    'Refused',
    'Child Not Available',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = _statusOptions.contains(widget.currentStatus)
        ? widget.currentStatus
        : 'Vaccinated';
    
    // Shuru mein empty rahenge (Select ka text show hoga)
    _selectedVaccine = null; 
    _selectedFingerMark = null;
    _remarksController = TextEditingController(text: widget.remarks);
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (widget.assignmentDocId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No document reference found to update!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validation Check: Agar Vaccinated chuna hai to Vaccine aur Finger Mark select karna zaruri hai
    if (_selectedStatus == 'Vaccinated' &&
        (_selectedVaccine == null || _selectedFingerMark == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Vaccine Given and Finger Mark!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Logic: House Locked & Child Not Available are saved under 'Missed' status
    String statusToSave = _selectedStatus;
    if (_selectedStatus == 'House Locked' || _selectedStatus == 'Child Not Available') {
      statusToSave = 'Missed';
    }

    try {
      await FirebaseFirestore.instance
          .collection('campaign_assignments')
          .doc(widget.assignmentDocId)
          .update({
        'status': statusToSave,
        'statusReason': _selectedStatus, // Specific reason ('House Locked' / 'Child Not Available')
        'vaccineGiven': _selectedStatus == 'Vaccinated' ? (_selectedVaccine ?? 'None') : 'None',
        'fingerMark': _selectedStatus == 'Vaccinated' ? (_selectedFingerMark ?? 'Not Done') : 'Not Done',
        'remarks': _remarksController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF00796B);
    const Color buttonGreen = Color(0xFF006A4E);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          widget.childName,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF2F0F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Campaign Status Section
            const Text(
              'Campaign Status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: _statusOptions.map((status) {
                  return RadioListTile<String>(
                    activeColor: primaryTeal,
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    title: Text(
                      status,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    value: status,
                    groupValue: _selectedStatus,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // 2. Vaccine Details Section
            const Text(
              'Vaccine Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Vaccine Given Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Vaccine Given',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        height: 48,
                        width: 150, // Standard exact width to match Finger Mark
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF5F6368),
                            width: 1.2,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedVaccine,
                            hint: const Text(
                              'Select',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                            isExpanded: true,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.black87,
                            ),
                            items: ['OPV Drops', 'IPV Injection', 'None']
                                .map((v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(
                                        v,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ))
                                .toList(),
                            onChanged: _selectedStatus == 'Vaccinated'
                                ? (val) => setState(() => _selectedVaccine = val)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Finger Mark Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Finger Mark',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        height: 48,
                        width: 150, // Exact same 150 width as above
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF5F6368),
                            width: 1.2,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedFingerMark,
                            hint: const Text(
                              'Select',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.black87,
                            ),
                            isExpanded: true,
                            items: ['Done', 'Not Done']
                                .map((v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(
                                        v,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ))
                                .toList(),
                            onChanged: _selectedStatus == 'Vaccinated'
                                ? (val) => setState(() => _selectedFingerMark = val)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Remarks Section
            const Text(
              'Remarks (Optional)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _remarksController,
              maxLines: 4,
              maxLength: 100,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Enter reason if House Locked, Refused, or Child Not Available...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
                fillColor: const Color(0xFFF4F5F7),
                filled: true,
                counterText: "${_remarksController.text.length}/100",
                counterStyle: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: primaryTeal,
                    width: 1.2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 4. Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _saveRecord,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save & Next',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}