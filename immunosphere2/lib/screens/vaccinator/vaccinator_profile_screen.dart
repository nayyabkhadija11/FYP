import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VaccinatorProfileScreen extends StatelessWidget {
  const VaccinatorProfileScreen({Key? key}) : super(key: key);

  // Safe Date Formatter for Joined On field
  String _formatJoinedDate(dynamic dateVal) {
    if (dateVal == null) return 'N/A';

    DateTime? dt;
    if (dateVal is Timestamp) {
      dt = dateVal.toDate();
    } else if (dateVal is DateTime) {
      dt = dateVal;
    } else if (dateVal is String) {
      dt = DateTime.tryParse(dateVal);
    }

    return dt != null ? DateFormat('dd MMM yyyy').format(dt) : dateVal.toString();
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: currentUser != null
            ? FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots()
            : null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF5C33CF)));
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading profile details'));
          }

          // Fetch values or fallback to default text
          Map<String, dynamic> data = (snapshot.data?.data() as Map<String, dynamic>?) ?? {};

          String name = data['fullName'] ?? data['name'] ?? currentUser?.displayName ?? 'Vaccinator';
          String role = data['role'] ?? 'Field Vaccinator';
          String vaccinatorId = data['empId'] ?? data['vaccinatorId'] ?? 'VAC-101';
          String phone = data['phone'] ?? data['phoneNumber'] ?? currentUser?.phoneNumber ?? 'N/A';
          String email = data['email'] ?? currentUser?.email ?? 'N/A';
          String assignedArea = data['assignedArea'] ?? 'Not Assigned';
          String joinedOn = _formatJoinedDate(data['createdAt'] ?? data['joinedOn'] ?? data['joinedDate']);

          // Fetch Health Center & District from valid_employees if missing in users collection
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('valid_employees').doc(vaccinatorId).get(),
            builder: (context, empSnapshot) {
              Map<String, dynamic> empData = (empSnapshot.data?.data() as Map<String, dynamic>?) ?? {};

              String healthCenter = data['healthCenter'] ?? empData['healthCenter'] ?? 'Basic Health Unit';
              String district = data['district'] ?? empData['district'] ?? 'Not Specified';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // PROFILE HEADER CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5C33CF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.person, size: 48, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            name,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            role,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              vaccinatorId,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // DETAILS SECTION
                    _buildDetailTile(Icons.local_hospital_outlined, 'Health Center', healthCenter),
                    _buildDetailTile(Icons.location_city_outlined, 'District', district),
                    _buildDetailTile(Icons.phone_outlined, 'Phone', phone),
                    _buildDetailTile(Icons.email_outlined, 'Email', email),
                    _buildDetailTile(Icons.map_outlined, 'Assigned Area', assignedArea),
                    _buildDetailTile(Icons.calendar_today_outlined, 'Joined On', joinedOn),

                    const SizedBox(height: 24),

                    // LOGOUT BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }
                        },
                        icon: const Icon(Icons.logout, color: Colors.red, size: 18),
                        label: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF5C33CF)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const Spacer(),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}