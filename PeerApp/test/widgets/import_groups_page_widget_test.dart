import 'package:f_getxstate_demo/ui/viewmodels/csv_import_controller.dart';
import 'package:f_getxstate_demo/ui/viewmodels/professor_controller.dart';
import 'package:f_getxstate_demo/ui/views/professor/import_groups_page.dart';
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

  testWidgets('ImportGroupsPage muestra formato CSV y selector de curso',
      (tester) async {
    final courseRepo = FakeCourseRepository()
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

    Get.put<ProfessorController>(ProfessorController(courseRepo));
  Get.put<ICourseRepository>(courseRepo);
    Get.put<CsvImportController>(CsvImportController(courseRepo));

    await tester.pumpWidget(
      const GetMaterialApp(home: ImportGroupsPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Importar grupos CSV'), findsOneWidget);
    expect(find.text('Formato CSV requerido'), findsOneWidget);
    expect(find.text('Seleccionar curso'), findsOneWidget);
    expect(find.text('Seleccionar y subir CSV'), findsOneWidget);
  });
}
