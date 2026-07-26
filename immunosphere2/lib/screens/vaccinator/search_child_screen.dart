import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'child_details_screen.dart';

class SearchChildScreen extends StatefulWidget {
  const SearchChildScreen({Key? key}) : super(key: key);

  @override
  State<SearchChildScreen> createState() => _SearchChildScreenState();
}

class _SearchChildScreenState extends State<SearchChildScreen> {
  int _activeFilter = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
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
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('children').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF3F51B5)),
            );
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading children data.'));
          }

          final allDocs = snapshot.data?.docs ?? [];

          // Process & Filter Data locally for responsive search and filter experience
          List<Map<String, dynamic>> childrenList = allDocs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return {
              'docId': doc.id,
              'id': data['regNo'] ?? doc.id.substring(0, 6).toUpperCase(),
              'name': data['fullName'] ?? data['name'] ?? 'Unknown',
              'age': data['age'] ?? 'N/A',
              'gender': data['gender'] ?? 'N/A',
              'village': data['village'] ?? data['address'] ?? 'N/A',
              'cnic': data['cnic'] ?? '',
              'nextDue': data['nextDue'] ?? 'N/A',
              'status': data['status'] ?? 'Vaccinated',
            };
          }).toList();

          // Apply Status Filter
          List<Map<String, dynamic>> statusFiltered = childrenList.where((child) {
            if (_activeFilter == 1) return child['status'].toString().contains('Due');
            if (_activeFilter == 2) return child['status'].toString().contains('Vaccinated');
            if (_activeFilter == 3) return child['status'].toString().contains('Missed');
            return true; // Filter 0: All
          }).toList();

          // Apply Search Query Filter
          List<Map<String, dynamic>> finalFilteredList = statusFiltered.where((child) {
            final nameMatch = child['name'].toString().toLowerCase().contains(_searchQuery);
            final idMatch = child['id'].toString().toLowerCase().contains(_searchQuery);
            final cnicMatch = child['cnic'].toString().toLowerCase().contains(_searchQuery);
            return nameMatch || idMatch || cnicMatch;
          }).toList();

          int countAll = childrenList.length;
          int countDue = childrenList.where((c) => c['status'].toString().contains('Due')).length;
          int countVaccinated = childrenList.where((c) => c['status'].toString().contains('Vaccinated')).length;
          int countMissed = childrenList.where((c) => c['status'].toString().contains('Missed')).length;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // SEARCH FIELD
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name, Child ID or CNIC',
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
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // FILTERS HORIZONTAL SCROLL
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
                      _buildFilterChip('Missed ($countMissed)', 3),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // CHILDREN LIST
                Expanded(
                  child: finalFilteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.search_off, size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                'No children found matching criteria.',
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
                                      backgroundColor: Color(0xFFEEF2FF),
                                      child: Icon(Icons.child_care, color: Color(0xFF3F51B5)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                child['name'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              _buildBadge(child['status']),
                                            ],
                                          ),
                                          Text(
                                            'ID: ${child['id']}',
                                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Age: ${child['age']}  |  ${child['gender']}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              Text(
                                                child['status'].toString().contains('Missed')
                                                    ? child['nextDue']
                                                    : 'Next Due: ${child['nextDue']}',
                                                style: TextStyle(
                                                  color: child['status'].toString().contains('Missed')
                                                      ? const Color(0xFFEF4444)
                                                      : Colors.grey.shade600,
                                                  fontSize: 10,
                                                  fontWeight: child['status'].toString().contains('Missed')
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            'Village: ${child['village']}',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 11,
                                            ),
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
          color: isSelected ? const Color(0xFF3F51B5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF3F51B5) : Colors.grey.shade300,
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
    Color bg = const Color(0xFFECFDF5);
    Color text = const Color(0xFF10B981);

    if (status.contains('Due')) {
      bg = const Color(0xFFFFFBEB);
      text = const Color(0xFFF59E0B);
    } else if (status.contains('Missed')) {
      bg = const Color(0xFFFEF2F2);
      text = const Color(0xFFEF4444);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        status,
        style: TextStyle(color: text, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}