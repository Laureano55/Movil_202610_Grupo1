import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/evaluation_controller.dart';
import '../../viewmodels/professor_controller.dart';

class EvaluationResultsPage extends StatefulWidget {
  const EvaluationResultsPage({super.key});

  @override
  State<EvaluationResultsPage> createState() => _EvaluationResultsPageState();
}

class _EvaluationResultsPageState extends State<EvaluationResultsPage> {
  static const _primary = Color(0xFF4B3CF0);

  late String _courseId;
  String? _selectedEvalId;
  int _tabIndex = 0; // 0=By Activity, 1=By Group, 2=By Student

  final EvaluationController _evalCtrl = Get.find();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _courseId = args['courseId'] ?? '';
    _evalCtrl.loadCourseEvaluations(_courseId);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Activa';
      case 'closed':
        return 'Cerrada';
      default:
        return 'Borrador';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Assessment Results',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Obx(() {
        final evals = _evalCtrl.courseEvaluations;

        if (evals.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assessment_outlined,
                      size: 64, color: Color(0xFF9CA3AF)),
                  SizedBox(height: 16),
                  Text(
                    'No evaluations yet',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Color(0xFF4B5563)),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create an evaluation from the professor panel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            // ── Evaluation selector ────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Assessment Name header card
                  if (_selectedEvalId != null) ...[
                    Builder(builder: (ctx) {
                      final eval = evals.firstWhere(
                          (e) => e['id'].toString() == _selectedEvalId,
                          orElse: () => {});
                      if (eval.isEmpty) return const SizedBox();
                      final status = (eval['status'] ?? 'draft').toString();
                      return Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Assessment Name',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      Text(
                                        eval['activityName'].toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _statusLabel(status),
                                    style: TextStyle(
                                        color: _statusColor(status),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Group Category',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500)),
                                      Text(
                                          eval['categoryName'].toString(),
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Visibility',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500)),
                                      Row(
                                        children: [
                                          Icon(
                                            eval['visibility'] == 'private'
                                                ? Icons.visibility_off_rounded
                                                : Icons.visibility_rounded,
                                            size: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            eval['visibility'] == 'private'
                                                ? 'Private'
                                                : 'Public',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const Text('Select evaluation',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                          fontSize: 12)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedEvalId,
                    hint: const Text('Choose an evaluation'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: evals
                        .map((e) => DropdownMenuItem<String>(
                              value: e['id'].toString(),
                              child: Text(
                                e['activityName'].toString(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedEvalId = v;
                        _tabIndex = 0;
                      });
                      if (v != null) {
                        _evalCtrl.loadEvaluationResults(v);
                      }
                    },
                  ),
                ],
              ),
            ),

            // ── Tabs ─────────────────────────────────────────────────────
            if (_selectedEvalId != null)
              Container(
                color: Colors.white,
                child: Row(
                  children: [
                    _TabBtn(
                        label: 'By Activity',
                        icon: Icons.bar_chart_rounded,
                        selected: _tabIndex == 0,
                        onTap: () => setState(() => _tabIndex = 0)),
                    _TabBtn(
                        label: 'By Group',
                        icon: Icons.group_rounded,
                        selected: _tabIndex == 1,
                        onTap: () => setState(() => _tabIndex = 1)),
                    _TabBtn(
                        label: 'By Student',
                        icon: Icons.person_rounded,
                        selected: _tabIndex == 2,
                        onTap: () => setState(() => _tabIndex = 2)),
                  ],
                ),
              ),

            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: _selectedEvalId == null
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app_rounded,
                              size: 48, color: Color(0xFF9CA3AF)),
                          SizedBox(height: 12),
                          Text('Select an evaluation to view results',
                              style: TextStyle(color: Color(0xFF9CA3AF))),
                        ],
                      ))
                  : Obx(() {
                      if (_evalCtrl.isLoadingResults.value) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final results = _evalCtrl.evaluationResults.value;
                      if (results == null) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No results available yet.\n'
                              'Evaluations will appear here once students submit.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF6B7280)),
                            ),
                          ),
                        );
                      }
                      if (_tabIndex == 0) {
                        return _ByActivityTab(results: results);
                      } else if (_tabIndex == 1) {
                        return _ByGroupTab(results: results);
                      } else {
                        return _ByStudentTab(results: results);
                      }
                    }),
            ),
          ],
        );
      }),
    );
  }
}

