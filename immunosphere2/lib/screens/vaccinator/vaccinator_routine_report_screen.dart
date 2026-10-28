import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:immunosphere2/helpers/epi_schedule_helper.dart';
import 'package:immunosphere2/helpers/vaccination_status_helper.dart';

class _Counts {
  int vac = 0;
  int pending = 0;
  int missed = 0;
  int refused = 0;
}

class _Rec {
  final DateTime date;
  final String vaccine;
  final String status; // 'vaccinated' | 'refused'
  final String childId;
  final DateTime? recordedAt; // createdAt = when the record was saved
  _Rec(this.date, this.vaccine, this.status, this.childId, {this.recordedAt});
}

class _Child {
  final DateTime? dob;
  final List<String> recordedVaccines;
  _Child(this.dob, this.recordedVaccines);
}

/// Routine Vaccination Report for the logged-in vaccinator.
///
/// Numbers:
///  - Vaccinated / Refused  = records this vaccinator entered in the period
///    (vaccinations.administeredBy == uid, by administeredDate).
///  - Pending / Missed      = EPI doses that fall due in the period for the
///    children this vaccinator registered and that nobody has recorded yet
///    (same 14-day rule as the rest of the app).
class VaccinatorRoutineReportScreen extends StatefulWidget {
  const VaccinatorRoutineReportScreen({Key? key}) : super(key: key);

  @override
  State<VaccinatorRoutineReportScreen> createState() => _VaccinatorRoutineReportScreenState();
}

class _VaccinatorRoutineReportScreenState extends State<VaccinatorRoutineReportScreen> {
  static const Color primaryGreen = Color(0xFF0B4D30);
  static const Color accentGreen = Color(0xFF0E7A45);
  static const Color lightGreenBg = Color(0xFFE5F7ED);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color greyTone = Color(0xFF64748B);
  static const Color bgCanvas = Color(0xFFF8FAFC);

  static const List<String> _families = [
    'BCG',
    'OPV',
    'Pentavalent',
    'PCV',
    'Rotavirus',
    'IPV',
    'Measles-Rubella',
    'TCV',
  ];

  int _mode = 0; // 0 daily, 1 weekly, 2 monthly
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  String? _error;
  bool _showAllActivity = false;

  List<_Rec> _myRecords = [];
  List<_Child> _children = [];
  Map<String, String> _nameById = {};
  String _vaccinatorName = '';
  String _center = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ---------------------------------------------------------------
  // DATA
  // ---------------------------------------------------------------
  DateTime? _asDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String && v.trim().isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Login nahi mila';
      final db = FirebaseFirestore.instance;

      final childF = db.collection('children').where('registeredBy', isEqualTo: user.uid).get();
      final myVacF = db.collection('vaccinations').where('administeredBy', isEqualTo: user.uid).get();
      final userF = db.collection('users').doc(user.uid).get();

      final childSnap = await childF;
      final mySnap = await myVacF;
      final userSnap = await userF;

      // Ids used in vaccinations.childId (doc id or regNo).
      final ids = <String>{};
      for (final d in childSnap.docs) {
        ids.add(d.id);
        final reg = (d.data()['regNo'] ?? '').toString();
        if (reg.isNotEmpty) ids.add(reg);
      }
      final idList = ids.toList();

      // Every record of my children (even if given by someone else) so that
      // Pending/Missed does not count doses that were already given.
      final Map<String, Map<String, dynamic>> recById = {
        for (final d in mySnap.docs) d.id: d.data(),
      };
      for (int i = 0; i < idList.length; i += 30) {
        final end = (i + 30 > idList.length) ? idList.length : i + 30;
        final snap = await db
            .collection('vaccinations')
            .where('childId', whereIn: idList.sublist(i, end))
            .get();
        for (final d in snap.docs) {
          recById[d.id] = d.data();
        }
      }

      final namesByChild = <String, List<String>>{};
      for (final r in recById.values) {
        final cid = (r['childId'] ?? '').toString();
        if (cid.isEmpty) continue;
        namesByChild.putIfAbsent(cid, () => []).add((r['vaccineName'] ?? '').toString());
      }

