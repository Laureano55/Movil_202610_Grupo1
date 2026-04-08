// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/student_controller.dart';
import 'student_course_classmates_page.dart';

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

class StudentHomePage extends GetView<StudentController> {
  const StudentHomePage({super.key});

  static const _primary = Color(0xFF4B3CF0);
  static const _accent = Color(0xFF3ECFCF);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Panel del Estudiante',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Unirse a curso',
            icon: const Icon(Icons.add_link_rounded),
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
        if (controller.isLoadingCourses.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            // ── Progress banner ───────────────────────────────────────────
            Container(
              color: _primary,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bienvenido, Estudiante',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 14)),
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
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Progreso general',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            Text(
                              '${(controller.overallProgress * 100).round()}%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: controller.overallProgress,
                            backgroundColor: Colors.white30,
                            color: _accent,
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _MiniStat(
                                label: 'Eval. activas',
                                value:
                                    '${controller.totalActiveEvals}',
                                color: controller.totalActiveEvals > 0
                                    ? Colors.orange.shade300
                                    : Colors.white60),
                            const SizedBox(width: 20),
                            _MiniStat(
                                label: 'Cursos',
                                value:
                                    '${controller.enrolledCourses.length}',
                                color: Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable content ────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.loadEnrolledCourses,
                child: ListView(
                  physics: const _LightBouncePhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    // Urgent alert
                    if (controller.totalActiveEvals > 0)
                      GestureDetector(
                        onTap: () => Get.toNamed(
                            '/student/active-evaluations')?.then(
                            (_) => controller.loadEnrolledCourses()),
                        child: Container(
                          margin:
                              const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.orange.shade200),
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
                                  '${controller.totalActiveEvals > 1 ? 's' : ''}.'
                                  ' ¡Toca para responder!',
                                  style: TextStyle(
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: Colors.orange.shade700),
                            ],
                          ),
                        ),
                      ),

                    // Mis cursos section
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Mis cursos',
                              style:
                                  theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A2E),
                              )),
                          TextButton.icon(
                            onPressed: () =>
                                _showJoinCourseDialog(context),
                            icon: const Icon(Icons.add_rounded,
                                size: 18),
                            label: const Text('Unirme'),
                            style: TextButton.styleFrom(
                                foregroundColor: _primary),
                          ),
                        ],
                      ),
                    ),

                    if (controller.enrolledCourses.isEmpty)
                      _EmptyCoursesHint(
                          onJoinTap: () =>
                              _showJoinCourseDialog(context))
                    else
                      ...controller.enrolledCourses
                          .map((course) => _EnrolledCourseCard(
                                course: course,
                                onTap: () => Get.to(
                                  () => StudentCourseClassmatesPage(
                                    courseId: course['id'] as String,
                                    courseTitle:
                                        course['title'] as String,
                                    courseCode: course['code'] as String,
                                  ),
                                )?.then((_) =>
                                    controller.loadEnrolledCourses()),
                                onEvaluate: () => Get.toNamed(
                                      '/student/active-evaluations',
                                    )?.then((_) =>
                                        controller.loadEnrolledCourses()),
                              )),

                    // Quick actions
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Text('Acciones rápidas',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                          )),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _QuickCard(
                            icon: Icons.rate_review_rounded,
                            title: 'Evaluaciones activas',
                            subtitle: 'Responde dentro del plazo',
                            color: _primary,
                            onTap: () => Get.toNamed(
                                    '/student/active-evaluations')
                                ?.then((_) =>
                                    controller.loadEnrolledCourses()),
                          ),
                          _QuickCard(
                            icon: Icons.insights_rounded,
                            title: 'Mis resultados',
                            subtitle: 'Ver mis calificaciones',
                            color: _accent,
                            onTap: () =>
                                Get.toNamed('/student/my-results'),
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
          TextButton(
              onPressed: Get.back, child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final code = codeCtrl.text.trim();
              if (code.isNotEmpty) {
                Get.back();
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

// ── Helpers ───────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _EmptyCoursesHint extends StatelessWidget {
  final VoidCallback onJoinTap;
  const _EmptyCoursesHint({required this.onJoinTap});

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
            const Text('Aún no estás inscrito en ningún curso',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 6),
            const Text(
                'Pídele a tu docente el código del curso e ingrésalo aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onJoinTap,
              icon: const Icon(Icons.add_link_rounded),
              label: const Text('Ingresar código'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnrolledCourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final VoidCallback onTap;
  final VoidCallback onEvaluate;
  const _EnrolledCourseCard(
      {required this.course,
      required this.onTap,
      required this.onEvaluate});

  @override
  Widget build(BuildContext context) {
    final activeEvals = (course['activeEvals'] as int?) ?? 0;
    final completed = (course['completedEvals'] as int?) ?? 0;
    final total = (course['totalEvals'] as int?) ?? 0;
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
              offset: const Offset(0, 3)),
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
                          Text(course['title'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF1A1A2E))),
                          Text(
                              '${course['code']}  ·  ${course['professor']}',
                              style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12)),
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
                      child: Text(course['myGroup'] as String,
                          style: const TextStyle(
                              color: Color(0xFF4B3CF0),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                    Text('$completed/$total',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500)),
                  ],
                ),
                if (activeEvals > 0) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onEvaluate,
                      icon:
                          const Icon(Icons.rate_review_rounded, size: 16),
                      label: Text(
                          '$activeEvals evaluación${activeEvals > 1 ? 'es' : ''} activa${activeEvals > 1 ? 's' : ''}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B3CF0),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('Toca para ver tus compañeros',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
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
  final VoidCallback? onTap;
  const _QuickCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
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
                  offset: const Offset(0, 2)),
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
      ),
    );
  }
}