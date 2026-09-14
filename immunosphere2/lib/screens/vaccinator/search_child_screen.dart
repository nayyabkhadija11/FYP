import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:immunosphere2/helpers/vaccination_status_helper.dart';
import 'child_details_screen.dart';

class SearchChildScreen extends StatefulWidget {
  const SearchChildScreen({Key? key}) : super(key: key);

  @override
  State<SearchChildScreen> createState() => _SearchChildScreenState();
}

class _SearchChildScreenState extends State<SearchChildScreen> {
  int _activeFilter = 0; // 0: All, 1: Due, 2: Vaccinated, 3: Refused/Missed
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // COLOR THEME: app-wide deep green (splash/dashboard ke sath consistent)
  static const Color primaryGreen = Color(0xFF0B4D30);
  static const Color accentGreen = Color(0xFF0E7A45);

  // FIX: Stream ko sirf EK dafa (initState mein) banate hain, build() ke
  // andar nahi. Pehle .snapshots() seedha build() ke andar call ho raha
  // tha, jo har setState (yaani har type kiye gaye letter) par ek NAYA
  // stream bana deta tha — is se StreamBuilder thodi der loading state
  // mein chala jata tha aur TextField unmount/remount ho kar focus
  // (keyboard cursor) kho deta tha. Ab stream stable hai, is liye typing
  // ke dauran focus nahi chhutta.
  late final Stream<QuerySnapshot> _childrenStream;
  late final Stream<QuerySnapshot> _vaccinationsStream;

