import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Call this once, right after the parent logs in / app starts with a
  /// logged-in user. Requests notification permission, gets the device's
  /// FCM token, and saves it to the user's Firestore doc so Cloud
  /// Functions can find it later by CNIC.
  static Future<void> initAndSaveToken() async {
    // 1. Ask for permission (required on iOS, and Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Get the device token
    final String? token = await _messaging.getToken();
    if (token == null) return;

    await _saveTokenToFirestore(token);

    // 3. Keep it updated if it ever refreshes
    _messaging.onTokenRefresh.listen(_saveTokenToFirestore);
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }
}