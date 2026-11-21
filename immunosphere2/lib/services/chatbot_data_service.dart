import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../helpers/epi_schedule_helper.dart';
import '../models/child_model.dart';
import '../models/vaccination_task_model.dart';

// ===================================================================
// Data classes used by the chatbot
// ===================================================================
enum DoseState { vaccinated, refused, missed, overdue, dueToday, upcoming }

class DoseItem {
  final String vaccine;
  final String stage;
  final DateTime dueDate;
  final DoseState state;
  final DateTime? givenOn; // date of the vaccination / refusal record
  final String centre;

  const DoseItem({
    required this.vaccine,
    required this.stage,
    required this.dueDate,
    required this.state,
    this.givenOn,
    this.centre = '',
  });
}

/// One document of the `vaccinations` collection (written by the vaccinator).
class VaccinationRecord {
  final String vaccineName;
  final String dose;
  final DateTime? date;
  final String status; // vaccinated / refused
  final String centre;

  const VaccinationRecord({
    required this.vaccineName,
    required this.dose,
    required this.date,
    required this.status,
    required this.centre,
  });
}

class ChildVaccineData {
  final ChildModel child;
  final List<DoseItem> doses; // routine EPI schedule with real status
  final List<VaccinationRecord> records; // newest first
  final List<VaccinationTaskModel> polio; // polio campaign tasks
  final List<VaccinationTaskModel> attempts; // routine tasks marked absent/refused

  ChildVaccineData({
    required this.child,
    required this.doses,
    required this.records,
    required this.polio,
    required this.attempts,
  });

  static bool _isPending(DoseState s) =>
      s == DoseState.overdue ||
      s == DoseState.dueToday ||
      s == DoseState.upcoming;

  /// First stage of the schedule that still has pending vaccines
  /// (same rule as EpiScheduleHelper.calculateNextDue).
  List<DoseItem> get nextDue {
    final pending = doses.where((d) => _isPending(d.state)).toList();
    if (pending.isEmpty) return [];
    final stage = pending.first.stage;
    return pending.where((d) => d.stage == stage).toList();
  }

  bool get allDone =>
      doses.isNotEmpty && doses.every((d) => d.state == DoseState.vaccinated);

  List<DoseItem> get missed =>
      doses.where((d) => d.state == DoseState.missed).toList();

  List<DoseItem> get refused =>
      doses.where((d) => d.state == DoseState.refused).toList();

  List<DoseItem> get completed =>
      doses.where((d) => d.state == DoseState.vaccinated).toList();
}

