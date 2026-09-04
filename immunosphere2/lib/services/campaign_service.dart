/*import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child_model.dart';
import '../models/campaign_model.dart';

class CampaignService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getAreasWithChildCounts() async {
    final snapshot = await _db.collection('children').get();
    final Map<String, int> counts = {};
    for (var doc in snapshot.docs) {
      final village = (doc.data()['village'] ?? '').toString().trim();
      if (village.isEmpty) continue;
      counts[village] = (counts[village] ?? 0) + 1;
    }
    return counts.entries
        .map((e) => <String, dynamic>{'name': e.key, 'children': e.value})
        .toList()
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  }

  Future<List<ChildModel>> getChildrenInAreas(List<String> villages) async {
    if (villages.isEmpty) return [];
    final snapshot = await _db
        .collection('children')
        .where('village', whereIn: villages)
        .get();
    return snapshot.docs
        .map((doc) => ChildModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getVaccinators({String? healthCenter}) async {
    Query<Map<String, dynamic>> query = _db
        .collection('users')
        .where('role', whereIn: ['vaccinator', 'Vaccinator']);

    final trimmedCenter = healthCenter?.trim() ?? '';
    if (trimmedCenter.isNotEmpty) {
      query = query.where('healthCenter', isEqualTo: trimmedCenter);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return <String, dynamic>{
        'id': doc.id,
        'name': data['fullName'] ?? data['name'] ?? 'Unknown',
        'employeeId': data['employeeId'] ?? data['vaccinatorId'] ?? doc.id,
        'healthCenter': data['healthCenter'] ?? data['health_center'] ?? '',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getVaccinatorsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final List<Map<String, dynamic>> result = [];
    final snapshot = await _db
        .collection('users')
        .where(FieldPath.documentId, whereIn: ids)
        .get();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      result.add(<String, dynamic>{
        'id': doc.id,
        'name': data['fullName'] ?? data['name'] ?? 'Unknown',
        'employeeId': data['employeeId'] ?? data['vaccinatorId'] ?? doc.id,
      });
    }
    return result;
  }

  Map<String, List<String>> divideChildrenAmongVaccinators(
    List<String> childIds,
    List<String> vaccinatorIds,
  ) {
    final Map<String, List<String>> assignment = {
      for (var v in vaccinatorIds) v: []
    };
    if (vaccinatorIds.isEmpty) return assignment;
    for (int i = 0; i < childIds.length; i++) {
      final vaccinatorId = vaccinatorIds[i % vaccinatorIds.length];
      assignment[vaccinatorId]!.add(childIds[i]);
    }
    return assignment;
  }

  Future<String> createCampaign({
    required CampaignModel campaign,
    required Map<String, List<String>> assignment,
  }) async {
    final campaignRef = _db.collection('campaigns').doc();
    final batch = _db.batch();
    batch.set(campaignRef, campaign.toMap());

    final allChildIds = assignment.values.expand((ids) => ids).toSet().toList();
    final Map<String, Map<String, dynamic>> childDataById = {};

    for (var i = 0; i < allChildIds.length; i += 30) {
      final end = (i + 30 > allChildIds.length) ? allChildIds.length : i + 30;
      final chunk = allChildIds.sublist(i, end);
      if (chunk.isEmpty) continue;
      final snap = await _db
          .collection('children')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (var doc in snap.docs) {
        childDataById[doc.id] = doc.data();
      }
    }

    assignment.forEach((vaccinatorId, childIds) {
      for (var childId in childIds) {
        final childData = childDataById[childId] ?? <String, dynamic>{};
        final childName = (childData['fullName'] ?? childData['name'] ?? 'Unknown Child').toString();
        final address = (childData['houseAddress'] ?? childData['address'] ?? '').toString();
        final regNo = (childData['regNo'] ?? childId).toString();
        final age = _formatChildAge(childData['dob']);

        final latitude = childData['latitude'] is num ? (childData['latitude'] as num).toDouble() : null;
        final longitude = childData['longitude'] is num ? (childData['longitude'] as num).toDouble() : null;

        final childRef = _db.collection('children').doc(childId);
        batch.update(childRef, {
          'campaign_id': campaignRef.id,
          'assignedVaccinatorId': vaccinatorId,
        });

        final assignmentRef = _db.collection('campaign_assignments').doc();
        batch.set(assignmentRef, {
          'campaignId': campaignRef.id,
          'vaccinatorId': vaccinatorId,
          'childId': childId,
          'childName': childName,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          'age': age,
          'regNo': regNo,
          'status': 'Pending',
          'vaccineGiven': '',
          'fingerMark': '',
          'remarks': '',
          'assignedAt': FieldValue.serverTimestamp(),
        });
      }
    });

    await batch.commit();
    return campaignRef.id;
  }

  String _formatChildAge(dynamic dobVal) {
    DateTime? dob;
    if (dobVal is Timestamp) dob = dobVal.toDate();
    if (dobVal is String && dobVal.trim().isNotEmpty) dob = DateTime.tryParse(dobVal);
    if (dob == null) return 'N/A';

    final now = DateTime.now();
    int years = now.year - dob.year;
    int months = now.month - dob.month;
    if (months < 0) {
      years--;
      months += 12;
    }
    return years > 0 ? '${years}Y' : '${months}M';
  }

  Future<CampaignModel?> getCampaignById(String campaignId) async {
    final doc = await _db.collection('campaigns').doc(campaignId).get();
    if (!doc.exists || doc.data() == null) return null;
    return CampaignModel.fromMap(doc.data()!, doc.id);
  }

  // Sirf usi supervisor ki banai hui campaigns wapas laata hai —
  // Reports/Polio Campaign Report screen ke dropdown/picker ke liye.
  //
  // NOTE: 'orderBy' Firestore query se hata diya gaya hai — sorting ab
  // Dart mein ho rahi hai. 'where' + 'orderBy' dono ek sath composite
  // index maangte hain jo missing hone par query ko silently fail kar
  // deta tha (screen hamesha loading mein atki reh jati thi).
  Future<List<CampaignModel>> getCampaignsBySupervisor(String supervisorId) async {
    final snapshot = await _db
        .collection('campaigns')
        .where('supervisorId', isEqualTo: supervisorId)
        .get();
    final campaigns = snapshot.docs
        .map((doc) => CampaignModel.fromMap(doc.data(), doc.id))
        .toList();
    campaigns.sort((a, b) => b.startDate.compareTo(a.startDate));
    return campaigns;
  }

  Future<Map<String, List<Map<String, dynamic>>>> getChildrenGroupedByVaccinator(
      String campaignId) async {
    final snapshot = await _db
        .collection('children')
        .where('campaign_id', isEqualTo: campaignId)
        .get();

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final vaccinatorId = (data['assignedVaccinatorId'] ?? '').toString();
      if (vaccinatorId.isEmpty) continue;
      grouped.putIfAbsent(vaccinatorId, () => []);
      grouped[vaccinatorId]!.add(<String, dynamic>{
        'id': doc.id,
        'name': data['name'] ?? data['fullName'] ?? 'Unknown',
        'houseAddress': data['houseAddress'] ?? '',
      });
    }
    return grouped;
  }
} */
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child_model.dart';
import '../models/campaign_model.dart';

