/*import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../helpers/epi_schedule_helper.dart';
import '../helpers/vaccination_status_helper.dart';

// =====================================================================
// SETTINGS
// =====================================================================
class AiConfig {
  // Python (FastAPI) server ka address:
  //  - Chrome (web) / Windows desktop : 'http://127.0.0.1:8000'
  //  - Android emulator               : 'http://10.0.2.2:8000'
  //  - Asli phone (same WiFi)         : 'http://<laptop ka WiFi IP>:8000'
  static const String serverUrl = 'http://127.0.0.1:8000';

  static const String healthCenter = 'DHQ Hospital Attock';

  // Coverage ka target (%). Isse neeche wale areas "at risk" gine jate hain.
  static const double coverageTarget = 90;
}

// =====================================================================
// VACCINE -> DISEASE TABLE (ye AI nahi, seedha mapping hai)
// =====================================================================
class DiseaseMap {
  static String group(String vaccineName) {
    final n = VaccinationStatusHelper.normalize(vaccineName);
    if (n.contains('bcg')) return 'BCG';
    if (n.contains('opv')) return 'Polio';
    if (n.contains('ipv')) return 'Polio';
    if (n.contains('penta')) return 'Pentavalent';
    if (n.contains('pcv')) return 'PCV';
    if (n.contains('rota')) return 'Rotavirus';
    if (n.contains('measles') || n.contains('mr')) return 'Measles';
    if (n.contains('tcv') || n.contains('typhoid')) return 'TCV';
    return vaccineName;
  }

  // Table mein chhota naam
  static String disease(String group) {
    switch (group) {
      case 'BCG':
        return 'Tuberculosis';
      case 'Polio':
        return 'Poliomyelitis';
      case 'Pentavalent':
        return 'Diphtheria';
      case 'PCV':
        return 'Pneumonia';
      case 'Rotavirus':
        return 'Rotavirus diarrhoea';
      case 'Measles':
        return 'Measles';
      case 'TCV':
        return 'Typhoid';
      default:
        return group;
    }
  }

  // Alert ke text mein poora naam
  static String longDisease(String group) {
    if (group == 'Pentavalent') {
      return 'Diphtheria, whooping cough, tetanus, Hepatitis B and Hib';
    }
    return disease(group);
  }
}

// =====================================================================
// RESULT MODELS
// =====================================================================
class RiskChild {
  final String docId;
  final String displayId;
  final String name;
  final String area;
  final String missedVaccine;
  final int missedDoses;
  final String disease;
  final String status; // 'High Risk' | 'At Risk'
  final double probability; // 0..1, -1 = AI score nahi
  final Set<String> groups;

  RiskChild({
    required this.docId,
    required this.displayId,
    required this.name,
    required this.area,
    required this.missedVaccine,
    required this.missedDoses,
    required this.disease,
    required this.status,
    required this.probability,
    required this.groups,
  });
}

class AreaStat {
  final String name;
  final double coverage;
  final int total;
  AreaStat({required this.name, required this.coverage, required this.total});
}

class InsightsResult {
  final String kind; // 'routine' | 'polio'
  final int highRiskCount;
  final double coverage;
  final double? coverageChange; // pichle 30 din ke muqable (percentage points)
  final int areasAtRisk;
  final List<AreaStat> areas;
  final bool hasAlert;
  final String alertTitle;
  final String alertText;
  final List<String> alertDetails;
  final String recommendation;
  final List<String> recAreas;
  final List<String> recChildIds;
  final String recVaccine;
  final String campaignType;
  final List<RiskChild> children;
  final bool aiOnline;
  final String? note;

  InsightsResult({
    required this.kind,
    required this.highRiskCount,
    required this.coverage,
    required this.coverageChange,
    required this.areasAtRisk,
    required this.areas,
    required this.hasAlert,
    required this.alertTitle,
    required this.alertText,
    required this.alertDetails,
    required this.recommendation,
    required this.recAreas,
    required this.recChildIds,
    required this.recVaccine,
    required this.campaignType,
    required this.children,
    required this.aiOnline,
    this.note,
  });

  factory InsightsResult.empty(String kind, String note) {
    return InsightsResult(
      kind: kind,
      highRiskCount: 0,
      coverage: 0,
      coverageChange: null,
      areasAtRisk: 0,
      areas: [],
      hasAlert: false,
      alertTitle: kind == 'polio' ? 'Polio Risk Alert' : 'Risk Alert',
      alertText: note,
      alertDetails: [],
      recommendation: 'Abhi koi campaign ki zaroorat nahi.',
      recAreas: [],
      recChildIds: [],
      recVaccine: '',
      campaignType: kind == 'polio' ? 'Polio' : 'Routine Immunization',
      children: [],
      aiOnline: true,
      note: note,
    );
  }
}

// =====================================================================
// INTERNAL HELPERS
// =====================================================================
class _Counts {
  int given = 0;
  int refused = 0;
  int missed = 0;
  int due = 0;
  int get total => given + refused + missed + due;
}

class _ChildEval {
  final List<String> missed;
  final List<String> refused;
  final int ageDays;
  final int visitsDue;
  final int visitsMissed;
  final int maxOverdue;
  final int daysSinceLast;
  final double meanDelay;
  final _Counts counts;

  _ChildEval({
    required this.missed,
    required this.refused,
    required this.ageDays,
    required this.visitsDue,
    required this.visitsMissed,
    required this.maxOverdue,
    required this.daysSinceLast,
    required this.meanDelay,
    required this.counts,
  });
}

class _Flagged {
  final String docId;
  final String displayId;
  final String name;
  final String village;
  final _ChildEval ev;
  _Flagged(this.docId, this.displayId, this.name, this.village, this.ev);
}

class _AlertInfo {
  final String group;
  final List<String> areas;
  final List<String> details;
  _AlertInfo(this.group, this.areas, this.details);
}

List<List<T>> _chunks<T>(List<T> list, int size) {
  final out = <List<T>>[];
  for (var i = 0; i < list.length; i += size) {
    out.add(list.sublist(i, i + size > list.length ? list.length : i + size));
  }
  return out;
}

String _rawVillage(Map<String, dynamic> data) =>
    (data['village'] ?? '').toString();

// "Jand", "jand" aur "Jand " ek hi area ginay jayein (sab se aam spelling dikhegi).
class _VillageNames {
  final Map<String, Map<String, int>> _v = {};

  static String _clean(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  static String _key(String raw) => _clean(raw).toLowerCase();
  static bool _startsUpper(String s) =>
      s.isNotEmpty && s[0] == s[0].toUpperCase() && s[0] != s[0].toLowerCase();

  void add(String raw) {
    final c = _clean(raw);
    if (c.isEmpty) return;
    final m = _v.putIfAbsent(_key(c), () => <String, int>{});
    m[c] = (m[c] ?? 0) + 1;
  }

  String canon(String raw) {
    final c = _clean(raw);
    if (c.isEmpty) return 'Unknown';
    final m = _v[_key(c)];
    if (m == null) return c;
    var best = c;
    var bestN = -1;
    m.forEach((name, n) {
      final better =
          n > bestN || (n == bestN && _startsUpper(name) && !_startsUpper(best));
      if (better) {
        best = name;
        bestN = n;
      }
    });
    return best;
  }
}

// =====================================================================
// SERVICE
// =====================================================================
class AiInsightsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------
  // ROUTINE (ML model + asli records)
  // ---------------------------------------------------------------
  Future<InsightsResult> loadRoutine() async {
    final now = DateTime.now();
    final before = now.subtract(const Duration(days: 30));

    final children = await _loadCenterChildren();
    if (children.isEmpty) {
      return InsightsResult.empty(
          'routine', 'DHQ Attock ke koi registered bache nahi mile.');
    }
    final grouped = await _loadRecords(children);

    final villageNames = _VillageNames();
    for (final doc in children) {
      villageNames.add(_rawVillage(doc.data()));
    }

    int givenNow = 0, totalNow = 0, givenPrev = 0, totalPrev = 0;
    final vGiven = <String, int>{};
    final vTotal = <String, int>{};
    final ratios = <String, List<double>>{};
    final groupCounts = <String, Map<String, int>>{};
    final flagged = <_Flagged>[];

    for (final doc in children) {
      final data = doc.data();
      if (!VaccinationStatusHelper.hasValidDob(data['dob'])) continue;
      final dob = VaccinationStatusHelper.parseDob(data['dob']);
      final village = villageNames.canon(_rawVillage(data));
      final regNo = (data['regNo'] ?? '').toString();
      final childName =
          (data['fullName'] ?? data['name'] ?? 'Unknown').toString();

      final records = <Map<String, dynamic>>[
        ...(grouped[doc.id] ?? const <Map<String, dynamic>>[]),
        if (regNo.isNotEmpty && regNo != doc.id)
          ...(grouped[regNo] ?? const <Map<String, dynamic>>[]),
      ];

      final ev = _evaluate(dob, records, now);
      final prev = _countAt(dob, records, before);

      givenNow += ev.counts.given;
      totalNow += ev.counts.total;
      givenPrev += prev.given;
      totalPrev += prev.total;
      vGiven[village] = (vGiven[village] ?? 0) + ev.counts.given;
      vTotal[village] = (vTotal[village] ?? 0) + ev.counts.total;

      if (ev.visitsDue > 0) {
        ratios.putIfAbsent(village, () => []).add(ev.visitsMissed / ev.visitsDue);
      }

      final bad = <String>[...ev.refused, ...ev.missed];
      if (bad.isNotEmpty) {
        for (final v in bad) {
          final g = DiseaseMap.group(v);
          final m = groupCounts.putIfAbsent(village, () => <String, int>{});
          m[g] = (m[g] ?? 0) + 1;
        }
        flagged.add(_Flagged(
            doc.id, regNo.isEmpty ? doc.id : regNo, childName, village, ev));
      }
    }

    double areaCoverageFeature(String v) {
      final r = ratios[v];
      if (r == null || r.isEmpty) return 85.0;
      final mean = r.reduce((a, b) => a + b) / r.length;
      return double.parse((100 * (1 - mean)).toStringAsFixed(1));
    }

    // ---- ML server se risk probability ----
    final items = flagged
        .map((f) => <String, dynamic>{
              'child_id': f.docId,
              'area': f.village,
              'age_days': f.ev.ageDays,
              'visits_due': f.ev.visitsDue,
              'visits_missed': f.ev.visitsMissed,
              'max_days_overdue': f.ev.maxOverdue,
              'days_since_last_visit': f.ev.daysSinceLast,
              'mean_delay_days': f.ev.meanDelay,
              'area_coverage': areaCoverageFeature(f.village),
            })
        .toList();
    final probs = items.isEmpty ? <String, double>{} : await _predict(items);
    final aiOnline = probs != null;

    final riskChildren = <RiskChild>[];
    for (final f in flagged) {
      final p = probs?[f.docId] ?? _fallbackProbability(f.ev);
      final all = <String>[...f.ev.refused, ...f.ev.missed];
      final groups = all.map(DiseaseMap.group).toSet();
      final firstGroup = DiseaseMap.group(all.first);
      final label = groups.length > 1
          ? '$firstGroup +${groups.length - 1}'
          : firstGroup;
      final isHigh =
          f.ev.refused.isNotEmpty || f.ev.visitsMissed >= 2 || p >= 0.60;
      riskChildren.add(RiskChild(
        docId: f.docId,
        displayId: f.displayId,
        name: f.name,
        area: f.village,
        missedVaccine: label,
        missedDoses: all.length,
        disease: DiseaseMap.disease(firstGroup),
        status: isHigh ? 'High Risk' : 'At Risk',
        probability: p,
        groups: groups,
      ));
    }
    riskChildren.sort((a, b) {
      final sa = a.status == 'High Risk' ? 0 : 1;
      final sb = b.status == 'High Risk' ? 0 : 1;
      if (sa != sb) return sa.compareTo(sb);
      return b.probability.compareTo(a.probability);
    });

    final areas = <AreaStat>[];
    vTotal.forEach((v, t) {
      if (t > 0) {
        areas.add(AreaStat(
            name: v, coverage: (vGiven[v] ?? 0) / t * 100, total: t));
      }
    });
    areas.sort((a, b) => a.coverage.compareTo(b.coverage));
    final areasAtRisk =
        areas.where((a) => a.coverage < AiConfig.coverageTarget).length;

    final coverage = totalNow > 0 ? givenNow / totalNow * 100 : 0.0;
    final prevCoverage = totalPrev > 0 ? givenPrev / totalPrev * 100 : null;
    final change = prevCoverage == null ? null : coverage - prevCoverage;

    // Routine tab ka alert sirf routine vaccines (Measles, Pentavalent, PCV...) ka hoga.
    // Polio ka alert sirf Polio tab mein aata hai.
    final alertCounts = <String, Map<String, int>>{};
    groupCounts.forEach((v, m) {
      final filtered = Map<String, int>.from(m)..remove('Polio');
      if (filtered.isNotEmpty) alertCounts[v] = filtered;
    });
    final alert = _topAlert(alertCounts);
    String alertTitle = 'Risk Alert';
    String alertText =
        'Routine vaccines mein koi bar bar miss hone wali vaccine nahi mili. Polio ka alert Polio tab mein dekhein.';
    String recommendation = 'Abhi koi campaign ki zaroorat nahi.';
    var recAreas = <String>[];
    var recChildIds = <String>[];
    var recVaccine = '';
    var details = <String>[];

    if (alert != null) {
      final areaText = alert.areas.join(' and ');
      final vacName = alert.group;
      alertTitle = '${alert.group} Risk Alert';
      alertText =
          '$vacName vaccine doses are continuously missed in $areaText, '
          'which may increase the risk of ${DiseaseMap.longDisease(alert.group)}.';
      recommendation = 'Launch a $vacName catch-up campaign in $areaText.';
      recAreas = alert.areas;
      recVaccine = alert.group;
      details = alert.details;
      recChildIds = riskChildren
          .where((c) =>
              alert.areas.contains(c.area) && c.groups.contains(alert.group))
          .map((c) => c.docId)
          .toList();
    }

    return InsightsResult(
      kind: 'routine',
      highRiskCount: riskChildren.where((c) => c.status == 'High Risk').length,
      coverage: coverage,
      coverageChange: change,
      areasAtRisk: areasAtRisk,
      areas: areas.take(4).toList(),
      hasAlert: alert != null,
      alertTitle: alertTitle,
      alertText: alertText,
      alertDetails: details,
      recommendation: recommendation,
      recAreas: recAreas,
      recChildIds: recChildIds,
      recVaccine: recVaccine,
      campaignType: 'Routine Immunization',
      children: riskChildren,
      aiOnline: aiOnline,
    );
  }

  // ---------------------------------------------------------------
  // POLIO (campaign_assignments ke asli records)
  // ---------------------------------------------------------------
  Future<InsightsResult> loadPolio() async {
    final now = DateTime.now();
    final before = now.subtract(const Duration(days: 30));

    final campSnap = await _db.collection('campaigns').get();
    final endById = <String, DateTime>{};
    final typeCounts = <String, int>{};
    for (final d in campSnap.docs) {
      final data = d.data();
      final type = (data['type'] ?? '').toString().trim();
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      // Polio aur Sub National Drive (SNID) dono polio ki campaigns hain
      if (type != 'Polio' && type != 'Sub National Drive') continue;
      final e = data['endDate'];
      endById[d.id] = e is Timestamp ? e.toDate() : now;
    }
    if (endById.isEmpty) {
      final found = typeCounts.isEmpty
          ? 'koi campaign hi nahi'
          : typeCounts.entries.map((e) => '${e.key} x${e.value}').join(', ');
      return InsightsResult.empty('polio',
          'Polio ya Sub National Drive type ki koi campaign nahi mili. Maujooda campaigns: $found.');
    }

    final assignments = <Map<String, dynamic>>[];
    for (final chunk in _chunks(endById.keys.toList(), 30)) {
      final snap = await _db
          .collection('campaign_assignments')
          .where('campaignId', whereIn: chunk)
          .get();
      assignments.addAll(snap.docs.map((d) => d.data()));
    }
    if (assignments.isEmpty) {
      return InsightsResult.empty('polio',
          '${endById.length} Polio campaign(s) mili hain, lekin un mein koi bacha assign nahi hua.');
    }

    final childIds = assignments
        .map((a) => (a['childId'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    final info = <String, Map<String, dynamic>>{};
    for (final chunk in _chunks(childIds, 30)) {
      final snap = await _db
          .collection('children')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final d in snap.docs) {
        info[d.id] = d.data();
      }
    }

    final villageNames = _VillageNames();
    for (final data in info.values) {
      villageNames.add(_rawVillage(data));
    }

    int goodNow = 0, badNow = 0, goodPrev = 0, badPrev = 0;
    final vGood = <String, int>{};
    final vBad = <String, int>{};
    final childBad = <String, int>{};
    final childVillage = <String, String>{};
    final childNames = <String, String>{};

    for (final a in assignments) {
      final cid = (a['childId'] ?? '').toString();
      if (cid.isEmpty) continue;
      var s = (a['status'] ?? 'Pending').toString().toLowerCase();
      final end = endById[(a['campaignId'] ?? '').toString()] ?? now;
      DateTime? when =
          a['updatedAt'] is Timestamp ? (a['updatedAt'] as Timestamp).toDate() : null;

      // Campaign khatam ho chuki aur bacha Pending hi hai = pahunch nahi hui
      if (s == 'pending' && now.isAfter(end)) {
        s = 'missed';
        when = end;
      }
      final isGood = s == 'vaccinated';
      final isBad = s == 'refused' || s == 'missed';
      if (!isGood && !isBad) continue;

      final village = villageNames.canon(_rawVillage(info[cid] ?? <String, dynamic>{}));
      childVillage[cid] = village;
      final aName = (a['childName'] ?? info[cid]?['fullName'] ?? info[cid]?['name'] ?? '')
          .toString();
      if (aName.isNotEmpty) childNames[cid] = aName;
      final inPrev = when != null && !when.isAfter(before);

      if (isGood) {
        goodNow++;
        vGood[village] = (vGood[village] ?? 0) + 1;
        if (inPrev) goodPrev++;
      } else {
        badNow++;
        vBad[village] = (vBad[village] ?? 0) + 1;
        childBad[cid] = (childBad[cid] ?? 0) + 1;
        if (inPrev) badPrev++;
      }
    }

    if (goodNow + badNow == 0) {
      return InsightsResult.empty('polio',
          '${endById.length} Polio campaign(s) mein ${assignments.length} bache assign hain, lekin abhi tak kisi ka status (Vaccinated / Refused / Missed) save nahi hua. Vaccinator status mark karenge ya campaign khatam hogi to yahan data aa jayega.');
    }

    final riskChildren = <RiskChild>[];
    childBad.forEach((cid, n) {
      final reg = (info[cid]?['regNo'] ?? cid).toString();
      riskChildren.add(RiskChild(
        docId: cid,
        displayId: reg,
        name: childNames[cid] ?? 'Unknown',
        area: childVillage[cid] ?? 'Unknown',
        missedVaccine: 'Polio',
        missedDoses: n,
        disease: 'Poliomyelitis',
        status: n >= 2 ? 'High Risk' : 'At Risk',
        probability: -1,
        groups: {'Polio'},
      ));
    });
    riskChildren.sort((a, b) => b.missedDoses.compareTo(a.missedDoses));

    final areaNames = <String>{...vGood.keys, ...vBad.keys};
    final areas = <AreaStat>[];
    for (final v in areaNames) {
      final g = vGood[v] ?? 0;
      final b = vBad[v] ?? 0;
      if (g + b > 0) {
        areas.add(AreaStat(name: v, coverage: g / (g + b) * 100, total: g + b));
      }
    }
    areas.sort((a, b) => a.coverage.compareTo(b.coverage));
    final areasAtRisk =
        areas.where((a) => a.coverage < AiConfig.coverageTarget).length;

    final coverage =
        (goodNow + badNow) > 0 ? goodNow / (goodNow + badNow) * 100 : 0.0;
    final prevCoverage = (goodPrev + badPrev) > 0
        ? goodPrev / (goodPrev + badPrev) * 100
        : null;
    final change = prevCoverage == null ? null : coverage - prevCoverage;

    final groupCounts = <String, Map<String, int>>{};
    vBad.forEach((v, n) {
      if (n > 0) groupCounts[v] = {'Polio': n};
    });
    final alert = _topAlert(groupCounts);

    String alertText =
        'Polio campaigns mein koi bar bar miss ya refuse hone wala area nahi mila.';
    String recommendation = 'Abhi koi campaign ki zaroorat nahi.';
    var recAreas = <String>[];
    var recChildIds = <String>[];
    var details = <String>[];
    if (alert != null) {
      final areaText = alert.areas.join(' and ');
      alertText =
          'Repeated Polio drops are missed in $areaText, which may increase Polio transmission risk.';
      recommendation = 'Strengthen Polio campaign in $areaText.';
      recAreas = alert.areas;
      details = alert.details;
      recChildIds = riskChildren
          .where((c) => alert.areas.contains(c.area))
          .map((c) => c.docId)
          .toList();
    }

    return InsightsResult(
      kind: 'polio',
      highRiskCount: riskChildren.where((c) => c.status == 'High Risk').length,
      coverage: coverage,
      coverageChange: change,
      areasAtRisk: areasAtRisk,
      areas: areas.take(4).toList(),
      hasAlert: alert != null,
      alertTitle: 'Polio Risk Alert',
      alertText: alertText,
      alertDetails: details,
      recommendation: recommendation,
      recAreas: recAreas,
      recChildIds: recChildIds,
      recVaccine: alert != null ? 'Polio' : '',
      campaignType: 'Polio',
      children: riskChildren,
      aiOnline: true,
    );
  }

  // ---------------------------------------------------------------
  // FIRESTORE LOADERS
  // ---------------------------------------------------------------
  // Dashboard jaisa wahi chain: valid_employees -> users -> children.registeredBy
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _loadCenterChildren() async {
    final employeesSnap = await _db
        .collection('valid_employees')
        .where('healthCenter', isEqualTo: AiConfig.healthCenter)
        .get();

    final employeeIds = employeesSnap.docs
        .where((d) =>
            (d.data()['role'] ?? '').toString().trim().toLowerCase() ==
            'vaccinator')
        .map((d) => d.id)
        .toList();

    final uids = <String>[];
    for (final chunk in _chunks(employeeIds, 30)) {
      final snap = await _db
          .collection('users')
          .where('employeeId', whereIn: chunk)
          .get();
      uids.addAll(snap.docs.map((d) => d.id));
    }

    final children = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final chunk in _chunks(uids, 30)) {
      final snap = await _db
          .collection('children')
          .where('registeredBy', whereIn: chunk)
          .get();
      children.addAll(snap.docs);
    }
    return children;
  }

  Future<Map<String, List<Map<String, dynamic>>>> _loadRecords(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> children) async {
    final ids = <String>{};
    for (final doc in children) {
      ids.add(doc.id);
      final regNo = (doc.data()['regNo'] ?? '').toString();
      if (regNo.isNotEmpty) ids.add(regNo);
    }
    final all = <Map<String, dynamic>>[];
    for (final chunk in _chunks(ids.toList(), 30)) {
      final snap = await _db
          .collection('vaccinations')
          .where('childId', whereIn: chunk)
          .get();
      all.addAll(snap.docs.map((d) => d.data()));
    }
    return VaccinationStatusHelper.groupRecordsByChildId(all);
  }

  // ---------------------------------------------------------------
  // PER-CHILD LOGIC (VaccinationStatusHelper wala hi rule: 14 din grace)
  // ---------------------------------------------------------------
  DateTime? _recDate(Map<String, dynamic> r) {
    final v = r['administeredDate'];
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  Map<String, dynamic>? _match(
      String vaccine, List<Map<String, dynamic>> records, DateTime asOf) {
    final target = VaccinationStatusHelper.normalize(vaccine);
    Map<String, dynamic>? refusedMatch;
    for (final r in records) {
      final stored =
          VaccinationStatusHelper.normalize((r['vaccineName'] ?? '').toString());
      if (stored.isEmpty) continue;
      if (stored == target ||
          stored.contains(target) ||
          target.contains(stored)) {
        final d = _recDate(r);
        if (d != null && d.isAfter(asOf)) continue;
        // Agar ek record "refused" aur doosra "vaccinated" ho, to vaccinated jeetay ga.
        if (!_isRefused(r)) return r;
        refusedMatch ??= r;
      }
    }
    return refusedMatch;
  }

  bool _isRefused(Map<String, dynamic> r) =>
      (r['status'] ?? '').toString().toLowerCase() == 'refused';

  _Counts _countAt(
      DateTime dob, List<Map<String, dynamic>> records, DateTime asOf) {
    final c = _Counts();
    for (final stage in EpiScheduleHelper.generateEpiSchedule(dob)) {
      final due = stage['dueDate'] as DateTime;
      if (asOf.isBefore(due)) continue;
      for (final v in List<String>.from(stage['vaccines'])) {
        final rec = _match(v, records, asOf);
        if (rec != null) {
          if (_isRefused(rec)) {
            c.refused++;
          } else {
            c.given++;
          }
        } else if (asOf.isAfter(due.add(const Duration(days: 14)))) {
          c.missed++;
        } else {
          c.due++;
        }
      }
    }
    return c;
  }

  _ChildEval _evaluate(
      DateTime dob, List<Map<String, dynamic>> records, DateTime now) {
    final missed = <String>[];
    final refused = <String>[];
    int visitsDue = 0;
    int visitsMissed = 0;
    int maxOverdue = 0;
    double delaySum = 0;
    int attendedCount = 0;

    for (final stage in EpiScheduleHelper.generateEpiSchedule(dob)) {
      final due = stage['dueDate'] as DateTime;
      if (now.isBefore(due)) continue;
      visitsDue++;

      DateTime? attended;
      for (final v in List<String>.from(stage['vaccines'])) {
        final rec = _match(v, records, now);
        if (rec != null) {
          if (_isRefused(rec)) {
            refused.add(v);
          } else {
            final d = _recDate(rec) ?? due;
            if (attended == null || d.isBefore(attended)) attended = d;
          }
        } else if (now.isAfter(due.add(const Duration(days: 14)))) {
          missed.add(v);
        }
      }

      final overdueDays = now.difference(due).inDays;
      if (attended == null && overdueDays > 28) {
        visitsMissed++;
        if (overdueDays > maxOverdue) maxOverdue = overdueDays;
      } else if (attended != null) {
        delaySum += math.max(0, attended.difference(due).inDays);
        attendedCount++;
      }
    }

    DateTime? lastVisit;
    for (final r in records) {
      if (_isRefused(r)) continue;
      final d = _recDate(r);
      if (d != null && (lastVisit == null || d.isAfter(lastVisit))) lastVisit = d;
    }
    final ageDays = math.max(0, now.difference(dob).inDays);
    final sinceLast =
        lastVisit == null ? ageDays : math.max(0, now.difference(lastVisit).inDays);

    return _ChildEval(
      missed: missed,
      refused: refused,
      ageDays: ageDays,
      visitsDue: visitsDue,
      visitsMissed: visitsMissed,
      maxOverdue: maxOverdue,
      daysSinceLast: sinceLast,
      meanDelay:
          attendedCount > 0 ? double.parse((delaySum / attendedCount).toStringAsFixed(1)) : 0.0,
      counts: _countAt(dob, records, now),
    );
  }

  // Server band ho to rules se andaza (taake screen khali na rahe)
  double _fallbackProbability(_ChildEval ev) {
    final p = 0.15 +
        0.20 * ev.visitsMissed +
        0.25 * ev.refused.length +
        0.002 * ev.maxOverdue;
    return math.min(0.95, p);
  }

  _AlertInfo? _topAlert(Map<String, Map<String, int>> groupCounts) {
    final totals = <String, int>{};
    groupCounts.forEach((v, m) {
      m.forEach((g, c) => totals[g] = (totals[g] ?? 0) + c);
    });
    if (totals.isEmpty) return null;

    final top = totals.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final byArea = <MapEntry<String, int>>[];
    groupCounts.forEach((v, m) {
      final c = m[top] ?? 0;
      if (c > 0) byArea.add(MapEntry(v, c));
    });
    byArea.sort((a, b) => b.value.compareTo(a.value));

    return _AlertInfo(
      top,
      byArea.take(2).map((e) => e.key).toList(),
      byArea.map((e) => '${e.key}: ${e.value} dose(s) missed/refused').toList(),
    );
  }

  // ---------------------------------------------------------------
  // PYTHON (ML) SERVER
  // ---------------------------------------------------------------
  Future<Map<String, double>?> _predict(List<Map<String, dynamic>> items) async {
    try {
      final out = <String, double>{};
      for (final chunk in _chunks(items, 100)) {
        final resp = await http
            .post(
              Uri.parse('${AiConfig.serverUrl}/predict'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(chunk),
            )
            .timeout(const Duration(seconds: 8));
        if (resp.statusCode != 200) return null;
        final list = jsonDecode(resp.body) as List;
        for (final e in list) {
          out[e['child_id'].toString()] = (e['miss_probability'] as num).toDouble();
        }
      }
      return out;
    } catch (_) {
      return null;
    }
  }
} */
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../helpers/epi_schedule_helper.dart';
import '../helpers/vaccination_status_helper.dart';

