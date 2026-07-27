enum TaskType { routine, polioCampaign }

enum VaccineStatus { dueToday, vaccinated, absent, refused, missed }

class VaccinationTaskModel {
  final String taskId;
  final String childId;
  final String childName;
  final String village;
  final String ageFormatted;
  final TaskType taskType;
  final String vaccines;
  final DateTime dueDate;
  VaccineStatus status;

  VaccinationTaskModel({
    required this.taskId,
    required this.childId,
    required this.childName,
    required this.village,
    required this.ageFormatted,
    required this.taskType,
    required this.vaccines,
    required this.dueDate,
    this.status = VaccineStatus.dueToday,
  });

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'childId': childId,
      'childName': childName,
      'village': village,
      'ageFormatted': ageFormatted,
      'taskType': taskType == TaskType.polioCampaign ? 'polio' : 'routine',
      'vaccines': vaccines,
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
    };
  }

  factory VaccinationTaskModel.fromMap(Map<String, dynamic> map, String id) {
    return VaccinationTaskModel(
      taskId: id,
      childId: map['childId'] ?? '',
      childName: map['childName'] ?? '',
      village: map['village'] ?? '',
      ageFormatted: map['ageFormatted'] ?? '',
      taskType: map['taskType'] == 'polio' ? TaskType.polioCampaign : TaskType.routine,
      vaccines: map['vaccines'] ?? '',
      dueDate: DateTime.parse(map['dueDate']),
      status: VaccineStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => VaccineStatus.dueToday,
      ),
    );
  }
}