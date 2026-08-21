import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/academic.dart';

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
}