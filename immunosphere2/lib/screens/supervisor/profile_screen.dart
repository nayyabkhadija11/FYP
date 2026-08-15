import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Logout Function
  Future<void> _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await FirebaseAuth.instance.signOut();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Supervisor Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF231B92),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _db.collection('users').doc(_uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('User data not found'));
                }

                final userData = snapshot.data!.data() ?? {};
                final fullName = userData['fullName'] ?? 'Dr. Ahmed Khan';
                final email = FirebaseAuth.instance.currentUser?.email ?? userData['email'] ?? 'supervisor@immunosphere.com';
                final designation = userData['designation'] ?? 'EPI Supervisor';
                final location = userData['location'] ?? 'BHU Jand, Attock';
                final phone = userData['phone'] ?? userData['phoneNumber'] ?? '+92 300 1234567';
                final role = userData['role'] ?? 'Supervisor';
                final photoUrl = userData['photoUrl'];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // Profile Header Card
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: const Color(0xFF231B92).withOpacity(0.1),
                              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                              child: photoUrl == null
                                  ? const Icon(Icons.person, size: 50, color: Color(0xFF231B92))
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF231B92),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.verified, color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fullName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        designation,
                        style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 20),

                      // Info Section Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildInfoTile(Icons.email_outlined, 'Email', email),
                            const Divider(height: 1, indent: 50),
                            _buildInfoTile(Icons.phone_outlined, 'Phone Number', phone),
                            const Divider(height: 1, indent: 50),
                            _buildInfoTile(Icons.location_on_outlined, 'Assigned Location', location),
                            const Divider(height: 1, indent: 50),
                            _buildInfoTile(Icons.admin_panel_settings_outlined, 'System Role', role.toUpperCase()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Actions / Settings Section
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.edit_outlined, color: Color(0xFF231B92)),
                              title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w500)),
                              trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Edit Profile feature coming soon!')),
                                );
                              },
                            ),
                            const Divider(height: 1, indent: 50),
                            ListTile(
                              leading: const Icon(Icons.lock_outline, color: Color(0xFF231B92)),
                              title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w500)),
                              trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Password reset link sent to email.')),
                                );
                              },
                            ),
                            const Divider(height: 1, indent: 50),
                            ListTile(
                              leading: const Icon(Icons.help_outline, color: Color(0xFF231B92)),
                              title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w500)),
                              trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFEBEE),
                            foregroundColor: const Color(0xFFD32F2F),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => _logout(context),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Log Out',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF231B92), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}