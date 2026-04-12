import 'package:get/get.dart';
import '../../domain/repositories/i_course_repository.dart';

class ProfessorController extends GetxController {
  final ICourseRepository _courseRepo;

  ProfessorController(this._courseRepo);

  // ── State ──────────────────────────────────────────────────────────────────
  final courses = <Map<String, dynamic>>[].obs;
  final isLoadingCourses = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await loadCourses();
  }

  // ── Computed stats ─────────────────────────────────────────────────────────
  int get totalStudents =>
      courses.fold(0, (sum, c) => sum + ((c['studentCount'] as int?) ?? 0));
  int get totalPendingEvals =>
      courses.fold(0, (sum, c) => sum + ((c['pendingEvals'] as int?) ?? 0));
  int get totalGroups =>
      courses.fold(0, (sum, c) => sum + ((c['groupCount'] as int?) ?? 0));

  // ── Selected course ────────────────────────────────────────────────────────
  final selectedCourseId = RxnString();
  void selectCourse(String id) => selectedCourseId.value = id;
  Map<String, dynamic>? get selectedCourse =>
      selectedCourseId.value == null
          ? null
          : courses.firstWhereOrNull((c) => c['id'] == selectedCourseId.value);

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> loadCourses() async {
    isLoadingCourses.value = true;
    try {
      final email = await _courseRepo.currentEmail();
      if (email == null || email.isEmpty) {
        courses.clear();
        return;
      }
      final mapped = await _courseRepo.professorCourseSummaries(email);
      courses.assignAll(mapped);
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar los cursos: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoadingCourses.value = false;
    }
  }

  Future<void> createCourse(String title, String code) async {
    try {
      await _courseRepo.createCourse(title: title, code: code);
      await loadCourses();
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
    try {
      await _courseRepo.deleteCourse(id);
      await loadCourses();
      Get.snackbar(
        'Curso eliminado',
        '"${course['title']}" ha sido eliminado.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  void logout() => Get.offAllNamed('/login');
}