/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vaccination_schedule_screen.dart';
import 'child_qr_code_screen.dart';

class ChildDetailScreen extends StatelessWidget {
  final String childId;
  final String childName;
  final String childAge;

  const ChildDetailScreen({
    Key? key,
    required this.childId,
    required this.childName,
    required this.childAge,
  }) : super(key: key);

  static const Color primaryGreen = Color(0xFF0E9F6E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          childName,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('children')
              .doc(childId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('Error loading profile details.'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryGreen),
              );
            }

            Map<String, dynamic> data = {};
            if (snapshot.hasData && snapshot.data!.exists) {
              data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            }

            final String gender = data['gender'] ?? 'Male';
            final String dob = _formatDate(data['dob'] ?? data['dateOfBirth']);
            final String bloodGroup = data['bloodGroup'] ?? 'N/A';
            final String parentCNIC = data['parentCNIC'] ?? 'N/A';
            final String address = data['address'] ?? 'N/A';

            final bool isMale = gender.toLowerCase() == 'boy' || gender.toLowerCase() == 'male';

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. PROFILE HEADER CARD
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: const Color(0xFFE5F7ED),
                          child: Text(
                            isMale ? '👦' : '👧',
                            style: const TextStyle(fontSize: 38),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          childName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          childAge,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            gender,
                            style: const TextStyle(
                              color: Color(0xFF0284C7),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. DETAILS TABLE / CARD
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('Child ID', childId),
                        const Divider(height: 20),
                        _buildInfoRow('Date of Birth', dob),
                        const Divider(height: 20),
                        _buildInfoRow('Blood Group', bloodGroup, valueColor: Colors.red),
                        const Divider(height: 20),
                        _buildInfoRow("Parent's CNIC", parentCNIC),
                        const Divider(height: 20),
                        _buildInfoRow('Address', address),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. DYNAMIC LAST VACCINATED INFO BOX
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('vaccine_records')
                        .where('childId', isEqualTo: childId)
                        .snapshots(),
                    builder: (context, recordSnapshot) {
                      String lastVaccineName = 'None';
                      String lastVaccineDate = 'N/A';
                      String centerName = 'N/A';

                      if (recordSnapshot.hasData && recordSnapshot.data!.docs.isNotEmpty) {
                        // Filter Completed / Administered records flexibly
                        var completedDocs = recordSnapshot.data!.docs.where((doc) {
                          var record = doc.data() as Map<String, dynamic>;
                          String status = (record['status'] ?? '').toString().toLowerCase().trim();
                          bool isDone = record['isDone'] == true || record['administered'] == true;
                          return status == 'completed' || status == 'done' || status == 'administered' || status == 'given' || isDone;
                        }).toList();

                        if (completedDocs.isNotEmpty) {
                          // Sort by date descending
                          completedDocs.sort((a, b) {
                            var aData = a.data() as Map<String, dynamic>;
                            var bData = b.data() as Map<String, dynamic>;

                            DateTime dtA = _convertToDateTime(aData['administeredDate'] ?? aData['date'] ?? aData['givenDate']);
                            DateTime dtB = _convertToDateTime(bData['administeredDate'] ?? bData['date'] ?? bData['givenDate']);
                            return dtB.compareTo(dtA);
                          });

                          var lastRecord = completedDocs.first.data() as Map<String, dynamic>;
                          lastVaccineName = lastRecord['vaccineName'] ?? lastRecord['vaccine'] ?? lastRecord['title'] ?? 'Vaccine';
                          lastVaccineDate = _formatDate(lastRecord['administeredDate'] ?? lastRecord['date'] ?? lastRecord['givenDate']);
                          centerName = lastRecord['centerName'] ?? lastRecord['hospitalName'] ?? lastRecord['administeredAt'] ?? 'BHU Center';
                        }
                      }

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_outlined,
                              color: primaryGreen,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Last Vaccinated',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    lastVaccineName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    lastVaccineDate,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Vaccinated At',
                                    style: TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                  Text(
                                    centerName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // 4. ACTION BUTTON 1: VACCINATION SCHEDULE
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VaccinationScheduleScreen(
                              childId: childId,
                              childName: childName,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Vaccination Schedule',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 5. ACTION BUTTON 2: QR CODE
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChildQRCodeScreen(
                              childName: childName,
                              childID: childId,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: primaryGreen),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'QR Code',
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, {Color valueColor = Colors.black87}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // --- Date Formatter Helper ---
  static String _formatDate(dynamic rawDate) {
    if (rawDate == null) return 'N/A';
    DateTime? dt;
    if (rawDate is Timestamp) {
      dt = rawDate.toDate();
    } else if (rawDate is DateTime) {
      dt = rawDate;
    } else if (rawDate is String) {
      dt = _convertToDateTime(rawDate);
    }

    if (dt == null || dt.year == 2000) return rawDate.toString();

    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return "$day-$month-${dt.year}";
  }

  // --- Safe Date Parsing Helper ---
  static DateTime _convertToDateTime(dynamic rawDate) {
    if (rawDate == null) return DateTime(2000);
    if (rawDate is Timestamp) return rawDate.toDate();
    if (rawDate is DateTime) return rawDate;
    
    if (rawDate is String) {
      String str = rawDate.trim();
      if (str.contains('/')) {
        List<String> parts = str.split('/');
        if (parts.length == 3) {
          // DD/MM/YYYY format handling
          return DateTime.tryParse('${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}') ?? DateTime(2000);
        }
      } else if (str.contains('-')) {
        List<String> parts = str.split('-');
        if (parts.length == 3 && parts[0].length == 2) {
          // DD-MM-YYYY format handling
          return DateTime.tryParse('${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}') ?? DateTime(2000);
        }
      }
      return DateTime.tryParse(str) ?? DateTime(2000);
    }
    return DateTime(2000);
  }
} */
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vaccination_schedule_screen.dart';
import 'child_qr_code_screen.dart';

class ChildDetailScreen extends StatelessWidget {
  final String childId;
  final String childName;
  final String childAge;

  const ChildDetailScreen({
    Key? key,
    required this.childId,
    required this.childName,
    required this.childAge,
  }) : super(key: key);

  static const Color primaryGreen = Color(0xFF0E9F6E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          childName,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('children')
              .doc(childId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('Error loading profile details.'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryGreen),
              );
            }

            Map<String, dynamic> data = {};
            if (snapshot.hasData && snapshot.data!.exists) {
              data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            }

            final String gender = data['gender'] ?? 'Male';
            final String dob = _formatDate(data['dob'] ?? data['dateOfBirth']);
            final String bloodGroup = data['bloodGroup'] ?? 'N/A';
            final String parentCNIC = data['cnic'] ?? 'N/A';
            final String address = data['address'] ?? 'N/A';

            final bool isMale = gender.toLowerCase() == 'boy' || gender.toLowerCase() == 'male';

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. PROFILE HEADER CARD
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: const Color(0xFFE5F7ED),
                          child: Text(
                            isMale ? '👦' : '👧',
                            style: const TextStyle(fontSize: 38),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          childName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          childAge,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            gender,
                            style: const TextStyle(
                              color: Color(0xFF0284C7),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. DETAILS TABLE / CARD
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('Child ID', childId),
                        const Divider(height: 20),
                        _buildInfoRow('Date of Birth', dob),
                        const Divider(height: 20),
                        _buildInfoRow('Blood Group', bloodGroup, valueColor: Colors.red),
                        const Divider(height: 20),
                        _buildInfoRow("Parent's CNIC", parentCNIC),
                        const Divider(height: 20),
                        _buildInfoRow('Address', address),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. DYNAMIC LAST VACCINATED INFO BOX
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('vaccinations')
                        .where('childId', isEqualTo: childId)
                        .snapshots(),
                    builder: (context, recordSnapshot) {
                      String lastVaccineName = 'None';
                      String lastVaccineDate = 'N/A';
                      String centerName = 'N/A';

                      if (recordSnapshot.hasData && recordSnapshot.data!.docs.isNotEmpty) {
                        // Filter Completed / Administered records flexibly
                        var completedDocs = recordSnapshot.data!.docs.where((doc) {
                          var record = doc.data() as Map<String, dynamic>;
                          String status = (record['status'] ?? '').toString().toLowerCase().trim();
                          bool isDone = record['isDone'] == true || record['administered'] == true;
                          return status == 'completed' || status == 'done' || status == 'administered' || status == 'given' || status == 'vaccinated' || isDone;
                        }).toList();

                        if (completedDocs.isNotEmpty) {
                          // Sort by date descending
                          completedDocs.sort((a, b) {
                            var aData = a.data() as Map<String, dynamic>;
                            var bData = b.data() as Map<String, dynamic>;

                            DateTime dtA = _convertToDateTime(aData['administeredDate'] ?? aData['date'] ?? aData['givenDate']);
                            DateTime dtB = _convertToDateTime(bData['administeredDate'] ?? bData['date'] ?? bData['givenDate']);
                            return dtB.compareTo(dtA);
                          });

                          var lastRecord = completedDocs.first.data() as Map<String, dynamic>;
                          lastVaccineName = lastRecord['vaccineName'] ?? lastRecord['vaccine'] ?? lastRecord['title'] ?? 'Vaccine';
                          lastVaccineDate = _formatDate(lastRecord['administeredDate'] ?? lastRecord['date'] ?? lastRecord['givenDate']);
                          centerName = lastRecord['centerName'] ?? lastRecord['hospitalName'] ?? lastRecord['administeredAt'] ?? 'BHU Center';
                        }
                      }

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_outlined,
                              color: primaryGreen,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Last Vaccinated',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    lastVaccineName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    lastVaccineDate,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Vaccinated At',
                                    style: TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                  Text(
                                    centerName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // 4. ACTION BUTTON 1: VACCINATION SCHEDULE
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VaccinationScheduleScreen(
                              childId: childId,
                              childName: childName,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Vaccination Schedule',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 5. ACTION BUTTON 2: QR CODE
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChildQRCodeScreen(
                              childName: childName,
                              childID: childId,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: primaryGreen),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'QR Code',
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, {Color valueColor = Colors.black87}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // --- Date Formatter Helper ---
  static String _formatDate(dynamic rawDate) {
    if (rawDate == null) return 'N/A';
    DateTime? dt;
    if (rawDate is Timestamp) {
      dt = rawDate.toDate();
    } else if (rawDate is DateTime) {
      dt = rawDate;
    } else if (rawDate is String) {
      dt = _convertToDateTime(rawDate);
    }

    if (dt == null || dt.year == 2000) return rawDate.toString();

    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return "$day-$month-${dt.year}";
  }

  // --- Safe Date Parsing Helper ---
  static DateTime _convertToDateTime(dynamic rawDate) {
    if (rawDate == null) return DateTime(2000);
    if (rawDate is Timestamp) return rawDate.toDate();
    if (rawDate is DateTime) return rawDate;
    
    if (rawDate is String) {
      String str = rawDate.trim();
      if (str.contains('/')) {
        List<String> parts = str.split('/');
        if (parts.length == 3) {
          // DD/MM/YYYY format handling
          return DateTime.tryParse('${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}') ?? DateTime(2000);
        }
      } else if (str.contains('-')) {
        List<String> parts = str.split('-');
        if (parts.length == 3 && parts[0].length == 2) {
          // DD-MM-YYYY format handling
          return DateTime.tryParse('${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}') ?? DateTime(2000);
        }
      }
      return DateTime.tryParse(str) ?? DateTime(2000);
    }
    return DateTime(2000);
  }
}