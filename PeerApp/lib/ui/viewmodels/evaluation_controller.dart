import 'package:get/get.dart';
import '../../domain/repositories/i_evaluation_repository.dart';
import '../../domain/repositories/i_course_repository.dart';

class EvaluationController extends GetxController {
  final IEvaluationRepository _evalRepo;
  final ICourseRepository _courseRepo;

  EvaluationController(this._evalRepo, this._courseRepo);

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

  // ── Professor methods ──────────────────────────────────────────────────────

  Future<void> loadCourseEvaluations(String courseId) async {
    try {
      final evals = await _evalRepo.getEvaluationsForCourse(courseId);
      courseEvaluations.assignAll(evals);
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
      await loadCourseEvaluations(courseId);
    } finally {
      isCreating.value = false;
    }
    return (created, failed);
  }

  Future<void> loadEvaluationResults(String evaluationId) async {
    isLoadingResults.value = true;
    try {
      final results = await _evalRepo.getEvaluationResults(evaluationId);
      evaluationResults.value = results;
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