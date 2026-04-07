import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/evaluation_controller.dart';
import '../../data/demo_course_store.dart';

class MyResultsPage extends StatefulWidget {
  const MyResultsPage({super.key});

  @override
  State<MyResultsPage> createState() => _MyResultsPageState();
}

class _MyResultsPageState extends State<MyResultsPage> {
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
      await _evalCtrl.loadMyResults(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Mis Resultados',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: Obx(() {
        final results = _evalCtrl.myResults;
        if (results.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EFFE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.insights_rounded,
                        size: 56, color: Color(0xFF4B3CF0)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sin resultados aún',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tus resultados aparecerán aquí cuando el docente publique las evaluaciones.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: results.length,
            itemBuilder: (ctx, i) => _ResultCard(result: results[i]),
          ),
        );
      }),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultCard({required this.result});

  static const _primary = Color(0xFF4B3CF0);

  Color _scoreColor(double avg) {
    if (avg >= 4.0) return Colors.green;
    if (avg >= 3.0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final eval = (result['evaluation'] as Map<String, dynamic>?) ?? {};
    final overallAvg = (result['overallAverage'] as double?) ?? 0.0;
    final criterionAverages =
        (result['criterionAverages'] as Map<String, dynamic>?) ?? {};
    final responseCount = (result['responseCount'] as int?) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primary, const Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        eval['activityName']?.toString() ?? 'Evaluación',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 17),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          overallAvg.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 36),
                        ),
                        const Text('/ 5.0',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: overallAvg / 5.0,
                    backgroundColor: Colors.white30,
                    color: Colors.white,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people_rounded,
                        size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text('$responseCount evaluaciones recibidas',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    const Spacer(),
                    const Icon(Icons.group_rounded,
                        size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(eval['categoryName']?.toString() ?? '',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          // Star rating display
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starFill = overallAvg - i;
                IconData icon;
                if (starFill >= 1) {
                  icon = Icons.star_rounded;
                } else if (starFill > 0) {
                  icon = Icons.star_half_rounded;
                } else {
                  icon = Icons.star_border_rounded;
                }
                return Icon(icon,
                    color: Colors.amber.shade500, size: 32);
              }),
            ),
          ),

          // Criteria breakdown
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Desglose por criterio',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 12),
                ...criterionAverages.entries.map((entry) {
                  final val = (entry.value as num).toDouble();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(entry.key,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4B5563))),
                        ),
                        Expanded(
                          flex: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: val / 5.0,
                              backgroundColor: const Color(0xFFE5E7EB),
                              color: _scoreColor(val),
                              minHeight: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 36,
                          child: Text(
                            val.toStringAsFixed(1),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _scoreColor(val)),
                          ),
                        ),
                        SizedBox(
                          width: 20,
                          child: Row(
                            children: List.generate(1, (_) {
                              return Icon(
                                val >= 4
                                    ? Icons.trending_up_rounded
                                    : val >= 3
                                        ? Icons.trending_flat_rounded
                                        : Icons.trending_down_rounded,
                                size: 14,
                                color: _scoreColor(val),
                              );
                            }),
                          ),
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
  }
}