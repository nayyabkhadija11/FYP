import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child_model.dart';
import '../models/vaccination_task_model.dart';
import '../helpers/epi_schedule_helper.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. REGISTER NEW CHILD & AUTO-GENERATE EPI SCHEDULE
  Future<void> registerChild(ChildModel child) async {
    try {
      // Save Child Document
      await _db.collection('children').doc(child.id).set(child.toMap());

      // Auto-generate EPI Schedule based on Date of Birth
      final schedule = EpiScheduleHelper.generateEpiSchedule(child.dob);

      for (var item in schedule) {
        final taskDoc = _db.collection('vaccination_tasks').doc();
        
        final task = VaccinationTaskModel(
          taskId: taskDoc.id,
          childId: child.id,
          childName: child.name,
          village: child.village,
          ageFormatted: child.formattedAge,
          taskType: TaskType.routine,
          vaccines: (item['vaccines'] as List<String>).join(', '),
          dueDate: item['dueDate'] as DateTime,
          status: VaccineStatus.dueToday,
        );

        await taskDoc.set(task.toMap());
      }
    } catch (e) {
      throw Exception("Error registering child: $e");
    }
  }

  // 2. GET UNIFIED TASKS FOR DASHBOARD (Routine + Polio)
  Stream<List<VaccinationTaskModel>> getDashboardTasks() {
    return _db.collection('vaccination_tasks').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => VaccinationTaskModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // 3. UPDATE VACCINATION ENTRY STATUS
  Future<void> updateVaccinationStatus({
    required String taskId,
    required VaccineStatus status,
    String? remarks,
  }) async {
    try {
      await _db.collection('vaccination_tasks').doc(taskId).update({
        'status': status.name,
        'updatedAt': DateTime.now().toIso8601String(),
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      });
    } catch (e) {
      throw Exception("Failed to update status: $e");
    }
  }

  // 4. GET ALL REGISTERED CHILDREN
  Stream<List<ChildModel>> getChildrenList() {
    return _db.collection('children').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ChildModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}