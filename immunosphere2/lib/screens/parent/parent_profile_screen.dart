import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart'; // Apni Login Screen ka path yahan check kar lein

class ParentProfileScreen extends StatefulWidget {
  final String parentCNIC; // <-- CNIC parameter added

  const ParentProfileScreen({
    Key? key,
    required this.parentCNIC, // <-- Constructor fix
  }) : super(key: key);

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // COLOR THEME: supervisor/vaccinator profile ke sath consistent (deep green)
  static const Color primaryGreen = Color(0xFF0B4D30);
  static const Color lightBgGreen = Color(0xFFEBF7F0);

  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _userData = doc.data() as Map<String, dynamic>?;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleLogout() async {
    try {
      await _auth.signOut();
      if (!mounted) return;

      // Logout hone ke baad Login Screen par redirect karein
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F7FB),
        body: Center(child: CircularProgressIndicator(color: primaryGreen)),
      );
    }

    String fullName = _userData?['fullName'] ?? 'N/A';
    String email = _userData?['email'] ?? _auth.currentUser?.email ?? 'N/A';
    String phone = _userData?['phone'] ?? 'N/A';
    // Prioritize passed CNIC or fetch from firestore data
    String cnic = _userData?['cnic'] ?? (widget.parentCNIC.isNotEmpty ? widget.parentCNIC : 'N/A');

    String joinedOn = 'N/A';
    if (_userData?['createdAt'] != null) {
      DateTime dt = (_userData!['createdAt'] as Timestamp).toDate();
      joinedOn = "${dt.day} ${_getMonthName(dt.month)} ${dt.year}";
    }

    return Scaffold(
      // UI: sirf top header strip green hai, baaki page background
      // halka/white hai (supervisor/vaccinator profile jaisa)
      backgroundColor: const Color(0xFFF6F7FB),
      body: SingleChildScrollView(
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
                  'Parent Profile',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),

            // Green header ke baad sab kuch (card + logout) upar shift
            // kiya hai (Transform.translate) taake white card green
            // header par overlap kare — supervisor/vaccinator profile
            // jaisa exact design.
            Transform.translate(
              offset: const Offset(0, -30),
              child: Column(
                children: [
                  // WHITE CARD: avatar + name + info rows
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
                              child: Icon(Icons.person_rounded, size: 44, color: primaryGreen),
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
                        const Text('Parent', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 20),

                        _buildDetailTile(Icons.phone_outlined, 'Phone', phone),
                        const SizedBox(height: 10),
                        _buildDetailTile(Icons.email_outlined, 'Email', email),
                        const SizedBox(height: 10),
                        _buildDetailTile(Icons.badge_outlined, 'CNIC', cnic),
                        const SizedBox(height: 10),
                        _buildDetailTile(Icons.calendar_today_outlined, 'Joined On', joinedOn),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // LOGOUT BUTTON — solid green (supervisor/vaccinator jaisa)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _handleLogout,
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

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}