class CampaignService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getAreasWithChildCounts() async {
    final snapshot = await _db.collection('children').get();
    final Map<String, int> counts = {};
    for (var doc in snapshot.docs) {
      final village = (doc.data()['village'] ?? '').toString().trim();
      if (village.isEmpty) continue;
      counts[village] = (counts[village] ?? 0) + 1;
    }
    return counts.entries
        .map((e) => <String, dynamic>{'name': e.key, 'children': e.value})
        .toList()
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  }

  Future<List<ChildModel>> getChildrenInAreas(List<String> villages) async {
    if (villages.isEmpty) return [];
    final snapshot = await _db
        .collection('children')
        .where('village', whereIn: villages)
        .get();
    return snapshot.docs
        .map((doc) => ChildModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getVaccinators({String? healthCenter}) async {
    Query<Map<String, dynamic>> query = _db
        .collection('users')
        .where('role', whereIn: ['vaccinator', 'Vaccinator']);

    final trimmedCenter = healthCenter?.trim() ?? '';
    if (trimmedCenter.isNotEmpty) {
      query = query.where('healthCenter', isEqualTo: trimmedCenter);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return <String, dynamic>{
        'id': doc.id,
        'name': data['fullName'] ?? data['name'] ?? 'Unknown',
        'employeeId': data['employeeId'] ?? data['vaccinatorId'] ?? doc.id,
        'healthCenter': data['healthCenter'] ?? data['health_center'] ?? '',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getVaccinatorsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final List<Map<String, dynamic>> result = [];
    final snapshot = await _db
        .collection('users')
        .where(FieldPath.documentId, whereIn: ids)
        .get();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      result.add(<String, dynamic>{
        'id': doc.id,
        'name': data['fullName'] ?? data['name'] ?? 'Unknown',
        'employeeId': data['employeeId'] ?? data['vaccinatorId'] ?? doc.id,
      });
    }
    return result;
  }

  Map<String, List<String>> divideChildrenAmongVaccinators(
    List<String> childIds,
    List<String> vaccinatorIds,
  ) {
    final Map<String, List<String>> assignment = {
      for (var v in vaccinatorIds) v: []
    };
    if (vaccinatorIds.isEmpty) return assignment;
    for (int i = 0; i < childIds.length; i++) {
      final vaccinatorId = vaccinatorIds[i % vaccinatorIds.length];
      assignment[vaccinatorId]!.add(childIds[i]);
    }
    return assignment;
  }

  Future<String> createCampaign({
    required CampaignModel campaign,
    required Map<String, List<String>> assignment,
  }) async {
    final campaignRef = _db.collection('campaigns').doc();
    final batch = _db.batch();
    batch.set(campaignRef, campaign.toMap());

    final allChildIds = assignment.values.expand((ids) => ids).toSet().toList();
    final Map<String, Map<String, dynamic>> childDataById = {};

    for (var i = 0; i < allChildIds.length; i += 30) {
      final end = (i + 30 > allChildIds.length) ? allChildIds.length : i + 30;
      final chunk = allChildIds.sublist(i, end);
      if (chunk.isEmpty) continue;
      final snap = await _db
          .collection('children')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (var doc in snap.docs) {
        childDataById[doc.id] = doc.data();
      }
    }

    assignment.forEach((vaccinatorId, childIds) {
      for (var childId in childIds) {
        final childData = childDataById[childId] ?? <String, dynamic>{};
        final childName = (childData['fullName'] ?? childData['name'] ?? 'Unknown Child').toString();
        final address = (childData['houseAddress'] ?? childData['address'] ?? '').toString();
        final regNo = (childData['regNo'] ?? childId).toString();
        final age = _formatChildAge(childData['dob']);

        final latitude = childData['latitude'] is num ? (childData['latitude'] as num).toDouble() : null;
        final longitude = childData['longitude'] is num ? (childData['longitude'] as num).toDouble() : null;

        final childRef = _db.collection('children').doc(childId);
        batch.update(childRef, {
          'campaign_id': campaignRef.id,
          'assignedVaccinatorId': vaccinatorId,
        });

        final assignmentRef = _db.collection('campaign_assignments').doc();
        batch.set(assignmentRef, {
          'campaignId': campaignRef.id,
          'vaccinatorId': vaccinatorId,
          'childId': childId,
          'childName': childName,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          'age': age,
          'regNo': regNo,
          'status': 'Pending',
          'vaccineGiven': '',
          'fingerMark': '',
          'remarks': '',
          'assignedAt': FieldValue.serverTimestamp(),
        });
      }
    });

    await batch.commit();
    return campaignRef.id;
  }

  String _formatChildAge(dynamic dobVal) {
    DateTime? dob;
    if (dobVal is Timestamp) dob = dobVal.toDate();
    if (dobVal is String && dobVal.trim().isNotEmpty) dob = DateTime.tryParse(dobVal);
    if (dob == null) return 'N/A';

    final now = DateTime.now();
    int years = now.year - dob.year;
    int months = now.month - dob.month;
    if (months < 0) {
      years--;
      months += 12;
    }
    return years > 0 ? '${years}Y' : '${months}M';
  }

  Future<CampaignModel?> getCampaignById(String campaignId) async {
    final doc = await _db.collection('campaigns').doc(campaignId).get();
    if (!doc.exists || doc.data() == null) return null;
    return CampaignModel.fromMap(doc.data()!, doc.id);
  }

  // NEW: ab yeh SAB campaigns wapas laata hai (supervisorId filter hata
  // diya gaya hai) — taake purani campaigns (jinme supervisorId field
  // save hi nahi hui thi kyunke wo field baad mein add hua) bhi
  // dropdown mein dikhein, sirf nayi banayi hui campaigns hi nahi.
  // Parameter (supervisorId) filhal use nahi ho raha, method ka
  // naam/signature same rakha gaya hai taake reports_screen.dart aur
  // polio_campaign_report_screen.dart mein koi tabdeeli na karni pare.
  Future<List<CampaignModel>> getCampaignsBySupervisor(String supervisorId) async {
    final snapshot = await _db.collection('campaigns').get();
    final campaigns = snapshot.docs
        .map((doc) => CampaignModel.fromMap(doc.data(), doc.id))
        .toList();
    campaigns.sort((a, b) => b.startDate.compareTo(a.startDate));
    return campaigns;
  }

  Future<Map<String, List<Map<String, dynamic>>>> getChildrenGroupedByVaccinator(
      String campaignId) async {
    final snapshot = await _db
        .collection('children')
        .where('campaign_id', isEqualTo: campaignId)
        .get();

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final vaccinatorId = (data['assignedVaccinatorId'] ?? '').toString();
      if (vaccinatorId.isEmpty) continue;
      grouped.putIfAbsent(vaccinatorId, () => []);
      grouped[vaccinatorId]!.add(<String, dynamic>{
        'id': doc.id,
        'name': data['name'] ?? data['fullName'] ?? 'Unknown',
        'houseAddress': data['houseAddress'] ?? '',
      });
    }
    return grouped;
  }
}