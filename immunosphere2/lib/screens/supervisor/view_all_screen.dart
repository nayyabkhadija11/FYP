import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewAllScreen extends StatefulWidget {
  const ViewAllScreen({Key? key}) : super(key: key);

  @override
  State<ViewAllScreen> createState() => _ViewAllScreenState();
}

class _ViewAllScreenState extends State<ViewAllScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  String _childSearchQuery = '';
  String _vaccinatorSearchQuery = '';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          title: const Text(
            'Registered Vaccinators & Children',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF231B92),
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(icon: Icon(Icons.badge_outlined), text: 'Registered Vaccinators'),
              Tab(icon: Icon(Icons.people), text: 'Registered Children'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Real-Time Live Stream from 'users' collection where role is Vaccinator
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _vaccinatorSearchQuery = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search vaccinator by name or ID...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF231B92)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF231B92), width: 1),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: db
                        .collection('users')
                        .where('role', whereIn: ['Vaccinator', 'vaccinator'])
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No registered vaccinators found',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        );
                      }

                      final vaccinatorDocs = snapshot.data!.docs.where((doc) {
                        final data = doc.data();
                        final name = (data['fullName'] ?? data['name'] ?? '').toString().toLowerCase();
                        final employeeId = (data['employeeId'] ?? '').toString().toLowerCase();
                        return name.contains(_vaccinatorSearchQuery) || employeeId.contains(_vaccinatorSearchQuery);
                      }).toList();

                      if (vaccinatorDocs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No matching vaccinator found',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: vaccinatorDocs.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                        itemBuilder: (context, index) {
                          final vaccinatorData = vaccinatorDocs[index].data();
                          
                          final name = vaccinatorData['fullName'] ?? vaccinatorData['name'] ?? 'Unnamed Vaccinator';
                          final phone = vaccinatorData['phone'] ?? 'N/A';
                          final employeeId = vaccinatorData['employeeId'] ?? 'N/A';
                          final email = vaccinatorData['email'] ?? 'N/A';

                          return Container(
                            color: Colors.white,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFF231B92).withOpacity(0.1),
                                child: const Icon(Icons.badge, color: Color(0xFF231B92), size: 18),
                              ),
                              title: Text(
                                name, // Yeh ab aapka real name ('Saad') show karega
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              subtitle: Text(
                                'ID: $employeeId • Phone: $phone • Email: $email',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            // Tab 2: Real-Time Live Stream from Firebase (Registered Children)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _childSearchQuery = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search child by name...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF231B92)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF231B92), width: 1),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: db.collection('children').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No registered children found in Firebase',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        );
                      }

                      final childrenDocs = snapshot.data!.docs.where((doc) {
                        final data = doc.data();
                        final name = (data['fullName'] ?? data['name'] ?? '').toString().toLowerCase();
                        return name.contains(_childSearchQuery);
                      }).toList();

                      if (childrenDocs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No matching child found',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: childrenDocs.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                        itemBuilder: (context, index) {
                          final childData = childrenDocs[index].data();
                          
                          final name = childData['fullName'] ?? childData['name'] ?? 'Unnamed Child';
                          final age = childData['age'] ?? 'N/A';
                          final regNo = childData['regNo'] ?? childData['childId'] ?? '';
                          final status = (childData['status'] ?? childData['vaccinationStatus'] ?? 'Active').toString();

                          Color statusColor = Colors.green;
                          final lowerStatus = status.toLowerCase();
                          if (lowerStatus == 'pending' || lowerStatus == 'missed') {
                            statusColor = Colors.orange;
                          } else if (lowerStatus == 'defaulter') {
                            statusColor = Colors.red;
                          }

                          return Container(
                            color: Colors.white,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFF231B92).withOpacity(0.1),
                                child: const Icon(Icons.child_care, color: Color(0xFF231B92), size: 18),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              subtitle: Text(
                                'Age: $age ${regNo.isNotEmpty ? "• ID: $regNo" : ""}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              trailing: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}