// =====================================================================
// SETTINGS
// =====================================================================
class AiConfig {
  // Python (FastAPI) server ka address:
  //  - Chrome (web) / Windows desktop : 'http://127.0.0.1:8000'
  //  - Android emulator               : 'http://10.0.2.2:8000'
  //  - Asli phone (same WiFi)         : 'http://<laptop ka WiFi IP>:8000'
  static const String serverUrl = 'http://127.0.0.1:8000';

  static const String healthCenter = 'DHQ Hospital Attock';

  // Coverage ka target (%). Isse neeche wale areas "at risk" gine jate hain.
  static const double coverageTarget = 90;
}

// =====================================================================
// VACCINE -> DISEASE TABLE (ye AI nahi, seedha mapping hai)
// =====================================================================
class DiseaseMap {
  static String group(String vaccineName) {
    final n = VaccinationStatusHelper.normalize(vaccineName);
    if (n.contains('bcg')) return 'BCG';
    if (n.contains('opv')) return 'Polio';
    if (n.contains('ipv')) return 'Polio';
    if (n.contains('penta')) return 'Pentavalent';
    if (n.contains('pcv')) return 'PCV';
    if (n.contains('rota')) return 'Rotavirus';
    if (n.contains('measles') || n.contains('mr')) return 'Measles';
    if (n.contains('tcv') || n.contains('typhoid')) return 'TCV';
    return vaccineName;
  }

