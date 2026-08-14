import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'epi_schedule_helper.dart';

class VaccinationStatusHelper {
  static String normalize(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static DateTime parseDob(dynamic dobVal) {
    if (dobVal is Timestamp) return dobVal.toDate();
    if (dobVal is DateTime) return dobVal;
    if (dobVal is String && dobVal.trim().isNotEmpty) {
      return DateTime.tryParse(dobVal) ?? DateTime.now();
    }
    return DateTime.now();
  }

  /// Checks if a child actually has a usable DOB value.
  /// IMPORTANT: parseDob() silently falls back to DateTime.now() when dob
  /// is missing/invalid, which would make that child's "At Birth" stage
  /// due date always equal "today" — wrongly inflating the current
  /// month's Pending count. Callers must check this FIRST and skip the
  /// child if false, instead of calling parseDob() blindly.
  static bool hasValidDob(dynamic dobVal) {
    if (dobVal is Timestamp) return true;
    if (dobVal is DateTime) return true;
    if (dobVal is String && dobVal.trim().isNotEmpty) {
      return DateTime.tryParse(dobVal) != null;
    }
    return false;
  }

  /// Computes missed / due / refused / given counts for ONE child
  /// using the EXACT same logic as child_details_screen.dart
  /// (14-day grace period after due date before marking as "Missed").
  /// Used by Dashboard and Search/Directory screens (all-time, overall status).
  static Map<String, dynamic> getChildVaccineStatus(
    DateTime dob,
    List<Map<String, dynamic>> records,
  ) {
    final schedule = EpiScheduleHelper.generateEpiSchedule(dob);
    final now = DateTime.now();

    int missedCount = 0;
    int dueCount = 0;
    int refusedCount = 0;
    int givenCount = 0;

    for (var stage in schedule) {
      DateTime dueDate = stage['dueDate'];
      List<String> vaccines = List<String>.from(stage['vaccines']);
      bool isStageDueOrPast = now.isAfter(dueDate) || now.isAtSameMomentAs(dueDate);

      for (var vaccine in vaccines) {
        String targetNormalized = normalize(vaccine);
        String? matchedStatus;

        bool isGiven = records.any((record) {
          String storedNormalized = normalize((record['vaccineName'] ?? '').toString());
          bool matches = storedNormalized == targetNormalized ||
              storedNormalized.contains(targetNormalized) ||
              targetNormalized.contains(storedNormalized);
          if (matches) {
            matchedStatus = (record['status'] ?? '').toString().toLowerCase();
          }
          return matches;
        });

        bool isRefused = isGiven && matchedStatus == 'refused';
        bool isMissed = !isGiven && now.isAfter(dueDate.add(const Duration(days: 14)));
        bool isDueNow = !isGiven && isStageDueOrPast && !isMissed;

        if (isRefused) {
          refusedCount++;
        } else if (isGiven) {
          givenCount++;
        } else if (isMissed) {
          missedCount++;
        } else if (isDueNow) {
          dueCount++;
        }
      }
    }

    String overallStatus;
    if (refusedCount > 0) {
      overallStatus = 'refused';
    } else if (missedCount > 0) {
      overallStatus = 'missed';
    } else if (dueCount > 0) {
      overallStatus = 'due';
    } else {
      overallStatus = 'vaccinated';
    }

    return {
      'missedCount': missedCount,
      'dueCount': dueCount,
      'refusedCount': refusedCount,
      'givenCount': givenCount,
      'overallStatus': overallStatus,
    };
  }

  /// Returns per-dose status ('vaccinated' / 'refused' / 'missed' / 'pending')
  /// ONLY for doses whose EPI schedule due-date falls in the given month
  /// (e.g. "August 2026"). Used by the Reports screen (Monthly tab) so
  /// numbers reflect strictly that single calendar month, not cumulative
  /// all-time data (that's what Dashboard/Search are for).
  static List<Map<String, dynamic>> getDoseStatusForMonth(
    DateTime dob,
    List<Map<String, dynamic>> records,
    String targetMonthText,
  ) {
    final schedule = EpiScheduleHelper.generateEpiSchedule(dob);
    final now = DateTime.now();
    List<Map<String, dynamic>> result = [];

    for (var stage in schedule) {
      DateTime dueDate = stage['dueDate'];
      String stageMonthText = DateFormat('MMMM yyyy').format(dueDate);
      if (stageMonthText != targetMonthText) continue;

      List<String> vaccines = List<String>.from(stage['vaccines']);
      bool isStageDueOrPast = now.isAfter(dueDate) || now.isAtSameMomentAs(dueDate);

      for (var vaccine in vaccines) {
        String targetNormalized = normalize(vaccine);
        String? matchedStatus;

        bool isGiven = records.any((record) {
          String storedNormalized = normalize((record['vaccineName'] ?? '').toString());
          bool matches = storedNormalized == targetNormalized ||
              storedNormalized.contains(targetNormalized) ||
              targetNormalized.contains(storedNormalized);
          if (matches) {
            matchedStatus = (record['status'] ?? '').toString().toLowerCase();
          }
          return matches;
        });

        bool isRefused = isGiven && matchedStatus == 'refused';
        bool isMissed = !isGiven && now.isAfter(dueDate.add(const Duration(days: 14)));
        bool isDueNow = !isGiven && isStageDueOrPast && !isMissed;

        String status;
        if (isRefused) {
          status = 'refused';
        } else if (isGiven) {
          status = 'vaccinated';
        } else if (isMissed) {
          status = 'missed';
        } else if (isDueNow) {
          status = 'pending';
        } else {
          status = 'pending'; // upcoming dose within the selected month
        }

        result.add({'vaccineName': vaccine, 'status': status});
      }
    }

    return result;
  }

  /// Groups all vaccination docs by childId so lookups are O(1) per child
  /// instead of re-querying Firestore for every single child.
  static Map<String, List<Map<String, dynamic>>> groupRecordsByChildId(
    List<Map<String, dynamic>> allVaccinationDocs,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var doc in allVaccinationDocs) {
      String cid = (doc['childId'] ?? '').toString();
      if (cid.isEmpty) continue;
      grouped.putIfAbsent(cid, () => []).add(doc);
    }
    return grouped;
  }
}