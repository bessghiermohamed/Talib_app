/// محتوى المقرر: أسابيع، محاضرات، ملفات، اختبارات — v0.2
class Week {
  final String id;
  final int orderIndex;
  final String? title;
  const Week({required this.id, required this.orderIndex, this.title});

  factory Week.fromMap(Map<String, dynamic> m) => Week(
        id: m['id'] as String,
        orderIndex: (m['order_index'] ?? 0) as int,
        title: m['title'] as String?,
      );
}

class Lecture {
  final String id;
  final String weekId;
  final String courseId;
  final String title;
  final String? body;
  final int? minutesRead;
  const Lecture({
    required this.id,
    required this.weekId,
    required this.courseId,
    required this.title,
    this.body,
    this.minutesRead,
  });

  factory Lecture.fromMap(Map<String, dynamic> m) => Lecture(
        id: m['id'] as String,
        weekId: m['week_id'] as String,
        courseId: m['course_id'] as String,
        title: (m['title'] ?? '') as String,
        body: m['body'] as String?,
        minutesRead: m['minutes_read'] as int?,
      );
}

class FileItem {
  final String id;
  final String courseId;
  final String? weekId;
  final String kind;
  final String title;
  final String? storagePath;
  final String? fileType;
  final int? fileSizeBytes;
  final DateTime? createdAt;
  const FileItem({
    required this.id,
    required this.courseId,
    this.weekId,
    required this.kind,
    required this.title,
    this.storagePath,
    this.fileType,
    this.fileSizeBytes,
    this.createdAt,
  });

  factory FileItem.fromMap(Map<String, dynamic> m) => FileItem(
        id: m['id'] as String,
        courseId: m['course_id'] as String,
        weekId: m['week_id'] as String?,
        kind: (m['kind'] ?? 'reference') as String,
        title: (m['title'] ?? '') as String,
        storagePath: m['storage_path'] as String?,
        fileType: m['file_type'] as String?,
        fileSizeBytes: m['file_size_bytes'] as int?,
        createdAt: m['created_at'] != null
            ? DateTime.tryParse(m['created_at'] as String)
            : null,
      );

  String get sizeLabel {
    if (fileSizeBytes == null) return '';
    if (fileSizeBytes! < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes! < 1048576) {
      return '${(fileSizeBytes! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes! / 1048576).toStringAsFixed(1)} MB';
  }
}

class ExamItem {
  final String id;
  final String courseId;
  final String title;
  final DateTime? examDate;
  final String? place;
  final String? scope;
  const ExamItem({
    required this.id,
    required this.courseId,
    required this.title,
    this.examDate,
    this.place,
    this.scope,
  });

  factory ExamItem.fromMap(Map<String, dynamic> m) => ExamItem(
        id: m['id'] as String,
        courseId: m['course_id'] as String,
        title: (m['title'] ?? '') as String,
        examDate: m['exam_date'] != null
            ? DateTime.tryParse(m['exam_date'] as String)
            : null,
        place: m['place'] as String?,
        scope: m['scope'] as String?,
      );

  int get daysLeft {
    if (examDate == null) return 0;
    final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(examDate!.year, examDate!.month, examDate!.day);
  return target.difference(today).inDays;
  }
}