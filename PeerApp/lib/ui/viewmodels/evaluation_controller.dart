import 'package:get/get.dart';
import '../../domain/repositories/i_evaluation_repository.dart';
import '../../domain/repositories/i_course_repository.dart';
import '../data/json_backup_storage.dart';

class EvaluationController extends GetxController {
  final IEvaluationRepository _evalRepo;
  final ICourseRepository _courseRepo;

  EvaluationController(this._evalRepo, this._courseRepo);

  final JsonBackupStorage _backupStorage = JsonBackupStorage();
  final Map<String, List<Map<String, dynamic>>> _courseEvaluationsCache = {};
  final Map<String, Map<String, dynamic>> _evaluationResultsCache = {};
  bool _cacheLoaded = false;

  // ── Professor state ────────────────────────────────────────────────────────
  final courseEvaluations = <Map<String, dynamic>>[].obs;
  final isCreating = false.obs;
  final evaluationResults = Rxn<Map<String, dynamic>>();
  final isLoadingResults = false.obs;

  // ── Student state ──────────────────────────────────────────────────────────
  final activeEvaluations = <Map<String, dynamic>>[].obs;
  final myResults = <Map<String, dynamic>>[].obs;
  final currentTeammates = <Map<String, dynamic>>[].obs;
  final isLoadingEvals = false.obs;
  final isSubmitting = false.obs;

  Future<void> _ensureCacheLoaded() async {
    if (_cacheLoaded) return;

    final raw = await _backupStorage.read();
    if (raw != null) {
      final courseCache = raw['courseEvaluationsCache'];
      if (courseCache is Map) {
        for (final entry in courseCache.entries) {
          final courseId = entry.key.toString();
          final evaluations = entry.value;
          if (evaluations is List) {
            _courseEvaluationsCache[courseId] = evaluations
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }
      }

      final resultsCache = raw['evaluationResultsCache'];
      if (resultsCache is Map) {
        for (final entry in resultsCache.entries) {
          final evaluationId = entry.key.toString();
          final result = entry.value;
          if (result is Map) {
            _evaluationResultsCache[evaluationId] =
                Map<String, dynamic>.from(result);
          }
        }
      }
    }

    _cacheLoaded = true;
  }

  Future<void> _persistCache() async {
    await _backupStorage.write({
      'courseEvaluationsCache': _courseEvaluationsCache,
      'evaluationResultsCache': _evaluationResultsCache,
    });
  }

  void _invalidateCourseCache(String courseId) {
    _courseEvaluationsCache.remove(courseId);
  }

  void _invalidateEvaluationCache(String evaluationId) {
    _evaluationResultsCache.remove(evaluationId);
  }

  // ── Professor methods ──────────────────────────────────────────────────────

  Future<void> loadCourseEvaluations(String courseId) async {
    try {
      await _ensureCacheLoaded();

      final cached = _courseEvaluationsCache[courseId];
      if (cached != null) {
        courseEvaluations.assignAll(cached);
        return;
      }

      final evals = await _evalRepo.getEvaluationsForCourse(courseId);
      courseEvaluations.assignAll(evals);
      _courseEvaluationsCache[courseId] = List<Map<String, dynamic>>.from(evals);
      await _persistCache();
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar las evaluaciones: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Creates a single evaluation and shows a snackbar.
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
    isCreating.value = true;
    try {
      await _evalRepo.createEvaluation(
        courseId: courseId,
        courseName: courseName,
        categoryName: categoryName,
        activityName: activityName,
        startDate: startDate,
        endDate: endDate,
        visibility: visibility,
        allowSelfEval: allowSelfEval,
        criteria: criteria,
        professorEmail: professorEmail,
      );
      _invalidateCourseCache(courseId);
      await _persistCache();
      await loadCourseEvaluations(courseId);
      Get.snackbar(
        'Evaluación creada',
        '"$activityName" ha sido creada exitosamente.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isCreating.value = false;
    }
  }

  /// Creates evaluations for multiple categories without showing individual
  /// snackbars. Returns a record of (created count, failed count).
  Future<(int, int)> createEvaluationsForCategories({
    required String courseId,
    required String courseName,
    required List<String> categoryNames,
    required String activityName,
    required DateTime startDate,
    required DateTime endDate,
    required String visibility,
    required bool allowSelfEval,
    required List<String> criteria,
    required String professorEmail,
  }) async {
    isCreating.value = true;
    int created = 0;
    int failed = 0;
    try {
      for (final cat in categoryNames) {
        try {
          await _evalRepo.createEvaluation(
            courseId: courseId,
            courseName: courseName,
            categoryName: cat,
            activityName: activityName,
            startDate: startDate,
            endDate: endDate,
            visibility: visibility,
            allowSelfEval: allowSelfEval,
            criteria: criteria,
            professorEmail: professorEmail,
          );
          created++;
        } catch (_) {
          failed++;
        }
      }
      _invalidateCourseCache(courseId);
      await _persistCache();
      await loadCourseEvaluations(courseId);
    } finally {
      isCreating.value = false;
    }
    return (created, failed);
  }

  Future<void> loadEvaluationResults(String evaluationId) async {
    isLoadingResults.value = true;
    try {
      await _ensureCacheLoaded();

      final cached = _evaluationResultsCache[evaluationId];
      if (cached != null) {
        evaluationResults.value = cached;
        return;
      }

      final results = await _evalRepo.getEvaluationResults(evaluationId);
      evaluationResults.value = results;
      _evaluationResultsCache[evaluationId] = Map<String, dynamic>.from(results);
      await _persistCache();
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar los resultados: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoadingResults.value = false;
    }
  }

  Future<List<String>> getCategoriesForCourse(String courseId) async {
    try {
      return await _courseRepo.getCategoriesForCourse(courseId);
    } catch (_) {
      return [];
    }
  }

  // ── Student methods ────────────────────────────────────────────────────────

  Future<void> loadActiveEvaluations(String email) async {
    isLoadingEvals.value = true;
    try {
      final evals = await _evalRepo.getActiveEvaluationsForStudent(email);
      activeEvaluations.assignAll(evals);
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar las evaluaciones: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoadingEvals.value = false;
    }
  }

  Future<void> loadTeammatesForEvaluation({
    required String evaluationId,
    required String evaluatorEmail,
  }) async {
    try {
      final teammates = await _evalRepo.getTeammatesForEvaluation(
        evaluationId: evaluationId,
        evaluatorEmail: evaluatorEmail,
      );
      currentTeammates.assignAll(teammates);
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar los compañeros: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<bool> submitResponse({
    required String evaluationId,
    required String evaluatorEmail,
    required String evaluateeEmail,
    required Map<String, int> scores,
  }) async {
    isSubmitting.value = true;
    try {
      await _evalRepo.submitEvaluationResponse(
        evaluationId: evaluationId,
        evaluatorEmail: evaluatorEmail,
        evaluateeEmail: evaluateeEmail,
        scores: scores,
      );
      _invalidateEvaluationCache(evaluationId);
      await _persistCache();
      await loadTeammatesForEvaluation(
        evaluationId: evaluationId,
        evaluatorEmail: evaluatorEmail,
      );
      await loadActiveEvaluations(evaluatorEmail);
      return true;
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> loadMyResults(String email) async {
    try {
      final results = await _evalRepo.getStudentResults(email);
      myResults.assignAll(results);
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar tus resultados: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}