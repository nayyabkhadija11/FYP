import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:immunosphere2/models/campaign_model.dart';
import 'package:immunosphere2/helpers/vaccination_status_helper.dart';
import 'child_details_screen.dart';

const Color _primaryGreen = Color(0xFF0B4D30);
const Color _accentGreen = Color(0xFF0E7A45);
const Color _lightGreenBg = Color(0xFFE5F7ED);
const Color _warningAmber = Color(0xFFF59E0B);
const Color _dangerRed = Color(0xFFEF4444);
const Color _bgCanvas = Color(0xFFF8FAFC);

String _groupStatus(dynamic raw) {
  final s = (raw ?? 'Pending').toString().toLowerCase();
  if (s == 'vaccinated') return 'Vaccinated';
  if (s == 'refused') return 'Refused';
  if (s == 'missed') return 'Missed';
  return 'Pending';
}

Color _statusColor(String status) {
  switch (status) {
    case 'Vaccinated':
      return _accentGreen;
    case 'Refused':
    case 'Missed':
      return _dangerRed;
    default:
      return _warningAmber;
  }
}

/// One child row of the campaign list.
class PolioChildRow {
  final String childId;
  final String name;
  final String cnic;
  final String age;
  final String gender;
  final String house;
  final String area;
  final String dose;
  final String status; // Vaccinated | Pending | Missed | Refused
  final DateTime? recordedAt; // when the vaccinator saved the status
  final Map<String, dynamic> childData;

  const PolioChildRow({
    required this.childId,
    required this.name,
    required this.cnic,
    required this.age,
    required this.gender,
    required this.house,
    required this.area,
    required this.dose,
    required this.status,
    required this.childData,
    this.recordedAt,
  });
}

