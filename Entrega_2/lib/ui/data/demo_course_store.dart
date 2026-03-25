import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'json_backup_storage.dart';

class DemoCourseStore {
  static const _coursesKey = 'demo_courses';
  static const _categoriesKey = 'demo_categories';
  static const _membersKey = 'demo_category_members';

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _members = [];

  final JsonBackupStorage _backupStorage = JsonBackupStorage();

  bool _loaded = false;

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

    final shouldRestoreFromBackup =
        _courses.isEmpty && _categories.isEmpty && _members.isEmpty;
    if (shouldRestoreFromBackup) {
      final backup = await _backupStorage.read();
      if (backup != null) {
        _courses = decodeList(jsonEncode(backup['courses'] ?? []));
        _categories = decodeList(jsonEncode(backup['categories'] ?? []));
        _members = decodeList(jsonEncode(backup['members'] ?? []));

        await prefs.setString(_coursesKey, jsonEncode(_courses));
        await prefs.setString(_categoriesKey, jsonEncode(_categories));
        await prefs.setString(_membersKey, jsonEncode(_members));
      }
    }

    _loaded = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_coursesKey, jsonEncode(_courses));
    await prefs.setString(_categoriesKey, jsonEncode(_categories));
    await prefs.setString(_membersKey, jsonEncode(_members));

    await _backupStorage.write({
      'updatedAt': DateTime.now().toIso8601String(),
      'courses': _courses,
      'categories': _categories,
      'members': _members,
    });
  }

  Future<String?> currentEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  Future<void> createCourse({required String title, required String code}) async {
    await _ensureLoaded();

    final already = _courses.any(
      (c) => (c['code'] ?? '').toString().toLowerCase() == code.toLowerCase(),
    );
    if (already) {
      throw Exception('Ya existe un curso con código $code');
    }

    _courses.add({
      'courseId': DateTime.now().microsecondsSinceEpoch.toString(),
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

      mapped.add({
        'id': courseId,
        'title': (course['title'] ?? 'Curso').toString(),
        'code': (course['code'] ?? '').toString(),
        'studentCount': uniqueStudents.length,
        'groupCount': categories.length,
        'pendingEvals': int.tryParse('${course['pendingEvals'] ?? 0}') ?? 0,
      });
    }

    return mapped;
  }

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
    for (final member in _members.where((m) => '${m['courseId']}' == courseId)) {
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
      if (category.isNotEmpty) {
        categories.add(category);
      }
    }

    for (final category in categories.map((c) => c.trim()).where((c) => c.isNotEmpty)) {
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

  Future<bool> enrollByCourseCode({
    required String email,
    required String courseCode,
  }) async {
    await _ensureLoaded();

    final course = _courses.firstWhere(
      (c) => (c['code'] ?? '').toString().toLowerCase() ==
          courseCode.toLowerCase(),
      orElse: () => {},
    );
    if (course.isEmpty) return false;

    final courseId = (course['courseId'] ?? '').toString();
    final alreadyInCourse = _members.any((m) =>
        '${m['courseId']}' == courseId &&
        (m['email'] ?? '').toString().toLowerCase() == email.toLowerCase());

    if (!alreadyInCourse) {
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
      mapped.add({
        'id': courseId,
        'title': (course?['title'] ?? 'Curso').toString(),
        'code': (course?['code'] ?? '').toString(),
        'professor': (course?['professorEmail'] ?? 'Docente').toString(),
        'myGroup': (member['category'] ?? 'Sin grupo').toString(),
        'activeEvals': 0,
        'completedEvals': 0,
        'totalEvals': 0,
      });
    }

    return mapped;
  }

  Future<List<Map<String, dynamic>>> professorCourseGroups(String courseId) async {
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
      if (category.isNotEmpty) {
        categories.add(category);
      }
    }

    final sortedCategories = categories.toList()..sort();
    final grouped = <Map<String, dynamic>>[];

    for (final category in sortedCategories) {
      final byCategory = courseMembers
          .where((m) => (m['category'] ?? '').toString().trim() == category)
          .toList();

      final seen = <String>{};
      final members = <Map<String, String>>[];
      for (final member in byCategory) {
        final email = (member['email'] ?? '').toString().trim().toLowerCase();
        if (email.isEmpty || seen.contains(email)) continue;
        seen.add(email);

        final firstName = (member['name'] ?? '').toString().trim();
        final lastName = (member['last_name'] ?? '').toString().trim();
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
          (m['email'] ?? '').toString().trim().toLowerCase() == normalizedEmail,
      orElse: () => {},
    );

    final myGroup = (myRow['category'] ?? 'Sin grupo').toString().trim();
    if (myRow.isEmpty || myGroup.isEmpty) {
      return {
        'myGroup': 'Sin grupo',
        'classmates': <Map<String, String>>[],
      };
    }

    final seen = <String>{};
    final classmates = <Map<String, String>>[];

    for (final member in _members) {
      if ('${member['courseId']}' != courseId) continue;
      final category = (member['category'] ?? '').toString().trim();
      if (category != myGroup) continue;

      final memberEmail =
          (member['email'] ?? '').toString().trim().toLowerCase();
      if (memberEmail.isEmpty || memberEmail == normalizedEmail) continue;
      if (seen.contains(memberEmail)) continue;
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

    return {
      'myGroup': myGroup,
      'classmates': classmates,
    };
  }
}
