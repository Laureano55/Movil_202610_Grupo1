import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isPasswordHidden = true.obs;
  final selectedRole = 'Estudiante'.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void selectRole(String role) {
    selectedRole.value = role;
  }

  void goToHome() {
    Get.toNamed('/home');
  }
}
