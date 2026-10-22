/*import 'package:intl/intl.dart';

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
} */
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

  // ---------------------------------------------------------------
  // NEXT DUE CALCULATION
  // ---------------------------------------------------------------

  static String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  // Same matching rule the Routine History tab uses, so both always agree
  // (also lets "TCV (Typhoid)" from the entry dropdown match "TCV").
  static bool _isGiven(String vaccine, Iterable<String> givenNames) {
    final t = _norm(vaccine);
    return givenNames.any((g) {
      final n = _norm(g);
      if (n.isEmpty) return false;
      return n == t || n.contains(t) || t.contains(n);
    });
  }

  static String _shortStageLabel(String stage) {
    return stage.startsWith('At Birth') ? 'At Birth' : stage;
  }

  /// [givenVaccineNames] = names of vaccines already given (refused ones must
  /// NOT be included). Returns the first stage that still has pending
  /// vaccines, listing only the pending ones.
  static String calculateNextDue(Iterable<String> givenVaccineNames) {
    final given = givenVaccineNames.toList();
    // dob is irrelevant here, only stage names and vaccine lists are used.
    final schedule = generateEpiSchedule(DateTime.now());

    for (final stage in schedule) {
      final vaccines = List<String>.from(stage['vaccines']);
      final pending = vaccines.where((v) => !_isGiven(v, given)).toList();
      if (pending.isNotEmpty) {
        return '${_shortStageLabel(stage['stage'] as String)}: ${pending.join(', ')}';
      }
    }
    return 'All Routine Vaccines Completed';
  }
}