import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:immunosphere2/services/campaign_service.dart';
import 'package:immunosphere2/models/campaign_model.dart';

enum CertificateType { routine, polio }

class CertificateViewScreen extends StatefulWidget {
  final String childId;
  final String childName;
  final CertificateType certType;

  const CertificateViewScreen({
    Key? key,
    required this.childId,
    required this.childName,
    required this.certType,
  }) : super(key: key);

  @override
  State<CertificateViewScreen> createState() => _CertificateViewScreenState();
}

class _CertificateViewScreenState extends State<CertificateViewScreen> {
  static const Color darkGreen = Color(0xFF0B4D30);
  static const Color primaryGreen = Color(0xFF0E7A45);
  static const Color lightGreenBg = Color(0xFFE5F7ED);

  final CampaignService _campaignService = CampaignService();
  bool _isGeneratingPdf = false;

  DateTime _parseDob(dynamic dobVal) {
    if (dobVal is Timestamp) return dobVal.toDate();
    if (dobVal is DateTime) return dobVal;
    if (dobVal is String && dobVal.trim().isNotEmpty) {
      return DateTime.tryParse(dobVal) ?? DateTime.now();
    }
    return DateTime.now();
  }

  String _formatAge(DateTime dob) {
    final now = DateTime.now();
    int years = now.year - dob.year;
    int months = now.month - dob.month;
    if (now.day < dob.day) months--;
    if (months < 0) {
      years--;
      months += 12;
    }
    if (years <= 0) return '$months Months';
    return '$years Years, $months Months';
  }

