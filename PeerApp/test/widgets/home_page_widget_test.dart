import 'package:f_getxstate_demo/ui/viewmodels/auth_controller.dart';
import 'package:f_getxstate_demo/ui/viewmodels/evaluation_controller.dart';
import 'package:f_getxstate_demo/ui/viewmodels/professor_controller.dart';
import 'package:f_getxstate_demo/ui/viewmodels/student_controller.dart';
import 'package:f_getxstate_demo/ui/views/home/home_page.dart';
import 'package:f_getxstate_demo/ui/views/professor/professor_home_page.dart';
import 'package:f_getxstate_demo/ui/views/student/student_home_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../support/fakes.dart';

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('HomePage muestra panel docente cuando el rol es Docente',
      (tester) async {
    final authRepo = FakeAuthRepository()..role = 'Docente';
    final controller = AuthController(authRepo);
    controller.selectedRole.value = 'Docente';
    Get.put<AuthController>(controller);
    Get.put<ProfessorController>(ProfessorController(FakeCourseRepository()));

    await tester.pumpWidget(const GetMaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    expect(find.byType(ProfessorHomePage), findsOneWidget);
  });

  testWidgets('HomePage muestra panel estudiante cuando el rol es Estudiante',
      (tester) async {
    final authRepo = FakeAuthRepository()..role = 'Estudiante';
    final controller = AuthController(authRepo);
    controller.selectedRole.value = 'Estudiante';
    Get.put<AuthController>(controller);
    final courseRepo = FakeCourseRepository()..email = 'student@uninorte.edu.co';
    Get.put<StudentController>(StudentController(courseRepo));
    Get.put<EvaluationController>(EvaluationController(FakeEvaluationRepository(), courseRepo));

    await tester.pumpWidget(const GetMaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    expect(find.byType(StudentHomePage), findsOneWidget);
  });
}
