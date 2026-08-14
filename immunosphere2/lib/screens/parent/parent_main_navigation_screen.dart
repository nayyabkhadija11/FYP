/*import 'package:flutter/material.dart';
import 'parent_home_screen.dart';
import 'my_children_screen.dart';
import 'health_education_screen.dart';
import 'parent_vaccination_history_screen.dart';
import 'parent_profile_screen.dart';
import 'ai_assistant_screen.dart';

class ParentMainNavigationScreen extends StatefulWidget {
  final String parentCNIC;

  const ParentMainNavigationScreen({
    Key? key,
    required this.parentCNIC,
  }) : super(key: key);

  @override
  State<ParentMainNavigationScreen> createState() =>
      _ParentMainNavigationScreenState();
}

class _ParentMainNavigationScreenState
    extends State<ParentMainNavigationScreen> {
  int _currentIndex = 0;

  static const Color primaryGreen = Color(0xFF0F8A5F);

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Standardize CNIC formatting for consistent Firestore sub-queries across ALL screens
    final String cleanCNIC = widget.parentCNIC.replaceAll('-', '').trim();

    // List of screens utilizing the normalized cleanCNIC
    final List<Widget> screens = [
      ParentHomeScreen(
        parentCnic: cleanCNIC,
        onNavigateToTab: (index) {
          if (index == 99) {
            // Special index flag for pushing Health Education standalone route
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HealthEducationScreen(),
              ),
            );
          } else if (index >= 0 && index < 4) {
            _onTabTapped(index);
          }
        },
      ),
      MyChildrenScreen(parentCNIC: cleanCNIC),
      ParentVaccinationHistoryScreen(parentCNIC: cleanCNIC),
      ParentProfileScreen(parentCNIC: cleanCNIC),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),

      // FLOATING AI BOT BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AIAssistantScreen(),
            ),
          );
        },
        backgroundColor: primaryGreen,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.smart_toy_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),

      // BOTTOM NAVIGATION BAR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey.shade500,
        backgroundColor: Colors.white,
        elevation: 10,
        selectedLabelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.child_care_rounded),
            label: 'Children',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
} */
import 'package:flutter/material.dart';
import 'parent_home_screen.dart';
import 'my_children_screen.dart';
import 'health_education_screen.dart';
import 'parent_vaccination_history_screen.dart';
import 'parent_profile_screen.dart';
import 'ai_assistant_screen.dart';
import 'package:immunosphere2/services/notification_service.dart';

class ParentMainNavigationScreen extends StatefulWidget {
  final String parentCNIC;

  const ParentMainNavigationScreen({
    Key? key,
    required this.parentCNIC,
  }) : super(key: key);

  @override
  State<ParentMainNavigationScreen> createState() =>
      _ParentMainNavigationScreenState();
}

class _ParentMainNavigationScreenState
    extends State<ParentMainNavigationScreen> {
  int _currentIndex = 0;

  static const Color primaryGreen = Color(0xFF0F8A5F);

  @override
  void initState() {
    super.initState();
    // Requests notification permission and saves this device's FCM
    // token to Firestore (users/{uid}.fcmToken) so Cloud Functions can
    // send push notifications to this parent later.
    NotificationService.initAndSaveToken();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Standardize CNIC formatting for consistent Firestore sub-queries across ALL screens
    final String cleanCNIC = widget.parentCNIC.replaceAll('-', '').trim();

    // List of screens utilizing the normalized cleanCNIC
    final List<Widget> screens = [
      ParentHomeScreen(
        parentCnic: cleanCNIC,
        onNavigateToTab: (index) {
          if (index == 99) {
            // Special index flag for pushing Health Education standalone route
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HealthEducationScreen(),
              ),
            );
          } else if (index >= 0 && index < 4) {
            _onTabTapped(index);
          }
        },
      ),
      MyChildrenScreen(parentCNIC: cleanCNIC),
      ParentVaccinationHistoryScreen(parentCNIC: cleanCNIC),
      ParentProfileScreen(parentCNIC: cleanCNIC),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),

      // FLOATING AI BOT BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AIAssistantScreen(),
            ),
          );
        },
        backgroundColor: primaryGreen,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.smart_toy_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),

      // BOTTOM NAVIGATION BAR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey.shade500,
        backgroundColor: Colors.white,
        elevation: 10,
        selectedLabelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.child_care_rounded),
            label: 'Children',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}