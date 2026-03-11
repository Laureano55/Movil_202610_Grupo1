import 'package:get/get.dart';

import '../viewmodels/auth_controller.dart';
import '../viewmodels/home_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
  }
}
