import '../../domain/models/course_model.dart';
import '../../domain/models/course_member_model.dart';

abstract class ICourseRepository {
  /// Crea un nuevo curso.
  Future<void> createCourse({required String title, required String code});

  /// Elimina un curso y todos sus datos relacionados.
  Future<void> deleteCourse(String courseId);

  /// Retorna resumen de cursos donde el usuario es profesor.
  Future<List<Map<String, dynamic>>> professorCourseSummaries(String professorEmail);

  /// Inscribe un estudiante por código de curso.
  /// Retorna false si el código no existe.
  Future<bool> enrollByCourseCode({
    required String email,
    required String courseCode,
  });

  /// Retorna cursos donde el estudiante está inscrito.
  Future<List<Map<String, dynamic>>> studentCourses(String email);

  /// Importa miembros desde CSV.
  Future<void> importCsvData({
    required String courseId,
    required String courseCode,
    required Set<String> categories,
    required List<Map<String, dynamic>> members,
  });

  /// Retorna grupos del curso para el profesor.
  Future<List<Map<String, dynamic>>> professorCourseGroups(String courseId);

  /// Retorna compañeros de grupo del estudiante.
  Future<Map<String, dynamic>> studentCourseClassmates({
    required String courseId,
    required String email,
  });

  /// Retorna categorías de un curso.
  Future<List<String>> getCategoriesForCourse(String courseId);

  /// Retorna todos los miembros de un curso con su categoría.
  Future<List<CourseMemberModel>> getMembersByCourse(String courseId);

  /// Retorna el correo del usuario autenticado.
  Future<String?> currentEmail();
}