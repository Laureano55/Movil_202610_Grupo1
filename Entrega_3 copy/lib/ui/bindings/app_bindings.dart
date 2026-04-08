import 'package:get/get.dart';

import '../../auth/data/datasources/remote/authentication_source_service_roble.dart';
import '../../auth/data/datasources/remote/i_authentication_source.dart';
import '../../auth/data/repositories/auth_repository.dart';
import '../../auth/domain/repositories/i_auth_repository.dart';
import '../viewmodels/auth_controller.dart';
import '../viewmodels/professor_controller.dart';
import '../viewmodels/student_controller.dart';
import '../viewmodels/evaluation_controller.dart';
import '../viewmodels/count_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Auth layer
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

    // Feature controllers
    Get.lazyPut<ProfessorController>(
      () => ProfessorController(),
      fenix: true,
    );
    Get.lazyPut<StudentController>(
      () => StudentController(),
      fenix: true,
    );
    Get.lazyPut<EvaluationController>(
      () => EvaluationController(),
      fenix: true,
    );

    // Shared controllers
    Get.lazyPut<CountController>(
      () => CountController(),
      fenix: true,
    );
  }
}