  String get _verificationId {
    final digits = widget.childId.replaceAll(RegExp(r'[^0-9]'), '');
    final suffix = digits.isNotEmpty ? digits : widget.childId;
    return widget.certType == CertificateType.routine
        ? 'IM-RN-$suffix'
        : 'IM-POL-$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final isRoutine = widget.certType == CertificateType.routine;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: darkGreen,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      isRoutine ? 'Routine Certificate' : 'Polio Certificate',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                  ),
                  Positioned(
                    left: 4,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('children').doc(widget.childId).snapshots(),
                builder: (context, childSnap) {
                  if (childSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: primaryGreen));
                  }
                  if (!childSnap.hasData || !childSnap.data!.exists) {
                    return const Center(child: Text('Child record not found.'));
                  }

                  final childData = childSnap.data!.data() as Map<String, dynamic>;
                  final dob = _parseDob(childData['dob'] ?? childData['dateOfBirth']);
                  final gender = (childData['gender'] ?? 'Male').toString();
                  final name = (childData['fullName'] ?? childData['name'] ?? widget.childName).toString();

                  return isRoutine
                      ? _buildRoutineCertificate(context, name, dob, gender)
                      : _buildPolioCertificate(context, name, dob, gender);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineCertificate(BuildContext context, String name, DateTime dob, String gender) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vaccinations')
          .where('childId', isEqualTo: widget.childId)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final rows = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final status = (data['status'] ?? '').toString().toLowerCase();
          return status != 'refused';
        }).toList();

        rows.sort((a, b) {
          final da = (a.data() as Map<String, dynamic>)['administeredDate'];
          final db_ = (b.data() as Map<String, dynamic>)['administeredDate'];
          final dtA = da is Timestamp ? da.toDate() : DateTime(2000);
          final dtB = db_ is Timestamp ? db_.toDate() : DateTime(2000);
          return dtA.compareTo(dtB);
        });

        final vaccinatorIds = rows
            .map((d) => (d.data() as Map<String, dynamic>)['administeredBy']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _campaignService.getVaccinatorsByIds(vaccinatorIds),
          builder: (context, vaccSnap) {
            final nameById = {for (var v in (vaccSnap.data ?? [])) v['id'] as String: v['name'] as String};

            final tableRows = rows.map((d) {
              final data = d.data() as Map<String, dynamic>;
              final rawDate = data['administeredDate'];
              final dateStr = rawDate is Timestamp ? DateFormat('dd MMM yyyy').format(rawDate.toDate()) : '-';
              return {
                'vaccine': (data['vaccineName'] ?? '').toString(),
                'dose': (data['dose'] ?? '-').toString(),
                'date': dateStr,
                'vaccinator': nameById[data['administeredBy']?.toString()] ?? '-',
                'center': (data['centerName'] as String?)?.isNotEmpty == true ? data['centerName'] as String : '-',
                'status': 'Completed',
              };
            }).toList();

            return _certificateBody(
              context: context,
              title: 'Digital Routine Immunization Certificate',
              name: name,
              dob: dob,
              gender: gender,
              tableHeaders: const ['Vaccine', 'Dose', 'Date', 'Vaccinator', 'Center', 'Status'],
              tableRows: tableRows.map((r) => [r['vaccine']!, r['dose']!, r['date']!, r['vaccinator']!, r['center']!, r['status']!]).toList(),
              sectionTitle: 'Vaccination Record',
              generatedAtCenter: tableRows.isNotEmpty ? tableRows.last['center']! : null,
            );
          },
        );
      },
    );
  }

  Widget _buildPolioCertificate(BuildContext context, String name, DateTime dob, String gender) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('campaign_assignments')
          .where('childId', isEqualTo: widget.childId)
          .snapshots(),
      builder: (context, snap) {
        final assignDocs = snap.data?.docs ?? [];

        final campaignIds = assignDocs
            .map((d) => (d.data() as Map<String, dynamic>)['campaignId']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();

        final vaccinatorIds = assignDocs
            .map((d) => (d.data() as Map<String, dynamic>)['vaccinatorId']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();

        return FutureBuilder<List<dynamic>>(
          future: Future.wait([
            _fetchCampaignsByIds(campaignIds),
            _campaignService.getVaccinatorsByIds(vaccinatorIds),
          ]),
          builder: (context, futureSnap) {
            if (!futureSnap.hasData) {
              return const Center(child: CircularProgressIndicator(color: primaryGreen));
            }
            final campaigns = futureSnap.data![0] as List<CampaignModel>;
            final vaccinators = futureSnap.data![1] as List<Map<String, dynamic>>;

            final campaignById = {for (var c in campaigns) c.id: c};
            final vaccinatorNameById = {for (var v in vaccinators) v['id'] as String: v['name'] as String};

            final sortedAssignments = List.from(assignDocs)
              ..sort((a, b) {
                final ca = campaignById[(a.data() as Map<String, dynamic>)['campaignId']];
                final cb = campaignById[(b.data() as Map<String, dynamic>)['campaignId']];
                final da = ca?.startDate ?? DateTime(2000);
                final db_ = cb?.startDate ?? DateTime(2000);
                return db_.compareTo(da);
              });

            final tableRows = sortedAssignments.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final campaign = campaignById[data['campaignId']];
              final updatedAt = data['updatedAt'];
              final dateStr = updatedAt is Timestamp
                  ? DateFormat('dd MMM yyyy').format(updatedAt.toDate())
                  : '-';
              final isPolio = (campaign?.type ?? '').toLowerCase().contains('polio');
              return [
                campaign?.name ?? 'Unknown Campaign',
                isPolio ? 'OPV' : (campaign?.type ?? '-'),
                dateStr,
                vaccinatorNameById[data['vaccinatorId']] ?? '-',
                (campaign != null && campaign.targetAreas.isNotEmpty) ? campaign.targetAreas.join(', ') : '-',
                (data['status'] ?? 'Pending').toString(),
              ];
            }).toList();

            return _certificateBody(
              context: context,
              title: 'Digital Polio Vaccination Certificate',
              name: name,
              dob: dob,
              gender: gender,
              tableHeaders: const ['Campaign', 'Vaccine', 'Date', 'Vaccinator', 'Area', 'Status'],
              tableRows: tableRows.cast<List<String>>(),
              sectionTitle: 'Polio Vaccination History',
              generatedAtCenter: null,
            );
          },
        );
      },
    );
  }

  Future<List<CampaignModel>> _fetchCampaignsByIds(List<String> ids) async {
    final List<CampaignModel> result = [];
    for (var i = 0; i < ids.length; i += 10) {
      final end = (i + 10 > ids.length) ? ids.length : i + 10;
      final chunk = ids.sublist(i, end);
      if (chunk.isEmpty) continue;
      final snap = await FirebaseFirestore.instance
          .collection('campaigns')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (var doc in snap.docs) {
        result.add(CampaignModel.fromMap(doc.data(), doc.id));
      }
    }
    return result;
  }

  Widget _certificateBody({
    required BuildContext context,
    required String title,
    required String name,
    required DateTime dob,
    required String gender,
    required List<String> tableHeaders,
    required List<List<String>> tableRows,
    required String sectionTitle,
    String? generatedAtCenter,
  }) {
    final generatedOn = DateFormat('dd MMM yyyy').format(DateTime.now());
    final qrData = 'ImmunoSphere-Verify:$_verificationId;ChildID:${widget.childId}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: darkGreen, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'ImmunoSphere',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: darkGreen),
                      ),
                    ),
                  ],
                ),
                Text('AI-Powered Immunization Platform', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                const SizedBox(height: 16),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: lightGreenBg,
                      child: Text(
                        gender.toLowerCase() == 'male' || gender.toLowerCase() == 'boy' ? '👦' : '👧',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            '${widget.childId}  •  ${_formatAge(dob)}  •  $gender',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Date of Birth', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                        Text(DateFormat('dd MMM yyyy').format(dob), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(sectionTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkGreen)),
                const SizedBox(height: 8),
                tableRows.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text('No records found yet.', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowHeight: 34,
                          dataRowMinHeight: 36,
                          dataRowMaxHeight: 42,
                          columns: tableHeaders
                              .map((h) => DataColumn(label: Text(h, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))))
                              .toList(),
                          rows: tableRows.map((r) {
                            return DataRow(
                              cells: r.asMap().entries.map((entry) {
                                final isStatusCol = entry.key == r.length - 1;
                                final isGood = entry.value == 'Completed' || entry.value == 'Vaccinated';
                                return DataCell(
                                  isStatusCol
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isGood ? lightGreenBg : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            entry.value,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isGood ? primaryGreen : Colors.grey.shade700,
                                            ),
                                          ),
                                        )
                                      : Text(entry.value, style: const TextStyle(fontSize: 11)),
                                );
                              }).toList(),
                            );
                          }).toList(),
                        ),
                      ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        QrImageView(data: qrData, version: QrVersions.auto, size: 70),
                        const SizedBox(height: 4),
                        Text('Verification ID:', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                        Text(_verificationId, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Generated on:', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                        Text(generatedOn, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        if (generatedAtCenter != null) ...[
                          const SizedBox(height: 4),
                          Text(generatedAtCenter, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                        const SizedBox(height: 4),
                        Text('Authorized by:', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                        const Text('ImmunoSphere Platform', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'This is a platform-generated digital certificate. Not a government-issued certificate.',
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGeneratingPdf
                  ? null
                  : () => _downloadPdf(title, name, dob, gender, tableHeaders, tableRows, sectionTitle, generatedOn, generatedAtCenter),
              icon: _isGeneratingPdf
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download, color: Colors.white, size: 18),
              label: Text(_isGeneratingPdf ? 'Generating...' : 'Download PDF', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPdf(
    String title,
    String name,
    DateTime dob,
    String gender,
    List<String> headers,
    List<List<String>> rows,
    String sectionTitle,
    String generatedOn,
    String? generatedAtCenter,
  ) async {
    setState(() => _isGeneratingPdf = true);
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Text('ImmunoSphere', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
            pw.Text('AI-Powered Immunization Platform', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 10),
            pw.Text(title, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Name: $name', style: const pw.TextStyle(fontSize: 11)),
            pw.Text('Child ID: ${widget.childId}', style: const pw.TextStyle(fontSize: 11)),
            pw.Text('Date of Birth: ${DateFormat('dd MMM yyyy').format(dob)}', style: const pw.TextStyle(fontSize: 11)),
            pw.Text('Gender: $gender', style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
            pw.Text(sectionTitle, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
            pw.SizedBox(height: 8),
            rows.isEmpty
                ? pw.Text('No records found yet.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))
                : pw.Table.fromTextArray(
                    headers: headers,
                    data: rows,
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    cellAlignment: pw.Alignment.centerLeft,
                  ),
            pw.SizedBox(height: 24),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  children: [
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: 'ImmunoSphere-Verify:$_verificationId;ChildID:${widget.childId}',
                      width: 70,
                      height: 70,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Verification ID: $_verificationId', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Spacer(),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Generated on: $generatedOn', style: const pw.TextStyle(fontSize: 8)),
                    if (generatedAtCenter != null) pw.Text(generatedAtCenter, style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Authorized by: ImmunoSphere Platform', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'This is a platform-generated digital certificate. Not a government-issued certificate.',
              style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        name: '${title.replaceAll(' ', '_')}_${widget.childId}.pdf',
        onLayout: (format) async => pdf.save(),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }
}