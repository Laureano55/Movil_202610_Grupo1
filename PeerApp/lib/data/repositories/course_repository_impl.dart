import 'package:shared_preferences/shared_preferences.dart';
import '../../core/roble_database_service.dart';
import '../../domain/models/course_model.dart';
import '../../domain/models/course_member_model.dart';
import '../../domain/repositories/i_course_repository.dart';
import 'repository_utils.dart';

class CourseRepositoryImpl implements ICourseRepository {
  final RobleDatabaseService _db;

  CourseRepositoryImpl(this._db);

  // ── Helpers ────────────────────────────────────────────────────────────────

  @override
  Future<String?> currentEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  // ── Courses ────────────────────────────────────────────────────────────────

  @override
  Future<void> createCourse({
    required String title,
    required String code,
  }) async {
    final email = await currentEmail();
    if (email == null) throw Exception('Not authenticated');

    // Verificar que no exista el código
    final existing = await _db.read('courses');
    final duplicate = existing.any(
      (c) => (c['code'] ?? '').toString().toLowerCase() == code.toLowerCase(),
    );
    if (duplicate) throw Exception('Ya existe un curso con código $code');

    await _db.insert('courses', [
      CourseModel(
        title: title,
        code: code,
        professorEmail: email,
      ).toInsertJson(),
    ]);
  }

  @override
  Future<void> deleteCourse(String courseId) async {
    // Eliminar miembros
    final members = await _db.read('course_members',
        filters: {'course_id': courseId});
    for (final m in members) {
      await _db.delete('course_members',
          idColumn: '_id', idValue: m['_id'].toString());
    }
    // Eliminar evaluaciones y sus respuestas
    final evals = await _db.read('evaluations',
        filters: {'course_id': courseId});
    for (final e in evals) {
      final evalId = e['_id'].toString();
      final responses = await _db.read('evaluation_responses',
          filters: {'evaluation_id': evalId});
      for (final r in responses) {
        await _db.delete('evaluation_responses',
            idColumn: '_id', idValue: r['_id'].toString());
      }
      await _db.delete('evaluations', idColumn: '_id', idValue: evalId);
    }
    // Eliminar el curso
    await _db.delete('courses', idColumn: '_id', idValue: courseId);
  }

  @override
  Future<List<Map<String, dynamic>>> professorCourseSummaries(
      String professorEmail) async {
    final allCourses = await _db.read('courses');
    final myCourses = allCourses
        .where((c) =>
            (c['professor_email'] ?? '').toString().toLowerCase() ==
            professorEmail.toLowerCase())
        .toList();

    final allMembers = await _db.read('course_members');
    final allEvals = await _db.read('evaluations');

    final result = <Map<String, dynamic>>[];
    for (final course in myCourses) {
      final courseId = course['_id'].toString();
      final courseMembers =
          allMembers.where((m) => m['course_id'] == courseId).toList();
      final uniqueStudents = courseMembers
          .map((m) => (m['email'] ?? '').toString().toLowerCase())
          .toSet();
      final categories = courseMembers
          .map((m) => (m['category_name'] ?? '').toString().trim())
          .where((c) => c.isNotEmpty)
          .toSet();
      final activeEvals = allEvals
          .where((e) =>
              e['course_id'] == courseId &&
            computeEvaluationStatus(e) == 'active')
          .length;

      result.add({
        'id': courseId,
        'title': course['title']?.toString() ?? '',
        'code': course['code']?.toString() ?? '',
        'studentCount': uniqueStudents.length,
        'groupCount': categories.length,
        'pendingEvals': activeEvals,
      });
    }
    return result;
  }

