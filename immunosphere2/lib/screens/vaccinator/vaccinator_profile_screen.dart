import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VaccinatorProfileScreen extends StatelessWidget {
  const VaccinatorProfileScreen({Key? key}) : super(key: key);

  // COLOR THEME: supervisor profile ke sath consistent (deep green)
  static const Color primaryGreen = Color(0xFF0B4D30);
  static const Color lightBgGreen = Color(0xFFEBF7F0);

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
      // UI: sirf top header strip green hai, baaki page background
      // halka/white hai (supervisor profile jaisa)
      backgroundColor: const Color(0xFFF6F7FB),
      body: StreamBuilder<DocumentSnapshot>(
        stream: currentUser != null
            ? FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots()
            : null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryGreen));
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading profile details'));
          }

          // Fetch values or fallback to default text — FUNCTIONALITY UNCHANGED
          Map<String, dynamic> data = (snapshot.data?.data() as Map<String, dynamic>?) ?? {};

          String name = data['fullName'] ?? data['name'] ?? currentUser?.displayName ?? 'Vaccinator';
          String role = data['role'] ?? 'Field Vaccinator';
          String vaccinatorId = data['empId'] ?? data['vaccinatorId'] ?? 'VAC-101';
          String phone = data['phone'] ?? data['phoneNumber'] ?? currentUser?.phoneNumber ?? 'N/A';
          String email = data['email'] ?? currentUser?.email ?? 'N/A';
          String joinedOn = _formatJoinedDate(data['createdAt'] ?? data['joinedOn'] ?? data['joinedDate']);

          // Fetch Health Center & District from valid_employees if missing in users collection
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('valid_employees').doc(vaccinatorId).get(),
            builder: (context, empSnapshot) {
              Map<String, dynamic> empData = (empSnapshot.data?.data() as Map<String, dynamic>?) ?? {};

              String healthCenter = data['healthCenter'] ?? empData['healthCenter'] ?? 'Basic Health Unit';
              String district = data['district'] ?? empData['district'] ?? 'Not Specified';

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // GREEN HEADER (ye ek tab hai, isliye back arrow nahi)
                    Container(
                      width: double.infinity,
                      color: primaryGreen,
                      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 55),
                      child: const Center(
                        child: Text(
                          'Profile',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),

                    // Green header ke baad sab kuch (card + logout button)
                    // upar shift kiya hai (Transform.translate) taake white
                    // card green header par overlap kare — supervisor
                    // profile jaisa exact design.
                    Transform.translate(
                      offset: const Offset(0, -30),
                      child: Column(
                        children: [
                          // WHITE CARD: avatar + name + ID badge + info rows
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: Column(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const CircleAvatar(
                                      radius: 42,
                                      backgroundColor: lightBgGreen,
                                      child: Icon(Icons.person, size: 44, color: primaryGreen),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: primaryGreen,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.black87)),
                                const SizedBox(height: 2),
                                Text(role, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: lightBgGreen, borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                    vaccinatorId,
                                    style: const TextStyle(color: primaryGreen, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                _buildDetailTile(Icons.local_hospital_outlined, 'Health Center', healthCenter),
                                const SizedBox(height: 10),
                                _buildDetailTile(Icons.location_city_outlined, 'District', district),
                                const SizedBox(height: 10),
                                _buildDetailTile(Icons.phone_outlined, 'Phone', phone),
                                const SizedBox(height: 10),
                                _buildDetailTile(Icons.email_outlined, 'Email', email),
                                const SizedBox(height: 10),
                                _buildDetailTile(Icons.calendar_today_outlined, 'Joined On', joinedOn),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // LOGOUT BUTTON — solid green (supervisor jaisa)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await FirebaseAuth.instance.signOut();
                                  if (context.mounted) {
                                    Navigator.of(context).popUntil((route) => route.isFirst);
                                  }
                                },
                                icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.white),
                                label: const Text('Log Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: lightBgGreen, shape: BoxShape.circle),
            child: Icon(icon, color: primaryGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}