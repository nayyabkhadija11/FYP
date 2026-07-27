class ChildModel {
  final String id;
  final String name;
  final DateTime dob;
  final String gender;
  final String parentName;
  final String phone;
  final String village;
  final String healthCenter;
  final String? avatarUrl;

  ChildModel({
    required this.id,
    required this.name,
    required this.dob,
    required this.gender,
    required this.parentName,
    required this.phone,
    required this.village,
    required this.healthCenter,
    this.avatarUrl,
  });

  // Calculate age in months
  int get ageInMonths {
    final now = DateTime.now();
    return (now.year - dob.year) * 12 + now.month - dob.month;
  }

  // Format age for UI display
  String get formattedAge {
    final months = ageInMonths;
    if (months < 1) {
      final days = DateTime.now().difference(dob).inDays;
      return '$days Days';
    }
    if (months < 24) return '$months Months';
    return '${(months / 12).toStringAsFixed(1)} Years';
  }

  // Convert to Map for Firebase/Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dob': dob.toIso8601String(),
      'gender': gender,
      'parentName': parentName,
      'phone': phone,
      'village': village,
      'healthCenter': healthCenter,
      'avatarUrl': avatarUrl ?? '',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  // Create Object from Firebase Map
  factory ChildModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChildModel(
      id: docId,
      name: map['name'] ?? '',
      dob: DateTime.parse(map['dob']),
      gender: map['gender'] ?? 'Male',
      parentName: map['parentName'] ?? '',
      phone: map['phone'] ?? '',
      village: map['village'] ?? '',
      healthCenter: map['healthCenter'] ?? '',
      avatarUrl: map['avatarUrl'],
    );
  }
}