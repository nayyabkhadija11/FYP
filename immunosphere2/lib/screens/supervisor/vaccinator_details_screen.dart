/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VaccinatorDetailsScreen extends StatefulWidget {
  final String vaccinatorId;
  final Map<String, dynamic>? initialData;

  const VaccinatorDetailsScreen({
    Key? key,
    required this.vaccinatorId,
    this.initialData,
  }) : super(key: key);

  @override
  State<VaccinatorDetailsScreen> createState() =>
      _VaccinatorDetailsScreenState();
}

class _VaccinatorDetailsScreenState extends State<VaccinatorDetailsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Exact image color hex code
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeaderProfile(data, employeeId),
                const SizedBox(height: 16),
                _buildProfileInformationCard(data, employeeId, joinedDate),
                const SizedBox(height: 16),
                _buildCampaignAssignmentCard(data),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryThemeGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.bar_chart,
                        color: Colors.white, size: 20),
                    label: const Text(
                      'View Performance Report',
                      style: TextStyle(
                        color: Colors.white,
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

  Widget _buildTopHeaderProfile(Map<String, dynamic> data, String employeeId) {
    final String name = data['fullName'] ?? data['name'] ?? 'Pakeeza';
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
            value: data['phone'] ?? data['phoneNumber'] ?? '03xxxxxxxxx',
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
    final String? campaign = data['campaign'];
    final bool hasActiveCampaign =
        campaign != null && campaign.trim().isNotEmpty;

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
          if (hasActiveCampaign) ...[
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
          ] else ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryThemeGreen.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_busy_outlined,
                    color: primaryThemeGreen,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No active campaign assignment.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This vaccinator is not assigned to any polio campaign.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ]
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
}