  // Table mein chhota naam
  static String disease(String group) {
    switch (group) {
      case 'BCG':
        return 'Tuberculosis';
      case 'Polio':
        return 'Poliomyelitis';
      case 'Pentavalent':
        return 'Diphtheria';
      case 'PCV':
        return 'Pneumonia';
      case 'Rotavirus':
        return 'Rotavirus diarrhoea';
      case 'Measles':
        return 'Measles';
      case 'TCV':
        return 'Typhoid';
      default:
        return group;
    }
  }

  // Alert ke text mein poora naam
  static String longDisease(String group) {
    if (group == 'Pentavalent') {
      return 'Diphtheria, whooping cough, tetanus, Hepatitis B and Hib';
    }
    return disease(group);
  }
}

// =====================================================================
// RESULT MODELS
// =====================================================================
class RiskChild {
  final String docId;
  final String displayId;
  final String name;
  final String area;
  final String missedVaccine;
  final int missedDoses;
  final String disease;
  final String status; // 'High Risk' | 'At Risk'
  final double probability; // 0..1, -1 = AI score nahi
  final Set<String> groups;

  RiskChild({
    required this.docId,
    required this.displayId,
    required this.name,
    required this.area,
    required this.missedVaccine,
    required this.missedDoses,
    required this.disease,
    required this.status,
    required this.probability,
    required this.groups,
  });
}

