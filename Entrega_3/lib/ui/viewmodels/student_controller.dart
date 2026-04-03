import 'package:get/get.dart';

import '../data/demo_course_store.dart';

class StudentController extends GetxController {
  final DemoCourseStore _store;

  StudentController({DemoCourseStore? demoCourseStore})
      : _store = demoCourseStore ?? DemoCourseStore();

  // ── Cursos en los que está inscrito el estudiante ─────────────────────────
  final enrolledCourses = <Map<String, dynamic>>[].obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await loadEnrolledCourses();
  }

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
  Future<void> joinCourse(String code) async {
    final alreadyIn = enrolledCourses.any((c) => c['code'] == code);
    if (alreadyIn) {
      Get.snackbar(
        'Ya inscrito',
        'Ya perteneces a un curso con ese código.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final email = (await _store.currentEmail())?.trim();
    if (email == null || email.isEmpty) {
      Get.snackbar('Error', 'No se pudo obtener tu correo de sesión');
      return;
    }

    final found = await _store.enrollByCourseCode(email: email, courseCode: code);
    if (!found) {
      Get.snackbar('No encontrado', 'No existe un curso con código $code.');
      return;
    }

    await loadEnrolledCourses();
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

  Future<void> loadEnrolledCourses() async {
    final email = (await _store.currentEmail())?.trim();
    if (email == null || email.isEmpty) {
      enrolledCourses.clear();
      return;
    }

    final mapped = await _store.studentCourses(email);
    enrolledCourses.assignAll(mapped);
  }

  void logout() => Get.offAllNamed('/login');
}