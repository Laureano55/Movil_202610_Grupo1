import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/professor_controller.dart';

/// Scroll con rebote suave — máximo 28px de overscroll.
class _LightBouncePhysics extends BouncingScrollPhysics {
  const _LightBouncePhysics() : super(parent: const AlwaysScrollableScrollPhysics());

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    const maxOverscroll = 28.0;
    if (value < position.minScrollExtent) {
      final over = position.minScrollExtent - value;
      if (over > maxOverscroll) return value - (position.minScrollExtent - maxOverscroll);
    }
    if (value > position.maxScrollExtent) {
      final over = value - position.maxScrollExtent;
      if (over > maxOverscroll) return value - (position.maxScrollExtent + maxOverscroll);
    }
    return super.applyBoundaryConditions(position, value);
  }
}

class ProfessorHomePage extends GetView<ProfessorController> {
  const ProfessorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = const Color(0xFF4B3CF0);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Panel del Docente',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded),
            onPressed: controller.logout,
          ),
        ],
      ),
      body: Obx(() {
        return Column(
          children: [
            // ── Banner fijo (nunca scrollea) ─────────────────────────────
            Container(
              color: primary,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bienvenido, Docente',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.groups_rounded,
                        label: '${controller.totalStudents}',
                        sublabel: 'Estudiantes',
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: Icons.assignment_rounded,
                        label: '${controller.totalGroups}',
                        sublabel: 'Grupos',
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: Icons.pending_actions_rounded,
                        label: '${controller.totalPendingEvals}',
                        sublabel: 'Pendientes',
                        highlight: controller.totalPendingEvals > 0,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Contenido scrolleable ────────────────────────────────────
            Expanded(
              child: ListView(
                physics: const _LightBouncePhysics(),
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mis cursos',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showCreateCourseDialog(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Crear'),
                          style: TextButton.styleFrom(foregroundColor: primary),
                        ),
                      ],
                    ),
                  ),
                  ...controller.courses.map((course) => _CourseCard(
                        course: course,
                        onPublish: () => controller
                            .publishResults(course['id'] as String),
                        onDelete: () => _confirmDelete(context, course),
                      )),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text(
                      'Acciones rápidas',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: const [
                        _ActionCard(
                          icon: Icons.group_add_rounded,
                          title: 'Importar grupos',
                          subtitle: 'Desde Brightspace o CSV',
                          color: Color(0xFF3ECFCF),
                        ),
                        _ActionCard(
                          icon: Icons.bar_chart_rounded,
                          title: 'Ver estadísticas',
                          subtitle: 'Promedios por grupo',
                          color: Color(0xFFFF6B6B),
                        ),
                        _ActionCard(
                          icon: Icons.tune_rounded,
                          title: 'Configurar rubrica',
                          subtitle: 'Criterios de evaluación',
                          color: Color(0xFFFFB347),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showCreateCourseDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Crear nuevo curso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del curso',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(
                labelText: 'Código (ej. COMP-4321)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty &&
                  codeCtrl.text.trim().isNotEmpty) {
                final title = titleCtrl.text.trim();
                final code = codeCtrl.text.trim();
                Get.back(); // cerrar primero, luego actuar
                controller.createCourse(title, code);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> course) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar curso'),
        content: Text('¿Estás seguro de eliminar "${course['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final id = course['id'] as String;
              Navigator.of(dialogContext).pop();
              controller.deleteCourse(id);
            },
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool highlight;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.sublabel,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: highlight
              ? Colors.orange.withOpacity(0.9)
              : Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              sublabel,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final VoidCallback onPublish;
  final VoidCallback onDelete;

  const _CourseCard({
    required this.course,
    required this.onPublish,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final pendingEvals = course['pendingEvals'] as int;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        course['code'] as String,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (pendingEvals > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Text(
                      '$pendingEvals pendiente${pendingEvals > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoPill(
                  Icons.person_rounded,
                  '${course['studentCount']} estudiantes',
                ),
                const SizedBox(width: 8),
                _InfoPill(
                  Icons.group_rounded,
                  '${course['groupCount']} grupos',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (pendingEvals > 0)
                  TextButton.icon(
                    onPressed: onPublish,
                    icon: const Icon(Icons.publish_rounded, size: 16),
                    label: const Text('Publicar resultados'),
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF4B3CF0)),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444), size: 20),
                  tooltip: 'Eliminar curso',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EFFE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4B3CF0)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4B3CF0),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 52) / 2,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}