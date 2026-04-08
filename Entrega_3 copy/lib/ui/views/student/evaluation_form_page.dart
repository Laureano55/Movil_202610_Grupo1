import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/evaluation_controller.dart';
import '../../data/demo_course_store.dart';

class EvaluationFormPage extends StatefulWidget {
  const EvaluationFormPage({super.key});

  @override
  State<EvaluationFormPage> createState() => _EvaluationFormPageState();
}

class _EvaluationFormPageState extends State<EvaluationFormPage> {
  static const _primary = Color(0xFF4B3CF0);

  late Map<String, dynamic> _eval;
  late List<String> _criteria;

  final EvaluationController _evalCtrl = Get.find();
  String? _currentEmail;

  // selectedPerson -> {criterion -> score}
  Map<String, dynamic>? _currentTeammate;
  final Map<String, int> _currentScores = {};

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _eval = Get.arguments as Map<String, dynamic>? ?? {};
    _criteria = (_eval['criteria'] as List<dynamic>? ?? [])
        .map((c) => c.toString())
        .toList();
    _loadTeammates();
  }

  Future<void> _loadTeammates() async {
    _currentEmail = await DemoCourseStore().currentEmail();
    if (_currentEmail != null) {
      await _evalCtrl.loadTeammatesForEvaluation(
        evaluationId: _eval['id'].toString(),
        evaluatorEmail: _currentEmail!,
      );
    }
  }

  void _selectTeammate(Map<String, dynamic> teammate) {
    setState(() {
      _currentTeammate = teammate;
      _currentScores.clear();
      // Pre-fill if already rated
      final existing = teammate['existingScores'];
      if (existing != null && existing is Map) {
        for (final criterion in _criteria) {
          final val = existing[criterion];
          if (val != null) {
            _currentScores[criterion] = (val as num).toInt();
          }
        }
      }
    });
  }

  Future<void> _submitRating() async {
    if (_currentTeammate == null) return;
    if (_currentScores.length < _criteria.length) {
      Get.snackbar('Incompleto',
          'Debes calificar todos los criterios antes de enviar',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _loading = true);
    try {
      final success = await _evalCtrl.submitResponse(
        evaluationId: _eval['id'].toString(),
        evaluatorEmail: _currentEmail!,
        evaluateeEmail: _currentTeammate!['email'].toString(),
        scores: Map<String, int>.from(_currentScores),
      );
      if (success) {
        setState(() {
          _currentTeammate = null;
          _currentScores.clear();
        });
        // Check if all done
        final remaining =
            _evalCtrl.currentTeammates.where((t) => t['alreadyRated'] == false);
        if (remaining.isEmpty) {
          Get.snackbar('¡Evaluación completa!',
              'Has calificado a todos tus compañeros.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white);
          Get.back();
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Text(
          _eval['activityName']?.toString() ?? 'Evaluación',
          style: const TextStyle(fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Obx(() {
        final teammates = _evalCtrl.currentTeammates;
        final pending =
            teammates.where((t) => t['alreadyRated'] == false).length;
        final done = teammates.length - pending;

        return Column(
          children: [
            // Progress header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$done de ${teammates.length} calificados',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B5563)),
                      ),
                      Text(
                        pending == 0
                            ? '¡Completado!'
                            : '$pending pendiente${pending == 1 ? '' : 's'}',
                        style: TextStyle(
                            color: pending == 0
                                ? Colors.green
                                : Colors.orange.shade700,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value:
                          teammates.isEmpty ? 0 : done / teammates.length,
                      backgroundColor: const Color(0xFFE5E7EB),
                      color: pending == 0 ? Colors.green : _primary,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _currentTeammate == null
                  ? _TeammateList(
                      teammates: teammates,
                      onSelect: _selectTeammate,
                    )
                  : _RatingForm(
                      teammate: _currentTeammate!,
                      criteria: _criteria,
                      scores: _currentScores,
                      loading: _loading,
                      onScoreChanged: (criterion, score) {
                        setState(() => _currentScores[criterion] = score);
                      },
                      onSubmit: _submitRating,
                      onBack: () => setState(() {
                        _currentTeammate = null;
                        _currentScores.clear();
                      }),
                    ),
            ),
          ],
        );
      }),
    );
  }
}

class _TeammateList extends StatelessWidget {
  final List<Map<String, dynamic>> teammates;
  final void Function(Map<String, dynamic>) onSelect;
  const _TeammateList({required this.teammates, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (teammates.isEmpty) {
      return const Center(
          child: Text('Sin compañeros para evaluar',
              style: TextStyle(color: Color(0xFF9CA3AF))));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: teammates.length,
      itemBuilder: (ctx, i) {
        final t = teammates[i];
        final rated = t['alreadyRated'] == true;
        final isSelf = t['isSelf'] == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: rated
                ? Border.all(color: Colors.green.shade200)
                : null,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: rated
                  ? Colors.green.shade100
                  : const Color(0xFFEAE7FF),
              child: Icon(
                rated ? Icons.check_rounded : Icons.person_rounded,
                color:
                    rated ? Colors.green.shade700 : const Color(0xFF4B3CF0),
              ),
            ),
            title: Text(
              '${t['name']}${isSelf ? '  (Yo)' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(t['email'].toString(),
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            trailing: rated
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Calificado',
                        style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  )
                : ElevatedButton(
                    onPressed: () => onSelect(t),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4B3CF0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Calificar',
                        style: TextStyle(fontSize: 13)),
                  ),
            onTap: rated ? () => onSelect(t) : null,
          ),
        );
      },
    );
  }
}

class _RatingForm extends StatelessWidget {
  final Map<String, dynamic> teammate;
  final List<String> criteria;
  final Map<String, int> scores;
  final bool loading;
  final void Function(String, int) onScoreChanged;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const _RatingForm({
    required this.teammate,
    required this.criteria,
    required this.scores,
    required this.loading,
    required this.onScoreChanged,
    required this.onSubmit,
    required this.onBack,
  });

  static const _primary = Color(0xFF4B3CF0);

  @override
  Widget build(BuildContext context) {
    final isSelf = teammate['isSelf'] == true;
    final alreadyRated = teammate['alreadyRated'] == true;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Teammate card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0EFFE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _primary,
                child: Text(
                  (teammate['name'].toString().isNotEmpty
                          ? teammate['name'].toString()[0]
                          : '?')
                      .toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${teammate['name']}${isSelf ? '  (Autoevaluación)' : ''}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    Text(teammate['email'].toString(),
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              if (alreadyRated)
                const Icon(Icons.edit_rounded,
                    color: _primary, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Criteria
        const Text('Calificación por criterios (1-5)',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 4),
        const Text('1 = Deficiente  ·  5 = Excelente',
            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
        const SizedBox(height: 16),

        ...criteria.map((criterion) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scores.containsKey(criterion)
                      ? _primary.withOpacity(0.5)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(criterion,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            if (kCriteriaDescriptions[criterion] != null)
                              Text(
                                  kCriteriaDescriptions[criterion]!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6B7280))),
                          ],
                        ),
                      ),
                      if (scores.containsKey(criterion))
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${scores[criterion]}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      final score = index + 1;
                      final selected = scores[criterion] == score;
                      return GestureDetector(
                        onTap: () => onScoreChanged(criterion, score),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: selected
                                ? _primary
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? _primary
                                  : const Color(0xFFE5E7EB),
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: _primary.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              '$score',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            )),

        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Volver'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: loading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        alreadyRated
                            ? 'Actualizar calificación'
                            : 'Enviar calificación',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}