class AreaStat {
  final String name;
  final double coverage;
  final int total;
  AreaStat({required this.name, required this.coverage, required this.total});
}

class InsightsResult {
  final String kind; // 'routine' | 'polio'
  final int highRiskCount;
  final double coverage;
  final double? coverageChange; // pichle 30 din ke muqable (percentage points)
  final int areasAtRisk;
  final List<AreaStat> areas;
  final bool hasAlert;
  final String alertTitle;
  final String alertText;
  final List<String> alertDetails;
  final String recommendation;
  final List<String> recAreas;
  final List<String> recChildIds;
  final String recVaccine;
  final String campaignType;
  final List<RiskChild> children;
  final bool aiOnline;
  final String? note;

  InsightsResult({
    required this.kind,
    required this.highRiskCount,
    required this.coverage,
    required this.coverageChange,
    required this.areasAtRisk,
    required this.areas,
    required this.hasAlert,
    required this.alertTitle,
    required this.alertText,
    required this.alertDetails,
    required this.recommendation,
    required this.recAreas,
    required this.recChildIds,
    required this.recVaccine,
    required this.campaignType,
    required this.children,
    required this.aiOnline,
    this.note,
  });

  factory InsightsResult.empty(String kind, String note) {
    return InsightsResult(
      kind: kind,
      highRiskCount: 0,
      coverage: 0,
      coverageChange: null,
      areasAtRisk: 0,
      areas: [],
      hasAlert: false,
      alertTitle: kind == 'polio' ? 'Polio Risk Alert' : 'Risk Alert',
      alertText: note,
      alertDetails: [],
      recommendation: 'Abhi koi campaign ki zaroorat nahi.',
      recAreas: [],
      recChildIds: [],
      recVaccine: '',
      campaignType: kind == 'polio' ? 'Polio' : 'Routine Immunization',
      children: [],
      aiOnline: true,
      note: note,
    );
  }
}

