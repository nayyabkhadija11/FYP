/*// lib/models/campaign_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CampaignModel {
  final String id;
  final String name;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> targetAreas; // village names
  final String status; // 'active' | 'completed'
  final String teamName;
  final List<String> vaccinatorIds;
  final int totalChildren;
  final int totalHouseholds;
  final int healthCenters;
  final DateTime createdAt;

  CampaignModel({
    required this.id,
    required this.name,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.targetAreas,
    required this.status,
    required this.teamName,
    required this.vaccinatorIds,
    required this.totalChildren,
    required this.totalHouseholds,
    this.healthCenters = 1,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'targetAreas': targetAreas,
      'status': status,
      'teamName': teamName,
      'vaccinatorIds': vaccinatorIds,
      'target_count': totalChildren,
      'totalHouseholds': totalHouseholds,
      'healthCenters': healthCenters,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CampaignModel.fromMap(Map<String, dynamic> map, String docId) {
    return CampaignModel(
      id: docId,
      name: map['name'] ?? '',
      type: map['type'] ?? 'Polio',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      targetAreas: List<String>.from(map['targetAreas'] ?? []),
      status: map['status'] ?? 'active',
      teamName: map['teamName'] ?? '',
      vaccinatorIds: List<String>.from(map['vaccinatorIds'] ?? []),
      totalChildren: map['target_count'] ?? 0,
      totalHouseholds: map['totalHouseholds'] ?? 0,
      healthCenters: map['healthCenters'] ?? 1,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
} */
import 'package:cloud_firestore/cloud_firestore.dart';

class CampaignModel {
  final String id;
  final String name;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> targetAreas; // village names
  final String status; // 'active' | 'completed'
  final String teamName;
  final List<String> vaccinatorIds;
  final int totalChildren;
  final int totalHouseholds;
  final int healthCenters;
  final String supervisorId; // NEW: campaign kis supervisor ne banayi
  final DateTime createdAt;

  CampaignModel({
    required this.id,
    required this.name,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.targetAreas,
    required this.status,
    required this.teamName,
    required this.vaccinatorIds,
    required this.totalChildren,
    required this.totalHouseholds,
    this.healthCenters = 1,
    this.supervisorId = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'targetAreas': targetAreas,
      'status': status,
      'teamName': teamName,
      'vaccinatorIds': vaccinatorIds,
      'target_count': totalChildren,
      'totalHouseholds': totalHouseholds,
      'healthCenters': healthCenters,
      'supervisorId': supervisorId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CampaignModel.fromMap(Map<String, dynamic> map, String docId) {
    return CampaignModel(
      id: docId,
      name: map['name'] ?? '',
      type: map['type'] ?? 'Polio',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      targetAreas: List<String>.from(map['targetAreas'] ?? []),
      status: map['status'] ?? 'active',
      teamName: map['teamName'] ?? '',
      vaccinatorIds: List<String>.from(map['vaccinatorIds'] ?? []),
      totalChildren: map['target_count'] ?? 0,
      totalHouseholds: map['totalHouseholds'] ?? 0,
      healthCenters: map['healthCenters'] ?? 1,
      supervisorId: map['supervisorId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}