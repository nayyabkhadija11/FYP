import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'campaign_preview_screen.dart';

class AssignVaccinatorsScreen extends StatefulWidget {
  final Map<String, dynamic> campaignData;

  const AssignVaccinatorsScreen({super.key, required this.campaignData});

  @override
  State<AssignVaccinatorsScreen> createState() => _AssignVaccinatorsScreenState();
}

class _AssignVaccinatorsScreenState extends State<AssignVaccinatorsScreen> {
  final _teamNumberController = TextEditingController(text: '1');
  final Set<String> _selectedVaccinatorIds = {};

  @override
  void dispose() {
    _teamNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Previous screen se aaya hua target area yahan access kar rahe hain
    final String targetArea = widget.campaignData['targetArea'] ?? 'Not Specified';

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
          'Assign Vaccinators / Team',
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
            // Target Area Display Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF231B92)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Target Area: $targetArea',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF231B92),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text('Create Team', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 6),
            TextField(
              controller: _teamNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Team Number',
                hintText: 'Enter team number (e.g. 1)',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Select Registered Vaccinators', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('No users found in database.'),
                  ));
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final role = data['role']?.toString().toLowerCase() ?? '';
                  return role == 'vaccinator' || role == 'vaccinators';
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('No vaccinators found in database.'),
                  ));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final vacId = doc.id;
                    final vacName = data['fullName'] ?? data['name'] ?? 'Unknown';
                    final employeeId = data['employeeId'] ?? 'N/A';
                    
                    final isSelected = _selectedVaccinatorIds.contains(vacId);
                    
                    // Jaise hi select hoga, area targetArea ban jayega
                    final vacArea = isSelected 
                        ? targetArea 
                        : (data['area'] ?? 'Not Assigned');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF1B5E20) : Colors.grey.shade300,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(child: Icon(Icons.person)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(vacName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Employee ID: $employeeId', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                Text(
                                  'Area: $vacArea', 
                                  style: TextStyle(
                                    fontSize: 11, 
                                    color: isSelected ? const Color(0xFF1B5E20) : Colors.grey.shade600, 
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedVaccinatorIds.add(vacId);
                                } else {
                                  _selectedVaccinatorIds.remove(vacId);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // Validation: Check if team number is entered
                  if (_teamNumberController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a team number')),
                    );
                    return;
                  }

                  // Validation: Check if at least one vaccinator is selected
                  if (_selectedVaccinatorIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least one vaccinator')),
                    );
                    return;
                  }

                  // Save data to campaignData map
                  widget.campaignData['teamNumber'] = _teamNumberController.text.trim();
                  widget.campaignData['assignedVaccinatorIds'] = _selectedVaccinatorIds.toList();

                  // Move to Preview Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CampaignPreviewScreen(campaignData: widget.campaignData),
                    ),
                  );
                },
                child: const Text(
                  'Next: Auto Assign',
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