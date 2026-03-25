import 'package:get/get.dart';

import '../data/demo_course_store.dart';

class ProfessorController extends GetxController {
  final DemoCourseStore _store;

  ProfessorController({DemoCourseStore? demoCourseStore})
      : _store = demoCourseStore ?? DemoCourseStore();

  // ── Estado de cursos ──────────────────────────────────────────────────────
  final courses = <Map<String, dynamic>>[].obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await loadCourses();
  }

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
  Future<void> createCourse(String title, String code) async {
    await _store.createCourse(title: title, code: code);

    await loadCourses();
    Get.snackbar('Curso creado', '"$title" ha sido creado exitosamente.',
        snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> deleteCourse(String id) async {
    final course = courses.firstWhereOrNull((c) => c['id'] == id);
    if (course == null) return;

    await _store.deleteCourse(id);

    await loadCourses();
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

  Future<void> loadCourses() async {
    final mapped = await _store.professorCourseSummaries();
    courses.assignAll(mapped);
  }

  void logout() => Get.offAllNamed('/login');
}