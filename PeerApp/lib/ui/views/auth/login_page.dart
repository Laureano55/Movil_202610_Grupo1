import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../viewmodels/auth_controller.dart';
import 'forgot_password_page.dart';
import 'signup_page.dart';

class LoginPage extends GetView<AuthController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (controller.passwordController.text != AuthController.fixedDemoPassword) {
      controller.passwordController.text = AuthController.fixedDemoPassword;
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDDE4F2), Color(0xFFEEF1F8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  color: const Color(0xFFF7F7FA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 7,
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Color(0xFF4B3CF0),
                          child: Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'PeerApp',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sistema de evaluacion colaborativa',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blueGrey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: controller.emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Correo electronico',
                            hintText: 'tu@uninorte.edu.co',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Obx(
                          () => TextField(
                            controller: controller.passwordController,
                            obscureText: controller.isPasswordHidden.value,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Contrasena (fija)',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              helperText: 'Valor fijo para demo: ThePassword!1',
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Obx(
                          () => SegmentedButton<String>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment<String>(
                                value: 'Docente',
                                label: Text('Docente'),
                                icon: Icon(Icons.co_present_rounded),
                              ),
                              ButtonSegment<String>(
                                value: 'Estudiante',
                                label: Text('Estudiante'),
                                icon: Icon(Icons.person_rounded),
                              ),
                            ],
                            selected: {controller.selectedRole.value},
                            onSelectionChanged: (newSelection) {
                              if (newSelection.isNotEmpty) {
                                controller.selectRole(newSelection.first);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: Obx(
                            () => ElevatedButton(
                              onPressed: controller.isLoading.value
                                  ? null
                                  : () async {
                                      try {
                                        await controller.loginWithRoble();
                                      } catch (e) {
                                        Get.snackbar(
                                          'Login',
                                          e.toString().replaceFirst('Exception: ', ''),
                                          snackPosition: SnackPosition.BOTTOM,
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4B3CF0),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: controller.isLoading.value
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Iniciar sesion'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () {
                            Get.to(() => const ForgotPasswordPage());
                          },
                          child: const Text('Recuperar contrasena'),
                        ),
                        TextButton(
                          onPressed: () {
                            Get.to(() => const SignUpPage());
                          },
                          child: const Text('Crear cuenta'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
