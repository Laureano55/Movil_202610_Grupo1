// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/student_controller.dart';
import 'student_course_classmates_page.dart';

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

class StudentHomePage extends GetView<StudentController> {
  const StudentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = const Color(0xFF4B3CF0);
    final accent = const Color(0xFF3ECFCF);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Panel del Estudiante',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Unirse a curso',
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => _showJoinCourseDialog(context),
          ),
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
                    'Bienvenido, Estudiante',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Progreso general',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${(controller.overallProgress * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: controller.overallProgress,
                            backgroundColor: Colors.white30,
                            color: accent,
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _MiniStat(
                              label: 'Completadas',
                              value: '${controller.totalCompleted}',
                              color: accent,
                            ),
                            const SizedBox(width: 20),
                            _MiniStat(
                              label: 'Pendientes',
                              value: '${controller.totalActiveEvals}',
                              color: controller.totalActiveEvals > 0
                                  ? Colors.orange.shade300
                                  : Colors.white60,
                            ),
                            const SizedBox(width: 20),
                            _MiniStat(
                              label: 'Cursos',
                              value: '${controller.enrolledCourses.length}',
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
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
                  if (controller.totalActiveEvals > 0)
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.notifications_active_rounded,
                              color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tienes ${controller.totalActiveEvals} evaluación'
                              '${controller.totalActiveEvals > 1 ? 'es' : ''}'
                              ' pendiente'
                              '${controller.totalActiveEvals > 1 ? 's' : ''}'
                              ' por completar.',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                          onPressed: () => _showJoinCourseDialog(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Unirme'),
                          style: TextButton.styleFrom(foregroundColor: primary),
                        ),
                      ],
                    ),
                  ),
                  ...controller.enrolledCourses.map((course) =>
                      _EnrolledCourseCard(
                        course: course,
                        onTap: () => Get.to(
                          () => StudentCourseClassmatesPage(
                            courseId: course['id'] as String,
                            courseTitle: course['title'] as String,
                            courseCode: course['code'] as String,
                          ),
                        ),
                        onEvaluate: () => controller
                            .completeEvaluation(course['id'] as String),
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
                        _QuickCard(
                          icon: Icons.rate_review_rounded,
                          title: 'Evaluaciones activas',
                          subtitle: 'Responde dentro del plazo',
                          color: Color(0xFF4B3CF0),
                        ),
                        _QuickCard(
                          icon: Icons.insights_rounded,
                          title: 'Mis resultados',
                          subtitle: 'Según visibilidad del docente',
                          color: Color(0xFF3ECFCF),
                        ),
                        _QuickCard(
                          icon: Icons.group_rounded,
                          title: 'Mi grupo',
                          subtitle: 'Ver compañeros asignados',
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

  void _showJoinCourseDialog(BuildContext context) {
    final codeCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Unirse a un curso'),
        content: TextField(
          controller: codeCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Código del curso',
            hintText: 'Ej. COMP-4321',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.vpn_key_rounded),
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final code = codeCtrl.text.trim();
              if (code.isNotEmpty) {
                Get.back(); // cerrar primero, luego actuar
                controller.joinCourse(code);
              }
            },
            child: const Text('Unirme'),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _EnrolledCourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final VoidCallback onTap;
  final VoidCallback onEvaluate;

  const _EnrolledCourseCard({
    required this.course,
    required this.onTap,
    required this.onEvaluate,
  });

  @override
  Widget build(BuildContext context) {
    final activeEvals = course['activeEvals'] as int;
    final completed = course['completedEvals'] as int;
    final total = course['totalEvals'] as int;
    final progress = total == 0 ? 0.0 : completed / total;

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
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        '${course['code']}  •  ${course['professor']}',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EFFE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    course['myGroup'] as String,
                    style: const TextStyle(
                      color: Color(0xFF4B3CF0),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Barra de progreso del curso
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFFE9E9F8),
                      color: const Color(0xFF4B3CF0),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$completed/$total',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (activeEvals > 0) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onEvaluate,
                  icon: const Icon(Icons.rate_review_rounded, size: 16),
                  label: Text(
                    '$activeEvals evaluación${activeEvals > 1 ? 'es' : ''} activa${activeEvals > 1 ? 's' : ''}',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B3CF0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Toca para ver tus compañeros',
                style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
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

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _QuickCard({
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