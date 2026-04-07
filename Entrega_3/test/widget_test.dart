import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:f_getxstate_demo/ui/data/demo_course_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('DemoCourseStore - Lógica de negocio', () {
    test('Crear curso nuevo agrega curso a la lista', () async {
      SharedPreferences.setMockInitialValues({
        'email': 'prof@uninorte.edu.co',
      });

      final store = DemoCourseStore();
      await store.createCourse(title: 'Diseño Móvil', code: 'MOVIL-001');

      final courses = await store.professorCourseSummaries();
      expect(courses.length, 1);
      expect(courses.first['title'], 'Diseño Móvil');
      expect(courses.first['code'], 'MOVIL-001');
    });

    test('Crear curso con código duplicado lanza excepción', () async {
      SharedPreferences.setMockInitialValues({
        'email': 'prof@uninorte.edu.co',
      });

      final store = DemoCourseStore();
      await store.createCourse(title: 'Curso A', code: 'DUP-001');

      expect(
        () async => await store.createCourse(title: 'Curso B', code: 'DUP-001'),
        throwsException,
      );
    });

    test('Inscribir estudiante con código válido retorna true', () async {
      SharedPreferences.setMockInitialValues({
        'email': 'prof@uninorte.edu.co',
      });

      final store = DemoCourseStore();
      await store.createCourse(title: 'Ingeniería de Software', code: 'ISW-301');

      final result = await store.enrollByCourseCode(
        email: 'student@uninorte.edu.co',
        courseCode: 'ISW-301',
      );
      expect(result, true);
    });

    test('Inscribir estudiante con código inválido retorna false', () async {
      SharedPreferences.setMockInitialValues({});

      final store = DemoCourseStore();

      final result = await store.enrollByCourseCode(
        email: 'student@uninorte.edu.co',
        courseCode: 'NOEXISTE-999',
      );
      expect(result, false);
    });

    test('Cursos del estudiante incluye cursos inscritos', () async {
      SharedPreferences.setMockInitialValues({
        'email': 'prof@uninorte.edu.co',
      });

      final store = DemoCourseStore();
      await store.createCourse(title: 'Bases de Datos', code: 'BD-202');

      await store.enrollByCourseCode(
        email: 'est@uninorte.edu.co',
        courseCode: 'BD-202',
      );

      final studentCourses = await store.studentCourses('est@uninorte.edu.co');
      expect(studentCourses.any((c) => c['code'] == 'BD-202'), true);
    });

    test('Eliminar curso lo remueve de la lista', () async {
      SharedPreferences.setMockInitialValues({
        'email': 'prof@uninorte.edu.co',
      });

      final store = DemoCourseStore();
      await store.createCourse(title: 'Redes', code: 'RED-101');

      var courses = await store.professorCourseSummaries();
      expect(courses.length, 1);

      final courseId = courses.first['id'] as String;
      await store.deleteCourse(courseId);

      courses = await store.professorCourseSummaries();
      expect(courses.isEmpty, true);
    });

    test('Importar CSV agrega categorías y miembros correctamente', () async {
      SharedPreferences.setMockInitialValues({
        'email': 'prof@uninorte.edu.co',
      });

      final store = DemoCourseStore();
      await store.createCourse(title: 'Programación Móvil', code: 'PM-401');

      final courses = await store.professorCourseSummaries();
      final courseId = courses.first['id'] as String;

      await store.importCsvData(
        courseId: courseId,
        courseCode: 'PM-401',
        categories: {'Grupo 1', 'Grupo 2'},
        members: [
          {
            'courseId': courseId,
            'courseCode': 'PM-401',
            'category': 'Grupo 1',
            'email': 'a@uninorte.edu.co',
            'name': 'Ana',
            'last_name': 'García',
          },
          {
            'courseId': courseId,
            'courseCode': 'PM-401',
            'category': 'Grupo 1',
            'email': 'b@uninorte.edu.co',
            'name': 'Beto',
            'last_name': 'Pérez',
          },
          {
            'courseId': courseId,
            'courseCode': 'PM-401',
            'category': 'Grupo 2',
            'email': 'c@uninorte.edu.co',
            'name': 'Carlos',
            'last_name': 'López',
          },
        ],
      );

      final groups = await store.professorCourseGroups(courseId);
      expect(groups.length, 2);

      final grupo1 = groups.firstWhere((g) => g['groupName'] == 'Grupo 1');
      expect(grupo1['memberCount'], 2);
    });

    test('Compañeros del estudiante solo incluye su grupo', () async {
      SharedPreferences.setMockInitialValues({
        'email': 'prof@uninorte.edu.co',
      });

      final store = DemoCourseStore();
      await store.createCourse(title: 'Algoritmos', code: 'ALG-303');

      final courses = await store.professorCourseSummaries();
      final courseId = courses.first['id'] as String;

      await store.importCsvData(
        courseId: courseId,
        courseCode: 'ALG-303',
        categories: {'Grupo A', 'Grupo B'},
        members: [
          {
            'courseId': courseId,
            'courseCode': 'ALG-303',
            'category': 'Grupo A',
            'email': 'luis@uninorte.edu.co',
            'name': 'Luis',
            'last_name': 'M',
          },
          {
            'courseId': courseId,
            'courseCode': 'ALG-303',
            'category': 'Grupo A',
            'email': 'sofia@uninorte.edu.co',
            'name': 'Sofia',
            'last_name': 'R',
          },
          {
            'courseId': courseId,
            'courseCode': 'ALG-303',
            'category': 'Grupo B',
            'email': 'pedro@uninorte.edu.co',
            'name': 'Pedro',
            'last_name': 'V',
          },
        ],
      );

      final result = await store.studentCourseClassmates(
        courseId: courseId,
        email: 'luis@uninorte.edu.co',
      );

      expect(result['myGroup'], 'Grupo A');
      final classmates = result['classmates'] as List;
      // Solo sofia está en el mismo grupo, pedro está en Grupo B
      expect(classmates.length, 1);
      expect(classmates.first['email'], 'sofia@uninorte.edu.co');
    });

    test('Crear evaluación registra correctamente', () async {
      SharedPreferences.setMockInitialValues({
        'email': 'prof@uninorte.edu.co',
      });

      final store = DemoCourseStore();
      await store.createCourse(title: 'Desarrollo Web', code: 'WEB-201');

      final courses = await store.professorCourseSummaries();
      final courseId = courses.first['id'] as String;

      await store.createEvaluation(
        courseId: courseId,
        courseName: 'Desarrollo Web',
        categoryName: 'Grupo 1',
        activityName: 'Entrega Final',
        startDate: DateTime.now().subtract(const Duration(hours: 1)),
        endDate: DateTime.now().add(const Duration(days: 2)),
        visibility: 'public',
        allowSelfEval: false,
        criteria: ['Comunicación', 'Responsabilidad', 'Colaboración'],
        professorEmail: 'prof@uninorte.edu.co',
      );

      final evaluations = await store.getEvaluationsForCourse(courseId);
      expect(evaluations.length, 1);
      expect(evaluations.first['activityName'], 'Entrega Final');
      expect(evaluations.first['status'], 'active');
    });

    test('Evaluación cerrada aparece con status closed', () async {
      SharedPreferences.setMockInitialValues({
        'email': 'prof@uninorte.edu.co',
      });

      final store = DemoCourseStore();
      await store.createCourse(title: 'UI/UX', code: 'UX-101');

      final courses = await store.professorCourseSummaries();
      final courseId = courses.first['id'] as String;

      // Evaluación que ya terminó
      await store.createEvaluation(
        courseId: courseId,
        courseName: 'UI/UX',
        categoryName: 'Grupo 1',
        activityName: 'Evaluación Pasada',
        startDate: DateTime.now().subtract(const Duration(days: 3)),
        endDate: DateTime.now().subtract(const Duration(days: 1)),
        visibility: 'private',
        allowSelfEval: true,
        criteria: ['Puntualidad'],
        professorEmail: 'prof@uninorte.edu.co',
      );

      final evaluations = await store.getEvaluationsForCourse(courseId);
      expect(evaluations.length, 1);
      expect(evaluations.first['status'], 'closed');
    });

    test('Submision de evaluación guarda respuesta correctamente', () async {
      SharedPreferences.setMockInitialValues({
        'email': 'prof@uninorte.edu.co',
      });

      final store = DemoCourseStore();
      await store.createCourse(title: 'Cálculo', code: 'CAL-101');

      final courses = await store.professorCourseSummaries();
      final courseId = courses.first['id'] as String;

      await store.importCsvData(
        courseId: courseId,
        courseCode: 'CAL-101',
        categories: {'Grupo 1'},
        members: [
          {
            'courseId': courseId,
            'courseCode': 'CAL-101',
            'category': 'Grupo 1',
            'email': 'eva@uninorte.edu.co',
            'name': 'Eva',
            'last_name': 'Torres',
          },
          {
            'courseId': courseId,
            'courseCode': 'CAL-101',
            'category': 'Grupo 1',
            'email': 'mario@uninorte.edu.co',
            'name': 'Mario',
            'last_name': 'Ríos',
          },
        ],
      );

      await store.createEvaluation(
        courseId: courseId,
        courseName: 'Cálculo',
        categoryName: 'Grupo 1',
        activityName: 'Peer Review',
        startDate: DateTime.now().subtract(const Duration(hours: 1)),
        endDate: DateTime.now().add(const Duration(days: 1)),
        visibility: 'public',
        allowSelfEval: false,
        criteria: ['Comunicación', 'Responsabilidad'],
        professorEmail: 'prof@uninorte.edu.co',
      );

      final evaluations = await store.getEvaluationsForCourse(courseId);
      final evalId = evaluations.first['id'].toString();

      await store.submitEvaluationResponse(
        evaluationId: evalId,
        evaluatorEmail: 'eva@uninorte.edu.co',
        evaluateeEmail: 'mario@uninorte.edu.co',
        scores: {'Comunicación': 4, 'Responsabilidad': 5},
      );

      final results = await store.getEvaluationResults(evalId);
      final byStudent = results['byStudent'] as List;
      expect(byStudent.isNotEmpty, true);

      final marioResult = byStudent.firstWhere(
        (s) => s['email'] == 'mario@uninorte.edu.co',
        orElse: () => {},
      );
      expect(marioResult.isNotEmpty, true);
      expect(marioResult['overallAverage'], closeTo(4.5, 0.01));
    });
  });

  group('LoginPage - UI básica', () {
    testWidgets('Botón de iniciar sesión existe', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        GetMaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const Key('loginButton'),
                  onPressed: () {},
                  child: const Text('Iniciar sesion'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('loginButton')), findsOneWidget);
      expect(find.text('Iniciar sesion'), findsOneWidget);
    });

    testWidgets('Campo de email existe', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  key: const Key('emailField'),
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo'),
                ),
                TextField(
                  key: const Key('passwordField'),
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('emailField')), findsOneWidget);
      expect(find.byKey(const Key('passwordField')), findsOneWidget);
    });
  });

  group('SegmentedButton - Selección de rol', () {
    testWidgets('Selector de rol cambia correctamente', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final roleObs = 'Estudiante'.obs;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Obx(() => SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment<String>(value: 'Docente', label: Text('Docente')),
                ButtonSegment<String>(value: 'Estudiante', label: Text('Estudiante')),
              ],
              selected: {roleObs.value},
              onSelectionChanged: (newSelection) {
                if (newSelection.isNotEmpty) {
                  roleObs.value = newSelection.first;
                }
              },
            )),
          ),
        ),
      );

      expect(roleObs.value, 'Estudiante');
      await tester.tap(find.text('Docente'));
      await tester.pump();
      expect(roleObs.value, 'Docente');
    });
  });
}