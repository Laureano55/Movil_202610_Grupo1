class CourseModel {
  final String? id;
  final String title;
  final String code;
  final String professorEmail;

  const CourseModel({
    this.id,
    required this.title,
    required this.code,
    required this.professorEmail,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
        id: json['_id']?.toString(),
        title: json['title']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        professorEmail: json['professor_email']?.toString() ?? '',
      );

  Map<String, dynamic> toInsertJson() => {
        'title': title,
        'code': code,
        'professor_email': professorEmail,
      };
}