// =====================================================================
// INTERNAL HELPERS
// =====================================================================
class _Counts {
  int given = 0;
  int refused = 0;
  int missed = 0;
  int due = 0;
  int get total => given + refused + missed + due;
}

class _ChildEval {
  final List<String> missed;
  final List<String> refused;
  final int ageDays;
  final int visitsDue;
  final int visitsMissed;
  final int maxOverdue;
  final int daysSinceLast;
  final double meanDelay;
  final _Counts counts;

  _ChildEval({
    required this.missed,
    required this.refused,
    required this.ageDays,
    required this.visitsDue,
    required this.visitsMissed,
    required this.maxOverdue,
    required this.daysSinceLast,
    required this.meanDelay,
    required this.counts,
  });
}

class _Flagged {
  final String docId;
  final String displayId;
  final String name;
  final String village;
  final _ChildEval ev;
  _Flagged(this.docId, this.displayId, this.name, this.village, this.ev);
}

class _AlertInfo {
  final String group;
  final List<String> areas;
  final List<String> details;
  _AlertInfo(this.group, this.areas, this.details);
}

List<List<T>> _chunks<T>(List<T> list, int size) {
  final out = <List<T>>[];
  for (var i = 0; i < list.length; i += size) {
    out.add(list.sublist(i, i + size > list.length ? list.length : i + size));
  }
  return out;
}

String _rawVillage(Map<String, dynamic> data) =>
    (data['village'] ?? '').toString();

// "Jand", "jand" aur "Jand " ek hi area ginay jayein (sab se aam spelling dikhegi).
class _VillageNames {
  final Map<String, Map<String, int>> _v = {};

