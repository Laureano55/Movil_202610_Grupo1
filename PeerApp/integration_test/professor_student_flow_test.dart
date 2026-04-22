import 'dart:convert';

import 'package:f_getxstate_demo/core/roble_database_service.dart';
import 'package:f_getxstate_demo/data/repositories/course_repository_impl.dart';
import 'package:f_getxstate_demo/data/repositories/evaluation_repository_impl.dart';
import 'package:f_getxstate_demo/ui/viewmodels/evaluation_controller.dart';
import 'package:f_getxstate_demo/ui/viewmodels/professor_controller.dart';
import 'package:f_getxstate_demo/ui/viewmodels/student_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemoryRobleApi {
  final Map<String, List<Map<String, dynamic>>> tables;
  final Map<String, int> _idCounter = {};

  _InMemoryRobleApi(this.tables);

  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path;
    if (path.endsWith('/read')) {
      return _read(request);
    }
    if (path.endsWith('/insert')) {
      return _insert(request);
    }
    if (path.endsWith('/update')) {
      return _update(request);
    }
    if (path.endsWith('/delete')) {
      return _delete(request);
    }
    return http.Response('Not found', 404);
  }

  http.Response _read(http.Request request) {
    final tableName = request.url.queryParameters['tableName'];
    if (tableName == null) return http.Response('Missing tableName', 400);
    final rows = List<Map<String, dynamic>>.from(tables[tableName] ?? []);

    final filters = Map<String, String>.from(request.url.queryParameters)
      ..remove('tableName');

    final filtered = rows.where((row) {
      for (final entry in filters.entries) {
        if ((row[entry.key] ?? '').toString() != entry.value) {
          return false;
        }
      }
      return true;
    }).toList();

    return http.Response(jsonEncode(filtered), 200);
  }

  http.Response _insert(http.Request request) {
    final payload = jsonDecode(request.body) as Map<String, dynamic>;
    final tableName = payload['tableName']?.toString();
    final records = (payload['records'] as List?)?.cast<Map>() ?? [];
    if (tableName == null) return http.Response('Missing tableName', 400);

    final table = tables.putIfAbsent(tableName, () => <Map<String, dynamic>>[]);
    for (final raw in records) {
      final row = Map<String, dynamic>.from(raw.cast<String, dynamic>());
      row['_id'] ??= _nextId(tableName);
      table.add(row);
    }
    return http.Response('{}', 201);
  }

  http.Response _update(http.Request request) {
    final payload = jsonDecode(request.body) as Map<String, dynamic>;
    final tableName = payload['tableName']?.toString();
    final idColumn = payload['idColumn']?.toString();
    final idValue = payload['idValue']?.toString();
    final updates = Map<String, dynamic>.from(
      (payload['updates'] as Map).cast<String, dynamic>(),
    );

    if (tableName == null || idColumn == null || idValue == null) {
      return http.Response('Bad request', 400);
    }

    final table = tables[tableName] ?? [];
    final idx = table.indexWhere((row) => (row[idColumn] ?? '').toString() == idValue);
    if (idx >= 0) {
      table[idx] = {
        ...table[idx],
        ...updates,
      };
    }
    return http.Response('{}', 200);
  }

  http.Response _delete(http.Request request) {
    final payload = jsonDecode(request.body) as Map<String, dynamic>;
    final tableName = payload['tableName']?.toString();
    final idColumn = payload['idColumn']?.toString();
    final idValue = payload['idValue']?.toString();

    if (tableName == null || idColumn == null || idValue == null) {
      return http.Response('Bad request', 400);
    }

    final table = tables[tableName] ?? [];
    table.removeWhere((row) => (row[idColumn] ?? '').toString() == idValue);
    return http.Response('{}', 200);
  }

  String _nextId(String tableName) {
    final next = (_idCounter[tableName] ?? 0) + 1;
    _idCounter[tableName] = next;
    return '$tableName-$next';
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Flujo completo profesor/estudiante con MockClient', (tester) async {
    SharedPreferences.setMockInitialValues({
      'token': 'token-demo',
      'email': 'teacher@uninorte.edu.co',
    });

    final dbState = <String, List<Map<String, dynamic>>>{
      'courses': [],
      'course_members': [],
      'evaluations': [],
      'evaluation_responses': [],
    };

    final api = _InMemoryRobleApi(dbState);
    final client = MockClient((request) => api.handle(request));

    final db = RobleDatabaseService(client: client);
    final courseRepo = CourseRepositoryImpl(db);
    final evaluationRepo = EvaluationRepositoryImpl(db);

    // Profesor crea curso y carga resumen.
    await courseRepo.createCourse(title: 'Arquitectura Limpia', code: 'ACL-101');
    final professorCourses =
        await courseRepo.professorCourseSummaries('teacher@uninorte.edu.co');
    expect(professorCourses, isNotEmpty);
    final courseId = professorCourses.first['id'].toString();

    // Importa estudiantes y grupos.
    await courseRepo.importCsvData(
      courseId: courseId,
      courseCode: 'ACL-101',
      categories: {'G1', 'G2'},
      members: [
        {
          'email': 'student1@uninorte.edu.co',
          'category': 'G1',
          'name': 'Ana',
          'last_name': 'Rios',
        },
        {
          'email': 'student2@uninorte.edu.co',
          'category': 'G1',
          'name': 'Luis',
          'last_name': 'Paz',
        },
        {
          'email': 'student3@uninorte.edu.co',
          'category': 'G2',
          'name': 'Maria',
          'last_name': 'Diaz',
        },
        {
          'email': 'student4@uninorte.edu.co',
          'category': 'G2',
          'name': 'Juan',
          'last_name': 'Soto',
        },
      ],
    );

    // Crea evaluaciones por grupo para la misma actividad.
    final now = DateTime.now();
    await evaluationRepo.createEvaluation(
      courseId: courseId,
      courseName: 'Arquitectura Limpia',
      categoryName: 'G1',
      activityName: 'Sprint 1',
      startDate: now.subtract(const Duration(days: 1)),
      endDate: now.add(const Duration(days: 1)),
      visibility: 'public',
      allowSelfEval: false,
      criteria: ['Trabajo', 'Comunicacion'],
      professorEmail: 'teacher@uninorte.edu.co',
    );
    await evaluationRepo.createEvaluation(
      courseId: courseId,
      courseName: 'Arquitectura Limpia',
      categoryName: 'G2',
      activityName: 'Sprint 1',
      startDate: now.subtract(const Duration(days: 1)),
      endDate: now.add(const Duration(days: 1)),
      visibility: 'public',
      allowSelfEval: false,
      criteria: ['Trabajo', 'Comunicacion'],
      professorEmail: 'teacher@uninorte.edu.co',
    );

    final evals = await evaluationRepo.getEvaluationsForCourse(courseId);
    expect(evals.length, 2);
    final evalG1 = evals.firstWhere((e) => e['categoryName'] == 'G1');
    final evalG2 = evals.firstWhere((e) => e['categoryName'] == 'G2');

    // Estudiantes responden evaluación en cada grupo.
    await evaluationRepo.submitEvaluationResponse(
      evaluationId: evalG1['id'].toString(),
      evaluatorEmail: 'student1@uninorte.edu.co',
      evaluateeEmail: 'student2@uninorte.edu.co',
      scores: {'Trabajo': 4, 'Comunicacion': 5},
    );
    await evaluationRepo.submitEvaluationResponse(
      evaluationId: evalG1['id'].toString(),
      evaluatorEmail: 'student2@uninorte.edu.co',
      evaluateeEmail: 'student1@uninorte.edu.co',
      scores: {'Trabajo': 3, 'Comunicacion': 4},
    );
    await evaluationRepo.submitEvaluationResponse(
      evaluationId: evalG2['id'].toString(),
      evaluatorEmail: 'student3@uninorte.edu.co',
      evaluateeEmail: 'student4@uninorte.edu.co',
      scores: {'Trabajo': 5, 'Comunicacion': 5},
    );
    await evaluationRepo.submitEvaluationResponse(
      evaluationId: evalG2['id'].toString(),
      evaluatorEmail: 'student4@uninorte.edu.co',
      evaluateeEmail: 'student3@uninorte.edu.co',
      scores: {'Trabajo': 4, 'Comunicacion': 4},
    );

    // Verificación de reporte por evaluación y promedio del curso.
    final resultsG1 = await evaluationRepo.getEvaluationResults(evalG1['id'].toString());
    expect(resultsG1['averageEvaluation'], greaterThan(0));
    expect((resultsG1['byGroup'] as Map).isNotEmpty, isTrue);
    expect(resultsG1['averageCourse'], greaterThan(0));

    final evaluationsWithAverages = await evaluationRepo.getEvaluationsForCourse(courseId);
    expect(
      evaluationsWithAverages.every(
        (e) => (e['averageEvaluation'] as double?) != null,
      ),
      isTrue,
    );
    expect(
      evaluationsWithAverages.every(
        (e) => (e['averageCourse'] as double?) != null,
      ),
      isTrue,
    );

    // Flujo de controladores profesor/estudiante.
    final professorController = ProfessorController(courseRepo);
    final studentController = StudentController(courseRepo);
    final evalController = EvaluationController(evaluationRepo, courseRepo);

    await professorController.loadCourses();
    expect(professorController.courses.isNotEmpty, isTrue);

    await evalController.loadCourseEvaluations(courseId);
    expect(evalController.courseEvaluations.length, 2);

    await evalController.loadEvaluationResults(evalG1['id'].toString());
    expect(evalController.evaluationResults.value, isNotNull);

    // Cambia sesión al estudiante para flujo de evaluaciones activas.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', 'student1@uninorte.edu.co');

    await studentController.loadEnrolledCourses();
    expect(studentController.enrolledCourses, isNotEmpty);

    await evalController.loadActiveEvaluations('student1@uninorte.edu.co');
    expect(evalController.activeEvaluations.isNotEmpty, isTrue);
  });
}
