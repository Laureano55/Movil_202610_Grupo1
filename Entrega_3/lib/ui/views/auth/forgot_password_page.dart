import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../viewmodels/auth_controller.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contrasena')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Ingresa el correo para recibir el enlace de recuperacion.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa tu correo';
                        }
                        if (!value.contains('@')) {
                          return 'Correo invalido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: auth.isLoading.value
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }

                                  try {
                                    await auth.forgotPassword(_emailController.text);
                                    Get.snackbar(
                                      'Recuperacion',
                                      'Revisa tu correo para continuar',
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                    Get.back();
                                  } catch (e) {
                                    Get.snackbar(
                                      'Recuperacion',
                                      e.toString().replaceFirst('Exception: ', ''),
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  }
                                },
                          child: auth.isLoading.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Enviar enlace'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