  @override
  void initState() {
    super.initState();
    _childrenStream = FirebaseFirestore.instance.collection('children').snapshots();
    _vaccinationsStream = FirebaseFirestore.instance.collection('vaccinations').snapshots();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Children Directory',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _childrenStream,
        builder: (context, childrenSnapshot) {
          if (childrenSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            );
          }

          if (childrenSnapshot.hasError) {
            return const Center(
              child: Text('Error loading children directory.'),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _vaccinationsStream,
            builder: (context, vaccinationsSnapshot) {
              final allDocs = childrenSnapshot.data?.docs ?? [];

              List<Map<String, dynamic>> allVaccinationDocs = [];
              if (vaccinationsSnapshot.hasData) {
                allVaccinationDocs = vaccinationsSnapshot.data!.docs
                    .map((d) => d.data() as Map<String, dynamic>)
                    .toList();
              }
              final grouped =
                  VaccinationStatusHelper.groupRecordsByChildId(allVaccinationDocs);

              List<Map<String, dynamic>> childrenList = allDocs.map((doc) {
                var data = doc.data() as Map<String, dynamic>;

                String docId = doc.id;
                String regNo = (data['regNo'] ?? '').toString();

                DateTime dob = VaccinationStatusHelper.parseDob(data['dob']);
                List<Map<String, dynamic>> childRecords = [
                  ...(grouped[docId] ?? []),
                  if (regNo.isNotEmpty) ...(grouped[regNo] ?? []),
                ];

                final result =
                    VaccinationStatusHelper.getChildVaccineStatus(dob, childRecords);
                String calculatedStatus = (result['overallStatus'] ?? 'due').toString();

                return {
                  'docId': doc.id,
                  'id': data['regNo'] ?? (doc.id.length >= 6 ? doc.id.substring(0, 6).toUpperCase() : doc.id.toUpperCase()),
                  'name': data['fullName'] ?? data['childName'] ?? data['name'] ?? 'N/A',
                  'fatherName': data['fatherName'] ?? 'N/A',
                  'age': data['age'] ?? 'N/A',
                  'gender': data['gender'] ?? 'N/A',
                  'village': data['village'] ?? data['address'] ?? 'N/A',
                  'cnic': data['cnic'] ?? data['guardianCnic'] ?? '',
                  'nextDue': data['nextDue'] ?? 'N/A',
                  'status': calculatedStatus,
                };
              }).toList();

              int countAll = childrenList.length;
              int countDue = childrenList.where((c) => c['status'].toString().toLowerCase().contains('due')).length;
              int countVaccinated = childrenList.where((c) => c['status'].toString().toLowerCase().contains('vaccinated')).length;
              int countMissed = childrenList.where((c) => 
                c['status'].toString().toLowerCase().contains('missed') || 
                c['status'].toString().toLowerCase().contains('refused')
              ).length;

              List<Map<String, dynamic>> statusFiltered = childrenList.where((child) {
                final st = child['status'].toString().toLowerCase();
                if (_activeFilter == 1) return st.contains('due');
                if (_activeFilter == 2) return st.contains('vaccinated');
                if (_activeFilter == 3) return st.contains('missed') || st.contains('refused');
                return true;
              }).toList();

              List<Map<String, dynamic>> finalFilteredList = statusFiltered.where((child) {
                final nameMatch = child['name'].toString().toLowerCase().contains(_searchQuery);
                final fatherMatch = child['fatherName'].toString().toLowerCase().contains(_searchQuery);
                final idMatch = child['id'].toString().toLowerCase().contains(_searchQuery);
                final cnicMatch = child['cnic'].toString().toLowerCase().contains(_searchQuery);
                return nameMatch || fatherMatch || idMatch || cnicMatch;
              }).toList();

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            cursorColor: accentGreen,
                            decoration: InputDecoration(
                              hintText: 'Search by name, father name, ID or CNIC',
                              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () => _searchController.clear(),
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: accentGreen, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All ($countAll)', 0),
                          const SizedBox(width: 6),
                          _buildFilterChip('Due ($countDue)', 1),
                          const SizedBox(width: 6),
                          _buildFilterChip('Vaccinated ($countVaccinated)', 2),
                          const SizedBox(width: 6),
                          _buildFilterChip('Missed/Refused ($countMissed)', 3),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: finalFilteredList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.search_off, size: 48, color: Colors.grey),
                                  SizedBox(height: 12),
                                  Text(
                                    'No child records found.',
                                    style: TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: finalFilteredList.length,
                              itemBuilder: (context, index) {
                                final child = finalFilteredList[index];
                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChildDetailsScreen(childData: child),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        const CircleAvatar(
                                          radius: 24,
                                          backgroundColor: Color(0xFFECFDF5),
                                          child: Icon(Icons.child_care, color: accentGreen),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      child['name'],
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  _buildBadge(child['status']),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'ID: ${child['id']}  |  S/O: ${child['fatherName']}',
                                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      'Age: ${child['age']}  |  ${child['gender']}',
                                                      style: TextStyle(
                                                        color: Colors.grey.shade600,
                                                        fontSize: 11,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      child['status'].toString().toLowerCase().contains('missed') || 
                                                      child['status'].toString().toLowerCase().contains('refused')
                                                          ? 'Status: ${child['status']}'
                                                          : 'Next Due: ${child['nextDue']}',
                                                      textAlign: TextAlign.right,
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                      style: TextStyle(
                                                        color: child['status'].toString().toLowerCase().contains('missed') || 
                                                               child['status'].toString().toLowerCase().contains('refused')
                                                            ? const Color(0xFFEF4444)
                                                            : Colors.grey.shade600,
                                                        fontSize: 10,
                                                        fontWeight: child['status'].toString().toLowerCase().contains('missed')
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                'Address: ${child['village']}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 11,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _activeFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryGreen : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String status) {
    String st = status.toLowerCase();
    Color bg = const Color(0xFFECFDF5);
    Color text = accentGreen;

    if (st.contains('due')) {
      bg = const Color(0xFFFFFBEB);
      text = const Color(0xFFF59E0B);
    } else if (st.contains('missed') || st.contains('refused')) {
      bg = const Color(0xFFFEF2F2);
      text = const Color(0xFFEF4444);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: text, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}