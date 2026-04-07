import 'package:get/get.dart';
import '../data/demo_course_store.dart';

class EvaluationController extends GetxController {
  final DemoCourseStore _store;

  EvaluationController({DemoCourseStore? store})
      : _store = store ?? DemoCourseStore();

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
    final evals = await _store.getEvaluationsForCourse(courseId);
    courseEvaluations.assignAll(evals);
  }

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
      await _store.createEvaluation(
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

  Future<void> loadEvaluationResults(String evaluationId) async {
    isLoadingResults.value = true;
    try {
      final results = await _store.getEvaluationResults(evaluationId);
      evaluationResults.value = results;
    } finally {
      isLoadingResults.value = false;
    }
  }

  Future<List<String>> getCategoriesForCourse(String courseId) async {
    return await _store.getCategoriesForCourse(courseId);
  }

  // ── Student methods ────────────────────────────────────────────────────────

  Future<void> loadActiveEvaluations(String email) async {
    isLoadingEvals.value = true;
    try {
      final evals = await _store.getActiveEvaluationsForStudent(email);
      activeEvaluations.assignAll(evals);
    } finally {
      isLoadingEvals.value = false;
    }
  }

  Future<void> loadTeammatesForEvaluation({
    required String evaluationId,
    required String evaluatorEmail,
  }) async {
    final teammates = await _store.getTeammatesForEvaluation(
      evaluationId: evaluationId,
      evaluatorEmail: evaluatorEmail,
    );
    currentTeammates.assignAll(teammates);
  }

  Future<bool> submitResponse({
    required String evaluationId,
    required String evaluatorEmail,
    required String evaluateeEmail,
    required Map<String, int> scores,
  }) async {
    isSubmitting.value = true;
    try {
      await _store.submitEvaluationResponse(
        evaluationId: evaluationId,
        evaluatorEmail: evaluatorEmail,
        evaluateeEmail: evaluateeEmail,
        scores: scores,
      );
      // Refresh teammates list
      await loadTeammatesForEvaluation(
        evaluationId: evaluationId,
        evaluatorEmail: evaluatorEmail,
      );
      // Refresh active evaluations
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
    final results = await _store.getStudentResults(email);
    myResults.assignAll(results);
  }
}