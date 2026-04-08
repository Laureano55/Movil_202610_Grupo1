import 'package:get/get.dart';
import '../data/demo_course_store.dart';

class StudentController extends GetxController {
  final DemoCourseStore _store;

  StudentController({DemoCourseStore? demoCourseStore})
      : _store = demoCourseStore ?? DemoCourseStore();

  // ── Enrolled courses ──────────────────────────────────────────────────────
  final enrolledCourses = <Map<String, dynamic>>[].obs;
  final isLoadingCourses = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await loadEnrolledCourses();
  }

  // ── Stats ──────────────────────────────────────────────────────────────────
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

  // ── Selected course ───────────────────────────────────────────────────────
  final selectedCourseId = RxnString();
  void selectCourse(String id) => selectedCourseId.value = id;
  Map<String, dynamic>? get selectedCourse =>
      selectedCourseId.value == null
          ? null
          : enrolledCourses
              .firstWhereOrNull((c) => c['id'] == selectedCourseId.value);

  // ── Load enrolled courses ──────────────────────────────────────────────────
  Future<void> loadEnrolledCourses() async {
    isLoadingCourses.value = true;
    try {
      final email = (await _store.currentEmail())?.trim();
      if (email == null || email.isEmpty) {
        enrolledCourses.clear();
        return;
      }
      final mapped = await _store.studentCourses(email);
      enrolledCourses.assignAll(mapped);
    } finally {
      isLoadingCourses.value = false;
    }
  }

  // ── Join course ────────────────────────────────────────────────────────────
  Future<void> joinCourse(String code) async {
    final email = (await _store.currentEmail())?.trim();
    if (email == null || email.isEmpty) {
      Get.snackbar('Error', 'No se pudo obtener tu correo de sesión');
      return;
    }
    final alreadyIn = enrolledCourses.any((c) =>
        (c['code'] ?? '').toString().toLowerCase() == code.toLowerCase());
    if (alreadyIn) {
      Get.snackbar('Ya inscrito', 'Ya perteneces a un curso con ese código.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final found =
        await _store.enrollByCourseCode(email: email, courseCode: code);
    if (!found) {
      Get.snackbar('No encontrado', 'No existe un curso con código $code.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    await loadEnrolledCourses();
    Get.snackbar('¡Inscripción exitosa!',
        'Te has unido al curso con código $code.',
        snackPosition: SnackPosition.BOTTOM);
  }

  void logout() => Get.offAllNamed('/login');
}