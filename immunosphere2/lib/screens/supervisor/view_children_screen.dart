import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'assign_vaccinators_screen.dart';

class ViewChildrenScreen extends StatefulWidget {
  final Map<String, dynamic> campaignData;

  const ViewChildrenScreen({super.key, required this.campaignData});

  @override
  State<ViewChildrenScreen> createState() => _ViewChildrenScreenState();
}

class _ViewChildrenScreenState extends State<ViewChildrenScreen> {
  @override
  Widget build(BuildContext context) {
    // Campaign data se select kiya hua mohallah/area nikal rahe hain
    final String chosenArea = widget.campaignData['targetArea'] ?? 
                              widget.campaignData['village'] ?? 
                              widget.campaignData['mohallah'] ?? 
                              'mohallah station';
                              
    final String searchVillage = chosenArea.trim().toLowerCase();

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
          'Children in Chosen Area',
          style: TextStyle(
            color: Color(0xFF231B92),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      // StreamBuilder use karne se real-time data milega (baad mein naye bache add hon ge toh foran yahan show hon ge)
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('children')
            .where('village', isEqualTo: searchVillage)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF231B92)));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          int totalChildrenCount = docs.length;
          
          Set<String> uniqueHouseholds = {};
          for (var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;
            if (data.containsKey('houseAddress') && data['houseAddress'] != null) {
              uniqueHouseholds.add(data['houseAddress'].toString());
            }
          }
          int totalHouseholdsCount = uniqueHouseholds.isNotEmpty ? uniqueHouseholds.length : totalChildrenCount;

          // Campaign data ko update kar dein taake agli screen par bhi theek count jaye
          widget.campaignData['totalChildren'] = totalChildrenCount;
          widget.campaignData['totalHouses'] = totalHouseholdsCount;

          return Column(
            children: [
              // Area Info Banner with Real-Time Count
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Mohallah: $chosenArea',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF231B92),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Real Total Children\n(0-5 Years)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text('$totalChildrenCount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Total Households', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text('$totalHouseholdsCount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF231B92))),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search & Filter Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search child or household...',
                            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 18),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.filter_list, color: Colors.grey.shade700, size: 18),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Children List View (Real-time Builder)
              Expanded(
                child: docs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'No registered children found in "$chosenArea".',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final childName = data['fullName'] ?? data['name'] ?? 'Unknown Name';
                          final regNo = data['regNo'] ?? data['childId'] ?? docs[index].id.substring(0, 8);
                          final house = data['houseAddress'] ?? 'N/A';
                          final village = data['village'] ?? chosenArea;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Colors.blueAccent,
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                 child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(childName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text('Reg No: $regNo | House: $house', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                      Text('Village: $village', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: const Icon(Icons.check, size: 16, color: Colors.green),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Next Button
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.white,
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssignVaccinatorsScreen(campaignData: widget.campaignData),
                        ),
                      );
                    },
                    child: const Text(
                      'Next: Assign Vaccinators',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}