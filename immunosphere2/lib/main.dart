/*import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Existing Screens
import 'screens/auth/splash_screen.dart';

// Campaign Module Screens
import 'screens/supervisor/create_campaign_screen.dart';
import 'screens/supervisor/polio_campaign_report_screen.dart';
import 'screens/supervisor/campaign_map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ImmunoSphere',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF10B981),
        scaffoldBackgroundColor: Colors.white,
      ),
      // App SplashScreen se start hoga
      home: const SplashScreen(),

      routes: {
        '/create_campaign': (context) => const CreateCampaignScreen(),
        '/polio_campaign_report': (context) => const PolioCampaignReportScreen(),
        '/campaign_map': (context) => const CampaignMapScreen(),
      },
    );
  }
} */
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Existing Screens
import 'screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ImmunoSphere',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF10B981),
        scaffoldBackgroundColor: Colors.white,
      ),
      // App SplashScreen se start hoga
      home: const SplashScreen(),
      // NEW: '/create_campaign', '/polio_campaign_report' aur
      // '/campaign_map' ki named routes hata di hain — yeh screens ab
      // required parameters (jaise campaignId) leti hain jo static
      // named routes ke through pass nahi ho sakte. In sab par navigate
      // karne ke liye ab hamesha MaterialPageRoute ke sath data pass
      // karein — jaise CampaignOverviewScreen mein pehle se ho raha hai.
    );
  }
}