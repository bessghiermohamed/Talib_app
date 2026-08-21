/// عقدة الهيكل الأكاديمي — تصلح للمؤسسة والتخصص والملمح والمستوى والسداسي
class AcademicNode {
  final String id;
  final String name;
  const AcademicNode({required this.id, required this.name});

  factory AcademicNode.fromMap(Map<String, dynamic> m) =>
      AcademicNode(id: m['id'] as String, name: (m['name'] ?? '') as String);
}

class Course {
  final String id;
  final String name;
  final String? teacherName;
  final int? hoursPerWeek;
  final String? description;
  const Course({
    required this.id,
    required this.name,
    this.teacherName,
    this.hoursPerWeek,
    this.description,
  });

  factory Course.fromMap(Map<String, dynamic> m) => Course(
        id: m['id'] as String,
        name: (m['name'] ?? '') as String,
        teacherName: m['teacher_name'] as String?,
        hoursPerWeek: m['hours_per_week'] as int?,
        description: m['description'] as String?,
      );
}

class Profile {
  final String id;
  final String? displayName;
  final String? institutionId;
  final String? specializationId;
  final String? trackId;
  final String? levelId;
  final String? semesterId;
  const Profile({
    required this.id,
    this.displayName,
    this.institutionId,
    this.specializationId,
    this.trackId,
    this.levelId,
    this.semesterId,
  });

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        displayName: m['display_name'] as String?,
        institutionId: m['institution_id'] as String?,
        specializationId: m['specialization_id'] as String?,
        trackId: m['track_id'] as String?,
        levelId: m['level_id'] as String?,
        semesterId: m['semester_id'] as String?,
      );

  bool get isOnboarded => semesterId != null;
}