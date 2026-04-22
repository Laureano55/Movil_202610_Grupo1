import 'package:f_getxstate_demo/ui/viewmodels/professor_controller.dart';
import 'package:f_getxstate_demo/ui/views/professor/course_groups_page.dart';
import 'package:f_getxstate_demo/domain/repositories/i_course_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../support/fakes.dart';

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('CourseGroupsPage muestra grupos y acciones principales',
      (tester) async {
    final courseRepo = FakeCourseRepository()
      ..groups.addAll([
        {
          'groupName': 'G1',
          'memberCount': 2,
          'members': [
            {'name': 'Ana', 'email': 'ana@uninorte.edu.co'},
            {'name': 'Luis', 'email': 'luis@uninorte.edu.co'},
          ],
        }
      ]);

    Get.put<ProfessorController>(ProfessorController(courseRepo));
  Get.put<ICourseRepository>(courseRepo);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: CourseGroupsPage(
          courseId: 'c1',
          courseTitle: 'Arquitectura de Software',
          courseCode: 'ISW-1001',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Arquitectura de Software'), findsOneWidget);
    expect(find.text('ISW-1001'), findsOneWidget);
    expect(find.text('1 grupos'), findsWidgets);
    expect(find.text('Crear Evaluación'), findsOneWidget);
    expect(find.text('Ver Resultados'), findsOneWidget);
    expect(find.text('Sync CSV'), findsOneWidget);
  });
}
