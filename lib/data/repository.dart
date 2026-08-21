import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/academic.dart';
import '../models/content.dart';

/// كل حوارات قاعدة البيانات في مكان واحد
class TalibRepo {
  SupabaseClient get c => Supabase.instance.client;

  List<Map<String, dynamic>> _rows(dynamic r) =>
      (r as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  // ---------- الهيكل الأكاديمي ----------
  Future<List<AcademicNode>> institutions() async {
    final rows = _rows(await c
        .from('institutions').select('id,name')
        .eq('is_active', true).order('name'));
    return rows.map(AcademicNode.fromMap).toList();
  }

  Future<List<AcademicNode>> specializations(String institutionId) async {
    final rows = _rows(await c
        .from('specializations').select('id,name')
        .eq('institution_id', institutionId)
        .eq('is_active', true).order('name'));
    return rows.map(AcademicNode.fromMap).toList();
  }

  Future<List<AcademicNode>> tracks(String specializationId) async {
    final rows = _rows(await c
        .from('tracks').select('id,name')
        .eq('specialization_id', specializationId).order('name'));
    return rows.map(AcademicNode.fromMap).toList();
  }

  Future<List<AcademicNode>> levels(String trackId) async {
    final rows = _rows(await c
        .from('levels').select('id,name')
        .eq('track_id', trackId).order('order_index'));
    return rows.map(AcademicNode.fromMap).toList();
  }

  Future<List<AcademicNode>> semesters(String levelId) async {
    final rows = _rows(await c
        .from('semesters').select('id,name')
        .eq('level_id', levelId).order('order_index'));
    return rows.map(AcademicNode.fromMap).toList();
  }

  // ---------- الملف الشخصي ----------
  Future<Profile> myProfile() async {
    final uid = c.auth.currentUser!.id;
    final rows = _rows(await c.from('profiles').select().eq('id', uid));
    if (rows.isEmpty) throw Exception('الملف الشخصي غير موجود');
    return Profile.fromMap(rows.first);
  }

  Future<void> saveOnboarding({
    required String institutionId,
    required String specializationId,
    required String trackId,
    required String levelId,
    required String semesterId,
  }) async {
    await c.from('profiles').update({
      'institution_id': institutionId,
      'specialization_id': specializationId,
      'track_id': trackId,
      'level_id': levelId,
      'semester_id': semesterId,
    }).eq('id', c.auth.currentUser!.id);
  }

  // ---------- المقررات ----------
  Future<List<Course>> courses(String semesterId) async {
    final rows = _rows(await c
        .from('courses').select()
        .eq('semester_id', semesterId).order('order_index'));
    return rows.map(Course.fromMap).toList();
  }

  // ---------- محتوى المقرر (v0.2) ----------
  Future<List<Week>> weeks(String courseId) async {
    final rows = _rows(await c
        .from('weeks')
        .select('id,order_index,title')
        .eq('course_id', courseId)
        .eq('is_published', true)
        .order('order_index'));
    return rows.map(Week.fromMap).toList();
  }

  Future<Map<String, Lecture>> lecturesByWeek(String courseId) async {
    final rows =
        _rows(await c.from('lectures').select().eq('course_id', courseId));
    return {
      for (final r in rows) r['week_id'] as String: Lecture.fromMap(r)
    };
  }

  Future<List<FileItem>> courseFiles(String courseId, {String? weekId}) async {
    var q = c.from('files').select().eq('course_id', courseId);
    if (weekId != null) q = q.eq('week_id', weekId);
    final rows =
        _rows(await q.order('created_at', ascending: false));
    return rows.map(FileItem.fromMap).toList();
  }

  Future<List<ExamItem>> courseExams(String courseId) async {
    final rows = _rows(await c
        .from('exams')
        .select()
        .eq('course_id', courseId)
        .order('exam_date'));
    return rows.map(ExamItem.fromMap).toList();
  }

  String fileUrl(String storagePath) =>
      c.storage.from('course-files').getPublicUrl(storagePath);

  Future<Set<String>> readLectureIds(String courseId) async {
    final uid = c.auth.currentUser!.id;
    final rows = _rows(await c
        .from('progress')
        .select('read_lecture_ids')
        .eq('user_id', uid)
        .eq('course_id', courseId)
        .limit(1));
    if (rows.isEmpty) return {};
    final list = rows.first['read_lecture_ids'] as List?;
    return list?.map((e) => e as String).toSet() ?? {};
  }

  Future<void> setLectureRead(
    String courseId,
    String lectureId,
    bool read,
    int totalLectures,
  ) async {
    final ids = await readLectureIds(courseId);
    if (read) {
      ids.add(lectureId);
    } else {
      ids.remove(lectureId);
    }
    final percent =
        totalLectures == 0 ? 0 : (ids.length * 100 ~/ totalLectures);
    await c.from('progress').upsert({
      'user_id': c.auth.currentUser!.id,
      'course_id': courseId,
      'read_lecture_ids': ids.toList(),
      'percent': percent,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}