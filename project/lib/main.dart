/*import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Screens
import 'login_screen.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'vaccinator_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase initialization (ONLY ONCE)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 👇 FIRST SCREEN
      home: const LoginScreen(),

      // ✅ ROUTES (FIXED)
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),

        // ❗ IMPORTANT: no const needed if constructor not const-safe
        '/vaccinator_screen': (context) => VaccinatorScreen(),
      },

      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
    );
  }
}*/
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Screens
import 'login_screen.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'vaccinator_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ FIREBASE INITIALIZATION (ONLY ONCE)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 👇 FIRST SCREEN
      home: const LoginScreen(),

      // ✅ ROUTES
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/vaccinator_screen': (context) => VaccinatorScreen(),
      },

      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
    );
  }
}