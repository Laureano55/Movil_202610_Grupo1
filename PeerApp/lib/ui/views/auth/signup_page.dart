import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../viewmodels/auth_controller.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'Estudiante';

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _passwordController.text = AuthController.fixedDemoPassword;
    _confirmPasswordController.text = AuthController.fixedDemoPassword;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa tu nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Apellido',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa tu apellido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(
                          value: 'Estudiante',
                          label: Text('Estudiante'),
                          icon: Icon(Icons.person_rounded),
                        ),
                        ButtonSegment<String>(
                          value: 'Docente',
                          label: Text('Docente'),
                          icon: Icon(Icons.co_present_rounded),
                        ),
                      ],
                      selected: {_selectedRole},
                      onSelectionChanged: (value) {
                        if (value.isNotEmpty) {
                          setState(() {
                            _selectedRole = value.first;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _hidePassword,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Contrasena (fija)',
                        border: const OutlineInputBorder(),
                        helperText: 'Valor fijo para demo: ThePassword!1',
                      ),
                      validator: (value) {
                        if (value != AuthController.fixedDemoPassword) {
                          return 'La contrasena debe ser ThePassword!1';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _hideConfirmPassword,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Confirmar contrasena (fija)',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value != AuthController.fixedDemoPassword) {
                          return 'Las contrasenas no coinciden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
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
                                    await auth.signUpWithRoble(
                                      name: _nameController.text,
                                      lastName: _lastNameController.text,
                                      role: _selectedRole,
                                      email: _emailController.text,
                                      direct: true,
                                    );

                                    Get.snackbar(
                                      'Registro',
                                      'Cuenta creada correctamente',
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                    Get.back();
                                  } catch (e) {
                                    Get.snackbar(
                                      'Registro',
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
                              : const Text('Crear cuenta'),
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
