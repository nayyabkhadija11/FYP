/*import 'package:cloud_firestore/cloud_firestore.dart';
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
} */
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../helpers/epi_schedule_helper.dart';
import '../models/child_model.dart';
import '../models/vaccination_task_model.dart';

// ===================================================================
// Works with your EXISTING models and registration code (no changes needed
// anywhere else):
//  - children are found through the parent's CNIC (users/{uid}.cnic)
//  - tasks without dueDate (saved by register_child_screen) are handled
//  - "missed" = 14 days after due date (same rule as checkMissedVaccines)
// ===================================================================

/// Age text computed from DOB (use this instead of child.formattedAge).
extension ChildAge on ChildModel {
  String get ageLabel {
    final now = DateTime.now();
    var m = (now.year - dob.year) * 12 + now.month - dob.month;
    if (now.day < dob.day) m--;
    if (m < 1) {
      final days = now.difference(dob).inDays;
      return '${days < 0 ? 0 : days} Days';
    }
    if (m < 24) return '$m Months';
    final y = m ~/ 12;
    final r = m % 12;
    return r == 0 ? '$y Years' : '$y Years $r Months';
  }
}

enum DoseState { vaccinated, refused, missed, overdue, dueToday, upcoming }

class DoseItem {
  final String vaccine;
  final String stage;
  final DateTime dueDate;
  final DoseState state;
  final DateTime? givenOn;
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
  final String status; // vaccinated / refused / missed
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
  final List<DoseItem> doses;
  final List<VaccinationRecord> records; // newest first
  final List<VaccinationTaskModel> polio;
  final List<VaccinationTaskModel> attempts;

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

  /// First stage that still has pending vaccines.
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

  /// Health centre: from the child document, else from the latest record.
  String get centre {
    if (child.healthCenter.trim().isNotEmpty) return child.healthCenter.trim();
    for (final r in records) {
      if (r.centre.isNotEmpty) return r.centre;
    }
    return '';
  }
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

bool _same(String a, String b) {
  final x = _norm(a);
  final y = _norm(b);
  if (x.isEmpty || y.isEmpty) return false;
  return x == y || x.contains(y) || y.contains(x);
}

String _shortStage(String stage) =>
    stage.startsWith('At Birth') ? 'At Birth' : stage;

const int _graceDays = 14;

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
      parentName: (m['parentName'] ?? m['motherName'] ?? '').toString(),
      phone: (m['phone'] ?? m['phoneNumber'] ?? '').toString(),
      village: (m['village'] ?? '').toString(),
      healthCenter: (m['healthCenter'] ?? m['centerName'] ?? '').toString(),
      avatarUrl: (avatar == null || avatar.isEmpty) ? null : avatar,
    );
  }

  /// Children of the logged-in parent (matched by CNIC; parentId also
  /// checked in case some children have it).
  Future<List<ChildModel>> getMyChildren() async {
    final uid = _uid;
    if (uid == null) throw Exception('Not logged in');

    final found = <String, ChildModel>{};
    void collect(QuerySnapshot<Map<String, dynamic>> snap) {
      for (final doc in snap.docs) {
        final c = _childFromDoc(doc.id, doc.data());
        if (c != null) found[doc.id] = c;
      }
    }

    final u = await _db.collection('users').doc(uid).get();
    final clean =
        (u.data()?['cnic'] ?? '').toString().replaceAll('-', '').trim();

    if (clean.isNotEmpty) {
      final values = <String>[clean];
      if (clean.length == 13) {
        values.add(
            '${clean.substring(0, 5)}-${clean.substring(5, 12)}-${clean.substring(12)}');
      }
      collect(await _db
          .collection('children')
          .where('cnic', whereIn: values)
          .get());
    }

    try {
      collect(await _db
          .collection('children')
          .where('parentId', isEqualTo: uid)
          .get());
    } catch (_) {}

    final list = found.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  /// Routine + polio tasks of one child. Parsed manually so tasks saved
  /// without dueDate (registration) are not lost.
  Future<List<VaccinationTaskModel>> getTasksForChild(ChildModel child) async {
    final snap = await _db
        .collection('vaccination_tasks')
        .where('childId', isEqualTo: child.id)
        .get();

    final list = <VaccinationTaskModel>[];
    for (final doc in snap.docs) {
      try {
        final m = doc.data();
        final isPolio = m['taskType'] == 'polio';
        final due = _toDate(m['dueDate']) ??
            (isPolio ? _toDate(m['createdAt']) : child.dob) ??
            child.dob;
        final statusName = (m['status'] ?? '').toString();
        list.add(VaccinationTaskModel(
          taskId: doc.id,
          childId: (m['childId'] ?? '').toString(),
          childName: (m['childName'] ?? '').toString(),
          village: (m['village'] ?? '').toString(),
          ageFormatted: (m['ageFormatted'] ?? '').toString(),
          taskType: isPolio ? TaskType.polioCampaign : TaskType.routine,
          vaccines: (m['vaccines'] ?? m['vaccineName'] ?? '').toString(),
          dueDate: due,
          status: VaccineStatus.values.firstWhere(
            (e) => e.name == statusName,
            orElse: () => VaccineStatus.dueToday,
          ),
        ));
      } catch (_) {}
    }
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  /// Real vaccination records saved by the vaccinator.
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

  /// Health centre of a child (child doc, else latest vaccination record).
  Future<String> getHealthCentre(ChildModel child) async {
    if (child.healthCenter.trim().isNotEmpty) return child.healthCenter.trim();
    try {
      final recs = await getRecordsForChild(child.id);
      for (final r in recs) {
        if (r.centre.isNotEmpty) return r.centre;
      }
    } catch (_) {}
    return '';
  }

  /// Everything the chatbot needs about one child.
  Future<ChildVaccineData> getChildVaccineData(ChildModel child) async {
    final tasks = await getTasksForChild(child);
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

        final d = _dayOnly(due);
        final graceOver =
            d.isBefore(today.subtract(const Duration(days: _graceDays)));
        final markedMissed = missedTasks.any(
            (t) => t.vaccines.split(',').any((n) => _same(v, n.trim())));

        if (graceOver || markedMissed) {
          doses.add(DoseItem(
            vaccine: v,
            stage: stageName,
            dueDate: due,
            state: DoseState.missed,
          ));
          continue;
        }

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

    // Polio campaign tasks (done if a polio dose was recorded near the date).
    final polio = tasks.where((t) => t.taskType == TaskType.polioCampaign).map((t) {
      if (t.status == VaccineStatus.dueToday) {
        final done = records.any((r) =>
            r.status == 'vaccinated' &&
            (r.vaccineName.toLowerCase().contains('polio') ||
                r.vaccineName.toLowerCase().contains('opv')) &&
            r.date != null &&
            _dayOnly(r.date!).difference(_dayOnly(t.dueDate)).inDays.abs() <=
                7);
        if (done) t.status = VaccineStatus.vaccinated;
      }
      return t;
    }).toList();

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