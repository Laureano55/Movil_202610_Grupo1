import 'package:f_getxstate_demo/ui/viewmodels/professor_controller.dart';
import 'package:f_getxstate_demo/ui/views/professor/professor_home_page.dart';
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

  testWidgets('ProfessorHomePage muestra cursos y acciones rapidas',
      (tester) async {
    final fakeRepo = FakeCourseRepository()
      ..email = 'teacher@uninorte.edu.co'
      ..professorSummaries.addAll([
        {
          'id': 'c1',
          'title': 'Arquitectura de Software',
          'code': 'ISW-1001',
          'studentCount': 10,
          'groupCount': 2,
          'pendingEvals': 1,
        }
      ]);

    Get.put<ProfessorController>(ProfessorController(fakeRepo));

    await tester.pumpWidget(
      const GetMaterialApp(home: ProfessorHomePage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Panel del Docente'), findsOneWidget);
    expect(find.text('Mis cursos'), findsOneWidget);
    expect(find.text('Arquitectura de Software'), findsOneWidget);
    expect(find.text('Importar grupos'), findsOneWidget);
    expect(find.text('Ver estadísticas'), findsOneWidget);
  });

  testWidgets('ProfessorHomePage muestra estado vacio sin cursos',
      (tester) async {
    final fakeRepo = FakeCourseRepository()..email = 'teacher@uninorte.edu.co';
    Get.put<ProfessorController>(ProfessorController(fakeRepo));

    await tester.pumpWidget(
      const GetMaterialApp(home: ProfessorHomePage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes cursos'), findsOneWidget);
    expect(find.text('Crear primer curso'), findsOneWidget);
  });
}
