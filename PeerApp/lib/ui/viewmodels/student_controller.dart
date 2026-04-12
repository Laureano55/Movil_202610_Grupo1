import 'package:get/get.dart';
import '../../domain/repositories/i_course_repository.dart';

class StudentController extends GetxController {
  final ICourseRepository _courseRepo;

  StudentController(this._courseRepo);

  // ── State ──────────────────────────────────────────────────────────────────
  final enrolledCourses = <Map<String, dynamic>>[].obs;
  final isLoadingCourses = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await loadEnrolledCourses();
  }

  // ── Computed stats ─────────────────────────────────────────────────────────
  int get totalActiveEvals =>
      enrolledCourses.fold(0, (sum, c) => sum + ((c['activeEvals'] as int?) ?? 0));
  int get totalCompleted =>
      enrolledCourses.fold(0, (sum, c) => sum + ((c['completedEvals'] as int?) ?? 0));
  double get overallProgress {
    final total = enrolledCourses.fold(
        0, (sum, c) => sum + ((c['totalEvals'] as int?) ?? 0));
    if (total == 0) return 0.0;
    return totalCompleted / total;
  }

  // ── Selected course ────────────────────────────────────────────────────────
  final selectedCourseId = RxnString();
  void selectCourse(String id) => selectedCourseId.value = id;
  Map<String, dynamic>? get selectedCourse =>
      selectedCourseId.value == null
          ? null
          : enrolledCourses
              .firstWhereOrNull((c) => c['id'] == selectedCourseId.value);

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> loadEnrolledCourses() async {
    isLoadingCourses.value = true;
    try {
      final email = await _courseRepo.currentEmail();
      if (email == null || email.isEmpty) {
        enrolledCourses.clear();
        return;
      }
      final mapped = await _courseRepo.studentCourses(email);
      enrolledCourses.assignAll(mapped);
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar tus cursos: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoadingCourses.value = false;
    }
  }

  Future<void> joinCourse(String code) async {
    final email = await _courseRepo.currentEmail();
    if (email == null || email.isEmpty) {
      Get.snackbar('Error', 'No se pudo obtener tu correo de sesión');
      return;
    }

    final alreadyIn = enrolledCourses.any(
      (c) => (c['code'] ?? '').toString().toLowerCase() == code.toLowerCase(),
    );
    if (alreadyIn) {
      Get.snackbar('Ya inscrito', 'Ya perteneces a un curso con ese código.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      final found = await _courseRepo.enrollByCourseCode(
        email: email,
        courseCode: code,
      );
      if (!found) {
        Get.snackbar('No encontrado', 'No existe un curso con código $code.',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      await loadEnrolledCourses();
      Get.snackbar('¡Inscripción exitosa!',
          'Te has unido al curso con código $code.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo inscribir: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void logout() => Get.offAllNamed('/login');
}