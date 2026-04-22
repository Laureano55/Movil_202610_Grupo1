import 'package:get/get.dart';

import 'package:f_getxstate_demo/auth/domain/models/authentication_user.dart';
import 'package:f_getxstate_demo/auth/domain/repositories/i_auth_repository.dart';
import 'package:f_getxstate_demo/domain/models/course_member_model.dart';
import 'package:f_getxstate_demo/domain/repositories/i_course_repository.dart';
import 'package:f_getxstate_demo/domain/repositories/i_evaluation_repository.dart';

class FakeAuthRepository implements IAuthRepository {
  bool shouldFailLogin = false;
  bool tokenValid = true;
  String? role = 'Estudiante';
  String? loggedEmail;

  @override
  Future<void> login(String email, String password) async {
    if (shouldFailLogin) {
      throw Exception('Credenciales invalidas');
    }
    loggedEmail = email;
  }

  @override
  Future<void> signUp(
    String email,
    String password,
    String name,
    bool direct, {
    String lastName = '',
    String role = 'Estudiante',
  }) async {
    loggedEmail = email;
    this.role = role;
  }

  @override
  Future<bool> logOut() async {
    loggedEmail = null;
    return true;
  }

  @override
  Future<bool> validate(String email, String validationCode) async => true;

  @override
  Future<bool> validateToken() async => tokenValid;

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  Future<String?> getAccountRoleByEmail(String email) async => role;

  @override
  Future<AuthenticationUser> getLoggedUser() async => AuthenticationUser(
        email: loggedEmail ?? 'demo@uninorte.edu.co',
        name: 'Demo User',
      );

  @override
  Future<List<AuthenticationUser>> getUsers() async => [];
}

class FakeCourseRepository implements ICourseRepository {
  String? email = 'docente@uninorte.edu.co';
  final List<Map<String, dynamic>> professorSummaries = [];
  final List<Map<String, dynamic>> studentCourseRows = [];
  final List<Map<String, dynamic>> groups = [];
  final Map<String, dynamic> classmates = {
    'myGroup': 'G1',
    'classmates': <Map<String, String>>[],
  };
  final List<String> categories = [];
  final List<CourseMemberModel> members = [];

  @override
  Future<void> createCourse({required String title, required String code}) async {
    professorSummaries.add({
      'id': 'course-${professorSummaries.length + 1}',
      'title': title,
      'code': code,
      'studentCount': 0,
      'groupCount': 0,
      'pendingEvals': 0,
    });
  }

  @override
  Future<void> deleteCourse(String courseId) async {
    professorSummaries.removeWhere((c) => c['id'] == courseId);
  }

  @override
  Future<List<Map<String, dynamic>>> professorCourseSummaries(String professorEmail) async {
    return List<Map<String, dynamic>>.from(professorSummaries);
  }

  @override
  Future<bool> enrollByCourseCode({required String email, required String courseCode}) async {
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> studentCourses(String email) async {
    return List<Map<String, dynamic>>.from(studentCourseRows);
  }

  @override
  Future<void> importCsvData({
    required String courseId,
    required String courseCode,
    required Set<String> categories,
    required List<Map<String, dynamic>> members,
  }) async {}

  @override
  Future<List<Map<String, dynamic>>> professorCourseGroups(String courseId) async {
    return List<Map<String, dynamic>>.from(groups);
  }

  @override
  Future<Map<String, dynamic>> studentCourseClassmates({required String courseId, required String email}) async {
    return Map<String, dynamic>.from(classmates);
  }

  @override
  Future<List<String>> getCategoriesForCourse(String courseId) async {
    return List<String>.from(categories);
  }

  @override
  Future<List<CourseMemberModel>> getMembersByCourse(String courseId) async {
    return List<CourseMemberModel>.from(members);
  }

  @override
  Future<String?> currentEmail() async => email;
}

class FakeEvaluationRepository implements IEvaluationRepository {
  final Map<String, List<Map<String, dynamic>>> evalsByCourse = {};
  final Map<String, Map<String, dynamic>> resultsByEval = {};
  final Map<String, List<Map<String, dynamic>>> activeByEmail = {};
  final Map<String, List<Map<String, dynamic>>> teammatesByEval = {};
  final Map<String, List<Map<String, dynamic>>> studentResultsByEmail = {};

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
    final list = evalsByCourse.putIfAbsent(courseId, () => []);
    list.add({
      'id': 'eval-${list.length + 1}',
      'courseId': courseId,
      'courseName': courseName,
      'categoryName': categoryName,
      'activityName': activityName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'visibility': visibility,
      'allowSelfEval': allowSelfEval,
      'criteria': criteria,
      'status': 'active',
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getEvaluationsForCourse(String courseId) async {
    return List<Map<String, dynamic>>.from(evalsByCourse[courseId] ?? []);
  }

  @override
  Future<List<Map<String, dynamic>>> getActiveEvaluationsForStudent(String email) async {
    return List<Map<String, dynamic>>.from(activeByEmail[email] ?? []);
  }

  @override
  Future<List<Map<String, dynamic>>> getTeammatesForEvaluation({
    required String evaluationId,
    required String evaluatorEmail,
  }) async {
    return List<Map<String, dynamic>>.from(teammatesByEval[evaluationId] ?? []);
  }

  @override
  Future<void> submitEvaluationResponse({
    required String evaluationId,
    required String evaluatorEmail,
    required String evaluateeEmail,
    required Map<String, int> scores,
  }) async {}

  @override
  Future<Map<String, dynamic>> getEvaluationResults(String evaluationId) async {
    return Map<String, dynamic>.from(resultsByEval[evaluationId] ?? {
      'evaluation': {
        'id': evaluationId,
        'criteria': <String>['C1', 'C2'],
      },
      'byStudent': <Map<String, dynamic>>[],
      'byGroup': <String, Map<String, dynamic>>{},
      'averageEvaluation': 0.0,
      'averageCourse': 0.0,
      'overall': 0.0,
      'totalResponses': 0,
    });
  }

  @override
  Future<Map<String, dynamic>?> getMyResults({
    required String evaluationId,
    required String studentEmail,
  }) async {
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentResults(String email) async {
    return List<Map<String, dynamic>>.from(studentResultsByEmail[email] ?? []);
  }
}

void resetTestGet() {
  if (Get.isRegistered<GetxController>()) {
    // no-op marker to keep analyzer happy on generic cleanup branch
  }
  Get.reset();
}
