import '../../core/roble_database_service.dart';
import '../../domain/models/evaluation_model.dart';
import '../../domain/models/evaluation_response_model.dart';
import '../../domain/repositories/i_evaluation_repository.dart';
import 'repository_utils.dart';

class EvaluationRepositoryImpl implements IEvaluationRepository {
  final RobleDatabaseService _db;

  EvaluationRepositoryImpl(this._db);

  double _averageFrom(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _calculateGroupAverage(List<Map<String, dynamic>> groupStudents) {
    final averages = groupStudents
        .map((s) => (s['overallAverage'] as double?) ?? 0.0)
        .toList(growable: false);
    return _averageFrom(averages);
  }

  double _calculateEvaluationAverage(Map<String, Map<String, dynamic>> byGroup) {
    final groupAverages = byGroup.values
        .map((g) => (g['average'] as double?) ?? 0.0)
        .toList(growable: false);
    return _averageFrom(groupAverages);
  }

  double _calculateCourseAverage(List<double> evaluationAverages) {
    return _averageFrom(evaluationAverages);
  }

  Map<String, dynamic> _buildEvaluationStats({
    required EvaluationModel eval,
    required String evaluationId,
    required List<Map<String, dynamic>> allResponses,
    required List<Map<String, dynamic>> allMembers,
  }) {
    final evalResponses = allResponses
        .where((r) => r['evaluation_id'] == evaluationId)
        .map(EvaluationResponseModel.fromJson)
        .toList();

    final studentMap = <String, List<EvaluationResponseModel>>{};
    for (final r in evalResponses) {
      studentMap.putIfAbsent(r.evaluateeEmail, () => []).add(r);
    }

    final byStudent = <Map<String, dynamic>>[];
    for (final entry in studentMap.entries) {
      final email = entry.key;
      final responses = entry.value;

      final memberInfo = allMembers.firstWhere(
        (m) => normalizeEmail(m['email']) == email && m['course_id'] == eval.courseId,
        orElse: () => <String, dynamic>{},
      );

      final criterionAverages = <String, double>{};
      for (final criterion in eval.criteria) {
        final vals = responses
            .map((r) => (r.scores[criterion] ?? 0).toDouble())
            .where((v) => v > 0)
            .toList();
        criterionAverages[criterion] = _averageFrom(vals);
      }

      final overallAvg = _averageFrom(criterionAverages.values.toList());

      byStudent.add({
        'email': email,
        'name': buildDisplayNameFromRow(memberInfo, fallbackEmail: email),
        'group': (memberInfo['category_name'] ?? '').toString(),
        'overallAverage': overallAvg,
        'criterionAverages': criterionAverages,
        'responseCount': responses.length,
      });
    }

    byStudent.sort((a, b) =>
        (b['overallAverage'] as double).compareTo(a['overallAverage'] as double));

    final byGroup = <String, Map<String, dynamic>>{};
    for (final s in byStudent) {
      final group = (s['group'] ?? 'Sin grupo').toString();
      byGroup.putIfAbsent(
        group,
        () => {
          'name': group,
          'students': <Map<String, dynamic>>[],
        },
      );
      (byGroup[group]!['students'] as List<Map<String, dynamic>>).add(s);
    }

    for (final g in byGroup.values) {
      final groupStudents = (g['students'] as List<Map<String, dynamic>>);
      g['count'] = groupStudents.length;
      g['average'] = _calculateGroupAverage(groupStudents);

      final criterionAverages = <String, double>{};
      for (final criterion in eval.criteria) {
        final vals = groupStudents
            .map((s) =>
                ((s['criterionAverages'] as Map<String, dynamic>?)?[criterion] as double?) ??
                    0.0)
            .where((v) => v > 0)
            .toList();
        criterionAverages[criterion] = _averageFrom(vals);
      }
      g['criterionAverages'] = criterionAverages;
      g.remove('students');
    }

    final averageEvaluation = _calculateEvaluationAverage(byGroup);

    return {
      'byStudent': byStudent,
      'byGroup': byGroup,
      'averageEvaluation': averageEvaluation,
      // Compatibilidad hacia atras con pantallas que ya consumen "overall"
      'overall': averageEvaluation,
      'totalResponses': evalResponses.length,
    };
  }

  // ── Create ─────────────────────────────────────────────────────────────────

  @override
  Future<void> createEvaluation({
    required String courseId,
    required String courseName,
    required String categoryName,
    required String activityName,
    required DateTime startDate,
    required DateTime endDate,
    required String visibility,
    required bool allowSelfEval,
    required List<String> criteria,
    required String professorEmail,
  }) async {
    final model = EvaluationModel(
      courseId: courseId,
      courseName: courseName,
      categoryName: categoryName,
      activityName: activityName,
      startDate: startDate,
      endDate: endDate,
      visibility: visibility,
      allowSelfEval: allowSelfEval,
      criteria: criteria,
      createdBy: professorEmail,
      status: 'draft',
    );
    await _db.insert('evaluations', [model.toInsertJson()]);
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getEvaluationsForCourse(
      String courseId) async {
    final rows = await _db.read('evaluations');
    final allResponses = await _db.read('evaluation_responses');
    final allMembers = await _db.read('course_members');

    final courseRows = rows.where((e) => e['course_id'] == courseId).toList();
    final evaluations = <Map<String, dynamic>>[];
    final evaluationAverages = <double>[];

    for (final row in courseRows) {
      final eval = EvaluationModel.fromJson(row).withComputedStatus();
      final evalId = row['_id']?.toString() ?? '';

      final stats = evalId.isEmpty
          ? {
              'averageEvaluation': 0.0,
              'overall': 0.0,
              'totalResponses': 0,
            }
          : _buildEvaluationStats(
              eval: eval,
              evaluationId: evalId,
              allResponses: allResponses,
              allMembers: allMembers,
            );

      final averageEvaluation = (stats['averageEvaluation'] as double?) ?? 0.0;
      evaluationAverages.add(averageEvaluation);

      evaluations.add({
        ...eval.toMap(),
        'averageEvaluation': averageEvaluation,
        // Compatibilidad hacia atras
        'overall': (stats['overall'] as double?) ?? averageEvaluation,
        'totalResponses': (stats['totalResponses'] as int?) ?? 0,
      });
    }

    final averageCourse = _calculateCourseAverage(evaluationAverages);
    for (final e in evaluations) {
      e['averageCourse'] = averageCourse;
    }

    evaluations.sort(
      (a, b) => (b['startDate'] as String).compareTo(a['startDate'] as String),
    );

    return evaluations;
  }

  @override
  Future<List<Map<String, dynamic>>> getActiveEvaluationsForStudent(
      String email) async {
    final normalizedEmail = normalizeEmail(email);
    final allMembers = await _db.read('course_members');
    final myMemberships = allMembers
        .where((m) =>
            (m['email'] ?? '').toString().toLowerCase() == normalizedEmail)
        .toList();

    final allEvals = await _db.read('evaluations');
    final allResponses = await _db.read('evaluation_responses');

    final result = <Map<String, dynamic>>[];

    for (final membership in myMemberships) {
      final courseId = membership['course_id']?.toString() ?? '';
      final myGroup = (membership['category_name'] ?? '').toString().trim();
      if (myGroup.isEmpty || myGroup == 'Sin grupo') continue;

      final courseEvals = allEvals
          .where((e) =>
              e['course_id'] == courseId &&
              (e['category_name'] ?? '') == myGroup &&
              computeEvaluationStatus(e) == 'active')
          .toList();

      for (final eval in courseEvals) {
        final evalId = eval['_id'].toString();
        final teammates = allMembers
            .where((m) =>
                m['course_id'] == courseId &&
                (m['category_name'] ?? '').toString().trim() == myGroup &&
              normalizeEmail(m['email']) != normalizedEmail)
            .toList();

        final alreadyRated = allResponses
            .where((r) =>
                r['evaluation_id'] == evalId &&
              normalizeEmail(r['evaluator_email']) ==
                    normalizedEmail)
            .map((r) => normalizeEmail(r['evaluatee_email']))
            .toSet();

        final pending = teammates
            .where((t) => !alreadyRated.contains(normalizeEmail(t['email'])))
            .length;

        final model = EvaluationModel.fromJson(eval).withComputedStatus();

        result.add({
          ...model.toMap(),
          'myGroup': myGroup,
          'pendingRatings': pending,
          'totalRatable': teammates.length,
          'completed': pending == 0,
        });
      }
    }
    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> getTeammatesForEvaluation({
    required String evaluationId,
    required String evaluatorEmail,
  }) async {
    final normalizedEvaluator = normalizeEmail(evaluatorEmail);
    final allEvals = await _db.read('evaluations');
    final evalJson = allEvals.firstWhere(
      (e) => e['_id']?.toString() == evaluationId,
      orElse: () => <String, dynamic>{},
    );
    if (evalJson.isEmpty) return [];

    final eval = EvaluationModel.fromJson(evalJson);
    final courseId = eval.courseId;
    final categoryName = eval.categoryName;

    final allMembers = await _db.read('course_members');
    final groupMembers = allMembers
        .where((m) =>
            m['course_id'] == courseId &&
            (m['category_name'] ?? '').toString().trim() == categoryName)
        .toList();

    final allResponses = await _db.read('evaluation_responses');

    final teammates = <Map<String, dynamic>>[];
    for (final member in groupMembers) {
      final memberEmail = normalizeEmail(member['email']);
      if (memberEmail.isEmpty) continue;
      final isSelf = memberEmail == normalizedEvaluator;
      if (isSelf && !eval.allowSelfEval) continue;

      final existingResponse = allResponses.firstWhere(
        (r) =>
            r['evaluation_id'] == evaluationId &&
          normalizeEmail(r['evaluator_email']) ==
                normalizedEvaluator &&
          normalizeEmail(r['evaluatee_email']) ==
                memberEmail,
        orElse: () => <String, dynamic>{},
      );

      Map<String, dynamic>? existingScores;
      if (existingResponse.isNotEmpty) {
        final model = EvaluationResponseModel.fromJson(existingResponse);
        existingScores = model.scores
            .map((k, v) => MapEntry(k, v));
      }

      teammates.add({
        'email': memberEmail,
        'name': buildDisplayNameFromRow(member, fallbackEmail: memberEmail),
        'isSelf': isSelf,
        'alreadyRated': existingResponse.isNotEmpty,
        'existingScores': existingScores,
      });
    }

    teammates.sort((a, b) {
      if (a['isSelf'] == true) return 1;
      if (b['isSelf'] == true) return -1;
      return (a['name'] as String).compareTo(b['name'] as String);
    });
    return teammates;
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  @override
  Future<void> submitEvaluationResponse({
    required String evaluationId,
    required String evaluatorEmail,
    required String evaluateeEmail,
    required Map<String, int> scores,
  }) async {
    final normalizedEvaluator = normalizeEmail(evaluatorEmail);
    final normalizedEvaluatee = normalizeEmail(evaluateeEmail);

    final allResponses = await _db.read('evaluation_responses');
    final existing = allResponses.firstWhere(
      (r) =>
          r['evaluation_id'] == evaluationId &&
          normalizeEmail(r['evaluator_email']) ==
              normalizedEvaluator &&
          normalizeEmail(r['evaluatee_email']) ==
              normalizedEvaluatee,
      orElse: () => <String, dynamic>{},
    );

    final model = EvaluationResponseModel(
      evaluationId: evaluationId,
      evaluatorEmail: normalizedEvaluator,
      evaluateeEmail: normalizedEvaluatee,
      scores: scores,
      submittedAt: DateTime.now().toIso8601String(),
    );

    if (existing.isNotEmpty) {
      await _db.update(
        'evaluation_responses',
        idColumn: '_id',
        idValue: existing['_id'].toString(),
        updates: model.toInsertJson(),
      );
    } else {
      await _db.insert('evaluation_responses', [model.toInsertJson()]);
    }
  }

  // ── Results ────────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getEvaluationResults(
      String evaluationId) async {
    final allEvals = await _db.read('evaluations');
    final evalJson = allEvals.firstWhere(
      (e) => e['_id']?.toString() == evaluationId,
      orElse: () => <String, dynamic>{},
    );
    if (evalJson.isEmpty) {
      return {
        'byStudent': [],
        'byGroup': {},
        'averageEvaluation': 0.0,
        'averageCourse': 0.0,
        'overall': 0.0,
        'totalResponses': 0,
      };
    }
    final eval = EvaluationModel.fromJson(evalJson).withComputedStatus();

    final allResponses = await _db.read('evaluation_responses');
    final allMembers = await _db.read('course_members');

    final stats = _buildEvaluationStats(
      eval: eval,
      evaluationId: evaluationId,
      allResponses: allResponses,
      allMembers: allMembers,
    );

    final courseRows = allEvals.where((e) => e['course_id'] == eval.courseId).toList();
    final evaluationAverages = <double>[];
    for (final row in courseRows) {
      final evalId = row['_id']?.toString() ?? '';
      if (evalId.isEmpty) {
        evaluationAverages.add(0.0);
        continue;
      }
      final courseEval = EvaluationModel.fromJson(row).withComputedStatus();
      final courseStats = _buildEvaluationStats(
        eval: courseEval,
        evaluationId: evalId,
        allResponses: allResponses,
        allMembers: allMembers,
      );
      evaluationAverages.add((courseStats['averageEvaluation'] as double?) ?? 0.0);
    }

    final averageCourse = _calculateCourseAverage(evaluationAverages);

    return {
      'evaluation': eval.toMap(),
      ...stats,
      'averageCourse': averageCourse,
    };
  }

  @override
  Future<Map<String, dynamic>?> getMyResults({
    required String evaluationId,
    required String studentEmail,
  }) async {
    final normalizedEmail = normalizeEmail(studentEmail);
    final allEvals = await _db.read('evaluations');
    final evalJson = allEvals.firstWhere(
      (e) => e['_id']?.toString() == evaluationId,
      orElse: () => <String, dynamic>{},
    );
    if (evalJson.isEmpty) return null;
    final eval = EvaluationModel.fromJson(evalJson).withComputedStatus();

    if (eval.visibility != 'public' && eval.status != 'closed') return null;

    final allResponses = await _db.read('evaluation_responses');
    final myResponses = allResponses
        .where((r) =>
            r['evaluation_id'] == evaluationId &&
        normalizeEmail(r['evaluatee_email']) ==
                normalizedEmail)
        .map(EvaluationResponseModel.fromJson)
        .toList();

    if (myResponses.isEmpty) return {'hasResults': false};

    final criterionAverages = <String, double>{};
    for (final criterion in eval.criteria) {
      final vals = myResponses
          .map((r) => (r.scores[criterion] ?? 0).toDouble())
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
      'evaluation': eval.toMap(),
      'overallAverage': overallAvg,
      'criterionAverages': criterionAverages,
      'responseCount': myResponses.length,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentResults(String email) async {
    final normalizedEmail = normalizeEmail(email);
    final allMembers = await _db.read('course_members');
    final myMemberships = allMembers
        .where((m) =>
            (m['email'] ?? '').toString().toLowerCase() == normalizedEmail)
        .toList();

    final allEvals = await _db.read('evaluations');
    final result = <Map<String, dynamic>>[];

    for (final membership in myMemberships) {
      final courseId = membership['course_id']?.toString() ?? '';
      final myGroup = (membership['category_name'] ?? '').toString().trim();

      final courseEvals = allEvals
          .where((e) =>
              e['course_id'] == courseId &&
              (e['category_name'] ?? '') == myGroup)
          .toList();

      for (final evalJson in courseEvals) {
        final eval = EvaluationModel.fromJson(evalJson).withComputedStatus();
        if (eval.visibility != 'public' && eval.status != 'closed') continue;
        if (eval.id == null) continue;

        final myResult = await getMyResults(
          evaluationId: eval.id!,
          studentEmail: normalizedEmail,
        );
        if (myResult != null && myResult['hasResults'] == true) {
          result.add(myResult);
        }
      }
    }
    return result;
  }
}