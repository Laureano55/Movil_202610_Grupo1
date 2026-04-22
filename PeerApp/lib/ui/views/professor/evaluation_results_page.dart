import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/professor_controller.dart';
import '../../viewmodels/evaluation_controller.dart';

class EvaluationResultsPage extends StatefulWidget {
  const EvaluationResultsPage({super.key});

  @override
  State<EvaluationResultsPage> createState() => _EvaluationResultsPageState();
}

class _EvaluationResultsPageState extends State<EvaluationResultsPage> {
  static const _primary = Color(0xFF4B3CF0);

  final ProfessorController _profCtrl = Get.find<ProfessorController>();
  final EvaluationController _evalCtrl = Get.find<EvaluationController>();

  String? _selectedCourseId;
  String? _selectedEvalId;
  String? _selectedGroupName;
  int _tabIndex = 0; // 0=By Activity, 1=Course General, 2=By Student
  late final Worker _coursesWorker;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _selectedCourseId = args['courseId']?.toString();
    _selectedEvalId = args['evaluationId']?.toString();
    _selectedGroupName = args['groupName']?.toString();

    _coursesWorker = ever<List<Map<String, dynamic>>>(_profCtrl.courses, (_) {
      _syncCourseSelection();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncCourseSelection();
    });
  }

  @override
  void dispose() {
    _coursesWorker.dispose();
    super.dispose();
  }

  void _syncCourseSelection() {
    final courses = _profCtrl.courses;
    if (courses.isEmpty) return;

    final validCourseIds = courses.map((c) => c['id'].toString()).toSet();
    final preferredCourseId =
        _selectedCourseId != null && validCourseIds.contains(_selectedCourseId)
            ? _selectedCourseId
            : courses.first['id'].toString();

    if (preferredCourseId != _selectedCourseId) {
      _loadCourse(preferredCourseId, preserveEvaluationId: _selectedEvalId);
    } else if (_selectedEvalId == null && _evalCtrl.courseEvaluations.isNotEmpty) {
      _loadEvaluation(_evalCtrl.courseEvaluations.first['id'].toString());
    }
  }

  Future<void> _loadCourse(
    String? courseId, {
    String? preserveEvaluationId,
  }) async {
    if (courseId == null || courseId.isEmpty) return;

    setState(() {
      _selectedCourseId = courseId;
      _selectedEvalId = null;
      _selectedGroupName = null;
      _tabIndex = 0;
    });

    _evalCtrl.evaluationResults.value = null;
    await _evalCtrl.loadCourseEvaluations(courseId);

    final evals = _evalCtrl.courseEvaluations;
    if (evals.isEmpty) {
      setState(() {
        _selectedEvalId = null;
      });
      return;
    }

    final targetEvalId = preserveEvaluationId != null &&
            evals.any((e) => e['id'].toString() == preserveEvaluationId)
        ? preserveEvaluationId
        : evals.first['id'].toString();

    await _loadEvaluation(targetEvalId);
  }

  Future<void> _loadEvaluation(
    String evaluationId, {
    String? preferredGroup,
  }) async {
    setState(() {
      _selectedEvalId = evaluationId;
      _selectedGroupName = null;
      _tabIndex = 0;
    });

    await _evalCtrl.loadEvaluationResults(evaluationId);
    final results = _evalCtrl.evaluationResults.value;
    final groups = _groupNames(results);

    setState(() {
      _selectedGroupName = groups.isEmpty
          ? null
          : (preferredGroup != null && groups.contains(preferredGroup)
              ? preferredGroup
              : groups.first);
    });
  }

  List<String> _groupNames(Map<String, dynamic>? results) {
    final byGroup = (results?['byGroup'] as Map<String, dynamic>? ?? {});
    final groupNames = byGroup.keys.map((e) => e.toString()).toList();
    groupNames.sort();
    return groupNames;
  }

  Map<String, dynamic>? _courseById(String? courseId) {
    if (courseId == null) return null;
    for (final course in _profCtrl.courses) {
      if (course['id'].toString() == courseId) return course;
    }
    return null;
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

  Map<String, List<Map<String, dynamic>>> _evaluationsGroupedByActivity(
    List<Map<String, dynamic>> evaluations,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final eval in evaluations) {
      final activity = (eval['activityName'] ?? 'Sin nombre').toString();
      grouped.putIfAbsent(activity, () => <Map<String, dynamic>>[]).add(eval);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

    final sorted = <String, List<Map<String, dynamic>>>{};
    for (final entry in entries) {
      final values = [...entry.value]
        ..sort((a, b) =>
            (a['categoryName'] ?? '').toString().toLowerCase().compareTo(
                  (b['categoryName'] ?? '').toString().toLowerCase(),
                ));
      sorted[entry.key] = values;
    }
    return sorted;
  }

  Future<void> _showEvaluationGroupedPicker(
    List<Map<String, dynamic>> evaluations,
  ) async {
    if (evaluations.isEmpty) return;

    final grouped = _evaluationsGroupedByActivity(evaluations);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF9FAFB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.82,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Selecciona evaluación y grupo',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Text(
                    'Agrupadas por actividad para evitar listas largas.',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    children: grouped.entries.map((entry) {
                      final activity = entry.key;
                      final activityEvals = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ExpansionTile(
                          initiallyExpanded: activityEvals.length <= 2,
                          title: Text(
                            activity,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${activityEvals.length} variante${activityEvals.length == 1 ? '' : 's'} por grupo',
                            style: const TextStyle(fontSize: 12),
                          ),
                          children: activityEvals.map((eval) {
                            final evalId = eval['id'].toString();
                            final category =
                                (eval['categoryName'] ?? 'Sin grupo').toString();
                            final status = (eval['status'] ?? 'draft').toString();
                            final selected = evalId == _selectedEvalId;

                            return ListTile(
                              leading: CircleAvatar(
                                radius: 15,
                                backgroundColor:
                                    _statusColor(status).withOpacity(0.15),
                                child: Text(
                                  category.isNotEmpty
                                      ? category.substring(0, 1).toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text('Grupo: $category'),
                              subtitle: Text(
                                _statusLabel(status),
                                style: TextStyle(
                                  color: _statusColor(status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: selected
                                  ? const Icon(Icons.check_circle_rounded,
                                      color: Color(0xFF4B3CF0))
                                  : null,
                              onTap: () async {
                                Navigator.of(ctx).pop();
                                await _loadEvaluation(evalId);
                              },
                            );
                          }).toList(growable: false),
                        ),
                      );
                    }).toList(growable: false),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Resultados de evaluaciones',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Obx(() {
        final courses = _profCtrl.courses;
        final evals = _evalCtrl.courseEvaluations;
        final selectedCourse = _courseById(_selectedCourseId);

        if (_profCtrl.isLoadingCourses.value && courses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (courses.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school_outlined,
                      size: 64, color: Color(0xFF9CA3AF)),
                  SizedBox(height: 16),
                  Text(
                    'No hay cursos disponibles',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Color(0xFF4B5563)),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Crea un curso desde el panel del profesor para ver sus evaluaciones y resultados.',
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
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Curso',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                          fontSize: 12)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCourseId,
                    hint: const Text('Escoge un curso'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: courses
                        .map((course) => DropdownMenuItem<String>(
                              value: course['id'].toString(),
                              child: Text(
                                '${course['title']} (${course['code']})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (value) => _loadCourse(value),
                  ),
                  if (selectedCourse != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedCourse['title'].toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedCourse['code'].toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${evals.length} evaluaciones',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B3CF0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text('Evaluación',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                          fontSize: 12)),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _showEvaluationGroupedPicker(evals),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Builder(
                              builder: (_) {
                                if (_selectedEvalId == null) {
                                  return const Text(
                                    'Escoge una evaluación',
                                    style: TextStyle(color: Color(0xFF6B7280)),
                                  );
                                }
                                final selected = evals.firstWhere(
                                  (e) => e['id'].toString() == _selectedEvalId,
                                  orElse: () => <String, dynamic>{},
                                );
                                if (selected.isEmpty) {
                                  return const Text(
                                    'Escoge una evaluación',
                                    style: TextStyle(color: Color(0xFF6B7280)),
                                  );
                                }
                                final activity =
                                    (selected['activityName'] ?? '').toString();
                                final category =
                                    (selected['categoryName'] ?? '').toString();
                                return Text(
                                  category.isEmpty
                                      ? activity
                                      : '$activity  -  $category',
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.unfold_more_rounded,
                              color: Color(0xFF6B7280)),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedEvalId != null) ...[
                    const SizedBox(height: 12),
                    Builder(builder: (ctx) {
                      final eval = evals.firstWhere(
                          (e) => e['id'].toString() == _selectedEvalId,
                          orElse: () => {});
                      if (eval.isEmpty) return const SizedBox();
                      final status = (eval['status'] ?? 'draft').toString();
                      return Container(
                        padding: const EdgeInsets.all(14),
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
                                        'Nombre de la evaluación',
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
                                      Text('Categoría de grupo',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500)),
                                      Text(eval['categoryName'].toString(),
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
                                      Text('Visibilidad',
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
                                                ? 'Privada'
                                                : 'Pública',
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
                        label: 'Course General',
                        icon: Icons.trending_up_rounded,
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
                                'Aún no hay resultados disponibles.\n'
                                'La evaluación aparecerá aquí cuando los estudiantes empiecen a responder.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF6B7280)),
                            ),
                          ),
                        );
                      }
                      if (_tabIndex == 0) {
                        return _ByActivityTab(results: results);
                      } else if (_tabIndex == 1) {
                          return _CourseGeneralTab(
                            courseEvaluations: evals,
                            selectedEvaluationResults: results,
                          );
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
  final String? selectedGroupName;
  final ValueChanged<String?> onGroupChanged;

  const _ByGroupTab({
    required this.results,
    required this.selectedGroupName,
    required this.onGroupChanged,
  });

  Color _scoreColor(double avg) {
    if (avg >= 4.0) return Colors.green;
    if (avg >= 3.0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final byGroup =
        (results['byGroup'] as Map<String, dynamic>? ?? {});
    final byStudent = (results['byStudent'] as List<dynamic>? ?? [])
      .cast<Map<String, dynamic>>();

    if (byGroup.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Aún no hay datos por grupo.',
            style: TextStyle(color: Color(0xFF9CA3AF)),
          ),
        ),
      );
    }

    final sortedGroups = byGroup.values.toList()
      ..sort((a, b) => (b['average'] as double)
          .compareTo(a['average'] as double));
    final availableGroups = sortedGroups
        .map((g) => g['name'].toString())
        .toList(growable: false);
    final groupName = selectedGroupName != null &&
            availableGroups.contains(selectedGroupName)
        ? selectedGroupName!
        : availableGroups.first;
    final groupData = byGroup[groupName] as Map<String, dynamic>?;
    final groupStudents = byStudent
        .where((student) => student['group'].toString() == groupName)
        .toList(growable: false);
    final overallAvg = (groupData?['average'] as double?) ?? 0.0;
    final evaluationData = results['evaluation'] as Map<String, dynamic>? ?? {};
    final criteria = (evaluationData['criteria'] as List<dynamic>? ?? [])
        .map((criterion) => criterion.toString())
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Grupo',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: groupName,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: Color(0xFFF9FAFB),
                ),
                items: availableGroups
                    .map(
                      (name) => DropdownMenuItem<String>(
                        value: name,
                        child: Text(name),
                      ),
                    )
                    .toList(),
                onChanged: onGroupChanged,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    groupName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const Spacer(),
                  Text(
                    overallAvg.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: _scoreColor(overallAvg),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: overallAvg / 5.0,
                  backgroundColor: const Color(0xFFE5E7EB),
                  color: _scoreColor(overallAvg),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Promedio: ${overallAvg.toStringAsFixed(1)} / 5.0 · ${groupData?['count'] ?? 0} estudiantes',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Promedio por criterio en este grupo',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: criteria.map((criterion) {
              final vals = groupStudents
                  .map((student) => ((student['criterionAverages']
                              as Map<String, dynamic>?)?[criterion]
                          as double?) ??
                      0.0)
                  .where((value) => value > 0)
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
        ),
        const SizedBox(height: 16),
        const Text(
          'Estudiantes del grupo',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 12),
        if (groupStudents.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No hay estudiantes con resultados en este grupo.',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          )
        else
          ...groupStudents.map((student) {
            final avg = (student['overallAverage'] as double?) ?? 0.0;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _scoreColor(avg).withOpacity(0.15),
                  child: Text(
                    avg.toStringAsFixed(1),
                    style: TextStyle(
                      color: _scoreColor(avg),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                title: Text(student['name'].toString()),
                subtitle: Text(
                  '${student['responseCount'] as int? ?? 0} evaluaciones',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                trailing: Text(
                  '${avg.toStringAsFixed(1)}/5',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _scoreColor(avg),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _CourseGeneralTab extends StatelessWidget {
  final List<Map<String, dynamic>> courseEvaluations;
  final Map<String, dynamic> selectedEvaluationResults;

  const _CourseGeneralTab({
    required this.courseEvaluations,
    required this.selectedEvaluationResults,
  });

  double _averageFrom(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  @override
  Widget build(BuildContext context) {
    if (courseEvaluations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Aún no hay evaluaciones disponibles en el curso.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9CA3AF)),
          ),
        ),
      );
    }

    final evaluationAverages = courseEvaluations
        .map((e) => (e['averageEvaluation'] as double?) ?? (e['overall'] as double?) ?? 0.0)
        .toList(growable: false);
    final evaluatedAverages = evaluationAverages
      .where((avg) => avg > 0)
      .toList(growable: false);
    final overall = _averageFrom(evaluatedAverages);
    final totalResponses = courseEvaluations.fold<int>(
      0,
      (sum, e) => sum + ((e['totalResponses'] as int?) ?? 0),
    );

    final selectedEval =
        selectedEvaluationResults['evaluation'] as Map<String, dynamic>? ?? {};
    final criteria = (selectedEval['criteria'] as List<dynamic>? ?? [])
        .map((c) => c.toString())
        .toList(growable: false);
    final selectedByGroup =
        (selectedEvaluationResults['byGroup'] as Map<String, dynamic>? ?? {});

    final criteriaAverages = <String, double>{};
    for (final criterion in criteria) {
      final vals = selectedByGroup.values
          .map((groupData) =>
              ((groupData['criterionAverages'] as Map<String, dynamic>?)?[criterion]
                      as double?) ??
                  0.0)
          .where((v) => v > 0)
          .toList(growable: false);
      criteriaAverages[criterion] = _averageFrom(vals);
    }

    if (evaluatedAverages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Aún no hay resultados disponibles en el curso.\n'
            'Los datos aparecerán cuando los estudiantes comiencen a responder evaluaciones.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9CA3AF)),
          ),
        ),
      );
    }

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
                  const Text('Desempeño General del Curso',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              Text(overall.toStringAsFixed(1),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w900)),
              Text('Calificación Promedio (sobre 5.0)',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Promedio general del curso calculado como promedio de los promedios de cada evaluación.',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text('$totalResponses respuestas registradas en total',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Criteria averages breakdown
        if (criteria.isNotEmpty && selectedByGroup.isNotEmpty) ...[
          const Text('Promedio por Criterio (evaluación seleccionada)',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: criteria.map((criterion) {
                final avg = criteriaAverages[criterion] ?? 0.0;

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
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            )),
                      ),
                      Expanded(
                        flex: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: avg / 5.0,
                            backgroundColor: const Color(0xFFE5E7EB),
                            color: barColor,
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${avg.toStringAsFixed(1)}/5',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: barColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Score distribution
        if (evaluatedAverages.isNotEmpty) ...[
          const Text('Distribución de Promedios por Evaluación',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          _ScoreDistribution(
            students: evaluatedAverages
                .map((avg) => <String, dynamic>{'overallAverage': avg})
                .toList(),
          ),
        ],

        // Summary statistics
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Estadísticas del Curso (General)',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 12),
                _StatRow('Evaluaciones con respuestas validas',
                  evaluatedAverages.length.toString()),
              _StatRow('Promedio del curso',
                  '${overall.toStringAsFixed(2)}/5.0'),
              Builder(builder: (_) {
                final scores = List<double>.from(evaluatedAverages)..sort();
                final min = scores.isEmpty ? 0.0 : scores.first;
                final max = scores.isEmpty ? 0.0 : scores.last;
                return Column(
                  children: [
                    _StatRow(
                        'Calificación mínima',
                        '${min.toStringAsFixed(2)}/5.0'),
                    _StatRow(
                        'Calificación máxima',
                        '${max.toStringAsFixed(2)}/5.0'),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}


class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF6B7280), fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF1A1A2E))),
        ],
      ),
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