  static String _clean(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  static String _key(String raw) => _clean(raw).toLowerCase();
  static bool _startsUpper(String s) =>
      s.isNotEmpty && s[0] == s[0].toUpperCase() && s[0] != s[0].toLowerCase();

  void add(String raw) {
    final c = _clean(raw);
    if (c.isEmpty) return;
    final m = _v.putIfAbsent(_key(c), () => <String, int>{});
    m[c] = (m[c] ?? 0) + 1;
  }

  String canon(String raw) {
    final c = _clean(raw);
    if (c.isEmpty) return 'Unknown';
    final m = _v[_key(c)];
    if (m == null) return c;
    var best = c;
    var bestN = -1;
    m.forEach((name, n) {
      final better =
          n > bestN || (n == bestN && _startsUpper(name) && !_startsUpper(best));
      if (better) {
        best = name;
        bestN = n;
      }
    });
    return best;
  }
}

// =====================================================================
// SERVICE
// =====================================================================
class AiInsightsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------
  // ROUTINE (ML model + asli records)
  // ---------------------------------------------------------------
  Future<InsightsResult> loadRoutine() async {
    final now = DateTime.now();
    final before = now.subtract(const Duration(days: 30));

    final children = await _loadCenterChildren();
    if (children.isEmpty) {
      return InsightsResult.empty(
          'routine', 'DHQ Attock ke koi registered bache nahi mile.');
    }
    final grouped = await _loadRecords(children);

    final villageNames = _VillageNames();
    for (final doc in children) {
      villageNames.add(_rawVillage(doc.data()));
    }

    int givenNow = 0, totalNow = 0, givenPrev = 0, totalPrev = 0;
    final vGiven = <String, int>{};
    final vTotal = <String, int>{};
    final ratios = <String, List<double>>{};
    final groupCounts = <String, Map<String, int>>{};
    final flagged = <_Flagged>[];

    for (final doc in children) {
      final data = doc.data();
      if (!VaccinationStatusHelper.hasValidDob(data['dob'])) continue;
      final dob = VaccinationStatusHelper.parseDob(data['dob']);
      final village = villageNames.canon(_rawVillage(data));
      final regNo = (data['regNo'] ?? '').toString();
      final childName =
          (data['fullName'] ?? data['name'] ?? 'Unknown').toString();

      final records = <Map<String, dynamic>>[
        ...(grouped[doc.id] ?? const <Map<String, dynamic>>[]),
        if (regNo.isNotEmpty && regNo != doc.id)
          ...(grouped[regNo] ?? const <Map<String, dynamic>>[]),
      ];

      final ev = _evaluate(dob, records, now);
      final prev = _countAt(dob, records, before);

      givenNow += ev.counts.given;
      totalNow += ev.counts.total;
      givenPrev += prev.given;
      totalPrev += prev.total;
      vGiven[village] = (vGiven[village] ?? 0) + ev.counts.given;
      vTotal[village] = (vTotal[village] ?? 0) + ev.counts.total;

      if (ev.visitsDue > 0) {
        ratios.putIfAbsent(village, () => []).add(ev.visitsMissed / ev.visitsDue);
      }

      final bad = <String>[...ev.refused, ...ev.missed];
      if (bad.isNotEmpty) {
        for (final v in bad) {
          final g = DiseaseMap.group(v);
          final m = groupCounts.putIfAbsent(village, () => <String, int>{});
          m[g] = (m[g] ?? 0) + 1;
        }
        flagged.add(_Flagged(
            doc.id, regNo.isEmpty ? doc.id : regNo, childName, village, ev));
      }
    }

    double areaCoverageFeature(String v) {
      final r = ratios[v];
      if (r == null || r.isEmpty) return 85.0;
      final mean = r.reduce((a, b) => a + b) / r.length;
      return double.parse((100 * (1 - mean)).toStringAsFixed(1));
    }

    // ---- ML server se risk probability ----
    final items = flagged
        .map((f) => <String, dynamic>{
              'child_id': f.docId,
              'area': f.village,
              'age_days': f.ev.ageDays,
              'visits_due': f.ev.visitsDue,
              'visits_missed': f.ev.visitsMissed,
              'max_days_overdue': f.ev.maxOverdue,
              'days_since_last_visit': f.ev.daysSinceLast,
              'mean_delay_days': f.ev.meanDelay,
              'area_coverage': areaCoverageFeature(f.village),
            })
        .toList();
    final probs = items.isEmpty ? <String, double>{} : await _predict(items);
    final aiOnline = probs != null;

    final riskChildren = <RiskChild>[];
    for (final f in flagged) {
      final p = probs?[f.docId] ?? _fallbackProbability(f.ev);
      final all = <String>[...f.ev.refused, ...f.ev.missed];
      final groups = all.map(DiseaseMap.group).toSet();
      final firstGroup = DiseaseMap.group(all.first);
      final label = groups.length > 1
          ? '$firstGroup +${groups.length - 1}'
          : firstGroup;
      final isHigh =
          f.ev.refused.isNotEmpty || f.ev.visitsMissed >= 2 || p >= 0.60;
      riskChildren.add(RiskChild(
        docId: f.docId,
        displayId: f.displayId,
        name: f.name,
        area: f.village,
        missedVaccine: label,
        missedDoses: all.length,
        disease: DiseaseMap.disease(firstGroup),
        status: isHigh ? 'High Risk' : 'At Risk',
        probability: p,
        groups: groups,
      ));
    }
    riskChildren.sort((a, b) {
      final sa = a.status == 'High Risk' ? 0 : 1;
      final sb = b.status == 'High Risk' ? 0 : 1;
      if (sa != sb) return sa.compareTo(sb);
      return b.probability.compareTo(a.probability);
    });

    final areas = <AreaStat>[];
    vTotal.forEach((v, t) {
      if (t > 0) {
        areas.add(AreaStat(
            name: v, coverage: (vGiven[v] ?? 0) / t * 100, total: t));
      }
    });
    areas.sort((a, b) => a.coverage.compareTo(b.coverage));
    final areasAtRisk =
        areas.where((a) => a.coverage < AiConfig.coverageTarget).length;

    final coverage = totalNow > 0 ? givenNow / totalNow * 100 : 0.0;
    final prevCoverage = totalPrev > 0 ? givenPrev / totalPrev * 100 : null;
    final change = prevCoverage == null ? null : coverage - prevCoverage;

    // Routine tab ka alert sirf routine vaccines (Measles, Pentavalent, PCV...) ka hoga.
    // Polio ka alert sirf Polio tab mein aata hai.
    final alertCounts = <String, Map<String, int>>{};
    groupCounts.forEach((v, m) {
      final filtered = Map<String, int>.from(m)..remove('Polio');
      if (filtered.isNotEmpty) alertCounts[v] = filtered;
    });
    final alert = _topAlert(alertCounts);
    String alertTitle = 'Risk Alert';
    String alertText =
        'Routine vaccines mein koi bar bar miss hone wali vaccine nahi mili. Polio ka alert Polio tab mein dekhein.';
    String recommendation = 'Abhi koi campaign ki zaroorat nahi.';
    var recAreas = <String>[];
    var recChildIds = <String>[];
    var recVaccine = '';
    var details = <String>[];

    if (alert != null) {
      final areaText = alert.areas.join(' and ');
      final vacName = alert.group;
      alertTitle = '${alert.group} Risk Alert';
      alertText =
          '$vacName vaccine doses are continuously missed in $areaText, '
          'which may increase the risk of ${DiseaseMap.longDisease(alert.group)}.';
      recommendation = 'Launch a $vacName catch-up campaign in $areaText.';
      recAreas = alert.areas;
      recVaccine = alert.group;
      details = alert.details;
      recChildIds = riskChildren
          .where((c) =>
              alert.areas.contains(c.area) && c.groups.contains(alert.group))
          .map((c) => c.docId)
          .toList();
    }

    return InsightsResult(
      kind: 'routine',
      highRiskCount: riskChildren.where((c) => c.status == 'High Risk').length,
      coverage: coverage,
      coverageChange: change,
      areasAtRisk: areasAtRisk,
      areas: areas.take(4).toList(),
      hasAlert: alert != null,
      alertTitle: alertTitle,
      alertText: alertText,
      alertDetails: details,
      recommendation: recommendation,
      recAreas: recAreas,
      recChildIds: recChildIds,
      recVaccine: recVaccine,
      campaignType: 'Routine Immunization',
      children: riskChildren,
      aiOnline: aiOnline,
    );
  }

