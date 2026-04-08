import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Predefined evaluation criteria
const List<String> kAllCriteria = [
  'Comunicación',
  'Responsabilidad',
  'Colaboración',
  'Puntualidad',
  'Calidad del trabajo',
  'Liderazgo',
];

const Map<String, String> kCriteriaDescriptions = {
  'Comunicación': 'Comunicación clara y efectiva',
  'Responsabilidad': 'Cumple con las tareas asignadas',
  'Colaboración': 'Trabaja bien con el equipo',
  'Puntualidad': 'Cumple con los plazos establecidos',
  'Calidad del trabajo': 'Produce entregables de alta calidad',
  'Liderazgo': 'Toma iniciativa y guía a otros',
};

class DemoCourseStore {
  // ── Singleton ─────────────────────────────────────────────────────────────
  static final DemoCourseStore _instance = DemoCourseStore._internal();
  factory DemoCourseStore() => _instance;
  DemoCourseStore._internal();

  // ── Storage keys ──────────────────────────────────────────────────────────
  static const _coursesKey = 'demo_courses';
  static const _categoriesKey = 'demo_categories';
  static const _membersKey = 'demo_category_members';
  static const _evaluationsKey = 'demo_evaluations';
  static const _responsesKey = 'demo_responses';

  // ── In-memory state ───────────────────────────────────────────────────────
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _evaluations = [];
  List<Map<String, dynamic>> _responses = [];

  bool _loaded = false;

  // ── Load/persist ──────────────────────────────────────────────────────────
  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> decodeList(String? raw) {
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    _courses = decodeList(prefs.getString(_coursesKey));
    _categories = decodeList(prefs.getString(_categoriesKey));
    _members = decodeList(prefs.getString(_membersKey));
    _evaluations = decodeList(prefs.getString(_evaluationsKey));
    _responses = decodeList(prefs.getString(_responsesKey));
    _loaded = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_coursesKey, jsonEncode(_courses));
    await prefs.setString(_categoriesKey, jsonEncode(_categories));
    await prefs.setString(_membersKey, jsonEncode(_members));
    await prefs.setString(_evaluationsKey, jsonEncode(_evaluations));
    await prefs.setString(_responsesKey, jsonEncode(_responses));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Future<String?> currentEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  String _newId() =>
      DateTime.now().microsecondsSinceEpoch.toString() +
      (DateTime.now().millisecond % 1000).toString();

  // ═══════════════════════════════════════════════════════════════════════════
  // COURSES
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> createCourse({required String title, required String code}) async {
    await _ensureLoaded();
    final already = _courses.any(
      (c) =>
          (c['code'] ?? '').toString().toLowerCase() == code.toLowerCase(),
    );
    if (already) throw Exception('Ya existe un curso con código $code');

    _courses.add({
      'courseId': _newId(),
      'title': title,
      'code': code,
      'professorEmail': (await currentEmail()) ?? '',
      'pendingEvals': 0,
    });
    await _persist();
  }

  Future<void> deleteCourse(String courseId) async {
    await _ensureLoaded();
    _courses.removeWhere((c) => '${c['courseId']}' == courseId);
    _categories.removeWhere((c) => '${c['courseId']}' == courseId);
    _members.removeWhere((m) => '${m['courseId']}' == courseId);
    _evaluations.removeWhere((e) => '${e['courseId']}' == courseId);
    await _persist();
  }

