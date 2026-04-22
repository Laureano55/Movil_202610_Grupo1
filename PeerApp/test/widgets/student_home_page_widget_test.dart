import 'package:f_getxstate_demo/ui/viewmodels/evaluation_controller.dart';
import 'package:f_getxstate_demo/ui/viewmodels/student_controller.dart';
import 'package:f_getxstate_demo/ui/views/student/student_home_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';

void main() {
  setUp(() {
    Get.reset();
    SharedPreferences.setMockInitialValues({
      'email': 'student@uninorte.edu.co',
    });
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('StudentHomePage muestra cursos y acciones rapidas',
      (tester) async {
    final courseRepo = FakeCourseRepository()
      ..email = 'student@uninorte.edu.co'
      ..studentCourseRows.addAll([
        {
          'id': 'c1',
          'title': 'Arquitectura de Software',
          'code': 'ISW-1001',
          'professor': 'teacher@uninorte.edu.co',
          'myGroup': 'G1',
          'activeEvals': 1,
          'completedEvals': 0,
          'totalEvals': 2,
        }
      ]);

    final evalRepo = FakeEvaluationRepository()
      ..activeByEmail['student@uninorte.edu.co'] = [
        {
          'id': 'e1',
          'activityName': 'Sprint 1',
          'courseName': 'Arquitectura de Software',
          'myGroup': 'G1',
          'pendingRatings': 1,
          'totalRatable': 2,
          'completed': false,
          'endDate': DateTime.now().add(const Duration(hours: 5)).toIso8601String(),
        }
      ];

    final studentController = StudentController(courseRepo);
    final evaluationController = EvaluationController(evalRepo, courseRepo);
    Get.put<StudentController>(studentController);
    Get.put<EvaluationController>(evaluationController);

    await studentController.loadEnrolledCourses();
    await evaluationController.loadActiveEvaluations('student@uninorte.edu.co');

    await tester.pumpWidget(
      const GetMaterialApp(home: StudentHomePage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Panel del Estudiante'), findsOneWidget);
    expect(find.text('Mis cursos'), findsOneWidget);
    expect(find.text('Arquitectura de Software'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Acciones rápidas'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acciones rápidas'), findsOneWidget);
  });
}
