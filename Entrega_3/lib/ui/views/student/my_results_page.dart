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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final email = await DemoCourseStore().currentEmail();
      if (email != null) {
        await _evalCtrl.loadMyResults(email);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('My Results',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Obx(() {
              final results = _evalCtrl.myResults;
              if (results.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Center(
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
                                'Results Available',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                    color: Color(0xFF1A1A2E)),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Your results will appear here when the professor publishes evaluations.\n\n'
                                'Make sure you have completed your peer evaluations first.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Color(0xFF6B7280), fontSize: 15),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    Get.toNamed('/student/active-evaluations'),
                                icon: const Icon(Icons.rate_review_rounded),
                                label: const Text('Go to Evaluations'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: results.length,
                  itemBuilder: (ctx, i) =>
                      _ResultCard(result: results[i]),
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
          // Header with overall average
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primary, Color(0xFF7C3AED)],
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
                // Assessment Name row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Assessment Name',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                          Text(
                            eval['activityName']?.toString() ?? 'Evaluation',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 17),
                          ),
                        ],
                      ),
                    ),
                    // Results Available badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.green.shade300, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 14, color: Colors.greenAccent),
                          const SizedBox(width: 4),
                          const Text('Results Available',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Your Overall Average
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your Overall Average',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          Text(
                            overallAvg.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                height: 1.1),
                          ),
                          const Text('out of 5.0',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 8),
                          // Stars
                          Row(
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
                                  color: Colors.amber.shade400, size: 24);
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: overallAvg / 5.0,
                  backgroundColor: Colors.white30,
                  color: Colors.white,
                  minHeight: 6,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people_rounded,
                        size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text('$responseCount evaluations received',
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

          // Breakdown by Criteria
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Breakdown by Criteria',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 12),
                if (criterionAverages.isEmpty)
                  const Text(
                    'No criterion data available.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  )
                else
                  ...criterionAverages.entries.map((entry) {
                    final val = (entry.value as num).toDouble();
                    Color barColor;
                    if (val >= 4.0) {
                      barColor = Colors.green;
                    } else if (val >= 3.0) {
                      barColor = Colors.orange;
                    } else {
                      barColor = Colors.red;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF4B5563),
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: val / 5.0,
                                    backgroundColor:
                                        const Color(0xFFE5E7EB),
                                    color: barColor,
                                    minHeight: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '${val.toStringAsFixed(1)}/5',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: barColor),
                                ),
                              ),
                            ],
                          ),
                          // Star rating for criterion
                          Row(
                            children: [
                              const SizedBox(width: 0),
                              ...List.generate(5, (i) {
                                return Icon(
                                  i < val.round()
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 14,
                                  color: Colors.amber.shade400,
                                );
                              }),
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
  }
}