  Future<List<Map<String, dynamic>>> professorCourseSummaries() async {
    await _ensureLoaded();
    final mapped = <Map<String, dynamic>>[];
    for (final course in _courses) {
      final courseId = (course['courseId'] ?? '').toString();
      final categories =
          _categories.where((c) => '${c['courseId']}' == courseId).toList();
      final members =
          _members.where((m) => '${m['courseId']}' == courseId).toList();
      final uniqueStudents = members
          .map((m) => (m['email'] ?? '').toString().trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toSet();
      // Count active evaluations
      _updateEvaluationStatuses();
      final activeEvals = _evaluations
          .where((e) =>
              '${e['courseId']}' == courseId && e['status'] == 'active')
          .length;
      mapped.add({
        'id': courseId,
        'title': (course['title'] ?? 'Curso').toString(),
        'code': (course['code'] ?? '').toString(),
        'studentCount': uniqueStudents.length,
        'groupCount': categories.length,
        'pendingEvals': activeEvals,
      });
    }
    return mapped;
  }

  Future<bool> enrollByCourseCode({
    required String email,
    required String courseCode,
  }) async {
    await _ensureLoaded();
    final course = _courses.firstWhere(
      (c) =>
          (c['code'] ?? '').toString().toLowerCase() ==
          courseCode.toLowerCase(),
      orElse: () => {},
    );
    if (course.isEmpty) return false;
    final courseId = (course['courseId'] ?? '').toString();
    final alreadyIn = _members.any((m) =>
        '${m['courseId']}' == courseId &&
        (m['email'] ?? '').toString().toLowerCase() == email.toLowerCase());
    if (!alreadyIn) {
      _members.add({
        'courseId': courseId,
        'courseCode': courseCode,
        'category': 'Sin grupo',
        'email': email,
        'name': '',
        'last_name': '',
      });
      await _persist();
    }
    return true;
  }

  Future<List<Map<String, dynamic>>> studentCourses(String email) async {
    await _ensureLoaded();
    final memberRows = _members
        .where((m) =>
            (m['email'] ?? '').toString().toLowerCase() == email.toLowerCase())
        .toList();
    final courseById = {
      for (final c in _courses) (c['courseId'] ?? '').toString(): c,
    };
    final seen = <String>{};
    final mapped = <Map<String, dynamic>>[];
    for (final member in memberRows) {
      final courseId = (member['courseId'] ?? '').toString();
      if (courseId.isEmpty || seen.contains(courseId)) continue;
      seen.add(courseId);
      final course = courseById[courseId];
      _updateEvaluationStatuses();
      final activeEvals = _evaluations
          .where((e) =>
              '${e['courseId']}' == courseId && e['status'] == 'active')
          .length;
      mapped.add({
        'id': courseId,
        'title': (course?['title'] ?? 'Curso').toString(),
        'code': (course?['code'] ?? '').toString(),
        'professor': (course?['professorEmail'] ?? 'Docente').toString(),
        'myGroup': (member['category'] ?? 'Sin grupo').toString(),
        'activeEvals': activeEvals,
        'completedEvals': 0,
        'totalEvals': activeEvals,
      });
    }
    return mapped;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CSV IMPORT
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> importCsvData({
    required String courseId,
    required String courseCode,
    required Set<String> categories,
    required List<Map<String, dynamic>> members,
  }) async {
    await _ensureLoaded();
    final nonCourseMembers = _members
        .where((m) => '${m['courseId']}' != courseId)
        .toList(growable: false);
    final byEmail = <String, Map<String, dynamic>>{};
    for (final member
        in _members.where((m) => '${m['courseId']}' == courseId)) {
      final email = (member['email'] ?? '').toString().trim().toLowerCase();
      if (email.isEmpty || byEmail.containsKey(email)) continue;
      byEmail[email] = Map<String, dynamic>.from(member);
    }
    for (final incoming in members) {
      final email = (incoming['email'] ?? '').toString().trim().toLowerCase();
      if (email.isEmpty) continue;
      final current = byEmail[email] ?? <String, dynamic>{};
      byEmail[email] = {
        ...current,
        ...incoming,
        'courseId': courseId,
        'courseCode': courseCode,
        'email': email,
      };
    }
    _members = [...nonCourseMembers, ...byEmail.values];
    final existingCategoryNames = _categories
        .where((c) => '${c['courseId']}' == courseId)
        .map((c) => (c['name'] ?? '').toString().trim())
        .where((c) => c.isNotEmpty)
        .toSet();
    for (final member in byEmail.values) {
      final category = (member['category'] ?? '').toString().trim();
      if (category.isNotEmpty) categories.add(category);
    }
    for (final category
        in categories.map((c) => c.trim()).where((c) => c.isNotEmpty)) {
      if (existingCategoryNames.contains(category)) continue;
      _categories.add({
        'courseId': courseId,
        'courseCode': courseCode,
        'name': category,
      });
      existingCategoryNames.add(category);
    }
    await _persist();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUPS / CLASSMATES
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> professorCourseGroups(
      String courseId) async {
    await _ensureLoaded();
    final categories = _categories
        .where((c) => '${c['courseId']}' == courseId)
        .map((c) => (c['name'] ?? '').toString().trim())
        .where((c) => c.isNotEmpty)
        .toSet();
    final courseMembers = _members
        .where((m) => '${m['courseId']}' == courseId)
        .toList(growable: false);
    for (final member in courseMembers) {
      final category = (member['category'] ?? '').toString().trim();
      if (category.isNotEmpty) categories.add(category);
    }
    final sortedCategories = categories.toList()..sort();
    final grouped = <Map<String, dynamic>>[];
    for (final category in sortedCategories) {
      final byCategory = courseMembers
          .where((m) =>
              (m['category'] ?? '').toString().trim() == category)
          .toList();
      final seen = <String>{};
      final members = <Map<String, String>>[];
      for (final member in byCategory) {
        final email =
            (member['email'] ?? '').toString().trim().toLowerCase();
        if (email.isEmpty || seen.contains(email)) continue;
        seen.add(email);
        final firstName = (member['name'] ?? '').toString().trim();
        final lastName =
            (member['last_name'] ?? '').toString().trim();
        final fullName = '$firstName $lastName'.trim();
        members.add({
          'name': fullName.isEmpty ? email : fullName,
          'email': email,
        });
      }
      members.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
      grouped.add({
        'groupName': category,
        'memberCount': members.length,
        'members': members,
      });
    }
    return grouped;
  }

  Future<Map<String, dynamic>> studentCourseClassmates({
    required String courseId,
    required String email,
  }) async {
    await _ensureLoaded();
    final normalizedEmail = email.trim().toLowerCase();
    final myRow = _members.firstWhere(
      (m) =>
          '${m['courseId']}' == courseId &&
          (m['email'] ?? '').toString().trim().toLowerCase() ==
              normalizedEmail,
      orElse: () => {},
    );
    final myGroup = (myRow['category'] ?? 'Sin grupo').toString().trim();
    if (myRow.isEmpty || myGroup.isEmpty) {
      return {'myGroup': 'Sin grupo', 'classmates': <Map<String, String>>[]};
    }
    final seen = <String>{};
    final classmates = <Map<String, String>>[];
    for (final member in _members) {
      if ('${member['courseId']}' != courseId) continue;
      final category = (member['category'] ?? '').toString().trim();
      if (category != myGroup) continue;
      final memberEmail =
          (member['email'] ?? '').toString().trim().toLowerCase();
      if (memberEmail.isEmpty ||
          memberEmail == normalizedEmail ||
          seen.contains(memberEmail)) continue;
      seen.add(memberEmail);
      final firstName = (member['name'] ?? '').toString().trim();
      final lastName = (member['last_name'] ?? '').toString().trim();
      final fullName = '$firstName $lastName'.trim();
      classmates.add({
        'name': fullName.isEmpty ? memberEmail : fullName,
        'email': memberEmail,
      });
    }
    classmates.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    return {'myGroup': myGroup, 'classmates': classmates};
  }

  Future<List<String>> getCategoriesForCourse(String courseId) async {
    await _ensureLoaded();
    final cats = _categories
        .where((c) => '${c['courseId']}' == courseId)
        .map((c) => (c['name'] ?? '').toString().trim())
        .where((c) => c.isNotEmpty)
        .toSet();
    // also from members
    for (final m in _members.where((m) => '${m['courseId']}' == courseId)) {
      final cat = (m['category'] ?? '').toString().trim();
      if (cat.isNotEmpty) cats.add(cat);
    }
    return cats.toList()..sort();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EVALUATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  void _updateEvaluationStatuses() {
    final now = DateTime.now();
    for (final eval in _evaluations) {
      try {
        final end = DateTime.parse(eval['endDate'] as String);
        if (now.isAfter(end) && eval['status'] == 'active') {
          eval['status'] = 'closed';
        }
        final start = DateTime.parse(eval['startDate'] as String);
        if (now.isAfter(start) &&
            now.isBefore(end) &&
            eval['status'] == 'draft') {
          eval['status'] = 'active';
        }
      } catch (_) {}
    }
  }

  /// Professor creates a new evaluation
  Future<void> createEvaluation({
    required String courseId,
    required String courseName,
    required String categoryName,
    required String activityName,
    required DateTime startDate,
    required DateTime endDate,
    required String visibility, // 'public' | 'private'
    required bool allowSelfEval,
    required List<String> criteria,
    required String professorEmail,
  }) async {
    await _ensureLoaded();
    final now = DateTime.now();
    String status = 'draft';
    if (now.isAfter(startDate) && now.isBefore(endDate)) {
      status = 'active';
    } else if (now.isAfter(endDate)) {
      status = 'closed';
    }
    _evaluations.add({
      'id': _newId(),
      'courseId': courseId,
      'courseName': courseName,
      'categoryName': categoryName,
      'activityName': activityName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'visibility': visibility,
      'allowSelfEval': allowSelfEval,
      'criteria': criteria,
      'createdBy': professorEmail,
      'status': status,
    });
    await _persist();
  }

  /// Get all evaluations for a course (professor view)
  Future<List<Map<String, dynamic>>> getEvaluationsForCourse(
      String courseId) async {
    await _ensureLoaded();
    _updateEvaluationStatuses();
    return _evaluations
        .where((e) => '${e['courseId']}' == courseId)
        .toList()
      ..sort((a, b) => (b['startDate'] ?? '').compareTo(a['startDate'] ?? ''));
  }

  /// Get active evaluations for a student
  Future<List<Map<String, dynamic>>> getActiveEvaluationsForStudent(
      String email) async {
    await _ensureLoaded();
    _updateEvaluationStatuses();
    final normalizedEmail = email.trim().toLowerCase();
    // Find courses/groups the student is in
    final studentMemberships = _members
        .where((m) =>
            (m['email'] ?? '').toString().toLowerCase() == normalizedEmail)
        .toList();

    final result = <Map<String, dynamic>>[];
    for (final membership in studentMemberships) {
      final courseId = (membership['courseId'] ?? '').toString();
      final myGroup = (membership['category'] ?? '').toString().trim();
      if (myGroup.isEmpty || myGroup == 'Sin grupo') continue;

      // Find active evaluations for this course and group
      final courseEvals = _evaluations.where((e) =>
          '${e['courseId']}' == courseId &&
          e['status'] == 'active' &&
          (e['categoryName'] ?? '') == myGroup).toList();

      for (final eval in courseEvals) {
        // Count how many teammates still need rating
        final teammates = _members
            .where((m) =>
                '${m['courseId']}' == courseId &&
                (m['category'] ?? '').toString().trim() == myGroup &&
                (m['email'] ?? '').toString().toLowerCase() != normalizedEmail)
            .toList();

        final alreadyRated = _responses
            .where((r) =>
                r['evaluationId'] == eval['id'] &&
                (r['evaluatorEmail'] ?? '').toString().toLowerCase() ==
                    normalizedEmail)
            .map((r) => (r['evaluateeEmail'] ?? '').toString().toLowerCase())
            .toSet();

        final pending = teammates
            .where((t) => !alreadyRated.contains(
                (t['email'] ?? '').toString().toLowerCase()))
            .length;

        final totalRatable = teammates.length +
            (eval['allowSelfEval'] == true &&
                    !alreadyRated.contains(normalizedEmail)
                ? 1
                : 0);

        result.add({
          ...eval,
          'myGroup': myGroup,
          'pendingRatings': pending,
          'totalRatable': totalRatable,
          'completed': pending == 0,
        });
      }
    }
    return result;
  }

  /// Get teammates to rate for a specific evaluation
  Future<List<Map<String, dynamic>>> getTeammatesForEvaluation({
    required String evaluationId,
    required String evaluatorEmail,
  }) async {
    await _ensureLoaded();
    final eval = _evaluations.firstWhere(
      (e) => e['id'] == evaluationId,
      orElse: () => {},
    );
    if (eval.isEmpty) return [];

    final courseId = eval['courseId'].toString();
    final categoryName = eval['categoryName'].toString();
    final normalizedEmail = evaluatorEmail.trim().toLowerCase();

    // Find evaluator's group
    final myMembership = _members.firstWhere(
      (m) =>
          '${m['courseId']}' == courseId &&
          (m['email'] ?? '').toString().toLowerCase() == normalizedEmail,
      orElse: () => {},
    );
    if (myMembership.isEmpty) return [];

    // Get all group members
    final groupMembers = _members
        .where((m) =>
            '${m['courseId']}' == courseId &&
            (m['category'] ?? '').toString().trim() == categoryName)
        .toList();

    final teammates = <Map<String, dynamic>>[];
    final allowSelfEval = eval['allowSelfEval'] == true;

    for (final member in groupMembers) {
      final memberEmail =
          (member['email'] ?? '').toString().trim().toLowerCase();
      if (memberEmail.isEmpty) continue;
      final isSelf = memberEmail == normalizedEmail;
      if (isSelf && !allowSelfEval) continue;

      // Check existing response
      final existingResponse = _responses.firstWhere(
        (r) =>
            r['evaluationId'] == evaluationId &&
            (r['evaluatorEmail'] ?? '').toString().toLowerCase() ==
                normalizedEmail &&
            (r['evaluateeEmail'] ?? '').toString().toLowerCase() ==
                memberEmail,
        orElse: () => {},
      );

      final firstName = (member['name'] ?? '').toString().trim();
      final lastName = (member['last_name'] ?? '').toString().trim();
      final fullName = '$firstName $lastName'.trim();

      teammates.add({
        'email': memberEmail,
        'name': fullName.isEmpty ? memberEmail : fullName,
        'isSelf': isSelf,
        'alreadyRated': existingResponse.isNotEmpty,
        'existingScores':
            existingResponse.isNotEmpty ? existingResponse['scores'] : null,
      });
    }

    // Self always last
    teammates.sort((a, b) {
      if (a['isSelf'] == true) return 1;
      if (b['isSelf'] == true) return -1;
      return (a['name'] as String).compareTo(b['name'] as String);
    });

    return teammates;
  }

  /// Student submits evaluation scores
  Future<void> submitEvaluationResponse({
    required String evaluationId,
    required String evaluatorEmail,
    required String evaluateeEmail,
    required Map<String, int> scores,
  }) async {
    await _ensureLoaded();
    final normalizedEvaluator = evaluatorEmail.trim().toLowerCase();
    final normalizedEvaluatee = evaluateeEmail.trim().toLowerCase();

    // Remove existing if re-submitting
    _responses.removeWhere((r) =>
        r['evaluationId'] == evaluationId &&
        (r['evaluatorEmail'] ?? '').toString().toLowerCase() ==
            normalizedEvaluator &&
        (r['evaluateeEmail'] ?? '').toString().toLowerCase() ==
            normalizedEvaluatee);

    _responses.add({
      'evaluationId': evaluationId,
      'evaluatorEmail': normalizedEvaluator,
      'evaluateeEmail': normalizedEvaluatee,
      'scores': scores,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _persist();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RESULTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Professor: get results for an evaluation
  Future<Map<String, dynamic>> getEvaluationResults(
      String evaluationId) async {
    await _ensureLoaded();
    final eval = _evaluations.firstWhere(
      (e) => e['id'] == evaluationId,
      orElse: () => {},
    );
    if (eval.isEmpty) {
      return {'byStudent': [], 'byGroup': {}, 'overall': 0.0};
    }

    final criteria = (eval['criteria'] as List<dynamic>? ?? [])
        .map((c) => c.toString())
        .toList();
    final evalResponses = _responses
        .where((r) => r['evaluationId'] == evaluationId)
        .toList();

    // Group by evaluatee
    final studentMap = <String, List<Map<String, dynamic>>>{};
    for (final r in evalResponses) {
      final evaluatee =
          (r['evaluateeEmail'] ?? '').toString().toLowerCase();
      studentMap.putIfAbsent(evaluatee, () => []).add(r);
    }

    final byStudent = <Map<String, dynamic>>[];
    for (final entry in studentMap.entries) {
      final email = entry.key;
      final responses = entry.value;

      // Get name
      final memberInfo = _members.firstWhere(
        (m) =>
            (m['email'] ?? '').toString().toLowerCase() == email &&
            '${m['courseId']}' == eval['courseId'].toString(),
        orElse: () => {},
      );
      final firstName = (memberInfo['name'] ?? '').toString().trim();
      final lastName = (memberInfo['last_name'] ?? '').toString().trim();
      final fullName = '$firstName $lastName'.trim();

      // Average per criterion
      final criterionAverages = <String, double>{};
      for (final criterion in criteria) {
        final vals = responses
            .map((r) =>
                ((r['scores'] as Map<String, dynamic>?)?[criterion] as num?)
                    ?.toDouble() ??
                0.0)
            .where((v) => v > 0)
            .toList();
        criterionAverages[criterion] =
            vals.isEmpty ? 0.0 : vals.reduce((a, b) => a + b) / vals.length;
      }

      final overallAvg = criterionAverages.values.isEmpty
          ? 0.0
          : criterionAverages.values.reduce((a, b) => a + b) /
              criterionAverages.values.length;

      byStudent.add({
        'email': email,
        'name': fullName.isEmpty ? email : fullName,
        'group': (memberInfo['category'] ?? '').toString(),
        'overallAverage': overallAvg,
        'criterionAverages': criterionAverages,
        'responseCount': responses.length,
      });
    }
    byStudent.sort(
        (a, b) => (b['overallAverage'] as double).compareTo(a['overallAverage'] as double));

    // Group averages
    final byGroup = <String, Map<String, dynamic>>{};
    for (final student in byStudent) {
      final group = (student['group'] ?? 'Sin grupo').toString();
      final avg = student['overallAverage'] as double;
      byGroup.putIfAbsent(group, () => {'sum': 0.0, 'count': 0, 'name': group});
      byGroup[group]!['sum'] = (byGroup[group]!['sum'] as double) + avg;
      byGroup[group]!['count'] = (byGroup[group]!['count'] as int) + 1;
    }
    for (final g in byGroup.values) {
      final count = g['count'] as int;
      g['average'] =
          count > 0 ? (g['sum'] as double) / count : 0.0;
    }

    // Overall average
    final overall = byStudent.isEmpty
        ? 0.0
        : byStudent
                .map((s) => s['overallAverage'] as double)
                .reduce((a, b) => a + b) /
            byStudent.length;

    return {
      'evaluation': eval,
      'byStudent': byStudent,
      'byGroup': byGroup,
      'overall': overall,
      'totalResponses': evalResponses.length,
    };
  }

  /// Student: get own results for a specific evaluation
  Future<Map<String, dynamic>?> getMyResults({
    required String evaluationId,
    required String studentEmail,
  }) async {
    await _ensureLoaded();
    final eval = _evaluations.firstWhere(
      (e) => e['id'] == evaluationId,
      orElse: () => {},
    );
    if (eval.isEmpty) return null;
    if (eval['visibility'] != 'public' && eval['status'] != 'closed') {
      return null; // not visible yet
    }

    final normalizedEmail = studentEmail.trim().toLowerCase();
    final myResponses = _responses
        .where((r) =>
            r['evaluationId'] == evaluationId &&
            (r['evaluateeEmail'] ?? '').toString().toLowerCase() ==
                normalizedEmail)
        .toList();

    if (myResponses.isEmpty) return {'hasResults': false};

    final criteria = (eval['criteria'] as List<dynamic>? ?? [])
        .map((c) => c.toString())
        .toList();

    final criterionAverages = <String, double>{};
    for (final criterion in criteria) {
      final vals = myResponses
          .map((r) =>
              ((r['scores'] as Map<String, dynamic>?)?[criterion] as num?)
                  ?.toDouble() ??
              0.0)
          .where((v) => v > 0)
          .toList();
      criterionAverages[criterion] =
          vals.isEmpty ? 0.0 : vals.reduce((a, b) => a + b) / vals.length;
    }

    final overallAvg = criterionAverages.values.isEmpty
        ? 0.0
        : criterionAverages.values.reduce((a, b) => a + b) /
            criterionAverages.values.length;

    return {
      'hasResults': true,
      'evaluation': eval,
      'overallAverage': overallAvg,
      'criterionAverages': criterionAverages,
      'responseCount': myResponses.length,
    };
  }

  /// Student: get all evaluations they've participated in (any status, public results)
  Future<List<Map<String, dynamic>>> getStudentResults(String email) async {
    await _ensureLoaded();
    _updateEvaluationStatuses();
    final normalizedEmail = email.trim().toLowerCase();

    // Find courses student is in
    final studentMemberships = _members
        .where((m) =>
            (m['email'] ?? '').toString().toLowerCase() == normalizedEmail)
        .toList();

    final result = <Map<String, dynamic>>[];
    for (final membership in studentMemberships) {
      final courseId = (membership['courseId'] ?? '').toString();
      final myGroup = (membership['category'] ?? '').toString().trim();

      final courseEvals = _evaluations.where((e) =>
          '${e['courseId']}' == courseId &&
          (e['categoryName'] ?? '') == myGroup &&
          (e['status'] == 'closed' ||
              (e['status'] == 'active' && e['visibility'] == 'public'))).toList();

      for (final eval in courseEvals) {
        final myResults = await getMyResults(
            evaluationId: eval['id'].toString(),
            studentEmail: normalizedEmail);
        if (myResults != null && myResults['hasResults'] == true) {
          result.add(myResults);
        }
      }
    }
    return result;
  }
}