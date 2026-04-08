import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/evaluation_controller.dart';
import '../../data/demo_course_store.dart';

class ActiveEvaluationsPage extends StatefulWidget {
  const ActiveEvaluationsPage({super.key});

  @override
  State<ActiveEvaluationsPage> createState() =>
      _ActiveEvaluationsPageState();
}

class _ActiveEvaluationsPageState extends State<ActiveEvaluationsPage> {
  static const _primary = Color(0xFF4B3CF0);
  final EvaluationController _evalCtrl = Get.find();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final email = await DemoCourseStore().currentEmail();
    if (email != null) {
      await _evalCtrl.loadActiveEvaluations(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Evaluaciones Activas',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: Obx(() {
        if (_evalCtrl.isLoadingEvals.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final evals = _evalCtrl.activeEvaluations;
        if (evals.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle_rounded,
                        size: 56, color: Colors.green.shade400),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '¡Estás al día!',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No tienes evaluaciones pendientes en este momento.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: Color(0xFF6B7280), fontSize: 15),
                  ),
                ],
              ),
            ),
          );
        }

        final pending =
            evals.where((e) => e['completed'] == false).toList();
        final completed =
            evals.where((e) => e['completed'] == true).toList();

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (pending.isNotEmpty) ...[
                _SectionLabel(
                  label: 'Por completar (${pending.length})',
                  color: Colors.orange.shade700,
                ),
                const SizedBox(height: 10),
                ...pending.map((e) => _EvalCard(
                      eval: e,
                      isCompleted: false,
                      onTap: () => Get.toNamed(
                        '/student/evaluation-form',
                        arguments: e,
                      )?.then((_) => _load()),
                    )),
              ],
              if (completed.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SectionLabel(
                  label: 'Completadas (${completed.length})',
                  color: Colors.green.shade700,
                ),
                const SizedBox(height: 10),
                ...completed.map((e) => _EvalCard(
                      eval: e,
                      isCompleted: true,
                      onTap: null,
                    )),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      ],
    );
  }
}

class _EvalCard extends StatelessWidget {
  final Map<String, dynamic> eval;
  final bool isCompleted;
  final VoidCallback? onTap;
  const _EvalCard(
      {required this.eval,
      required this.isCompleted,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pending = (eval['pendingRatings'] as int?) ?? 0;
    final total = (eval['totalRatable'] as int?) ?? 0;
    final progress =
        total == 0 ? 1.0 : (total - pending).toDouble() / total;

    final endDate =
        DateTime.tryParse((eval['endDate'] ?? '').toString());
    final remainingHours = endDate != null
        ? endDate.difference(DateTime.now()).inHours
        : 0;
    final isUrgent = remainingHours < 24 && !isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isUrgent
            ? Border.all(color: Colors.orange.shade300, width: 1.5)
            : null,
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
                      child: Text(
                        eval['activityName'].toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF1A1A2E)),
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded,
                                size: 14, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text('Completada',
                                style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    else if (isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${remainingHours}h restantes',
                          style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.group_rounded,
                        size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      eval['myGroup'].toString(),
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.school_rounded,
                        size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      eval['courseName'].toString(),
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: const Color(0xFFE5E7EB),
                          color: isCompleted
                              ? Colors.green
                              : const Color(0xFF4B3CF0),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isCompleted
                          ? '$total/$total'
                          : '${total - pending}/$total',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                if (!isCompleted) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.rate_review_rounded,
                          size: 16),
                      label: Text(pending == total
                          ? 'Comenzar evaluación'
                          : 'Continuar evaluación ($pending pendientes)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B3CF0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}