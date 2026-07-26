import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VaccinatorProfileScreen extends StatelessWidget {
  const VaccinatorProfileScreen({Key? key}) : super(key: key);

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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black),
            onPressed: () {
              // Edit Profile Navigation or Modal
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3F51B5)));
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading profile details'));
          }

          // Fetch values or fallback to default text
          Map<String, dynamic> data = (snapshot.data?.data() as Map<String, dynamic>?) ?? {};

          String name = data['name'] ?? currentUser?.displayName ?? 'Vaccinator';
          String role = data['role'] ?? 'Vaccinator';
          String vaccinatorId = data['vaccinatorId'] ?? 'VAC-${currentUser?.uid.substring(0, 5).toUpperCase() ?? "001"}';
          String healthCenter = data['healthCenter'] ?? 'Basic Health Unit';
          String district = data['district'] ?? 'Not Specified';
          String phone = data['phone'] ?? currentUser?.phoneNumber ?? 'N/A';
          String email = data['email'] ?? currentUser?.email ?? 'N/A';
          String assignedArea = data['assignedArea'] ?? 'Not Assigned';
          String joinedOn = data['joinedOn'] ?? 'N/A';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // PROFILE HEADER CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3F51B5),
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
                      ),
                      Text(
                        role,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vaccinatorId,
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
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

                const SizedBox(height: 16),

                // ACTIONS SECTION
                _buildActionTile(Icons.lock_outline, 'Change Password', () {
                  // Password reset action
                }),
                _buildActionTile(Icons.help_outline, 'Help & Support', () {
                  // Support page action
                }),
                _buildActionTile(Icons.info_outline, 'About ImmunoSphere', () {
                  // About modal/page
                }),

                const SizedBox(height: 20),

                // LOGOUT BUTTON
                OutlinedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red, size: 18),
                  label: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF3F51B5)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.black87),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}