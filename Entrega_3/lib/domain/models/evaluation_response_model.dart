import 'dart:convert';

class EvaluationResponseModel {
  final String? id;
  final String evaluationId;
  final String evaluatorEmail;
  final String evaluateeEmail;
  final Map<String, int> scores;
  final String submittedAt;

  const EvaluationResponseModel({
    this.id,
    required this.evaluationId,
    required this.evaluatorEmail,
    required this.evaluateeEmail,
    required this.scores,
    required this.submittedAt,
  });

  factory EvaluationResponseModel.fromJson(Map<String, dynamic> json) {
    Map<String, int> parsedScores = {};
    final scoresRaw = json['scores'];
    if (scoresRaw is String && scoresRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(scoresRaw);
        if (decoded is Map) {
          parsedScores = decoded
              .map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
        }
      } catch (_) {}
    } else if (scoresRaw is Map) {
      parsedScores =
          scoresRaw.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }

    return EvaluationResponseModel(
      id: json['_id']?.toString(),
      evaluationId: json['evaluation_id']?.toString() ?? '',
      evaluatorEmail:
          json['evaluator_email']?.toString().toLowerCase().trim() ?? '',
      evaluateeEmail:
          json['evaluatee_email']?.toString().toLowerCase().trim() ?? '',
      scores: parsedScores,
      submittedAt: json['submitted_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'evaluation_id': evaluationId,
        'evaluator_email': evaluatorEmail.toLowerCase().trim(),
        'evaluatee_email': evaluateeEmail.toLowerCase().trim(),
        'scores': jsonEncode(scores),
        'submitted_at': submittedAt,
      };
}