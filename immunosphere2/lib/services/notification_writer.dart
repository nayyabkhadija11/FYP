import 'package:cloud_firestore/cloud_firestore.dart';

/// Cloud Functions ke baghair, app khud `notifications` collection me
/// parent ke liye doc likhta hai (Spark plan par bhi free).
class NotificationWriter {
  static String cleanCnic(String? c) => (c ?? '').replaceAll('-', '').trim();

  static Map<String, dynamic> _build({
    required String cnic,
    required String title,
    required String message,
    String? type,
    String? childId,
  }) {
    return {
      'parentCNIC': cleanCnic(cnic),
      'title': title,
      'message': message,
      'time': 'Just now',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      if (type != null) 'type': type,
      if (childId != null) 'childId': childId,
    };
  }

  /// Kisi maujooda WriteBatch ke andar notification add karo (atomic).
  static void addToBatch(
    WriteBatch batch, {
    required String cnic,
    required String title,
    required String message,
    String? type,
    String? childId,
  }) {
    if (cleanCnic(cnic).isEmpty) return;
    final ref = FirebaseFirestore.instance.collection('notifications').doc();
    batch.set(
      ref,
      _build(cnic: cnic, title: title, message: message, type: type, childId: childId),
    );
  }

  /// Akeli notification likho (batch ke baghair). Fail ho to main kaam na ruke.
  static Future<void> send({
    required String cnic,
    required String title,
    required String message,
    String? type,
    String? childId,
  }) async {
    if (cleanCnic(cnic).isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('notifications').add(
            _build(cnic: cnic, title: title, message: message, type: type, childId: childId),
          );
    } catch (_) {}
  }
}