// ── Tab views ─────────────────────────────────────────────────────────────────

class _ByActivityTab extends StatelessWidget {
  final Map<String, dynamic> results;
  const _ByActivityTab({required this.results});

  @override
  Widget build(BuildContext context) {
    final overall = (results['overall'] as double?) ?? 0.0;
    final totalResponses = (results['totalResponses'] as int?) ?? 0;
    final byStudent =
        (results['byStudent'] as List<dynamic>? ?? []).cast<Map>();
    final eval = results['evaluation'] as Map<String, dynamic>? ?? {};
    final criteria = (eval['criteria'] as List<dynamic>? ?? [])
        .map((c) => c.toString())
        .toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Overall Performance card  
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4B3CF0), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.trending_up_rounded,
                      color: Colors.white70, size: 18),
                  const SizedBox(width: 6),
                  const Text('Overall Performance',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              Text(overall.toStringAsFixed(1),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w900)),
              Text('Average Score (out of 5.0)',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 16),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Progress',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      Text('${(overall / 5.0 * 100).round()}%',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: overall / 5.0,
                    backgroundColor: Colors.white30,
                    color: Colors.white,
                    minHeight: 6,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'This represents the average score across all students and groups in this assessment.',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text('$totalResponses responses registered',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Criteria averages breakdown
        if (criteria.isNotEmpty && byStudent.isNotEmpty) ...[
          const Text('Average by Criterion',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          _CriteriaBreakdown(
              students: byStudent, criteria: criteria),
          const SizedBox(height: 20),
        ],

        if (byStudent.isNotEmpty) ...[
          const Text('Score Distribution',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          _ScoreDistribution(students: byStudent),
        ],
      ],
    );
  }
}

