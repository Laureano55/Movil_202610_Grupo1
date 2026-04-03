import 'package:get/get.dart';

import '../../auth/data/datasources/remote/authentication_source_service_roble.dart';
import '../../auth/data/datasources/remote/i_authentication_source.dart';
import '../../auth/data/repositories/auth_repository.dart';
import '../../auth/domain/repositories/i_auth_repository.dart';
import '../viewmodels/auth_controller.dart';
import '../viewmodels/professor_controller.dart';
import '../viewmodels/student_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IAuthenticationSource>(
      () => AuthenticationSourceServiceRoble(),
      fenix: true,
    );
    Get.lazyPut<IAuthRepository>(
      () => AuthRepository(Get.find<IAuthenticationSource>()),
      fenix: true,
    );

    // Siempre disponible (contiene el rol seleccionado)
    Get.lazyPut<AuthController>(() => AuthController(Get.find<IAuthRepository>()), fenix: true);

    // Controladores por rol — ambos se crean con fenix: true para que
    // GetX los recicle si se destruyen y vuelven a necesitarse.
    Get.lazyPut<ProfessorController>(
      () => ProfessorController(),
      fenix: true,
    );
    Get.lazyPut<StudentController>(
      () => StudentController(),
      fenix: true,
    );
  }
}