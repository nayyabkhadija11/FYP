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

  static const Color primaryGreen = Color(0xFF0E9F6E);
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
        backgroundColor: Color(0xFFF9FAFB),
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Parent Profile', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // PROFILE AVATAR & NAME
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: Color(0xFFE5F7ED),
                      child: Icon(Icons.person_rounded, size: 52, color: primaryGreen),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      fullName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    const Text('Parent', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // DETAILS CONTAINER (Phone, Email, CNIC, Joined On)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.phone_outlined, 'Phone', phone),
                    const Divider(height: 1, indent: 48),
                    _buildDetailRow(Icons.email_outlined, 'Email', email),
                    const Divider(height: 1, indent: 48),
                    _buildDetailRow(Icons.badge_outlined, 'CNIC', cnic),
                    const Divider(height: 1, indent: 48),
                    _buildDetailRow(Icons.calendar_today_outlined, 'Joined On', joinedOn),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // LOGOUT BUTTON CONTAINER
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                  title: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                  onTap: _handleLogout,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: primaryGreen, size: 20),
          const SizedBox(width: 14),
          SizedBox(
            width: 75,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
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