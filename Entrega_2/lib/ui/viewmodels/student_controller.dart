import 'package:get/get.dart';

class StudentController extends GetxController {
  // ── Cursos en los que está inscrito el estudiante ─────────────────────────
  final enrolledCourses = <Map<String, dynamic>>[
    {
      'id': '1',
      'title': 'Desarrollo Móvil',
      'code': 'COMP-4321',
      'professor': 'Dr. Carlos Gómez',
      'myGroup': 'Grupo 3',
      'activeEvals': 2,
      'completedEvals': 5,
      'totalEvals': 7,
    },
    {
      'id': '2',
      'title': 'Programación Web',
      'code': 'COMP-3210',
      'professor': 'Dra. Ana Torres',
      'myGroup': 'Grupo 1',
      'activeEvals': 0,
      'completedEvals': 4,
      'totalEvals': 4,
    },
  ].obs;

  // ── Estado de evaluaciones pendientes ─────────────────────────────────────
  int get totalActiveEvals =>
      enrolledCourses.fold(0, (sum, c) => sum + (c['activeEvals'] as int));

  int get totalCompleted =>
      enrolledCourses.fold(0, (sum, c) => sum + (c['completedEvals'] as int));

  double get overallProgress {
    final total =
        enrolledCourses.fold(0, (sum, c) => sum + (c['totalEvals'] as int));
    if (total == 0) return 0.0;
    return totalCompleted / total;
  }

  // ── Curso seleccionado ────────────────────────────────────────────────────
  final selectedCourseId = RxnString();

  void selectCourse(String id) => selectedCourseId.value = id;

  Map<String, dynamic>? get selectedCourse {
    if (selectedCourseId.value == null) return null;
    return enrolledCourses
        .firstWhereOrNull((c) => c['id'] == selectedCourseId.value);
  }

  // ── Unirse a curso con código ─────────────────────────────────────────────
  void joinCourse(String code) {
    final alreadyIn = enrolledCourses.any((c) => c['code'] == code);
    if (alreadyIn) {
      Get.snackbar(
        'Ya inscrito',
        'Ya perteneces a un curso con ese código.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    // Simulación: en producción se haría la llamada a la API
    enrolledCourses.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': 'Nuevo Curso ($code)',
      'code': code,
      'professor': 'Por asignar',
      'myGroup': 'Sin grupo',
      'activeEvals': 0,
      'completedEvals': 0,
      'totalEvals': 0,
    });
    Get.snackbar(
      'Inscripción exitosa',
      'Te has unido al curso con código $code.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // ── Marcar evaluación como completada (simulación) ────────────────────────
  void completeEvaluation(String courseId) {
    final idx = enrolledCourses.indexWhere((c) => c['id'] == courseId);
    if (idx == -1) return;
    final course = enrolledCourses[idx];
    final active = course['activeEvals'] as int;
    if (active <= 0) return;
    enrolledCourses[idx] = {
      ...course,
      'activeEvals': active - 1,
      'completedEvals': (course['completedEvals'] as int) + 1,
    };
    enrolledCourses.refresh();
    Get.snackbar(
      'Evaluación completada',
      'Has completado una evaluación.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void logout() => Get.offAllNamed('/login');
}