class _CriteriaBreakdown extends StatelessWidget {
  final List<Map> students;
  final List<String> criteria;
  const _CriteriaBreakdown(
      {required this.students, required this.criteria});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: criteria.map((criterion) {
          // Calculate average for this criterion across all students
          final vals = students
              .map((s) =>
                  ((s['criterionAverages']
                          as Map<String, dynamic>?)?[criterion] as double?) ??
                  0.0)
              .where((v) => v > 0)
              .toList();
          final avg = vals.isEmpty
              ? 0.0
              : vals.reduce((a, b) => a + b) / vals.length;

          Color barColor;
          if (avg >= 4.0) {
            barColor = Colors.green;
          } else if (avg >= 3.0) {
            barColor = Colors.orange;
          } else {
            barColor = Colors.red;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(criterion,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF4B5563))),
                ),
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: avg / 5.0,
                      backgroundColor: const Color(0xFFE5E7EB),
                      color: barColor,
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 32,
                  child: Text(
                    avg.toStringAsFixed(1),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: barColor),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ScoreDistribution extends StatelessWidget {
  final List<Map> students;
  const _ScoreDistribution({required this.students});

  @override
  Widget build(BuildContext context) {
    final buckets = [0, 0, 0, 0, 0];
    for (final s in students) {
      final avg = (s['overallAverage'] as double?) ?? 0.0;
      if (avg < 2) {
        buckets[0]++;
      } else if (avg < 3) {
        buckets[1]++;
      } else if (avg < 4) {
        buckets[2]++;
      } else if (avg < 4.5) {
        buckets[3]++;
      } else {
        buckets[4]++;
      }
    }
    final labels = ['<2', '2–3', '3–4', '4–4.5', '≥4.5'];
    final colors = [
      Colors.red.shade400,
      Colors.orange.shade400,
      Colors.yellow.shade700,
      Colors.lightGreen.shade500,
      Colors.green.shade500,
    ];
    final maxVal =
        buckets.reduce((a, b) => a > b ? a : b).toDouble().clamp(1.0, 999.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: List.generate(5, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                    width: 36,
                    child: Text(labels[i],
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280)))),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: buckets[i] / maxVal,
                      backgroundColor: const Color(0xFFE5E7EB),
                      color: colors[i],
                      minHeight: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                    width: 24,
                    child: Text('${buckets[i]}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600))),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ByGroupTab extends StatelessWidget {
  final Map<String, dynamic> results;
  const _ByGroupTab({required this.results});

  Color _scoreColor(double avg) {
    if (avg >= 4.0) return Colors.green;
    if (avg >= 3.0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final byGroup =
        (results['byGroup'] as Map<String, dynamic>? ?? {});
    if (byGroup.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No group data available yet.',
            style: TextStyle(color: Color(0xFF9CA3AF)),
          ),
        ),
      );
    }
    final sorted = byGroup.values.toList()
      ..sort((a, b) => (b['average'] as double)
          .compareTo(a['average'] as double));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sorted.length,
      itemBuilder: (ctx, i) {
        final g = sorted[i] as Map<String, dynamic>;
        final avg = (g['average'] as double? ?? 0.0);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    g['name'].toString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const Spacer(),
                  Text(
                    avg.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: _scoreColor(avg),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: avg / 5.0,
                  backgroundColor: const Color(0xFFE5E7EB),
                  color: _scoreColor(avg),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Average: ${avg.toStringAsFixed(1)} / 5.0  ·  ${g['count']} students',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ByStudentTab extends StatelessWidget {
  final Map<String, dynamic> results;
  const _ByStudentTab({required this.results});

  Color _scoreColor(double avg) {
    if (avg >= 4.0) return Colors.green;
    if (avg >= 3.0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final byStudent =
        (results['byStudent'] as List<dynamic>? ?? []).cast<Map>();
    if (byStudent.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No responses registered yet.',
            style: TextStyle(color: Color(0xFF9CA3AF)),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: byStudent.length,
      itemBuilder: (ctx, i) {
        final s = byStudent[i];
        final avg = (s['overallAverage'] as double?) ?? 0.0;
        final criteria =
            (s['criterionAverages'] as Map<String, dynamic>?) ?? {};

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14)),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: _scoreColor(avg).withOpacity(0.15),
              child: Text(avg.toStringAsFixed(1),
                  style: TextStyle(
                      color: _scoreColor(avg),
                      fontWeight: FontWeight.w900,
                      fontSize: 13)),
            ),
            title: Text(s['name'].toString(),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
                '${s['group']}  ·  ${(s['responseCount'] as int? ?? 0)} evaluations',
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _scoreColor(avg).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${avg.toStringAsFixed(1)}/5',
                    style: TextStyle(
                      color: _scoreColor(avg),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Icon(Icons.expand_more),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Breakdown by Criteria',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF4B5563)),
                    ),
                    const SizedBox(height: 8),
                    ...criteria.entries.map((entry) {
                      final val = entry.value as double;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(entry.key,
                                      style: const TextStyle(fontSize: 13)),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: val / 5.0,
                                      backgroundColor:
                                          const Color(0xFFE5E7EB),
                                      color: _scoreColor(val),
                                      minHeight: 8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(val.toStringAsFixed(1),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Tab button ─────────────────────────────────────────────────────────────────
class _TabBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TabBtn(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  static const _primary = Color(0xFF4B3CF0);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? _primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? _primary : const Color(0xFF9CA3AF)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.normal,
                      color: selected
                          ? _primary
                          : const Color(0xFF9CA3AF))),
            ],
          ),
        ),
      ),
    );
  }
}