  // ---------------------------------------------------------------
  // POLIO (campaign_assignments ke asli records)
  // ---------------------------------------------------------------
  Future<InsightsResult> loadPolio() async {
    final now = DateTime.now();
    final before = now.subtract(const Duration(days: 30));

    final campSnap = await _db.collection('campaigns').get();
    final endById = <String, DateTime>{};
    final typeCounts = <String, int>{};
    for (final d in campSnap.docs) {
      final data = d.data();
      final type = (data['type'] ?? '').toString().trim();
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      // Polio aur Sub National Drive (SNID) dono polio ki campaigns hain
      if (type != 'Polio' && type != 'Sub National Drive') continue;
      final e = data['endDate'];
      endById[d.id] = e is Timestamp ? e.toDate() : now;
    }
    if (endById.isEmpty) {
      final found = typeCounts.isEmpty
          ? 'koi campaign hi nahi'
          : typeCounts.entries.map((e) => '${e.key} x${e.value}').join(', ');
      return InsightsResult.empty('polio',
          'Polio ya Sub National Drive type ki koi campaign nahi mili. Maujooda campaigns: $found.');
    }

    final assignments = <Map<String, dynamic>>[];
    for (final chunk in _chunks(endById.keys.toList(), 30)) {
      final snap = await _db
          .collection('campaign_assignments')
          .where('campaignId', whereIn: chunk)
          .get();
      assignments.addAll(snap.docs.map((d) => d.data()));
    }
    if (assignments.isEmpty) {
      return InsightsResult.empty('polio',
          '${endById.length} Polio campaign(s) mili hain, lekin un mein koi bacha assign nahi hua.');
    }

    final childIds = assignments
        .map((a) => (a['childId'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    final info = <String, Map<String, dynamic>>{};
    for (final chunk in _chunks(childIds, 30)) {
      final snap = await _db
          .collection('children')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final d in snap.docs) {
        info[d.id] = d.data();
      }
    }

    final villageNames = _VillageNames();
    for (final data in info.values) {
      villageNames.add(_rawVillage(data));
    }

    int goodNow = 0, badNow = 0, goodPrev = 0, badPrev = 0;
    final vGood = <String, int>{};
    final vBad = <String, int>{};
    final childBad = <String, int>{};
    final childVillage = <String, String>{};
    final childNames = <String, String>{};

    for (final a in assignments) {
      final cid = (a['childId'] ?? '').toString();
      if (cid.isEmpty) continue;
      var s = (a['status'] ?? 'Pending').toString().toLowerCase();
      final end = endById[(a['campaignId'] ?? '').toString()] ?? now;
      DateTime? when =
          a['updatedAt'] is Timestamp ? (a['updatedAt'] as Timestamp).toDate() : null;

      // Campaign khatam ho chuki aur bacha Pending hi hai = pahunch nahi hui
      if (s == 'pending' && now.isAfter(end)) {
        s = 'missed';
        when = end;
      }
      final isGood = s == 'vaccinated';
      final isBad = s == 'refused' || s == 'missed';
      if (!isGood && !isBad) continue;

      final village = villageNames.canon(_rawVillage(info[cid] ?? <String, dynamic>{}));
      childVillage[cid] = village;
      final aName = (a['childName'] ?? info[cid]?['fullName'] ?? info[cid]?['name'] ?? '')
          .toString();
      if (aName.isNotEmpty) childNames[cid] = aName;
      final inPrev = when != null && !when.isAfter(before);

      if (isGood) {
        goodNow++;
        vGood[village] = (vGood[village] ?? 0) + 1;
        if (inPrev) goodPrev++;
      } else {
        badNow++;
        vBad[village] = (vBad[village] ?? 0) + 1;
        childBad[cid] = (childBad[cid] ?? 0) + 1;
        if (inPrev) badPrev++;
      }
    }

    if (goodNow + badNow == 0) {
      return InsightsResult.empty('polio',
          '${endById.length} Polio campaign(s) mein ${assignments.length} bache assign hain, lekin abhi tak kisi ka status (Vaccinated / Refused / Missed) save nahi hua. Vaccinator status mark karenge ya campaign khatam hogi to yahan data aa jayega.');
    }

    final riskChildren = <RiskChild>[];
    childBad.forEach((cid, n) {
      final reg = (info[cid]?['regNo'] ?? cid).toString();
      riskChildren.add(RiskChild(
        docId: cid,
        displayId: reg,
        name: childNames[cid] ?? 'Unknown',
        area: childVillage[cid] ?? 'Unknown',
        missedVaccine: 'Polio',
        missedDoses: n,
        disease: 'Poliomyelitis',
        status: n >= 2 ? 'High Risk' : 'At Risk',
        probability: -1,
        groups: {'Polio'},
      ));
    });
    riskChildren.sort((a, b) => b.missedDoses.compareTo(a.missedDoses));

    final areaNames = <String>{...vGood.keys, ...vBad.keys};
    final areas = <AreaStat>[];
    for (final v in areaNames) {
      final g = vGood[v] ?? 0;
      final b = vBad[v] ?? 0;
      if (g + b > 0) {
        areas.add(AreaStat(name: v, coverage: g / (g + b) * 100, total: g + b));
      }
    }
    areas.sort((a, b) => a.coverage.compareTo(b.coverage));
    final areasAtRisk =
        areas.where((a) => a.coverage < AiConfig.coverageTarget).length;

    final coverage =
        (goodNow + badNow) > 0 ? goodNow / (goodNow + badNow) * 100 : 0.0;
    final prevCoverage = (goodPrev + badPrev) > 0
        ? goodPrev / (goodPrev + badPrev) * 100
        : null;
    final change = prevCoverage == null ? null : coverage - prevCoverage;

    final groupCounts = <String, Map<String, int>>{};
    vBad.forEach((v, n) {
      if (n > 0) groupCounts[v] = {'Polio': n};
    });
    final alert = _topAlert(groupCounts);

    String alertText =
        'Polio campaigns mein koi bar bar miss ya refuse hone wala area nahi mila.';
    String recommendation = 'Abhi koi campaign ki zaroorat nahi.';
    var recAreas = <String>[];
    var recChildIds = <String>[];
    var details = <String>[];
    if (alert != null) {
      final areaText = alert.areas.join(' and ');
      alertText =
          'Repeated Polio drops are missed in $areaText, which may increase Polio transmission risk.';
      recommendation = 'Strengthen Polio campaign in $areaText.';
      recAreas = alert.areas;
      details = alert.details;
      recChildIds = riskChildren
          .where((c) => alert.areas.contains(c.area))
          .map((c) => c.docId)
          .toList();
    }

    return InsightsResult(
      kind: 'polio',
      highRiskCount: riskChildren.where((c) => c.status == 'High Risk').length,
      coverage: coverage,
      coverageChange: change,
      areasAtRisk: areasAtRisk,
      areas: areas.take(4).toList(),
      hasAlert: alert != null,
      alertTitle: 'Polio Risk Alert',
      alertText: alertText,
      alertDetails: details,
      recommendation: recommendation,
      recAreas: recAreas,
      recChildIds: recChildIds,
      recVaccine: alert != null ? 'Polio' : '',
      campaignType: 'Polio',
      children: riskChildren,
      aiOnline: true,
    );
  }

  // ---------------------------------------------------------------
  // FIRESTORE LOADERS
  // ---------------------------------------------------------------
  // Dashboard jaisa wahi chain: valid_employees -> users -> children.registeredBy
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _loadCenterChildren() async {
    final employeesSnap = await _db
        .collection('valid_employees')
        .where('healthCenter', isEqualTo: AiConfig.healthCenter)
        .get();

    final employeeIds = employeesSnap.docs
        .where((d) =>
            (d.data()['role'] ?? '').toString().trim().toLowerCase() ==
            'vaccinator')
        .map((d) => d.id)
        .toList();

    final uids = <String>[];
    for (final chunk in _chunks(employeeIds, 30)) {
      final snap = await _db
          .collection('users')
          .where('employeeId', whereIn: chunk)
          .get();
      uids.addAll(snap.docs.map((d) => d.id));
    }

    final children = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final chunk in _chunks(uids, 30)) {
      final snap = await _db
          .collection('children')
          .where('registeredBy', whereIn: chunk)
          .get();
      children.addAll(snap.docs);
    }
    return children;
  }

  Future<Map<String, List<Map<String, dynamic>>>> _loadRecords(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> children) async {
    final ids = <String>{};
    for (final doc in children) {
      ids.add(doc.id);
      final regNo = (doc.data()['regNo'] ?? '').toString();
      if (regNo.isNotEmpty) ids.add(regNo);
    }
    final all = <Map<String, dynamic>>[];
    for (final chunk in _chunks(ids.toList(), 30)) {
      final snap = await _db
          .collection('vaccinations')
          .where('childId', whereIn: chunk)
          .get();
      all.addAll(snap.docs.map((d) => d.data()));
    }
    return VaccinationStatusHelper.groupRecordsByChildId(all);
  }

  // ---------------------------------------------------------------
  // PER-CHILD LOGIC (VaccinationStatusHelper wala hi rule: 14 din grace)
  // ---------------------------------------------------------------
  DateTime? _recDate(Map<String, dynamic> r) {
    final v = r['administeredDate'];
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  Map<String, dynamic>? _match(
      String vaccine, List<Map<String, dynamic>> records, DateTime asOf) {
    final target = VaccinationStatusHelper.normalize(vaccine);
    Map<String, dynamic>? refusedMatch;
    for (final r in records) {
      final stored =
          VaccinationStatusHelper.normalize((r['vaccineName'] ?? '').toString());
      if (stored.isEmpty) continue;
      if (stored == target ||
          stored.contains(target) ||
          target.contains(stored)) {
        final d = _recDate(r);
        if (d != null && d.isAfter(asOf)) continue;
        // Agar ek record "refused" aur doosra "vaccinated" ho, to vaccinated jeetay ga.
        if (!_isRefused(r)) return r;
        refusedMatch ??= r;
      }
    }
    return refusedMatch;
  }

  bool _isRefused(Map<String, dynamic> r) =>
      (r['status'] ?? '').toString().toLowerCase() == 'refused';

  _Counts _countAt(
      DateTime dob, List<Map<String, dynamic>> records, DateTime asOf) {
    final c = _Counts();
    for (final stage in EpiScheduleHelper.generateEpiSchedule(dob)) {
      final due = stage['dueDate'] as DateTime;
      if (asOf.isBefore(due)) continue;
      for (final v in List<String>.from(stage['vaccines'])) {
        final rec = _match(v, records, asOf);
        if (rec != null) {
          if (_isRefused(rec)) {
            c.refused++;
          } else {
            c.given++;
          }
        } else if (asOf.isAfter(due.add(const Duration(days: 14)))) {
          c.missed++;
        } else {
          c.due++;
        }
      }
    }
    return c;
  }

  _ChildEval _evaluate(
      DateTime dob, List<Map<String, dynamic>> records, DateTime now) {
    final missed = <String>[];
    final refused = <String>[];
    int visitsDue = 0;
    int visitsMissed = 0;
    int maxOverdue = 0;
    double delaySum = 0;
    int attendedCount = 0;

    for (final stage in EpiScheduleHelper.generateEpiSchedule(dob)) {
      final due = stage['dueDate'] as DateTime;
      if (now.isBefore(due)) continue;
      visitsDue++;

      DateTime? attended;
      for (final v in List<String>.from(stage['vaccines'])) {
        final rec = _match(v, records, now);
        if (rec != null) {
          if (_isRefused(rec)) {
            refused.add(v);
          } else {
            final d = _recDate(rec) ?? due;
            if (attended == null || d.isBefore(attended)) attended = d;
          }
        } else if (now.isAfter(due.add(const Duration(days: 14)))) {
          missed.add(v);
        }
      }

      final overdueDays = now.difference(due).inDays;
      if (attended == null && overdueDays > 28) {
        visitsMissed++;
        if (overdueDays > maxOverdue) maxOverdue = overdueDays;
      } else if (attended != null) {
        delaySum += math.max(0, attended.difference(due).inDays);
        attendedCount++;
      }
    }

    DateTime? lastVisit;
    for (final r in records) {
      if (_isRefused(r)) continue;
      final d = _recDate(r);
      if (d != null && (lastVisit == null || d.isAfter(lastVisit))) lastVisit = d;
    }
    final ageDays = math.max(0, now.difference(dob).inDays);
    final sinceLast =
        lastVisit == null ? ageDays : math.max(0, now.difference(lastVisit).inDays);

    return _ChildEval(
      missed: missed,
      refused: refused,
      ageDays: ageDays,
      visitsDue: visitsDue,
      visitsMissed: visitsMissed,
      maxOverdue: maxOverdue,
      daysSinceLast: sinceLast,
      meanDelay:
          attendedCount > 0 ? double.parse((delaySum / attendedCount).toStringAsFixed(1)) : 0.0,
      counts: _countAt(dob, records, now),
    );
  }

  // Server band ho to rules se andaza (taake screen khali na rahe)
  double _fallbackProbability(_ChildEval ev) {
    final p = 0.15 +
        0.20 * ev.visitsMissed +
        0.25 * ev.refused.length +
        0.002 * ev.maxOverdue;
    return math.min(0.95, p);
  }

  _AlertInfo? _topAlert(Map<String, Map<String, int>> groupCounts) {
    final totals = <String, int>{};
    groupCounts.forEach((v, m) {
      m.forEach((g, c) => totals[g] = (totals[g] ?? 0) + c);
    });
    if (totals.isEmpty) return null;

    final top = totals.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final byArea = <MapEntry<String, int>>[];
    groupCounts.forEach((v, m) {
      final c = m[top] ?? 0;
      if (c > 0) byArea.add(MapEntry(v, c));
    });
    byArea.sort((a, b) => b.value.compareTo(a.value));

    return _AlertInfo(
      top,
      byArea.take(2).map((e) => e.key).toList(),
      byArea.map((e) => '${e.key}: ${e.value} dose(s) missed/refused').toList(),
    );
  }

  // ---------------------------------------------------------------
  // PYTHON (ML) SERVER
  // ---------------------------------------------------------------
  Future<Map<String, double>?> _predict(List<Map<String, dynamic>> items) async {
    try {
      final out = <String, double>{};
      for (final chunk in _chunks(items, 100)) {
        final resp = await http
            .post(
              Uri.parse('${AiConfig.serverUrl}/predict'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(chunk),
            )
            .timeout(const Duration(seconds: 8));
        if (resp.statusCode != 200) return null;
        final list = jsonDecode(resp.body) as List;
        for (final e in list) {
          out[e['child_id'].toString()] = (e['miss_probability'] as num).toDouble();
        }
      }
      return out;
    } catch (_) {
      return null;
    }
  }
}