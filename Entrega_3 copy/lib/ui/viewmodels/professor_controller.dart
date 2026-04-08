import 'package:get/get.dart';
import '../data/demo_course_store.dart';

class ProfessorController extends GetxController {
  final DemoCourseStore _store;

  ProfessorController({DemoCourseStore? demoCourseStore})
      : _store = demoCourseStore ?? DemoCourseStore();

  // ── Course state ──────────────────────────────────────────────────────────
  final courses = <Map<String, dynamic>>[].obs;
  final isLoadingCourses = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await loadCourses();
  }

  // ── Computed stats (reactive via courses Rx) ───────────────────────────────
  int get totalStudents =>
      courses.fold(0, (sum, c) => sum + ((c['studentCount'] as int?) ?? 0));

  int get totalPendingEvals =>
      courses.fold(0, (sum, c) => sum + ((c['pendingEvals'] as int?) ?? 0));

  int get totalGroups =>
      courses.fold(0, (sum, c) => sum + ((c['groupCount'] as int?) ?? 0));

  // ── Selected course ───────────────────────────────────────────────────────
  final selectedCourseId = RxnString();

  void selectCourse(String id) => selectedCourseId.value = id;

  Map<String, dynamic>? get selectedCourse {
    if (selectedCourseId.value == null) return null;
    return courses.firstWhereOrNull((c) => c['id'] == selectedCourseId.value);
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> loadCourses() async {
    isLoadingCourses.value = true;
    try {
      final mapped = await _store.professorCourseSummaries();
      courses.assignAll(mapped);
    } finally {
      isLoadingCourses.value = false;
    }
  }

  Future<void> createCourse(String title, String code) async {
    try {
      await _store.createCourse(title: title, code: code);
      await loadCourses(); // reload so stats update
      Get.snackbar(
        'Curso creado',
        '"$title" ha sido creado exitosamente.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
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

  void logout() => Get.offAllNamed('/login');
}