import 'dart:convert';

class EvaluationModel {
  final String? id;
  final String courseId;
  final String courseName;
  final String categoryName;
  final String activityName;
  final DateTime startDate;
  final DateTime endDate;
  final String visibility; // 'public' | 'private'
  final bool allowSelfEval;
  final List<String> criteria;
  final String createdBy;
  final String status; // 'draft' | 'active' | 'closed'

  const EvaluationModel({
    this.id,
    required this.courseId,
    required this.courseName,
    required this.categoryName,
    required this.activityName,
    required this.startDate,
    required this.endDate,
    required this.visibility,
    required this.allowSelfEval,
    required this.criteria,
    required this.createdBy,
    required this.status,
  });

  factory EvaluationModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedCriteria = [];
    final criteriaRaw = json['criteria'];
    if (criteriaRaw is String && criteriaRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(criteriaRaw);
        if (decoded is List) {
          parsedCriteria = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        parsedCriteria =
            criteriaRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }

    return EvaluationModel(
      id: json['_id']?.toString(),
      courseId: json['course_id']?.toString() ?? '',
      courseName: json['course_name']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
      activityName: json['activity_name']?.toString() ?? '',
      startDate:
          DateTime.tryParse(json['start_date']?.toString() ?? '') ?? DateTime.now(),
      endDate:
          DateTime.tryParse(json['end_date']?.toString() ?? '') ?? DateTime.now(),
      visibility: json['visibility']?.toString() ?? 'private',
      allowSelfEval:
          json['allow_self_eval'] == true || json['allow_self_eval'] == 'true',
      criteria: parsedCriteria,
      createdBy: json['created_by']?.toString() ?? '',
      status: json['status']?.toString() ?? 'draft',
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'course_id': courseId,
        'course_name': courseName,
        'category_name': categoryName,
        'activity_name': activityName,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'visibility': visibility,
        'allow_self_eval': allowSelfEval,
        'criteria': jsonEncode(criteria),
        'created_by': createdBy,
        'status': computedStatus,
      };

  /// Calcula el status en base a las fechas actuales.
  String get computedStatus {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 'closed';
    if (now.isAfter(startDate)) return 'active';
    return 'draft';
  }

  EvaluationModel withComputedStatus() => EvaluationModel(
        id: id,
        courseId: courseId,
        courseName: courseName,
        categoryName: categoryName,
        activityName: activityName,
        startDate: startDate,
        endDate: endDate,
        visibility: visibility,
        allowSelfEval: allowSelfEval,
        criteria: criteria,
        createdBy: createdBy,
        status: computedStatus,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'courseId': courseId,
        'courseName': courseName,
        'categoryName': categoryName,
        'activityName': activityName,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'visibility': visibility,
        'allowSelfEval': allowSelfEval,
        'criteria': criteria,
        'createdBy': createdBy,
        'status': computedStatus,
      };
}