      final children = <_Child>[];
      final nameById = <String, String>{};
      for (final d in childSnap.docs) {
        final data = d.data();
        final name = (data['fullName'] ?? data['name'] ?? 'Child').toString();
        final reg = (data['regNo'] ?? '').toString();
        nameById[d.id] = name;
        if (reg.isNotEmpty) nameById[reg] = name;

        final DateTime? dob = VaccinationStatusHelper.hasValidDob(data['dob'])
            ? VaccinationStatusHelper.parseDob(data['dob'])
            : null;
        final recorded = <String>[
          ...(namesByChild[d.id] ?? []),
          if (reg.isNotEmpty) ...(namesByChild[reg] ?? []),
        ];
        children.add(_Child(dob, recorded));
      }

      final records = <_Rec>[];
      for (final d in mySnap.docs) {
        final data = d.data();
        if ((data['category'] ?? '').toString() == 'Polio') continue;
        final date = _asDate(data['administeredDate'] ?? data['dateGiven'] ?? data['createdAt']);
        if (date == null) continue;
        var status = (data['status'] ?? 'vaccinated').toString().toLowerCase();
        if (status == 'completed') status = 'vaccinated';
        if (status != 'vaccinated' && status != 'refused') continue;
        records.add(_Rec(
          date,
          (data['vaccineName'] ?? 'Vaccine').toString(),
          status,
          (data['childId'] ?? '').toString(),
          recordedAt: _asDate(data['createdAt']),
        ));
      }

      final u = userSnap.data() ?? <String, dynamic>{};

