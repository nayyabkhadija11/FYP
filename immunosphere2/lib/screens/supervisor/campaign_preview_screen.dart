import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'campaigns_screen.dart'; 

class CampaignPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> campaignData;

  const CampaignPreviewScreen({super.key, required this.campaignData});

  @override
  State<CampaignPreviewScreen> createState() => _CampaignPreviewScreenState();
}

class _CampaignPreviewScreenState extends State<CampaignPreviewScreen> {
  bool _isLoading = false;
  
  // Default status 'Active'
  String _selectedStatus = 'Active';

  final List<String> _statusOptions = ['Active', 'Pending', 'Completed', 'Paused'];

  Future<void> _finalizeAndCreateCampaign() async {
    setState(() => _isLoading = true);
    try {
      final db = FirebaseFirestore.instance;

      // Safe values extract kar rahe hain taake Null error na aaye
      final campaignName = widget.campaignData['name']?.toString() ?? 'Unnamed Campaign';
      final selectedArea = widget.campaignData['selectedArea']?.toString() ?? widget.campaignData['targetArea']?.toString() ?? 'N/A';

      // Campaign data ka payload map (Safe conversions ke sath)
      final Map<String, dynamic> campaignPayload = {
        'name': campaignName,
        'type': widget.campaignData['type']?.toString() ?? '',
        'vaccine': widget.campaignData['vaccine']?.toString() ?? '',
        'dose': widget.campaignData['dose']?.toString() ?? '',
        'targetArea': selectedArea,
        'targetVillage': widget.campaignData['targetVillage']?.toString() ?? '',
        'totalHouses': widget.campaignData['totalHouses'] ?? 0,
        'totalChildren': widget.campaignData['totalChildren'] ?? 0,
        'startDate': widget.campaignData['startDate'] is DateTime 
            ? Timestamp.fromDate(widget.campaignData['startDate']) 
            : Timestamp.now(),
        'endDate': widget.campaignData['endDate'] is DateTime 
            ? Timestamp.fromDate(widget.campaignData['endDate']) 
            : Timestamp.now(),
        'healthCenter': widget.campaignData['healthCenter']?.toString() ?? '',
        
        // Status dropdown value
        'status': _selectedStatus, 
        
        'teamNumber': widget.campaignData['teamNumber']?.toString() ?? '',
        'assignedVaccinatorIds': widget.campaignData['assignedVaccinatorIds'] ?? [],
        
        'progress': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 1. Save main campaign to Firestore
      DocumentReference campaignRef = await db.collection('campaigns').add(campaignPayload);

      // 2. Send notification to vaccinators
      await db.collection('notifications').add({
        'title': 'New Campaign Created',
        'body': 'A new campaign "$campaignName" has been created for $selectedArea.',
        'campaign_id': campaignRef.id,
        'created_at': FieldValue.serverTimestamp(),
        'is_read': false,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campaign successfully created!')),
      );

      // 3. Navigate to CampaignsScreen and clear previous creation screens
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const CampaignsScreen()),
        (route) => route.isFirst,
      );
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayArea = widget.campaignData['selectedArea']?.toString() ?? widget.campaignData['targetArea']?.toString() ?? 'Mohallah A, Jand';

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
          'Auto Assignment Preview',
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'System will automatically assign households equally among selected vaccinators.',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Area: $displayArea',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF231B92)),
            ),
            const SizedBox(height: 20),

            // Status Selection Dropdown
            const Text(
              'Select Campaign Status:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF231B92)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  isExpanded: true,
                  items: _statusOptions.map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status, style: const TextStyle(fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedStatus = newValue;
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _finalizeAndCreateCampaign,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Confirm & Create Campaign',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}