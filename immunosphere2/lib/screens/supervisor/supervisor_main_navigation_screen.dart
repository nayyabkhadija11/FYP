import 'package:flutter/material.dart';
import 'supervisor_dashboard_screen.dart';
import 'vaccinators_list_screen.dart';
import 'supervisor_campaigns_screen.dart';
import 'supervisor_reports_screen.dart';

class SupervisorMainNavigationScreen extends StatefulWidget {
  const SupervisorMainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<SupervisorMainNavigationScreen> createState() =>
      _SupervisorMainNavigationScreenState();
}

class _SupervisorMainNavigationScreenState
    extends State<SupervisorMainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SupervisorDashboardScreen(),
    VaccinatorsListScreen(),
    SupervisorCampaignsScreen(),
    SupervisorReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF3F2B96),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Vaccinators'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Campaigns'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
        ],
      ),
    );
  }
}