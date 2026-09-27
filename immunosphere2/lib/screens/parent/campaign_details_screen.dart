import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:immunosphere2/models/campaign_model.dart';

class CampaignDetailsScreen extends StatelessWidget {
  final CampaignModel campaign;
  final String childId;

  const CampaignDetailsScreen({
    Key? key,
    required this.campaign,
    required this.childId,
  }) : super(key: key);

  static const Color darkGreen = Color(0xFF0B4D30);
  static const Color primaryGreen = Color(0xFF0E7A45);
  static const Color lightGreenBg = Color(0xFFE5F7ED);

  Color _statusColor(String status) {
    switch (status) {
      case 'Vaccinated':
        return primaryGreen;
      case 'Pending':
        return const Color(0xFFF59E0B);
      case 'Refused':
        return const Color(0xFFEF4444);
      case 'Missed':
        return Colors.redAccent;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Vaccinated':
        return lightGreenBg;
      case 'Pending':
        return const Color(0xFFFFFBEB);
      case 'Refused':
        return const Color(0xFFFEF2F2);
      case 'Missed':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPolio = campaign.type.toLowerCase().contains('polio');
    final vaccineLabel = isPolio ? 'OPV (Polio Vaccine)' : campaign.type;

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
                  const Center(
                    child: Text(
                      'Campaign Details',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
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
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('campaign_assignments')
                    .where('campaignId', isEqualTo: campaign.id)
                    .where('childId', isEqualTo: childId)
                    .snapshots(),
                builder: (context, snap) {
                  Map<String, dynamic>? assignment;
                  if (snap.hasData && snap.data!.docs.isNotEmpty) {
                    assignment = snap.data!.docs.first.data() as Map<String, dynamic>;
                  }

                  final String status = (assignment?['status'] ?? 'Pending').toString();
                  final String? vaccinatorId = assignment?['vaccinatorId']?.toString();
                  final String? address = (assignment?['address'] as String?)?.isNotEmpty == true
                      ? assignment!['address'] as String
                      : null;
                  final dynamic updatedAtRaw = assignment?['updatedAt'];
                  String? visitDate;
                  if (updatedAtRaw is Timestamp) {
                    visitDate = DateFormat('dd MMM yyyy, hh:mm a').format(updatedAtRaw.toDate());
                  }
                  final String? vaccineGiven = (assignment?['vaccineGiven'] as String?)?.isNotEmpty == true &&
                          assignment!['vaccineGiven'] != 'None'
                      ? assignment['vaccineGiven'] as String
                      : null;
                  final String? remarks = (assignment?['remarks'] as String?)?.isNotEmpty == true
                      ? assignment!['remarks'] as String
                      : null;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Campaign header card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: lightGreenBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isPolio ? Icons.shield_outlined : Icons.campaign_outlined,
                                  color: primaryGreen,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  campaign.name,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: _statusBg(status), borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                  status,
                                  style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        _sectionTitle('Campaign Information'),
                        const SizedBox(height: 10),
                        _infoCard([
                          _detailRow(
                            Icons.calendar_today_outlined,
                            'Campaign Date',
                            '${DateFormat('dd MMM').format(campaign.startDate)} – ${DateFormat('dd MMM yyyy').format(campaign.endDate)}',
                          ),
                          _detailRow(
                            Icons.place_outlined,
                            'Target Area',
                            campaign.targetAreas.isNotEmpty ? campaign.targetAreas.join(', ') : 'N/A',
                          ),
                          _detailRow(Icons.vaccines_outlined, 'Vaccine', vaccineLabel, isLast: true),
                        ]),
                        const SizedBox(height: 16),

                        _sectionTitle('Vaccination Record'),
                        const SizedBox(height: 10),
                        _infoCard([
                          if (visitDate != null)
                            _detailRow(Icons.event_available_outlined, 'Vaccination Date', visitDate),
                          if (address != null)
                            _detailRow(Icons.location_on_outlined, 'Vaccination Location', address),
                          if (vaccinatorId != null && vaccinatorId.isNotEmpty)
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('users').doc(vaccinatorId).get(),
                              builder: (context, userSnap) {
                                String vaccinatorName = '';
                                if (userSnap.hasData && userSnap.data!.exists) {
                                  final u = userSnap.data!.data() as Map<String, dynamic>;
                                  vaccinatorName = (u['fullName'] ?? u['name'] ?? '').toString();
                                }
                                if (vaccinatorName.isEmpty) return const SizedBox.shrink();
                                return _detailRow(Icons.person_outline, 'Vaccinator', vaccinatorName);
                              },
                            ),
                          if (vaccineGiven != null) _detailRow(Icons.vaccines, 'Vaccine Given', vaccineGiven),
                          if (remarks != null) _detailRow(Icons.note_alt_outlined, 'Remarks', remarks),
                          _detailRow(
                            Icons.check_circle_outline,
                            'Status',
                            status,
                            valueColor: _statusColor(status),
                            isLast: true,
                          ),
                        ]),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color valueColor = Colors.black87, bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: isLast ? 12 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    const SizedBox(height: 2),
                    Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor)),
                  ],
                ),
              ),
            ],
          ),
          if (!isLast) const Padding(padding: EdgeInsets.only(top: 12), child: Divider(height: 1)),
        ],
      ),
    );
  }
}