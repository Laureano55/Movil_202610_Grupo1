import 'package:get/get.dart';

class ProfessorController extends GetxController {
  // ── Estado de cursos ──────────────────────────────────────────────────────
  final courses = <Map<String, dynamic>>[
    {
      'id': '1',
      'title': 'Desarrollo Móvil',
      'code': 'COMP-4321',
      'studentCount': 28,
      'groupCount': 6,
      'pendingEvals': 3,
    },
    {
      'id': '2',
      'title': 'Programación Web',
      'code': 'COMP-3210',
      'studentCount': 35,
      'groupCount': 8,
      'pendingEvals': 0,
    },
    {
      'id': '3',
      'title': 'Bases de Datos II',
      'code': 'COMP-3110',
      'studentCount': 22,
      'groupCount': 5,
      'pendingEvals': 1,
    },
  ].obs;

  // ── Estadísticas globales ─────────────────────────────────────────────────
  int get totalStudents =>
      courses.fold(0, (sum, c) => sum + (c['studentCount'] as int));

  int get totalPendingEvals =>
      courses.fold(0, (sum, c) => sum + (c['pendingEvals'] as int));

  int get totalGroups =>
      courses.fold(0, (sum, c) => sum + (c['groupCount'] as int));

  // ── Estado de curso seleccionado ──────────────────────────────────────────
  final selectedCourseId = RxnString();

  void selectCourse(String id) => selectedCourseId.value = id;

  Map<String, dynamic>? get selectedCourse {
    if (selectedCourseId.value == null) return null;
    return courses.firstWhereOrNull((c) => c['id'] == selectedCourseId.value);
  }

  // ── Acciones del profesor ─────────────────────────────────────────────────
  void createCourse(String title, String code) {
    courses.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'code': code,
      'studentCount': 0,
      'groupCount': 0,
      'pendingEvals': 0,
    });
    Get.snackbar(
      'Curso creado',
      '"$title" ha sido creado exitosamente.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void deleteCourse(String id) {
    final course = courses.firstWhereOrNull((c) => c['id'] == id);
    if (course == null) return;
    courses.removeWhere((c) => c['id'] == id);
    Get.snackbar(
      'Curso eliminado',
      '"${course['title']}" ha sido eliminado.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void publishResults(String courseId) {
    final idx = courses.indexWhere((c) => c['id'] == courseId);
    if (idx == -1) return;
    courses[idx] = {...courses[idx], 'pendingEvals': 0};
    courses.refresh();
    Get.snackbar(
      'Resultados publicados',
      'Las evaluaciones del curso han sido publicadas.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void logout() => Get.offAllNamed('/login');
}