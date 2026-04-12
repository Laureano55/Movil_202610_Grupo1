import '../../core/roble_database_service.dart';
import '../../domain/models/evaluation_model.dart';
import '../../domain/models/evaluation_response_model.dart';
import '../../domain/repositories/i_evaluation_repository.dart';

class EvaluationRepositoryImpl implements IEvaluationRepository {
  final RobleDatabaseService _db;

  EvaluationRepositoryImpl(this._db);

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
    return rows
        .where((e) => e['course_id'] == courseId)
        .map((e) => EvaluationModel.fromJson(e).withComputedStatus().toMap())
        .toList()
      ..sort((a, b) =>
          (b['startDate'] as String).compareTo(a['startDate'] as String));
  }

  @override
  Future<List<Map<String, dynamic>>> getActiveEvaluationsForStudent(
      String email) async {
    final normalizedEmail = email.toLowerCase().trim();
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
              _computeStatus(e) == 'active')
          .toList();

      for (final eval in courseEvals) {
        final evalId = eval['_id'].toString();
        final teammates = allMembers
            .where((m) =>
                m['course_id'] == courseId &&
                (m['category_name'] ?? '').toString().trim() == myGroup &&
                (m['email'] ?? '').toString().toLowerCase() != normalizedEmail)
            .toList();

        final alreadyRated = allResponses
            .where((r) =>
                r['evaluation_id'] == evalId &&
                (r['evaluator_email'] ?? '').toString().toLowerCase() ==
                    normalizedEmail)
            .map((r) => (r['evaluatee_email'] ?? '').toString().toLowerCase())
            .toSet();

        final pending = teammates
            .where((t) => !alreadyRated
                .contains((t['email'] ?? '').toString().toLowerCase()))
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
    final normalizedEvaluator = evaluatorEmail.toLowerCase().trim();
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
      final memberEmail =
          (member['email'] ?? '').toString().toLowerCase().trim();
      if (memberEmail.isEmpty) continue;
      final isSelf = memberEmail == normalizedEvaluator;
      if (isSelf && !eval.allowSelfEval) continue;

      final existingResponse = allResponses.firstWhere(
        (r) =>
            r['evaluation_id'] == evaluationId &&
            (r['evaluator_email'] ?? '').toString().toLowerCase() ==
                normalizedEvaluator &&
            (r['evaluatee_email'] ?? '').toString().toLowerCase() ==
                memberEmail,
        orElse: () => <String, dynamic>{},
      );

      final n = (member['name'] ?? '').toString().trim();
      final ln = (member['last_name'] ?? '').toString().trim();
      final fullName = '$n $ln'.trim();

      Map<String, dynamic>? existingScores;
      if (existingResponse.isNotEmpty) {
        final model = EvaluationResponseModel.fromJson(existingResponse);
        existingScores = model.scores
            .map((k, v) => MapEntry(k, v));
      }

      teammates.add({
        'email': memberEmail,
        'name': fullName.isEmpty ? memberEmail : fullName,
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
    final normalizedEvaluator = evaluatorEmail.toLowerCase().trim();
    final normalizedEvaluatee = evaluateeEmail.toLowerCase().trim();

    final allResponses = await _db.read('evaluation_responses');
    final existing = allResponses.firstWhere(
      (r) =>
          r['evaluation_id'] == evaluationId &&
          (r['evaluator_email'] ?? '').toString().toLowerCase() ==
              normalizedEvaluator &&
          (r['evaluatee_email'] ?? '').toString().toLowerCase() ==
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
      return {'byStudent': [], 'byGroup': {}, 'overall': 0.0};
    }
    final eval = EvaluationModel.fromJson(evalJson).withComputedStatus();

    final allResponses = await _db.read('evaluation_responses');
    final evalResponses = allResponses
        .where((r) => r['evaluation_id'] == evaluationId)
        .map(EvaluationResponseModel.fromJson)
        .toList();

    final allMembers = await _db.read('course_members');

    // Agrupar por evaluatee
    final studentMap = <String, List<EvaluationResponseModel>>{};
    for (final r in evalResponses) {
      studentMap.putIfAbsent(r.evaluateeEmail, () => []).add(r);
    }

    final byStudent = <Map<String, dynamic>>[];
    for (final entry in studentMap.entries) {
      final email = entry.key;
      final responses = entry.value;

      final memberInfo = allMembers.firstWhere(
        (m) =>
            (m['email'] ?? '').toString().toLowerCase() == email &&
            m['course_id'] == eval.courseId,
        orElse: () => <String, dynamic>{},
      );
      final n = (memberInfo['name'] ?? '').toString().trim();
      final ln = (memberInfo['last_name'] ?? '').toString().trim();
      final fullName = '$n $ln'.trim();

      final criterionAverages = <String, double>{};
      for (final criterion in eval.criteria) {
        final vals = responses
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

      byStudent.add({
        'email': email,
        'name': fullName.isEmpty ? email : fullName,
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
          group, () => {'sum': 0.0, 'count': 0, 'name': group});
      byGroup[group]!['sum'] =
          (byGroup[group]!['sum'] as double) + (s['overallAverage'] as double);
      byGroup[group]!['count'] = (byGroup[group]!['count'] as int) + 1;
    }
    for (final g in byGroup.values) {
      final count = g['count'] as int;
      g['average'] =
          count > 0 ? (g['sum'] as double) / count : 0.0;
    }

    final overall = byStudent.isEmpty
        ? 0.0
        : byStudent
                .map((s) => s['overallAverage'] as double)
                .reduce((a, b) => a + b) /
            byStudent.length;

    return {
      'evaluation': eval.toMap(),
      'byStudent': byStudent,
      'byGroup': byGroup,
      'overall': overall,
      'totalResponses': evalResponses.length,
    };
  }

  @override
  Future<Map<String, dynamic>?> getMyResults({
    required String evaluationId,
    required String studentEmail,
  }) async {
    final normalizedEmail = studentEmail.toLowerCase().trim();
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
            (r['evaluatee_email'] ?? '').toString().toLowerCase() ==
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
    final normalizedEmail = email.toLowerCase().trim();
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

  // ── Private helpers ────────────────────────────────────────────────────────

  String _computeStatus(Map<String, dynamic> evalJson) {
    final start = DateTime.tryParse(evalJson['start_date']?.toString() ?? '');
    final end = DateTime.tryParse(evalJson['end_date']?.toString() ?? '');
    if (start == null || end == null) return 'draft';
    final now = DateTime.now();
    if (now.isAfter(end)) return 'closed';
    if (now.isAfter(start)) return 'active';
    return 'draft';
  }
}