/// Loads this vaccinator's assignments for one campaign and joins them with
/// the child profile (CNIC, gender, house, area).
Future<List<PolioChildRow>> fetchPolioRows(String campaignId) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return [];
  final db = FirebaseFirestore.instance;

  final aSnap = await db
      .collection('campaign_assignments')
      .where('campaignId', isEqualTo: campaignId)
      .where('vaccinatorId', isEqualTo: uid)
      .get();

  final ids = aSnap.docs
      .map((d) => (d.data()['childId'] ?? '').toString())
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList();

  final Map<String, Map<String, dynamic>> childDocs = {};
  for (int i = 0; i < ids.length; i += 30) {
    final end = (i + 30 > ids.length) ? ids.length : i + 30;
    final snap = await db
        .collection('children')
        .where(FieldPath.documentId, whereIn: ids.sublist(i, end))
        .get();
    for (final d in snap.docs) {
      childDocs[d.id] = d.data();
    }
  }

  String pick(List<dynamic> vals) {
    for (final v in vals) {
      final s = (v ?? '').toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  final rows = aSnap.docs.map((d) {
    final a = d.data();
    final childId = (a['childId'] ?? '').toString();
    final c = childDocs[childId] ?? <String, dynamic>{};

    final name = pick([a['childName'], c['fullName'], c['name']]);
    final g = pick([c['gender']]).toLowerCase();
    final gender = (g == 'male' || g == 'boy')
        ? 'M'
        : (g == 'female' || g == 'girl')
            ? 'F'
            : '-';

    String age = pick([a['age']]);
    if (age.isEmpty && VaccinationStatusHelper.hasValidDob(c['dob'])) {
      final dob = VaccinationStatusHelper.parseDob(c['dob']);
      final now = DateTime.now();
      int years = now.year - dob.year;
      int months = now.month - dob.month;
      if (months < 0) {
        years--;
        months += 12;
      }
      age = years > 0 ? '${years}Y' : '${months}M';
    }

    final status = _groupStatus(a['status']);
    String dose = '-';
    if (status == 'Vaccinated') {
      final vg = pick([a['vaccineGiven']]);
      if (vg.isNotEmpty && vg != 'None') dose = vg;
    }

    // updatedAt is written by RecordStatusScreen when the status is saved.
    DateTime? recordedAt;
    final u = a['updatedAt'];
    if (u is Timestamp && status != 'Pending') recordedAt = u.toDate();

    return PolioChildRow(
      childId: childId,
      name: name.isEmpty ? 'Unknown Child' : name,
      cnic: pick([c['cnic'], c['guardianCnic'], c['motherCnic']]),
      age: age.isEmpty ? 'N/A' : age,
      gender: gender,
      house: pick([c['houseNo'], c['houseNumber'], c['houseAddress'], a['address']]),
      area: pick([c['village'], c['address']]),
      dose: dose,
      status: status,
      recordedAt: recordedAt,
      childData: <String, dynamic>{
        ...c,
        'docId': childId,
        if (c.isEmpty) 'fullName': name,
      },
    );
  }).toList();

  rows.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return rows;
}

// =====================================================================
// SCREEN 1: campaign picker + details + summary
// =====================================================================
class VaccinatorPolioReportScreen extends StatefulWidget {
  const VaccinatorPolioReportScreen({Key? key}) : super(key: key);

  @override
  State<VaccinatorPolioReportScreen> createState() => _VaccinatorPolioReportScreenState();
}

class _VaccinatorPolioReportScreenState extends State<VaccinatorPolioReportScreen> {
  bool _loading = true;
  String? _error;
  List<CampaignModel> _campaigns = [];
  CampaignModel? _selected;
  // campaignId -> statuses of this vaccinator's assignments
  Map<String, List<String>> _statusesByCampaign = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw 'Login nahi mila';
      final db = FirebaseFirestore.instance;

      final snap = await db.collection('campaign_assignments').where('vaccinatorId', isEqualTo: uid).get();

      final grouped = <String, List<String>>{};
      for (final d in snap.docs) {
        final data = d.data();
        final cid = (data['campaignId'] ?? '').toString();
        if (cid.isEmpty) continue;
        grouped.putIfAbsent(cid, () => []).add(_groupStatus(data['status']));
      }

      final campaigns = <CampaignModel>[];
      await Future.wait(grouped.keys.map((id) async {
        try {
          final doc = await db.collection('campaigns').doc(id).get();
          if (doc.exists && doc.data() != null) {
            campaigns.add(CampaignModel.fromMap(doc.data()!, doc.id));
          }
        } catch (_) {}
      }));
      campaigns.sort((a, b) => b.startDate.compareTo(a.startDate));

      // Keep the previous selection on refresh; otherwise prefer a running campaign.
      CampaignModel? pick;
      if (_selected != null) {
        for (final c in campaigns) {
          if (c.id == _selected!.id) pick = c;
        }
      }
      if (pick == null) {
        final now = DateTime.now();
        for (final c in campaigns) {
          final active = c.status != 'completed' &&
              !now.isBefore(c.startDate) &&
              now.isBefore(c.endDate.add(const Duration(days: 1)));
          if (active) {
            pick = c;
            break;
          }
        }
        pick ??= campaigns.isNotEmpty ? campaigns.first : null;
      }

      if (!mounted) return;
      setState(() {
        _campaigns = campaigns;
        _statusesByCampaign = grouped;
        _selected = pick;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Campaign load nahi ho saki: $e';
        _loading = false;
      });
    }
  }

  Future<void> _openCampaignPicker() async {
    if (_campaigns.isEmpty) return;
    final pickedId = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Select Campaign',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _primaryGreen)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _campaigns.length,
                itemBuilder: (context, i) {
                  final c = _campaigns[i];
                  final sel = c.id == _selected?.id;
                  return ListTile(
                    leading: Icon(Icons.verified_user_outlined, color: sel ? _primaryGreen : Colors.grey),
                    title: Text(c.name,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: sel ? _primaryGreen : Colors.black87)),
                    subtitle: Text(
                      '${DateFormat('dd MMM yyyy').format(c.startDate)} - ${DateFormat('dd MMM yyyy').format(c.endDate)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    trailing: sel ? const Icon(Icons.check, color: _primaryGreen) : null,
                    onTap: () => Navigator.pop(sheetContext, c.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (pickedId != null && pickedId != _selected?.id) {
      setState(() => _selected = _campaigns.firstWhere((c) => c.id == pickedId));
    }
  }

  Future<void> _openChildren() async {
    final c = _selected;
    if (c == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VaccinatorPolioChildrenScreen(campaign: c)),
    );
    if (mounted) _load(silent: true); // statuses may have changed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCanvas,
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Polio Campaign Report',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primaryGreen))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  ),
                )
              : _selected == null
                  ? _emptyState()
                  : _buildBody(_selected!),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 46, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text(
              'Aap ko abhi tak kisi polio campaign mein assign nahi kiya gaya.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(CampaignModel c) {
    final statuses = _statusesByCampaign[c.id] ?? [];
    final total = statuses.length;
    final vac = statuses.where((s) => s == 'Vaccinated').length;
    final pending = statuses.where((s) => s == 'Pending').length;
    final missedRefused = statuses.where((s) => s == 'Missed' || s == 'Refused').length;
    String pct(int n) => total > 0 ? '${(n / total * 100).round()}%' : '0%';

    final dates =
        '${DateFormat('dd MMM yyyy').format(c.startDate)} - ${DateFormat('dd MMM yyyy').format(c.endDate)}';
    final areas = c.targetAreas.isEmpty ? '-' : c.targetAreas.join(', ');

    return RefreshIndicator(
      color: _primaryGreen,
      onRefresh: () => _load(silent: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Campaign',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 10),
            InkWell(
              onTap: _openCampaignPicker,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: _lightGreenBg),
                      child: const Icon(Icons.verified_user, color: _primaryGreen, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.black87)),
                          const SizedBox(height: 2),
                          Text(dates, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade700),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Campaign Details',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _detailRow(Icons.campaign_outlined, 'Campaign Name', c.name),
                  Divider(height: 1, color: Colors.grey.shade200),
                  _detailRow(Icons.calendar_month_outlined, 'Campaign Dates', dates),
                  Divider(height: 1, color: Colors.grey.shade200),
                  _detailRow(Icons.location_on_outlined, 'Assigned Area', areas),
                  Divider(height: 1, color: Colors.grey.shade200),
                  _detailRow(Icons.flag_outlined, 'Campaign Type', c.type),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('Campaign Summary',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _summaryTile(Icons.groups_outlined, 'Assigned Children', '$total', '', _primaryGreen,
                      const Color(0xFFE5F7ED)),
                  const SizedBox(width: 8),
                  _summaryTile(Icons.vaccines, 'Vaccinated', '$vac', pct(vac), _accentGreen,
                      const Color(0xFFE5F7ED)),
                  const SizedBox(width: 8),
                  _summaryTile(Icons.schedule, 'Pending', '$pending', pct(pending), const Color(0xFFD97706),
                      const Color(0xFFFEF3C7)),
                  const SizedBox(width: 8),
                  _summaryTile(Icons.close_rounded, 'Missed / Refused', '$missedRefused', pct(missedRefused),
                      _dangerRed, const Color(0xFFFEE2E2)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: total == 0 ? null : _openChildren,
                icon: const Icon(Icons.groups, color: Colors.white, size: 19),
                label: Text('View Assigned Children ($total)',
                    style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  disabledBackgroundColor: Colors.grey.shade400,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _primaryGreen),
          const SizedBox(width: 12),
          SizedBox(
            width: 104,
            child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(IconData icon, String label, String value, String pct, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade700, height: 1.2)),
            const Spacer(),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(pct, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// SCREEN 2: assigned children table (search, status chips, PDF)
// =====================================================================
class VaccinatorPolioChildrenScreen extends StatefulWidget {
  final CampaignModel campaign;
  const VaccinatorPolioChildrenScreen({Key? key, required this.campaign}) : super(key: key);

  @override
  State<VaccinatorPolioChildrenScreen> createState() => _VaccinatorPolioChildrenScreenState();
}

class _VaccinatorPolioChildrenScreenState extends State<VaccinatorPolioChildrenScreen> {
  // column widths
  static const double _wNo = 30;
  static const double _wChild = 168;
  static const double _wAge = 48;
  static const double _wGender = 54;
  static const double _wHouse = 92;
  static const double _wArea = 92;
  static const double _wDose = 94;
  static const double _wFinger = 54;
  static const double _wTime = 112;
  static const double _wStatus = 86;
  static const double _wArrow = 22;
  static const double _tableWidth =
      _wNo + _wChild + _wAge + _wGender + _wHouse + _wArea + _wDose + _wTime + _wFinger + _wStatus + _wArrow + 16;

  bool _loading = true;
  String? _error;
  List<PolioChildRow> _rows = [];
  String _filter = 'All';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final rows = await fetchPolioRows(widget.campaign.id);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Bachon ki list load nahi ho saki: $e';
        _loading = false;
      });
    }
  }

  int _count(String f) => f == 'All' ? _rows.length : _rows.where((r) => r.status == f).length;

  List<PolioChildRow> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _rows.where((r) {
      if (_filter != 'All' && r.status != _filter) return false;
      if (q.isEmpty) return true;
      return r.name.toLowerCase().contains(q) ||
          r.cnic.toLowerCase().contains(q) ||
          r.house.toLowerCase().contains(q) ||
          r.area.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openChild(PolioChildRow r) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChildDetailsScreen(childData: r.childData)),
    );
    if (mounted) _load(silent: true);
  }

  // ---------------- PDF ----------------
  Future<void> _generatePdf() async {
    final c = widget.campaign;
    final total = _rows.length;
    int n(String s) => _rows.where((r) => r.status == s).length;
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          pw.Text('Polio Campaign Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
          pw.SizedBox(height: 4),
          pw.Text('Campaign: ${c.name} (${c.type})',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.Text(
              'Duration: ${DateFormat('dd MMM yyyy').format(c.startDate)} - ${DateFormat('dd MMM yyyy').format(c.endDate)}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          if (c.targetAreas.isNotEmpty)
            pw.Text('Assigned Area: ${c.targetAreas.join(', ')}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text('Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          pw.Divider(thickness: 1.5, color: PdfColors.green900),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['Assigned', 'Vaccinated', 'Pending', 'Missed', 'Refused'],
            data: [
              ['$total', '${n('Vaccinated')}', '${n('Pending')}', '${n('Missed')}', '${n('Refused')}'],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green900),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignment: pw.Alignment.center,
          ),
          pw.SizedBox(height: 14),
          pw.Text('Assigned Children',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
          pw.SizedBox(height: 6),
          pw.Table.fromTextArray(
            headers: ['#', 'Child Name', 'CNIC', 'Age', 'Gender', 'House No.', 'Area', 'Polio Dose', 'Date & Time', 'Status'],
            data: [
              for (int i = 0; i < _rows.length; i++)
                [
                  '${i + 1}',
                  _rows[i].name,
                  _rows[i].cnic.isEmpty ? '-' : _rows[i].cnic,
                  _rows[i].age,
                  _rows[i].gender,
                  _rows[i].house.isEmpty ? '-' : _rows[i].house,
                  _rows[i].area.isEmpty ? '-' : _rows[i].area,
                  _rows[i].dose,
                  _rows[i].recordedAt == null
                      ? '-'
                      : DateFormat('dd MMM yyyy, hh:mm a').format(_rows[i].recordedAt!),
                  _rows[i].status,
                ],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green900),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    try {
      await Printing.layoutPdf(
        name: 'Polio_Report_${c.name.replaceAll(' ', '_')}.pdf',
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF error: $e')));
      }
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final c = widget.campaign;
    final dates =
        '${DateFormat('dd MMM yyyy').format(c.startDate)} - ${DateFormat('dd MMM yyyy').format(c.endDate)}';
    final area = c.targetAreas.isEmpty ? '' : c.targetAreas.join(', ');

    return Scaffold(
      backgroundColor: _bgCanvas,
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Polio Campaign Report',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primaryGreen))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: _lightGreenBg),
                              child: const Icon(Icons.verified_user, color: _primaryGreen, size: 21),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.black87)),
                                  const SizedBox(height: 2),
                                  Text(dates, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            if (area.isNotEmpty)
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _lightGreenBg,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 13, color: _primaryGreen),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(area,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 10.5, color: _primaryGreen, fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search by name, CNIC, house no. or area...',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade600),
                          suffixIcon: _searchCtrl.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => setState(_searchCtrl.clear),
                                ),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _primaryGreen),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                        children: ['All', 'Vaccinated', 'Pending', 'Missed', 'Refused'].map(_chip).toList(),
                      ),
                    ),
                    Expanded(child: _buildTable()),
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
                              onPressed: _rows.isEmpty ? null : _generatePdf,
                              icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                              label: const Text('Download Campaign Report (PDF)',
                                  style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryGreen,
                                disabledBackgroundColor: Colors.grey.shade400,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _chip(String label) {
    final sel = _filter == label;
    final color = label == 'All' ? _primaryGreen : _statusColor(label);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(sel ? 1 : 0.3)),
          ),
          child: Text(
            '$label (${_count(label)})',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: sel ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    final list = _filtered;

    Widget head(String t, double w, {TextAlign align = TextAlign.left}) => SizedBox(
          width: w,
          child: Text(t,
              textAlign: align,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.black87)),
        );

    return RefreshIndicator(
      color: _primaryGreen,
      onRefresh: () => _load(silent: true),
      child: list.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 60),
                Icon(Icons.search_off, size: 40, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Center(
                  child: Text('Koi bacha nahi mila.',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
                ),
              ],
            )
          : Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: _tableWidth,
                  child: Column(
                    children: [
                      Container(
                        color: const Color(0xFFEAF6EF),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        child: Row(
                          children: [
                            head('#', _wNo),
                            head('Child Name', _wChild),
                            head('Age', _wAge),
                            head('Gender', _wGender),
                            head('House No.', _wHouse),
                            head('Area', _wArea),
                            head('Polio Dose', _wDose),
                            head('Date & Time', _wTime),
                            head('Finger', _wFinger, align: TextAlign.center),
                            head('Status', _wStatus),
                            const SizedBox(width: _wArrow),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: list.length,
                          itemBuilder: (context, i) => _row(list[i], i),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _row(PolioChildRow r, int i) {
    final col = _statusColor(r.status);

    Widget txt(String s, double w, {bool center = false}) => SizedBox(
          width: w,
          child: Text(
            s.isEmpty ? '-' : s,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: center ? TextAlign.center : TextAlign.left,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
        );

    return InkWell(
      onTap: () => _openChild(r),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
        child: Row(
          children: [
            txt('${i + 1}', _wNo),
            SizedBox(
              width: _wChild,
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: _lightGreenBg,
                    child: Icon(Icons.child_care, size: 16, color: _primaryGreen),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.w700, color: _primaryGreen)),
                        if (r.cnic.isNotEmpty)
                          Text('CNIC: ${r.cnic}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            txt(r.age, _wAge),
            txt(r.gender, _wGender),
            txt(r.house, _wHouse),
            txt(r.area, _wArea),
            txt(r.dose, _wDose),
            SizedBox(
              width: _wTime,
              child: r.recordedAt == null
                  ? const Text('-', style: TextStyle(fontSize: 11, color: Colors.black87))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(DateFormat('dd MMM yyyy').format(r.recordedAt!),
                            style: const TextStyle(fontSize: 11, color: Colors.black87)),
                        Text(DateFormat('hh:mm a').format(r.recordedAt!),
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                      ],
                    ),
            ),
            SizedBox(width: _wFinger, child: Icon(Icons.fingerprint, size: 22, color: col)),
            SizedBox(
              width: _wStatus,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: col.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(r.status,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: col)),
                ),
              ),
            ),
            SizedBox(width: _wArrow, child: Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}