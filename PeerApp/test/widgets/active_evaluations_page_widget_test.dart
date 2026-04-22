import 'package:f_getxstate_demo/ui/viewmodels/evaluation_controller.dart';
import 'package:f_getxstate_demo/ui/views/student/active_evaluations_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';

void main() {
  setUp(() {
    Get.reset();
    SharedPreferences.setMockInitialValues({'email': 'student1@uninorte.edu.co'});
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('ActiveEvaluationsPage muestra pendientes y completadas',
      (tester) async {
    final fakeCourseRepo = FakeCourseRepository()..email = 'student1@uninorte.edu.co';
    final fakeEvalRepo = FakeEvaluationRepository()
      ..activeByEmail['student1@uninorte.edu.co'] = [
        {
          'id': 'e1',
          'activityName': 'Sprint 1',
          'courseName': 'ISW',
          'myGroup': 'G1',
          'pendingRatings': 1,
          'totalRatable': 2,
          'completed': false,
          'endDate': DateTime.now().add(const Duration(hours: 5)).toIso8601String(),
        },
        {
          'id': 'e2',
          'activityName': 'Sprint 2',
          'courseName': 'ISW',
          'myGroup': 'G1',
          'pendingRatings': 0,
          'totalRatable': 2,
          'completed': true,
          'endDate': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        },
      ];

    Get.put<EvaluationController>(
      EvaluationController(fakeEvalRepo, fakeCourseRepo),
    );

    await tester.pumpWidget(
      const GetMaterialApp(home: ActiveEvaluationsPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Por completar (1)'), findsOneWidget);
    expect(find.text('Completadas (1)'), findsOneWidget);
    expect(find.text('Sprint 1'), findsOneWidget);
    expect(find.text('Sprint 2'), findsOneWidget);
  });
}
