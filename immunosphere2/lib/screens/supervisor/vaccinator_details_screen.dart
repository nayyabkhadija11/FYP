/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // Direct call aur SMS handle karne ke liye

class VaccinatorDetailsScreen extends StatefulWidget {
  final String vaccinatorId;
  final Map<String, dynamic>? initialData;

  const VaccinatorDetailsScreen({
    Key? key,
    this.vaccinatorId = 'VAC002', // Fallback ID
    this.initialData,
  }) : super(key: key);

  @override
  State<VaccinatorDetailsScreen> createState() =>
      _VaccinatorDetailsScreenState();
}

class _VaccinatorDetailsScreenState extends State<VaccinatorDetailsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const Color primaryThemeGreen = Color(0xFF00563B);
  static const Color bgCanvasColor = Color(0xFFF9FAFB);

  // Helper method to make phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch dialer for $phoneNumber')),
        );
      }
    }
  }

  // Helper method to send SMS
  Future<void> _sendSMS(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch SMS app for $phoneNumber')),
        );
      }
    }
  }

  String _getEmployeeId(Map<String, dynamic> data, String docId) {
    List<String> idKeys = [
      'employeeId',
      'employee_id',
      'empId',
      'vaccinatorId',
      'id'
    ];

    for (String key in idKeys) {
      if (data.containsKey(key) &&
          data[key] != null &&
          data[key].toString().trim().isNotEmpty &&
          data[key] is! Map) {
        return data[key].toString().trim();
      }
    }
    return docId;
  }

  Future<String> _fetchHealthCenter(
      String empId, Map<String, dynamic> userData) async {
    List<String> centerKeys = [
      'healthCenter',
      'health_center',
      'healthCenterName',
      'assignedHealthCenter',
      'center',
    ];

    for (String key in centerKeys) {
      if (userData.containsKey(key) &&
          userData[key] != null &&
          userData[key].toString().trim().isNotEmpty) {
        return userData[key].toString().trim();
      }
    }

    try {
      var docSnapshot =
          await _db.collection('valid_employees').doc(empId).get();

      if (!docSnapshot.exists) {
        final querySnapshot = await _db
            .collection('valid_employees')
            .where('employeeId', isEqualTo: empId)
            .limit(1)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          docSnapshot = querySnapshot.docs.first;
        }
      }

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final empData = docSnapshot.data()!;
        for (String key in centerKeys) {
          if (empData.containsKey(key) &&
              empData[key] != null &&
              empData[key].toString().trim().isNotEmpty) {
            return empData[key].toString().trim();
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching health center: $e");
    }

    return 'BHU Jand';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCanvasColor,
      appBar: AppBar(
        backgroundColor: primaryThemeGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Contact Vaccinator',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _db.collection('users').doc(widget.vaccinatorId).snapshots(),
        builder: (context, snapshot) {
          Map<String, dynamic> data = widget.initialData ?? {};
          if (snapshot.hasData && snapshot.data!.data() != null) {
            data = snapshot.data!.data()!;
          }

          final String employeeId = _getEmployeeId(data, widget.vaccinatorId);

          String joinedDate = '12 Jan 2024';
          if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
            joinedDate = DateFormat('dd MMM yyyy')
                .format((data['createdAt'] as Timestamp).toDate());
          } else if (data['joinedOn'] != null) {
            joinedDate = data['joinedOn'].toString();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeaderProfile(data, employeeId),
                const SizedBox(height: 16),
                _buildActionButtons(data),
                const SizedBox(height: 16),
                _buildProfileInformationCard(data, employeeId, joinedDate),
                const SizedBox(height: 16),
                _buildCampaignAssignmentCard(data),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryThemeGreen, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back,
                        color: primaryThemeGreen, size: 20),
                    label: const Text(
                      'Back to Previous Screen',
                      style: TextStyle(
                        color: primaryThemeGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Action Buttons linked with phone number
  Widget _buildActionButtons(Map<String, dynamic> data) {
    final String phoneNumber =
        data['phone'] ?? data['phoneNumber'] ?? '0300-1234567';

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: primaryThemeGreen),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _makePhoneCall(phoneNumber),
            icon: const Icon(Icons.call, color: primaryThemeGreen),
            label: const Text("Call",
                style: TextStyle(
                    color: primaryThemeGreen, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryThemeGreen,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _sendSMS(phoneNumber),
            icon: const Icon(Icons.message, color: Colors.white),
            label: const Text("Message",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildTopHeaderProfile(Map<String, dynamic> data, String employeeId) {
    final String name = data['fullName'] ?? data['name'] ?? 'Fatima Noor';
    final String status = data['status'] ?? 'Active';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: data['photoUrl'] != null &&
                  data['photoUrl'].toString().isNotEmpty
              ? NetworkImage(data['photoUrl'])
              : null,
          child: (data['photoUrl'] == null ||
                  data['photoUrl'].toString().isEmpty)
              ? const Icon(Icons.person, size: 40, color: primaryThemeGreen)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryThemeGreen,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                employeeId,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: primaryThemeGreen,
                  ),
                  const SizedBox(width: 4),
                  FutureBuilder<String>(
                    future: _fetchHealthCenter(employeeId, data),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? 'BHU Jand',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: primaryThemeGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 3,
                backgroundColor: primaryThemeGreen,
              ),
              const SizedBox(width: 5),
              Text(
                status,
                style: const TextStyle(
                  color: primaryThemeGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInformationCard(
      Map<String, dynamic> data, String employeeId, String joinedDate) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryThemeGreen.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline,
                    color: primaryThemeGreen, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Profile Information',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: primaryThemeGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: data['phone'] ?? data['phoneNumber'] ?? '0300-1234567',
          ),
          const Divider(height: 24, thickness: 0.6),
          _infoRow(
            icon: Icons.badge_outlined,
            label: 'Employee ID',
            value: employeeId,
          ),
          const Divider(height: 24, thickness: 0.6),
          _infoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Joined On',
            value: joinedDate,
          ),
          const Divider(height: 24, thickness: 0.6),
          FutureBuilder<String>(
            future: _fetchHealthCenter(employeeId, data),
            builder: (context, snapshot) {
              return _infoRow(
                icon: Icons.location_city_outlined,
                label: 'Health Center',
                value: snapshot.data ?? 'BHU Jand',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignAssignmentCard(Map<String, dynamic> data) {
    final String campaign = data['campaign'] ?? 'National Polio Campaign';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryThemeGreen.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.campaign_outlined,
                    color: primaryThemeGreen, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Current Campaign Assignment',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: primaryThemeGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(
            icon: Icons.calendar_month_outlined,
            label: 'Campaign',
            value: campaign,
          ),
          const Divider(height: 24, thickness: 0.6),
          _infoRow(
            icon: Icons.date_range_outlined,
            label: 'Campaign Period',
            value: data['campaignPeriod'] ?? '10 Aug – 15 Aug 2026',
          ),
          const Divider(height: 24, thickness: 0.6),
          _infoRow(
            icon: Icons.location_on_outlined,
            label: 'Area',
            value: data['assignedArea'] ?? data['area'] ?? 'Mohallah A, Jand',
          ),
          const Divider(height: 24, thickness: 0.6),
          _statusRow(
            icon: Icons.circle,
            label: 'Status',
            value: data['assignmentStatus'] ?? 'Assigned',
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w400,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _statusRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: primaryThemeGreen),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w400,
          ),
        ),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 3,
              backgroundColor: primaryThemeGreen,
            ),
            const SizedBox(width: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: primaryThemeGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
} */
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// =====================================================================
// SHARED HELPERS (vaccinators_screen.dart bhi yehi use karti hai)
// =====================================================================

/// Campaign abhi chal rahi hai? (start date aa chuki, end date ka poora din shamil,
/// aur status 'completed' nahi.)
bool campaignIsRunningNow(Map<String, dynamic> c, DateTime now) {
  final status = (c['status'] ?? '').toString().toLowerCase().trim();
  if (status == 'completed') return false;

  final s = c['startDate'];
  final e = c['endDate'];
  if (s is! Timestamp || e is! Timestamp) return false;

  final start = s.toDate();
  final end = e.toDate();
  final startOfDay = DateTime(start.year, start.month, start.day);
  final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
  return !now.isBefore(startOfDay) && !now.isAfter(endOfDay);
}

class VaccinatorStatus {
  final String label;
  final bool isActive;
  const VaccinatorStatus(this.label, this.isActive);
}

/// Active = vaccinator abhi kisi chal rahi campaign mein assign hai.
/// Warna "Available". (Account agar Inactive/Disabled ho to wohi dikhta hai.)
VaccinatorStatus vaccinatorStatusOf(Map<String, dynamic> data, bool hasRunningCampaign) {
  final account = (data['status'] ?? '').toString().trim();
  final lower = account.toLowerCase();
  if (lower == 'inactive' || lower == 'disabled' || lower == 'suspended' || lower == 'blocked') {
    return VaccinatorStatus(account, false);
  }
  return hasRunningCampaign
      ? const VaccinatorStatus('Active', true)
      : const VaccinatorStatus('Available', false);
}

Widget vaccinatorStatusChip(VaccinatorStatus s, {bool compact = false}) {
  const green = Color(0xFF00563B);
  final Color fg = s.isActive ? green : Colors.grey.shade700;
  final Color bg = s.isActive ? green.withOpacity(0.12) : Colors.grey.shade200;
  return Container(
    padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(compact ? 10 : 12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 3, backgroundColor: fg),
        SizedBox(width: compact ? 4 : 5),
        Text(
          s.label,
          style: TextStyle(
            color: fg,
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

// =====================================================================
// SCREEN
// =====================================================================
class VaccinatorDetailsScreen extends StatefulWidget {
  final String vaccinatorId;
  final Map<String, dynamic>? initialData;

  const VaccinatorDetailsScreen({
    Key? key,
    this.vaccinatorId = 'VAC002', // Fallback ID
    this.initialData,
  }) : super(key: key);

  @override
  State<VaccinatorDetailsScreen> createState() =>
      _VaccinatorDetailsScreenState();
}

class _VaccinatorDetailsScreenState extends State<VaccinatorDetailsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const Color primaryThemeGreen = Color(0xFF00563B);
  static const Color bgCanvasColor = Color(0xFFF9FAFB);

  String _getEmployeeId(Map<String, dynamic> data, String docId) {
    List<String> idKeys = [
      'employeeId',
      'employee_id',
      'empId',
      'vaccinatorId',
      'id'
    ];

    for (String key in idKeys) {
      if (data.containsKey(key) &&
          data[key] != null &&
          data[key].toString().trim().isNotEmpty &&
          data[key] is! Map) {
        return data[key].toString().trim();
      }
    }
    return docId;
  }

  Future<String> _fetchHealthCenter(
      String empId, Map<String, dynamic> userData) async {
    List<String> centerKeys = [
      'healthCenter',
      'health_center',
      'healthCenterName',
      'assignedHealthCenter',
      'center',
    ];

    for (String key in centerKeys) {
      if (userData.containsKey(key) &&
          userData[key] != null &&
          userData[key].toString().trim().isNotEmpty) {
        return userData[key].toString().trim();
      }
    }

    try {
      var docSnapshot =
          await _db.collection('valid_employees').doc(empId).get();

      if (!docSnapshot.exists) {
        final querySnapshot = await _db
            .collection('valid_employees')
            .where('employeeId', isEqualTo: empId)
            .limit(1)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          docSnapshot = querySnapshot.docs.first;
        }
      }

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final empData = docSnapshot.data()!;
        for (String key in centerKeys) {
          if (empData.containsKey(key) &&
              empData[key] != null &&
              empData[key].toString().trim().isNotEmpty) {
            return empData[key].toString().trim();
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching health center: $e");
    }

    return 'BHU Jand';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCanvasColor,
      appBar: AppBar(
        backgroundColor: primaryThemeGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Vaccinator Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _db.collection('users').doc(widget.vaccinatorId).snapshots(),
        builder: (context, snapshot) {
          Map<String, dynamic> data = widget.initialData ?? {};
          if (snapshot.hasData && snapshot.data!.data() != null) {
            data = snapshot.data!.data()!;
          }

          final String employeeId = _getEmployeeId(data, widget.vaccinatorId);

          String joinedDate = '12 Jan 2024';
          if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
            joinedDate = DateFormat('dd MMM yyyy')
                .format((data['createdAt'] as Timestamp).toDate());
          } else if (data['joinedOn'] != null) {
            joinedDate = data['joinedOn'].toString();
          }

          // Is vaccinator ki campaigns (vaccinatorIds mein uski ID ho)
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _db
                .collection('campaigns')
                .where('vaccinatorIds', arrayContains: widget.vaccinatorId)
                .snapshots(),
            builder: (context, campSnap) {
              final now = DateTime.now();
              final running = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              for (final d in campSnap.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
                if (campaignIsRunningNow(d.data(), now)) running.add(d);
              }
              final status = vaccinatorStatusOf(data, running.isNotEmpty);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopHeaderProfile(data, employeeId, status),
                    const SizedBox(height: 16),
                    _buildProfileInformationCard(data, employeeId, joinedDate),
                    const SizedBox(height: 16),
                    _buildCampaignAssignmentCard(running),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: primaryThemeGreen, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back,
                            color: primaryThemeGreen, size: 20),
                        label: const Text(
                          'Back to Previous Screen',
                          style: TextStyle(
                            color: primaryThemeGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  Widget _buildTopHeaderProfile(
      Map<String, dynamic> data, String employeeId, VaccinatorStatus status) {
    final String name = data['fullName'] ?? data['name'] ?? 'Fatima Noor';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: data['photoUrl'] != null &&
                  data['photoUrl'].toString().isNotEmpty
              ? NetworkImage(data['photoUrl'])
              : null,
          child: (data['photoUrl'] == null ||
                  data['photoUrl'].toString().isEmpty)
              ? const Icon(Icons.person, size: 40, color: primaryThemeGreen)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryThemeGreen,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                employeeId,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: primaryThemeGreen,
                  ),
                  const SizedBox(width: 4),
                  FutureBuilder<String>(
                    future: _fetchHealthCenter(employeeId, data),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? 'BHU Jand',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        vaccinatorStatusChip(status),
      ],
    );
  }

  Widget _buildProfileInformationCard(
      Map<String, dynamic> data, String employeeId, String joinedDate) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryThemeGreen.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline,
                    color: primaryThemeGreen, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Profile Information',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: primaryThemeGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: data['phone'] ?? data['phoneNumber'] ?? '0300-1234567',
          ),
          const Divider(height: 24, thickness: 0.6),
          _infoRow(
            icon: Icons.badge_outlined,
            label: 'Employee ID',
            value: employeeId,
          ),
          const Divider(height: 24, thickness: 0.6),
          _infoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Joined On',
            value: joinedDate,
          ),
          const Divider(height: 24, thickness: 0.6),
          FutureBuilder<String>(
            future: _fetchHealthCenter(employeeId, data),
            builder: (context, snapshot) {
              return _infoRow(
                icon: Icons.location_city_outlined,
                label: 'Health Center',
                value: snapshot.data ?? 'BHU Jand',
              );
            },
          ),
        ],
      ),
    );
  }

  // Sirf wo campaigns jo abhi chal rahi hain. Khatam hote hi apne aap hat jati hain.
  Widget _buildCampaignAssignmentCard(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> running) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryThemeGreen.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.campaign_outlined,
                    color: primaryThemeGreen, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Current Campaign Assignment',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: primaryThemeGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (running.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No active campaign right now.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            )
          else
            for (int i = 0; i < running.length; i++) ...[
              if (i > 0) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1.2),
                const SizedBox(height: 16),
              ],
              ..._campaignRows(running[i]),
            ],
        ],
      ),
    );
  }

  List<Widget> _campaignRows(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final c = doc.data();
    final String name = (c['name'] ?? c['title'] ?? 'Campaign').toString();
    final String type = (c['type'] ?? '').toString();

    String period = 'N/A';
    if (c['startDate'] is Timestamp && c['endDate'] is Timestamp) {
      final s = (c['startDate'] as Timestamp).toDate();
      final e = (c['endDate'] as Timestamp).toDate();
      period = '${DateFormat('dd MMM').format(s)} \u2013 ${DateFormat('dd MMM yyyy').format(e)}';
    }

    final areas = List<String>.from(c['targetAreas'] ?? []);
    final String area = areas.isNotEmpty ? areas.join(', ') : (c['area'] ?? 'N/A').toString();

    return [
      _infoRow(
        icon: Icons.calendar_month_outlined,
        label: 'Campaign',
        value: name,
      ),
      if (type.isNotEmpty) ...[
        const Divider(height: 24, thickness: 0.6),
        _infoRow(
          icon: Icons.category_outlined,
          label: 'Type',
          value: type,
        ),
      ],
      const Divider(height: 24, thickness: 0.6),
      _infoRow(
        icon: Icons.date_range_outlined,
        label: 'Campaign Period',
        value: period,
      ),
      const Divider(height: 24, thickness: 0.6),
      _infoRow(
        icon: Icons.location_on_outlined,
        label: 'Area',
        value: area,
      ),
      const Divider(height: 24, thickness: 0.6),
      // Is vaccinator ko is campaign mein kitne bache mile aur kitne vaccinate hue
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db
            .collection('campaign_assignments')
            .where('campaignId', isEqualTo: doc.id)
            .where('vaccinatorId', isEqualTo: widget.vaccinatorId)
            .snapshots(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          final done = docs
              .where((d) => (d.data()['status'] ?? '').toString() == 'Vaccinated')
              .length;
          return _infoRow(
            icon: Icons.groups_outlined,
            label: 'Progress',
            value: '$done / ${docs.length} children',
          );
        },
      ),
      const Divider(height: 24, thickness: 0.6),
      _statusRow(
        icon: Icons.circle,
        label: 'Status',
        value: 'Active',
      ),
    ];
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: primaryThemeGreen),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w400,
          ),
        ),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 3,
              backgroundColor: primaryThemeGreen,
            ),
            const SizedBox(width: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: primaryThemeGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}