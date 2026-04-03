import 'package:get/get.dart';

import 'auth_controller.dart';

class HomeController extends GetxController {
  late final AuthController _authController;

  String get currentRole => _authController.selectedRole.value;

  @override
  void onInit() {
    _authController = Get.find<AuthController>();
    super.onInit();
  }

  void goToLogin() {
    Get.offAllNamed('/login');
  }
}
