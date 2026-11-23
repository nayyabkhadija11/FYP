import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HouseholdDetailsScreen extends StatefulWidget {
  final String campaignId;
  final String houseAddress;
  final String vaccinatorName;

  const HouseholdDetailsScreen({
    super.key,
    required this.campaignId,
    required this.houseAddress,
    required this.vaccinatorName,
  });

  @override
  State<HouseholdDetailsScreen> createState() => _HouseholdDetailsScreenState();
}

class _HouseholdDetailsScreenState extends State<HouseholdDetailsScreen> {
  static const Color primaryGreen = Color(0xFF006837);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Household Details", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: primaryGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('campaign_assignments')
            .where('campaignId', isEqualTo: widget.campaignId)
            .where('address', isEqualTo: widget.houseAddress)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryGreen));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('No records found for this household.', style: TextStyle(color: Colors.grey)),
            );
          }

          final total = docs.length;
          final vaccinated = docs.where((d) => d.data()['status'] == 'Vaccinated').length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Household Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                _infoCard(total, vaccinated),

                const SizedBox(height: 16),
                const Text("Children Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                _childrenCard(docs),

                const SizedBox(height: 16),
                const Text("Visit History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                _historyCard(docs),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoCard(int total, int vaccinated) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        children: [
          _RowItem("Address", widget.houseAddress),
          _RowItem("Assigned Vaccinator", widget.vaccinatorName),
          _RowItem("Children Registered", '$total'),
          _RowItem(
            "Status",
            vaccinated == total ? 'All Vaccinated' : '$vaccinated / $total Vaccinated',
            isStatus: vaccinated != total,
          ),
        ],
      ),
    );
  }

  Widget _childrenCard(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        children: [
          for (int i = 0; i < docs.length; i++) ...[
            if (i > 0) const Divider(),
            _RowItem(
              '${docs[i].data()['childName'] ?? 'Unknown'} (${docs[i].data()['age'] ?? 'N/A'})',
              (docs[i].data()['status'] ?? 'Pending').toString(),
              isStatus: docs[i].data()['status'] != 'Vaccinated',
            ),
          ],
        ],
      ),
    );
  }

  Widget _historyCard(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final entries = docs
        .where((d) => d.data()['updatedAt'] is Timestamp)
        .toList()
      ..sort((a, b) => (b.data()['updatedAt'] as Timestamp).compareTo(a.data()['updatedAt'] as Timestamp));

    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
        child: const Text('No visits have been recorded yet..', style: TextStyle(fontSize: 11, color: Colors.grey)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        children: [
          for (int i = 0; i < entries.length; i++) ...[
            if (i > 0) const Divider(),
            _RowItem(
              DateFormat('dd MMM yyyy, hh:mm a').format((entries[i].data()['updatedAt'] as Timestamp).toDate()),
              (entries[i].data()['status'] ?? 'Pending').toString(),
            ),
          ],
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final String val;
  final bool isStatus;
  const _RowItem(this.label, this.val, {this.isStatus = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey))),
          Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isStatus ? Colors.orange : Colors.black)),
        ],
      ),
    );
  }
}