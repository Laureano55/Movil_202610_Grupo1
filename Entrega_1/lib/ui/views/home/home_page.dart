import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../viewmodels/auth_controller.dart';
import '../../viewmodels/home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PeerApp - Home'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesion',
            onPressed: controller.goToLogin,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Obx(() {
        final role = authController.selectedRole.value;
        final isTeacher = role == 'Docente';

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido, $role',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Primer avance UI: pantalla principal con estado GetX.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: isTeacher
                    ? const [
                        _HomeActionCard(
                          icon: Icons.menu_book_rounded,
                          title: 'Crear curso',
                          subtitle: 'Configura cursos para evaluacion.',
                        ),
                        _HomeActionCard(
                          icon: Icons.group_add_rounded,
                          title: 'Importar grupos',
                          subtitle: 'Sincroniza categorias Brightspace.',
                        ),
                        _HomeActionCard(
                          icon: Icons.analytics_rounded,
                          title: 'Ver estadisticas',
                          subtitle: 'Promedios por actividad y grupo.',
                        ),
                      ]
                    : const [
                        _HomeActionCard(
                          icon: Icons.qr_code_scanner_rounded,
                          title: 'Unirse a curso',
                          subtitle: 'Ingresa codigo de invitacion.',
                        ),
                        _HomeActionCard(
                          icon: Icons.rate_review_rounded,
                          title: 'Evaluaciones activas',
                          subtitle: 'Responde dentro de la ventana.',
                        ),
                        _HomeActionCard(
                          icon: Icons.insights_rounded,
                          title: 'Mis resultados',
                          subtitle: 'Disponible segun visibilidad.',
                        ),
                      ],
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30, color: const Color(0xFF4B3CF0)),
              const SizedBox(height: 10),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
