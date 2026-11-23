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

  static const Color primaryGreen = Color(0xFF025232);
  static const Color lightBgGreen = Color(0xFFEBF7F0);

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
              Navigator.pop(context);
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
      body: _uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _db.collection('users').doc(_uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primaryGreen));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('User data not found'));
                }

                final userData = snapshot.data!.data() ?? {};
                final fullName = userData['fullName'] ?? userData['name'] ?? 'Supervisor';
                final email = FirebaseAuth.instance.currentUser?.email ?? userData['email'] ?? '-';
                final designation = userData['designation'] ?? 'Immunization Supervisor';
                final employeeId = (userData['employeeId'] ??
                        userData['supervisorId'] ??
                        userData['empId'] ??
                        '-')
                    .toString();
                final phone = userData['phone'] ?? userData['phoneNumber'] ?? '-';
                final role = (userData['role'] ?? 'Supervisor').toString();
                final photoUrl = userData['photoUrl'];

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // GREEN HEADER (bina back arrow ke, ye ek tab hai)
                      Container(
                        width: double.infinity,
                        color: primaryGreen,
                        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 55),
                        child: const Center(
                          child: Text(
                            'Supervisor Profile',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ),

                      // Green header ke baad sab kuch (card + logout button)
                      // ek Transform.translate mein wrap kar ke upar shift
                      // kar rahe hain — Container.margin/Padding negative
                      // value allow nahi karte (crash deta hai), Transform
                      // safe hai kyunke ye sirf visual paint-position
                      // badalta hai.
                      Transform.translate(
                        offset: const Offset(0, -30),
                        child: Column(
                          children: [
                            Container(
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
                                      CircleAvatar(
                                        radius: 42,
                                        backgroundColor: lightBgGreen,
                                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                        child: photoUrl == null
                                            ? const Icon(Icons.person, size: 44, color: primaryGreen)
                                            : null,
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
                                  Text(fullName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  const SizedBox(height: 2),
                                  Text(designation, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                  const SizedBox(height: 20),

                                  _infoCard(Icons.email_outlined, 'Email', email),
                                  const SizedBox(height: 10),
                                  _infoCard(Icons.phone_outlined, 'Phone Number', phone),
                                  const SizedBox(height: 10),
                                  _infoCard(Icons.badge_outlined, 'Employee ID', employeeId),
                                  const SizedBox(height: 10),
                                  _infoCard(Icons.shield_outlined, 'System Role', role.toUpperCase()),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryGreen,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => _logout(context),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.logout_rounded, size: 18, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Log Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ],
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
            ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
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
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}