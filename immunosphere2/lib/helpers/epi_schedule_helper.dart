import 'package:intl/intl.dart';

class EpiScheduleHelper {
  /// Total EPI Doses Count
  static const int totalRoutineDoses = 18;

  /// Generates automatic Pakistan EPI Vaccination Schedule based on Child's Date of Birth
  static List<Map<String, dynamic>> generateEpiSchedule(DateTime dob) {
    return [
      {
        'stage': 'At Birth (Within 24 Hours)',
        'dueDate': dob,
        'vaccines': ['BCG', 'OPV-0'],
      },
      {
        'stage': '6 Weeks',
        'dueDate': dob.add(const Duration(days: 42)),
        'vaccines': ['Pentavalent-1', 'PCV-1', 'OPV-1', 'Rotavirus-1'],
      },
      {
        'stage': '10 Weeks',
        'dueDate': dob.add(const Duration(days: 70)),
        'vaccines': ['Pentavalent-2', 'PCV-2', 'OPV-2', 'Rotavirus-2'],
      },
      {
        'stage': '14 Weeks',
        'dueDate': dob.add(const Duration(days: 98)),
        'vaccines': ['Pentavalent-3', 'PCV-3', 'OPV-3', 'IPV-1'],
      },
      {
        'stage': '9 Months',
        'dueDate': dob.add(const Duration(days: 270)),
        'vaccines': ['Measles-Rubella (MR-1)', 'TCV'],
      },
      {
        'stage': '15 Months',
        'dueDate': dob.add(const Duration(days: 450)),
        'vaccines': ['Measles-Rubella (MR-2)', 'IPV-2'],
      },
    ];
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }
} 