      if (!mounted) return;
      setState(() {
        _children = children;
        _myRecords = records;
        _nameById = nameById;
        _vaccinatorName = (u['fullName'] ?? u['name'] ?? '').toString();
        _center = (u['healthCenter'] ?? u['health_center'] ?? '').toString();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Report load nahi ho saki: $e';
        _loading = false;
      });
    }
  }

  // ---------------------------------------------------------------
  // CALCULATIONS
  // ---------------------------------------------------------------
  String _family(String name) {
    final n = VaccinationStatusHelper.normalize(name);
    if (n.startsWith('bcg')) return 'BCG';
    if (n.startsWith('opv')) return 'OPV';
    if (n.startsWith('penta')) return 'Pentavalent';
    if (n.startsWith('pcv')) return 'PCV';
    if (n.startsWith('rota')) return 'Rotavirus';
    if (n.startsWith('ipv')) return 'IPV';
    if (n.startsWith('measles') || n.startsWith('mr')) return 'Measles-Rubella';
    if (n.startsWith('tcv')) return 'TCV';
    return name;
  }

  bool _isRecorded(String vaccine, List<String> names) {
    final t = VaccinationStatusHelper.normalize(vaccine);
    return names.any((g) {
      final n = VaccinationStatusHelper.normalize(g);
      if (n.isEmpty) return false;
      return n == t || n.contains(t) || t.contains(n);
    });
  }

  DateTime _addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

  DateTime get _start {
    final d = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    if (_mode == 0) return d;
    if (_mode == 1) return _addDays(d, -(d.weekday - 1));
    return DateTime(d.year, d.month, 1);
  }

  DateTime get _end {
    final s = _start;
    if (_mode == 0) return _addDays(s, 1);
    if (_mode == 1) return _addDays(s, 7);
    return DateTime(s.year, s.month + 1, 1);
  }

  DateTime get _prevStart {
    final s = _start;
    if (_mode == 0) return _addDays(s, -1);
    if (_mode == 1) return _addDays(s, -7);
    return DateTime(s.year, s.month - 1, 1);
  }

  String get _periodLabel {
    final s = _start;
    if (_mode == 0) return DateFormat('dd MMM yyyy').format(s);
    if (_mode == 1) {
      final last = _addDays(_end, -1);
      return '${DateFormat('dd MMM yyyy').format(s)} - ${DateFormat('dd MMM yyyy').format(last)}';
    }
    return DateFormat('MMMM yyyy').format(s);
  }

  String get _modeName => _mode == 0 ? 'Daily' : (_mode == 1 ? 'Weekly' : 'Monthly');
  String get _prevName => _mode == 0 ? 'previous day' : (_mode == 1 ? 'previous week' : 'previous month');

  Map<String, _Counts> _compute(DateTime start, DateTime end) {
    final map = <String, _Counts>{};
    _Counts c(String f) => map.putIfAbsent(f, () => _Counts());

    for (final r in _myRecords) {
      if (r.date.isBefore(start) || !r.date.isBefore(end)) continue;
      final cc = c(_family(r.vaccine));
      if (r.status == 'refused') {
        cc.refused++;
      } else {
        cc.vac++;
      }
    }

    final now = DateTime.now();
    for (final child in _children) {
      final dob = child.dob;
      if (dob == null) continue;
      for (final stage in EpiScheduleHelper.generateEpiSchedule(dob)) {
        final due = stage['dueDate'] as DateTime;
        final dueDay = DateTime(due.year, due.month, due.day);
        if (dueDay.isBefore(start) || !dueDay.isBefore(end)) continue;
        for (final v in List<String>.from(stage['vaccines'])) {
          if (_isRecorded(v, child.recordedVaccines)) continue;
          final cc = c(_family(v));
          if (now.isAfter(due.add(const Duration(days: 14)))) {
            cc.missed++;
          } else {
            cc.pending++;
          }
        }
      }
    }
    return map;
  }

  _Counts _total(Map<String, _Counts> m) {
    final t = _Counts();
    for (final v in m.values) {
      t.vac += v.vac;
      t.pending += v.pending;
      t.missed += v.missed;
      t.refused += v.refused;
    }
    return t;
  }

  List<_Rec> _recordsIn(DateTime s, DateTime e) {
    final list = _myRecords.where((r) => !r.date.isBefore(s) && r.date.isBefore(e)).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<String> _rowNames(Map<String, _Counts> cur) =>
      [..._families, ...cur.keys.where((k) => !_families.contains(k))];

  // ---------------------------------------------------------------
  // PDF
  // ---------------------------------------------------------------
  // The vaccination date is the one the vaccinator picked; createdAt is when
  // the record was actually saved. Both are shown, so a back-dated entry is
  // always visible as such (nothing is hidden or guessed).
  String _recordedAtFull(_Rec r) =>
      r.recordedAt == null ? '-' : DateFormat('dd MMM yyyy, hh:mm a').format(r.recordedAt!);

  // Short note under the date in the app list.
  String _enteredNote(_Rec r) {
    final t = r.recordedAt;
    if (t == null) return '';
    final sameDay = t.year == r.date.year && t.month == r.date.month && t.day == r.date.day;
    return sameDay ? DateFormat('hh:mm a').format(t) : 'Entered ${DateFormat('dd MMM').format(t)}';
  }

  Future<void> _generatePdf(Map<String, _Counts> cur, List<_Rec> records) async {
    final t = _total(cur);
    final pdf = pw.Document();
    final names = _rowNames(cur);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          pw.Text('Routine Vaccination Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
          pw.SizedBox(height: 4),
          pw.Text('$_modeName report: $_periodLabel',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          if (_vaccinatorName.isNotEmpty)
            pw.Text('Vaccinator: $_vaccinatorName',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          if (_center.isNotEmpty)
            pw.Text('Health Center: $_center', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text('Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          pw.Divider(thickness: 1.5, color: PdfColors.green900),
          pw.SizedBox(height: 10),
          pw.Text('Summary',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
          pw.SizedBox(height: 6),
          pw.Table.fromTextArray(
            headers: ['Total Vaccinated', 'Pending', 'Missed', 'Refused'],
            data: [
              ['${t.vac}', '${t.pending}', '${t.missed}', '${t.refused}'],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green900),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignment: pw.Alignment.center,
          ),
          pw.SizedBox(height: 16),
          pw.Text('Vaccine-wise Breakdown',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
          pw.SizedBox(height: 6),
          pw.Table.fromTextArray(
            headers: ['Vaccine', 'Vaccinated', 'Pending', 'Missed', 'Refused'],
            data: names.map((n) {
              final c = cur[n] ?? _Counts();
              return [n, '${c.vac}', '${c.pending}', '${c.missed}', '${c.refused}'];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green900),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          if (records.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('Activity (${records.length} records)',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
            pw.SizedBox(height: 6),
            pw.Table.fromTextArray(
              headers: ['Vaccine Date', 'Child Name', 'Vaccine', 'Status', 'Recorded At'],
              data: records
                  .map((r) => [
                        DateFormat('dd MMM yyyy').format(r.date),
                        _nameById[r.childId] ?? 'Child',
                        r.vaccine,
                        r.status == 'refused' ? 'Refused' : 'Vaccinated',
                        _recordedAtFull(r),
                      ])
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green900),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ],
        ],
      ),
    );

    try {
      await Printing.layoutPdf(
        name: 'Routine_Report_${_modeName}_${DateFormat('yyyyMMdd').format(_start)}.pdf',
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF error: $e')));
      }
    }
  }

  // ---------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: primaryGreen,
            onPrimary: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _showAllActivity = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCanvas,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Routine Vaccination Report',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: Colors.white, size: 22),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  ),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final start = _start;
    final end = _end;
    final cur = _compute(start, end);
    final prev = _compute(_prevStart, start);
    final t = _total(cur);
    final p = _total(prev);
    final records = _recordsIn(start, end);
    final childrenVaccinated =
        records.where((r) => r.status == 'vaccinated').map((r) => r.childId).toSet().length;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: primaryGreen,
            onRefresh: () => _load(silent: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dateSelector(),
                  const SizedBox(height: 12),
                  _modeToggle(),
                  const SizedBox(height: 14),
                  if (_mode == 2) ...[
                    const Text('Monthly Overview',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.black87)),
                    const SizedBox(height: 10),
                  ],
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _statCard(Icons.vaccines, 'Total Vaccinated', t.vac, p.vac, accentGreen, true),
                        const SizedBox(width: 8),
                        _statCard(Icons.schedule, 'Pending', t.pending, p.pending, warningAmber, false),
                        const SizedBox(width: 8),
                        _statCard(Icons.close_rounded, 'Missed', t.missed, p.missed, dangerRed, false),
                        const SizedBox(width: 8),
                        _statCard(Icons.person_off_outlined, 'Refused', t.refused, p.refused, greyTone, false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Change compared to $_prevName',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  if (_mode == 1) ...[
                    const SizedBox(height: 16),
                    _trendCard(start),
                  ],
                  const SizedBox(height: 18),
                  const Text('Vaccine-wise Breakdown',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.black87)),
                  const SizedBox(height: 10),
                  _breakdownCard(cur),
                  if (_mode != 2) ...[
                    const SizedBox(height: 18),
                    _activityCard(records),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: lightGreenBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_note_outlined, color: primaryGreen, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Report generated for $_periodLabel ($_modeName)',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: primaryGreen)),
                              const SizedBox(height: 2),
                              Text('Total children vaccinated: $childrenVaccinated',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => _generatePdf(cur, records),
                  icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                  label: const Text('Download Routine Report (PDF)',
                      style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateSelector() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined, size: 19, color: primaryGreen),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_periodLabel,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _modeToggle() {
    const labels = ['Daily', 'Weekly', 'Monthly'];
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final sel = _mode == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _mode = i;
                _showAllActivity = false;
              }),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _statCard(IconData icon, String label, int value, int prev, Color color, bool goodWhenUp) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(label,
                maxLines: 2,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600, height: 1.2)),
            const Spacer(),
            Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            _delta(value, prev, goodWhenUp),
          ],
        ),
      ),
    );
  }

  Widget _delta(int cur, int prev, bool goodWhenUp) {
    if (prev == 0) {
      return Text('—', style: TextStyle(fontSize: 10, color: Colors.grey.shade500));
    }
    final pct = ((cur - prev) / prev * 100).round();
    if (pct == 0) {
      return Text('0%', style: TextStyle(fontSize: 10, color: Colors.grey.shade500));
    }
    final up = pct > 0;
    final good = up == goodWhenUp;
    final col = good ? accentGreen : dangerRed;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(up ? Icons.arrow_upward : Icons.arrow_downward, size: 10, color: col),
        const SizedBox(width: 2),
        Text('${pct.abs()}%', style: TextStyle(fontSize: 10, color: col, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _trendCard(DateTime start) {
    final days = List.generate(7, (i) => _addDays(start, i));
    final data = days.map((d) => _total(_compute(d, _addDays(d, 1)))).toList();

    int maxVal = 0;
    for (final d in data) {
      for (final v in [d.vac, d.pending, d.missed, d.refused]) {
        if (v > maxVal) maxVal = v;
      }
    }
    final maxY = maxVal < 4 ? 5.0 : (maxVal * 1.25).ceilToDouble();
    final interval = maxY <= 5 ? 1.0 : (maxY / 5).ceilToDouble();

    BarChartRodData rod(int v, Color c) => BarChartRodData(
          toY: v.toDouble(),
          color: c,
          width: 5,
          borderRadius: BorderRadius.circular(2),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vaccination Trend (Weekly)',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.black87)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              _legend(accentGreen, 'Vaccinated'),
              _legend(warningAmber, 'Pending'),
              _legend(dangerRed, 'Missed'),
              _legend(greyTone, 'Refused'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: interval),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: interval,
                      getTitlesWidget: (v, meta) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= days.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(DateFormat('EEE').format(days[i]),
                              style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (int i = 0; i < data.length; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 2,
                      barRods: [
                        rod(data[i].vac, accentGreen),
                        rod(data[i].pending, warningAmber),
                        rod(data[i].missed, dangerRed),
                        rod(data[i].refused, greyTone),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _breakdownCard(Map<String, _Counts> cur) {
    final names = _rowNames(cur);

    Widget hdr(String s) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(s, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.black87)),
          ),
        );

    Widget cell(String s, Color c, {bool bold = true, TextAlign align = TextAlign.center}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          child: Text(
            s,
            textAlign: align,
            style: TextStyle(fontSize: 11.5, color: c, fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {0: FlexColumnWidth(2.4)},
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFEAF6EF)),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                child: const Text('Vaccine',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.black87)),
              ),
              hdr('Vaccinated'),
              hdr('Pending'),
              hdr('Missed'),
              hdr('Refused'),
            ],
          ),
          for (int i = 0; i < names.length; i++)
            TableRow(
              decoration: BoxDecoration(
                color: i.isEven ? Colors.white : const Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              children: () {
                final c = cur[names[i]] ?? _Counts();
                return [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                    child: Text(names[i],
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.black87)),
                  ),
                  cell('${c.vac}', accentGreen),
                  cell('${c.pending}', c.pending > 0 ? warningAmber : Colors.grey, bold: c.pending > 0),
                  cell('${c.missed}', c.missed > 0 ? dangerRed : Colors.grey, bold: c.missed > 0),
                  cell('${c.refused}', c.refused > 0 ? greyTone : Colors.grey, bold: c.refused > 0),
                ];
              }(),
            ),
        ],
      ),
    );
  }

  Widget _activityCard(List<_Rec> records) {
    final shown = _showAllActivity ? records : records.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Activity',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.black87)),
              if (records.length > 5)
                GestureDetector(
                  onTap: () => setState(() => _showAllActivity = !_showAllActivity),
                  child: Text(_showAllActivity ? 'Show Less' : 'View All (${records.length})',
                      style: const TextStyle(fontSize: 11.5, color: primaryGreen, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text('Is period mein koi vaccination record nahi hui.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(color: const Color(0xFFEAF6EF), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: Text('Date', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700))),
                  Expanded(flex: 3, child: Text('Child Name', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700))),
                  Expanded(flex: 3, child: Text('Vaccine', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700))),
                  Expanded(flex: 3, child: Text('Status', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700))),
                ],
              ),
            ),
            ...shown.map((r) {
              final refused = r.status == 'refused';
              final col = refused ? dangerRed : accentGreen;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('dd MMM').format(r.date),
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                          if (_enteredNote(r).isNotEmpty)
                            Text(_enteredNote(r), style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(_nameById[r.childId] ?? 'Child',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(r.vaccine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.black87)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: col.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(refused ? 'Refused' : 'Vaccinated',
                              style: TextStyle(fontSize: 10, color: col, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}