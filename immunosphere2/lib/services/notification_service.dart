/*import 'package:firebase_messaging/firebase_messaging.dart';
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
} */
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:immunosphere2/helpers/epi_schedule_helper.dart';
import 'package:immunosphere2/helpers/vaccination_status_helper.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static bool _localReady = false;
  static StreamSubscription<QuerySnapshot>? _sub;
  static final Set<String> _shown = {};

  // Local notifications sirf Android/iOS par chalti hain (web par nahi).
  static bool get _supportsLocal =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'immunosphere_alerts',
      'ImmunoSphere Alerts',
      channelDescription: 'Vaccination alerts and reminders',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  // ---------------------------------------------------------------
  // (Purana) FCM token save -- jaisa pehle tha waisa hi
  // ---------------------------------------------------------------
  static Future<void> initAndSaveToken() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    final String? token = await _messaging.getToken();
    if (token == null) return;

    await _saveTokenToFirestore(token);
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

  // ---------------------------------------------------------------
  // NEW: local notifications setup
  // ---------------------------------------------------------------
  static Future<void> initLocal() async {
    if (!_supportsLocal || _localReady) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Karachi'));

      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _local.initialize(initSettings);

      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      _localReady = true;
    } catch (e) {
      debugPrint('Local notifications init failed: $e');
    }
  }

  static int _stableId(String s) {
    int h = 0;
    for (final r in s.runes) {
      h = (h * 31 + r) & 0x3fffffff;
    }
    return h;
  }

  // ---------------------------------------------------------------
  // NEW: parent ke naye in-app notification doc par phone banner
  // ---------------------------------------------------------------
  static void startListening(String parentCnic) {
    if (!_localReady) return;
    final cnic = parentCnic.replaceAll('-', '').trim();
    if (cnic.isEmpty) return;

    _sub?.cancel();
    _sub = FirebaseFirestore.instance
        .collection('notifications')
        .where('parentCNIC', isEqualTo: cnic)
        .snapshots()
        .listen((snap) {
      bool anyNew = false;
      for (final ch in snap.docChanges) {
        if (ch.type != DocumentChangeType.added) continue;
        final d = ch.doc.data();
        if (d == null) continue;
        if (_shown.contains(ch.doc.id)) continue;

        // Sirf taaza notifications (purani list load hone par banner nahi)
        final ts = d['createdAt'];
        if (ts is Timestamp &&
            DateTime.now().difference(ts.toDate()).inMinutes > 10) {
          continue;
        }

        _shown.add(ch.doc.id);
        anyNew = true;
        _local.show(
          _stableId(ch.doc.id),
          (d['title'] ?? 'ImmunoSphere').toString(),
          (d['message'] ?? '').toString(),
          _details,
        );
      }
      // Koi vaccine record hui ho to reminders dobara hisaab se lagao
      if (anyNew) syncDueReminders(cnic);
    }, onError: (_) {});
  }

  static void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  // ---------------------------------------------------------------
  // NEW: roz subah 9 baje (Pakistan time) due vaccine reminder.
  // Har bache ke liye ek repeating notification: pehli un-lagi
  // vaccine ki date se shuru, aur roz tab tak jab tak app me vaccine
  // record na ho jaye (agli sync par band ho jati hai).
  // ---------------------------------------------------------------
  static Future<void> syncDueReminders(String parentCnic) async {
    if (!_localReady) return;
    try {
      final cnic = parentCnic.replaceAll('-', '').trim();
      if (cnic.isEmpty) return;
      final db = FirebaseFirestore.instance;

      // Pehle purani reminders hatao
      final pending = await _local.pendingNotificationRequests();
      for (final p in pending) {
        if ((p.payload ?? '').startsWith('reminder:')) {
          await _local.cancel(p.id);
        }
      }

      final kids =
          await db.collection('children').where('cnic', isEqualTo: cnic).get();
      final now = DateTime.now();

      for (final c in kids.docs) {
        final data = c.data();
        if (!VaccinationStatusHelper.hasValidDob(data['dob'])) continue;
        final dob = VaccinationStatusHelper.parseDob(data['dob']);
        final childName =
            (data['fullName'] ?? data['name'] ?? 'Your child').toString();

        final ids = <String>{c.id};
        final reg = (data['regNo'] ?? '').toString();
        if (reg.isNotEmpty) ids.add(reg);

        final vs = await db
            .collection('vaccinations')
            .where('childId', whereIn: ids.toList())
            .get();
        // Refused ko "lagi hui" nahi maana jata
        final given = vs.docs
            .where((d) =>
                (d.data()['status'] ?? '').toString().toLowerCase() !=
                'refused')
            .map((d) => VaccinationStatusHelper.normalize(
                (d.data()['vaccineName'] ?? '').toString()))
            .toList();

        DateTime? firstDue;
        final stageUngiven = <MapEntry<DateTime, List<String>>>[];

        for (final stage in EpiScheduleHelper.generateEpiSchedule(dob)) {
          final due = stage['dueDate'] as DateTime;
          final ungiven = <String>[];
          for (final v in List<String>.from(stage['vaccines'])) {
            final t = VaccinationStatusHelper.normalize(v);
            final isGiven = given.any(
                (s) => s.isNotEmpty && (s == t || s.contains(t) || t.contains(s)));
            if (!isGiven) ungiven.add(v);
          }
          if (ungiven.isNotEmpty) {
            stageUngiven.add(MapEntry(due, ungiven));
            firstDue ??= due;
          }
        }

        if (firstDue == null) continue; // sab vaccines lag chuki hain

        // Future wali date par abhi reminder nahi, sirf us date se shuru
        final threshold = firstDue.isAfter(now) ? firstDue : now;
        final names = <String>[
          for (final e in stageUngiven)
            if (!e.key.isAfter(threshold)) ...e.value,
        ];
        if (names.isEmpty) continue;

        final nowTz = tz.TZDateTime.now(tz.local);
        var start = tz.TZDateTime(
            tz.local, firstDue.year, firstDue.month, firstDue.day, 9);
        if (start.isBefore(nowTz)) {
          start = tz.TZDateTime(
              tz.local, nowTz.year, nowTz.month, nowTz.day, 9);
          if (start.isBefore(nowTz)) start = start.add(const Duration(days: 1));
        }

        await _local.zonedSchedule(
          _stableId('reminder_${c.id}'),
          'Vaccine Due Reminder',
          '$childName has pending vaccines: ${names.join(', ')}. '
              'Please visit your nearest BHU center.',
          start,
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'reminder:${c.id}',
        );
      }
    } catch (e) {
      debugPrint('syncDueReminders failed: $e');
    }
  }
}