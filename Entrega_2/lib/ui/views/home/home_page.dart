import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../viewmodels/auth_controller.dart';
import '../professor/professor_home_page.dart';
import '../student/student_home_page.dart';

/// Punto de entrada al home: delega al panel correcto según el rol.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Obx(() {
      final isTeacher = auth.selectedRole.value == 'Docente';
      return isTeacher
          ? const ProfessorHomePage()
          : const StudentHomePage();
    });
  }
}