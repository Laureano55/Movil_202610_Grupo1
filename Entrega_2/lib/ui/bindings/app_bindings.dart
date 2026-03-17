import 'package:get/get.dart';

import '../viewmodels/auth_controller.dart';
import '../viewmodels/professor_controller.dart';
import '../viewmodels/student_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Siempre disponible (contiene el rol seleccionado)
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);

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