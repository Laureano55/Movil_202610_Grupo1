import 'package:get/get.dart';

import '../../auth/data/datasources/remote/authentication_source_service_roble.dart';
import '../../auth/data/datasources/remote/i_authentication_source.dart';
import '../../auth/data/repositories/auth_repository.dart';
import '../../auth/domain/repositories/i_auth_repository.dart';

import '../../core/roble_database_service.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../../data/repositories/evaluation_repository_impl.dart';
import '../../domain/repositories/i_course_repository.dart';
import '../../domain/repositories/i_evaluation_repository.dart';

import '../viewmodels/auth_controller.dart';
import '../viewmodels/professor_controller.dart';
import '../viewmodels/student_controller.dart';
import '../viewmodels/evaluation_controller.dart';
import '../viewmodels/count_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // ── Auth layer ─────────────────────────────────────────────────────────
    Get.lazyPut<IAuthenticationSource>(
      () => AuthenticationSourceServiceRoble(),
      fenix: true,
    );
    Get.lazyPut<IAuthRepository>(
      () => AuthRepository(Get.find<IAuthenticationSource>()),
      fenix: true,
    );
    Get.lazyPut<AuthController>(
      () => AuthController(Get.find<IAuthRepository>()),
      fenix: true,
    );

    // ── ROBLE DB service ───────────────────────────────────────────────────
    Get.lazyPut<RobleDatabaseService>(
      () => RobleDatabaseService(),
      fenix: true,
    );

    // ── Repository layer ───────────────────────────────────────────────────
    Get.lazyPut<ICourseRepository>(
      () => CourseRepositoryImpl(Get.find<RobleDatabaseService>()),
      fenix: true,
    );
    Get.lazyPut<IEvaluationRepository>(
      () => EvaluationRepositoryImpl(Get.find<RobleDatabaseService>()),
      fenix: true,
    );

    // ── Feature controllers ────────────────────────────────────────────────
    Get.lazyPut<ProfessorController>(
      () => ProfessorController(Get.find<ICourseRepository>()),
      fenix: true,
    );
    Get.lazyPut<StudentController>(
      () => StudentController(Get.find<ICourseRepository>()),
      fenix: true,
    );
    Get.lazyPut<EvaluationController>(
      () => EvaluationController(
        Get.find<IEvaluationRepository>(),
        Get.find<ICourseRepository>(),
      ),
      fenix: true,
    );

    // ── Shared controllers ─────────────────────────────────────────────────
    Get.lazyPut<CountController>(
      () => CountController(),
      fenix: true,
    );
  }
}