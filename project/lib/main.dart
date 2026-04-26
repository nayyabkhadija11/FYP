import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';

// Screens
import 'splash_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'vaccinator_screen.dart';
import 'parent_screen.dart';
import 'supervisor_screen.dart';
import 'finance_screen.dart';

// =====================
// NOTIFICATION SETUP
// =====================
final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔔 Local Notifications init
  const androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const settings =
      InitializationSettings(android: androidInit);

  await notifications.initialize(settings);

  runApp(const MyApp());
}

// =====================
// ROOT APP
// =====================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 🔥 FIRST SCREEN
      //home: const LoginScreen(),
      home: const SplashScreen(),


      // 🧭 ROUTES
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/vaccinator_screen': (context) => VaccinatorScreen(),
        '/parent_screen': (context) => const ParentScreen(),
        '/supervisor_screen': (context) => const SupervisorScreen(),
        '/finance_screen': (context) => const FinanceScreen(),
      },

      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
    );
  }
}