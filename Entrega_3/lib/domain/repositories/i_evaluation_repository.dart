abstract class IEvaluationRepository {
  /// Crea una nueva evaluación.
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
  });

  /// Retorna todas las evaluaciones de un curso.
  Future<List<Map<String, dynamic>>> getEvaluationsForCourse(String courseId);

  /// Retorna evaluaciones activas para un estudiante.
  Future<List<Map<String, dynamic>>> getActiveEvaluationsForStudent(String email);

  /// Retorna compañeros a evaluar en una evaluación específica.
  Future<List<Map<String, dynamic>>> getTeammatesForEvaluation({
    required String evaluationId,
    required String evaluatorEmail,
  });

  /// Envía o actualiza la evaluación de un compañero.
  Future<void> submitEvaluationResponse({
    required String evaluationId,
    required String evaluatorEmail,
    required String evaluateeEmail,
    required Map<String, int> scores,
  });

  /// Retorna resultados de una evaluación (vista del profesor).
  Future<Map<String, dynamic>> getEvaluationResults(String evaluationId);

  /// Retorna los resultados propios del estudiante en una evaluación.
  Future<Map<String, dynamic>?> getMyResults({
    required String evaluationId,
    required String studentEmail,
  });

  /// Retorna todos los resultados del estudiante.
  Future<List<Map<String, dynamic>>> getStudentResults(String email);
}