class CourseMemberModel {
  final String? id;
  final String courseId;
  final String email;
  final String categoryName;
  final String name;
  final String lastName;

  const CourseMemberModel({
    this.id,
    required this.courseId,
    required this.email,
    required this.categoryName,
    required this.name,
    required this.lastName,
  });

  factory CourseMemberModel.fromJson(Map<String, dynamic> json) =>
      CourseMemberModel(
        id: json['_id']?.toString(),
        courseId: json['course_id']?.toString() ?? '',
        email: json['email']?.toString().toLowerCase().trim() ?? '',
        categoryName: json['category_name']?.toString().trim() ?? '',
        name: json['name']?.toString().trim() ?? '',
        lastName: json['last_name']?.toString().trim() ?? '',
      );

  Map<String, dynamic> toInsertJson() => {
        'course_id': courseId,
        'email': email.toLowerCase().trim(),
        'category_name': categoryName.trim(),
        'name': name.trim(),
        'last_name': lastName.trim(),
      };

  String get fullName {
    final full = '$name $lastName'.trim();
    return full.isEmpty ? email : full;
  }
}