// ===================================================================
// Helpers
// ===================================================================
DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime? _toDate(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

// Same matching rule as EpiScheduleHelper (so "TCV (Typhoid)" matches "TCV").
bool _same(String a, String b) {
  final x = _norm(a);
  final y = _norm(b);
  if (x.isEmpty || y.isEmpty) return false;
  return x == y || x.contains(y) || y.contains(x);
}

String _shortStage(String stage) =>
    stage.startsWith('At Birth') ? 'At Birth' : stage;

// ===================================================================
// SERVICE
// ===================================================================
class ChatbotDataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  ChildModel? _childFromDoc(String id, Map<String, dynamic> m) {
    final name = (m['name'] ?? m['fullName'] ?? '').toString().trim();
    final dob = _toDate(m['dob'] ?? m['dateOfBirth']);
    if (name.isEmpty || dob == null) return null;
    final avatar = m['avatarUrl']?.toString();
    return ChildModel(
      id: id,
      name: name,
      dob: dob,
      gender: (m['gender'] ?? '').toString(),
      parentName: (m['parentName'] ?? '').toString(),
      phone: (m['phone'] ?? '').toString(),
      village: (m['village'] ?? '').toString(),
      healthCenter: (m['healthCenter'] ?? m['centerName'] ?? '').toString(),
      avatarUrl: (avatar == null || avatar.isEmpty) ? null : avatar,
    );
  }

  /// Only the children registered under the logged-in parent.
  Future<List<ChildModel>> getMyChildren() async {
    final uid = _uid;
    if (uid == null) throw Exception('Not logged in');

    final snap = await _db
        .collection('children')
        .where('parentId', isEqualTo: uid)
        .get();

    final list = <ChildModel>[];
    for (final doc in snap.docs) {
      final c = _childFromDoc(doc.id, doc.data());
      if (c != null) list.add(c);
    }
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  /// Registration/campaign tasks of one child (only for this parent).
  Future<List<VaccinationTaskModel>> getTasksForChild(String childId) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not logged in');

    final snap = await _db
        .collection('vaccination_tasks')
        .where('parentId', isEqualTo: uid)
        .where('childId', isEqualTo: childId)
        .get();

    final list = <VaccinationTaskModel>[];
    for (final doc in snap.docs) {
      try {
        list.add(VaccinationTaskModel.fromMap(doc.data(), doc.id));
      } catch (_) {}
    }
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  /// Real vaccination records saved by the vaccinator for one child.
  Future<List<VaccinationRecord>> getRecordsForChild(String childId) async {
    final snap = await _db
        .collection('vaccinations')
        .where('childId', isEqualTo: childId)
        .get();

    final list = <VaccinationRecord>[];
    for (final doc in snap.docs) {
      final m = doc.data();
      var date = _toDate(m['administeredDate']);
      if (date == null && m['formattedDate'] is String) {
        try {
          date = DateFormat('dd MMM yyyy').parse(m['formattedDate'] as String);
        } catch (_) {}
      }
      final name = (m['vaccineName'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      list.add(VaccinationRecord(
        vaccineName: name,
        dose: (m['dose'] ?? '').toString(),
        date: date,
        status: (m['status'] ?? '').toString().toLowerCase().trim(),
        centre: (m['centerName'] ?? '').toString().trim(),
      ));
    }
    list.sort((a, b) {
      final x = a.date;
      final y = b.date;
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return y.compareTo(x);
    });
    return list;
  }

  /// Everything the chatbot needs about one child.
  Future<ChildVaccineData> getChildVaccineData(ChildModel child) async {
    final tasks = await getTasksForChild(child.id);
    final records = await getRecordsForChild(child.id);

    final today = _dayOnly(DateTime.now());
    final given = records.where((r) => r.status == 'vaccinated').toList();
    final refused = records.where((r) => r.status == 'refused').toList();
    final missedTasks = tasks
        .where((t) =>
            t.taskType == TaskType.routine && t.status == VaccineStatus.missed)
        .toList();

    VaccinationRecord? find(List<VaccinationRecord> l, String v) {
      for (final r in l) {
        if (_same(v, r.vaccineName)) return r;
      }
      return null;
    }

    final doses = <DoseItem>[];
    for (final stage in EpiScheduleHelper.generateEpiSchedule(child.dob)) {
      final stageName = _shortStage(stage['stage'] as String);
      final due = stage['dueDate'] as DateTime;
      final vaccines = List<String>.from(stage['vaccines'] as List);

      for (final v in vaccines) {
        final g = find(given, v);
        if (g != null) {
          doses.add(DoseItem(
            vaccine: v,
            stage: stageName,
            dueDate: due,
            state: DoseState.vaccinated,
            givenOn: g.date,
            centre: g.centre,
          ));
          continue;
        }

        final r = find(refused, v);
        if (r != null) {
          doses.add(DoseItem(
            vaccine: v,
            stage: stageName,
            dueDate: due,
            state: DoseState.refused,
            givenOn: r.date,
            centre: r.centre,
          ));
          continue;
        }

        final isMissed = missedTasks.any(
            (t) => t.vaccines.split(',').any((n) => _same(v, n.trim())));
        if (isMissed) {
          doses.add(DoseItem(
            vaccine: v,
            stage: stageName,
            dueDate: due,
            state: DoseState.missed,
          ));
          continue;
        }

        final d = _dayOnly(due);
        final state = d.isBefore(today)
            ? DoseState.overdue
            : (d == today ? DoseState.dueToday : DoseState.upcoming);
        doses.add(DoseItem(
          vaccine: v,
          stage: stageName,
          dueDate: due,
          state: state,
        ));
      }
    }

    final polio =
        tasks.where((t) => t.taskType == TaskType.polioCampaign).toList();
    final attempts = tasks
        .where((t) =>
            t.taskType == TaskType.routine &&
            (t.status == VaccineStatus.absent ||
                t.status == VaccineStatus.refused))
        .toList();

    return ChildVaccineData(
      child: child,
      doses: doses,
      records: records,
      polio: polio,
      attempts: attempts,
    );
  }
}