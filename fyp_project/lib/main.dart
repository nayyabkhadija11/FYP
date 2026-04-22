import 'package:flutter/material.dart';
import 'role_selection_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'vaccinator_dashboard.dart'; 
import 'parent_portal_page.dart'; // Ensure this file name matches your actual file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ImmunoSphere',
      initialRoute: '/role', 
      routes: {
        '/role': (context) => const RoleSelectionScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/vaccinator_dashboard': (context) => VaccinatorDashboard(),
        
        // This is the route your app was looking for:
        '/dashboard': (context) => const ParentPortal(),
        
        // Also keeping this for consistency
        '/parent_portal': (context) => const ParentPortal(),
      },
    );
  }
}