import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/domain/repositories/i_auth_repository.dart';

class AuthController extends GetxController {
  final IAuthRepository _authRepository;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isPasswordHidden = true.obs;
  final selectedRole = 'Estudiante'.obs;
  final isLoading = false.obs;
  final isAuthenticated = false.obs;

  AuthController(this._authRepository);

  @override
  Future<void> onInit() async {
    super.onInit();
    await restoreSession();
  }

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

  Future<void> restoreSession() async {
    try {
      final valid = await _authRepository.validateToken();
      isAuthenticated.value = valid;
    } catch (_) {
      isAuthenticated.value = false;
    }
  }

  Future<void> loginWithRoble() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      throw Exception('Debes ingresar correo y contraseña');
    }

    isLoading.value = true;
    try {
      await _authRepository.login(email, password);

      final realRole = await _authRepository.getAccountRoleByEmail(email);
      if (realRole == null) {
        await _authRepository.logOut();
        throw Exception(
          'No se encontro el rol del usuario en tablas students/teachers.',
        );
      }

      if (selectedRole.value != realRole) {
        await _authRepository.logOut();
        throw Exception(
          'Credenciales validas, pero el rol seleccionado no coincide. Debes ingresar como $realRole.',
        );
      }

      selectedRole.value = realRole;
      isAuthenticated.value = true;
      Get.offAllNamed('/home');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUpWithRoble({
    required String name,
    required String lastName,
    required String role,
    required String email,
    required String password,
    bool direct = true,
  }) async {
    isLoading.value = true;
    try {
      await _authRepository.signUp(
        email.trim(),
        password,
        name.trim(),
        direct,
        lastName: lastName.trim(),
        role: role,
      );
      isAuthenticated.value = true;
      emailController.text = email.trim();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgotPassword(String email) async {
    isLoading.value = true;
    try {
      await _authRepository.forgotPassword(email.trim());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    isLoading.value = true;
    try {
      await _authRepository.logOut();
    } finally {
      isAuthenticated.value = false;
      isLoading.value = false;
      Get.offAllNamed('/login');
    }
  }
}
