// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/professor_controller.dart';
import 'course_groups_page.dart';
import 'import_groups_page.dart';

class _LightBouncePhysics extends BouncingScrollPhysics {
  const _LightBouncePhysics()
      : super(parent: const AlwaysScrollableScrollPhysics());

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    const maxOverscroll = 28.0;
    if (value < position.minScrollExtent) {
      final over = position.minScrollExtent - value;
      if (over > maxOverscroll) {
        return value - (position.minScrollExtent - maxOverscroll);
      }
    }
    if (value > position.maxScrollExtent) {
      final over = value - position.maxScrollExtent;
      if (over > maxOverscroll) {
        return value - (position.maxScrollExtent + maxOverscroll);
      }
    }
    return super.applyBoundaryConditions(position, value);
  }
}

class ProfessorHomePage extends GetView<ProfessorController> {
  const ProfessorHomePage({super.key});

  static const _primary = Color(0xFF4B3CF0);
  static const _accent = Color(0xFF3ECFCF);
  static const _bg = Color(0xFFF4F6FB);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
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
        if (controller.isLoadingCourses.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            // ── Stats banner ─────────────────────────────────────────────
            Container(
              color: _primary,
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
                        icon: Icons.folder_copy_rounded,
                        label: '${controller.totalGroups}',
                        sublabel: 'Grupos',
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: Icons.pending_actions_rounded,
                        label: '${controller.totalPendingEvals}',
                        sublabel: 'Eval. activas',
                        highlight: controller.totalPendingEvals > 0,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Scrollable body ──────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.loadCourses,
                child: ListView(
                  physics: const _LightBouncePhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    // Section: Mis cursos
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mis cursos',
                            style:
                                theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                _showCreateCourseDialog(context),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Nuevo'),
                            style: TextButton.styleFrom(
                                foregroundColor: _primary),
                          ),
                        ],
                      ),
                    ),

                    if (controller.courses.isEmpty)
                      _EmptyCoursesHint(
                          onCreateTap: () =>
                              _showCreateCourseDialog(context))
                    else
                      ...controller.courses.map((course) => _CourseCard(
                            course: course,
                            onTap: () => Get.to(
                              () => CourseGroupsPage(
                                courseId: course['id'] as String,
                                courseTitle: course['title'] as String,
                                courseCode: course['code'] as String,
                              ),
                            )?.then((_) => controller.loadCourses()),
                            onDelete: () =>
                                _confirmDelete(context, course),
                          )),

                    // Section: Acciones rápidas
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
                    // Two equal-width cards using Row + Expanded (same layout
                    // as student home page).
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.group_add_rounded,
                              title: 'Importar grupos',
                              subtitle: 'Desde CSV / Brightspace',
                              color: _accent,
                              onTap: () =>
                                  Get.to(() => const ImportGroupsPage())
                                      ?.then((_) =>
                                          controller.loadCourses()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.bar_chart_rounded,
                              title: 'Ver estadísticas',
                              subtitle: 'Resultados de evaluaciones',
                              color: const Color(0xFFFFB347),
                              onTap: controller.courses.isEmpty
                                  ? null
                                  : () => Get.toNamed(
                                        '/professor/evaluation-results',
                                        arguments: {
                                          'courseId':
                                              controller.courses.first[
                                                  'id'] as String,
                                        },
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
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
          TextButton(onPressed: Get.back, child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              final code = codeCtrl.text.trim();
              if (title.isNotEmpty && code.isNotEmpty) {
                Get.back();
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
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar curso'),
        content:
            Text('¿Estás seguro de eliminar "${course['title']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.deleteCourse(course['id'] as String);
            },
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool highlight;
  const _StatChip(
      {required this.icon,
      required this.label,
      required this.sublabel,
      this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
            Text(sublabel,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _EmptyCoursesHint extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyCoursesHint({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            const Icon(Icons.school_outlined,
                size: 52, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 12),
            const Text(
              'Aún no tienes cursos',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Crea tu primer curso para comenzar a gestionar grupos y evaluaciones.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear primer curso'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _CourseCard(
      {required this.course,
      required this.onTap,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final pendingEvals = (course['pendingEvals'] as int?) ?? 0;
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
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
                                color: Color(0xFF1A1A2E)),
                          ),
                          Text(
                            course['code'] as String,
                            style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 13),
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
                          border:
                              Border.all(color: Colors.orange.shade300),
                        ),
                        child: Text(
                          '$pendingEvals activa${pendingEvals > 1 ? 's' : ''}',
                          style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoPill(Icons.person_rounded,
                        '${course['studentCount']} estudiantes'),
                    const SizedBox(width: 8),
                    _InfoPill(Icons.group_rounded,
                        '${course['groupCount']} grupos'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => Get.toNamed(
                        '/professor/create-evaluation',
                        arguments: {
                          'courseId': course['id'],
                          'courseName': course['title'],
                          'courseCode': course['code'],
                        },
                      )?.then((_) =>
                          Get.find<ProfessorController>().loadCourses()),
                      icon: const Icon(Icons.add_circle_outline,
                          size: 16),
                      label: const Text('Nueva eval.'),
                      style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4B3CF0)),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444), size: 20),
                      tooltip: 'Eliminar',
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Toca para ver grupos y evaluaciones',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
          ),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EFFE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4B3CF0)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4B3CF0),
                  fontWeight: FontWeight.w500)),
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
  final VoidCallback? onTap;
  const _ActionCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 3),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }
}