  @override
  Future<bool> enrollByCourseCode({
    required String email,
    required String courseCode,
  }) async {
    final allCourses = await _db.read('courses');
    final course = allCourses.firstWhere(
      (c) =>
          (c['code'] ?? '').toString().toLowerCase() ==
          courseCode.toLowerCase(),
      orElse: () => <String, dynamic>{},
    );
    if (course.isEmpty) return false;

    final courseId = course['_id'].toString();
    final existing = await _db.read('course_members');
    final alreadyIn = existing.any((m) =>
        m['course_id'] == courseId &&
        (m['email'] ?? '').toString().toLowerCase() == email.toLowerCase());
    if (!alreadyIn) {
      await _db.insert('course_members', [
        CourseMemberModel(
          courseId: courseId,
          email: email,
          categoryName: 'Sin grupo',
          name: '',
          lastName: '',
        ).toInsertJson(),
      ]);
    }
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> studentCourses(String email) async {
    final normalizedEmail = email.toLowerCase().trim();
    final allMembers = await _db.read('course_members');
    final myMemberships = allMembers
        .where((m) =>
            (m['email'] ?? '').toString().toLowerCase() == normalizedEmail)
        .toList();

    if (myMemberships.isEmpty) return [];

    final allCourses = await _db.read('courses');
    final courseById = {
      for (final c in allCourses) c['_id'].toString(): c,
    };
    final allEvals = await _db.read('evaluations');

    final seen = <String>{};
    final result = <Map<String, dynamic>>[];

    for (final membership in myMemberships) {
      final courseId = membership['course_id']?.toString() ?? '';
      if (courseId.isEmpty || seen.contains(courseId)) continue;
      seen.add(courseId);

      final course = courseById[courseId];
      final activeEvals = allEvals
          .where((e) =>
              e['course_id'] == courseId &&
            computeEvaluationStatus(e) == 'active')
          .length;

      result.add({
        'id': courseId,
        'title': course?['title']?.toString() ?? 'Curso',
        'code': course?['code']?.toString() ?? '',
        'professor': course?['professor_email']?.toString() ?? 'Docente',
        'myGroup': membership['category_name']?.toString() ?? 'Sin grupo',
        'activeEvals': activeEvals,
        'completedEvals': 0,
        'totalEvals': activeEvals,
      });
    }
    return result;
  }

  @override
  Future<void> importCsvData({
    required String courseId,
    required String courseCode,
    required Set<String> categories,
    required List<Map<String, dynamic>> members,
  }) async {
    final existing = await _db.read('course_members');
    final byEmail = <String, Map<String, dynamic>>{};

    for (final m in existing.where((m) => m['course_id'] == courseId)) {
      final e = normalizeEmail(m['email']);
      if (e.isNotEmpty) byEmail[e] = Map<String, dynamic>.from(m);
    }

    final toInsert = <Map<String, dynamic>>[];
    final toUpdate = <Map<String, dynamic>>[];

    for (final incoming in members) {
      final email = normalizeEmail(incoming['email']);
      if (email.isEmpty) continue;

      final record = CourseMemberModel(
        courseId: courseId,
        email: email,
        categoryName: (incoming['category'] ?? incoming['category_name'] ?? '').toString().trim(),
        name: (incoming['name'] ?? '').toString().trim(),
        lastName: (incoming['last_name'] ?? incoming['lastName'] ?? '').toString().trim(),
      );

      if (byEmail.containsKey(email)) {
        final existingId = byEmail[email]!['_id']?.toString();
        if (existingId != null) {
          toUpdate.add({
            'id': existingId,
            'data': record.toInsertJson(),
          });
        }
      } else {
        toInsert.add(record.toInsertJson());
        byEmail[email] = record.toInsertJson();
      }
    }

    if (toInsert.isNotEmpty) {
      await _db.insert('course_members', toInsert);
    }
    for (final upd in toUpdate) {
      await _db.update(
        'course_members',
        idColumn: '_id',
        idValue: upd['id'] as String,
        updates: upd['data'] as Map<String, dynamic>,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> professorCourseGroups(
      String courseId) async {
    final allMembers = await _db.read('course_members');
    final courseMembers =
        allMembers.where((m) => m['course_id'] == courseId).toList();

    final categories = courseMembers
        .map((m) => (m['category_name'] ?? '').toString().trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final grouped = <Map<String, dynamic>>[];
    for (final category in categories) {
      final byCategory = courseMembers
          .where((m) =>
              (m['category_name'] ?? '').toString().trim() == category)
          .toList();
      final seen = <String>{};
      final memberList = <Map<String, String>>[];
      for (final m in byCategory) {
        final email = normalizeEmail(m['email']);
        if (email.isEmpty || seen.contains(email)) continue;
        seen.add(email);
        memberList.add({
          'name': buildDisplayNameFromRow(m, fallbackEmail: email),
          'email': email,
        });
      }
      memberList.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
      grouped.add({
        'groupName': category,
        'memberCount': memberList.length,
        'members': memberList,
      });
    }
    return grouped;
  }

  @override
  Future<Map<String, dynamic>> studentCourseClassmates({
    required String courseId,
    required String email,
  }) async {
    final normalizedEmail = normalizeEmail(email);
    final allMembers = await _db.read('course_members');

    final myRow = allMembers.firstWhere(
      (m) =>
          m['course_id'] == courseId &&
          (m['email'] ?? '').toString().toLowerCase() == normalizedEmail,
      orElse: () => <String, dynamic>{},
    );

    final myGroup = (myRow['category_name'] ?? 'Sin grupo').toString().trim();
    if (myRow.isEmpty || myGroup.isEmpty || myGroup == 'Sin grupo') {
      return {'myGroup': 'Sin grupo', 'classmates': <Map<String, String>>[]};
    }

    final seen = <String>{};
    final classmates = <Map<String, String>>[];

    for (final m in allMembers) {
      if (m['course_id'] != courseId) continue;
      if ((m['category_name'] ?? '').toString().trim() != myGroup) continue;
      final mEmail = normalizeEmail(m['email']);
      if (mEmail.isEmpty || mEmail == normalizedEmail || seen.contains(mEmail)) {
        continue;
      }
      seen.add(mEmail);
      classmates.add({
        'name': buildDisplayNameFromRow(m, fallbackEmail: mEmail),
        'email': mEmail,
      });
    }
    classmates.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    return {'myGroup': myGroup, 'classmates': classmates};
  }

  @override
  Future<List<String>> getCategoriesForCourse(String courseId) async {
    final members = await _db.read('course_members');
    final cats = members
        .where((m) => m['course_id'] == courseId)
        .map((m) => (m['category_name'] ?? '').toString().trim())
        .where((c) => c.isNotEmpty && c != 'Sin grupo')
        .toSet()
        .toList()
      ..sort();
    return cats;
  }

  @override
  Future<List<CourseMemberModel>> getMembersByCourse(String courseId) async {
    final rows = await _db.read('course_members');
    return rows
        .where((m) => m['course_id'] == courseId)
        .map(CourseMemberModel.fromJson)
        .toList();
  }
}