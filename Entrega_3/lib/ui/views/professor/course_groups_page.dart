import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/demo_course_store.dart';

class CourseGroupsPage extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String courseCode;

  const CourseGroupsPage({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.courseCode,
  });

  @override
  State<CourseGroupsPage> createState() => _CourseGroupsPageState();
}

class _CourseGroupsPageState extends State<CourseGroupsPage> {
  static const _primary = Color(0xFF4B3CF0);
  final DemoCourseStore _store = DemoCourseStore();
  late Future<List<Map<String, dynamic>>> _groupsFuture;

  @override
  void initState() {
    super.initState();
    _groupsFuture = _store.professorCourseGroups(widget.courseId);
  }

  Future<void> _reload() async {
    setState(() {
      _groupsFuture = _store.professorCourseGroups(widget.courseId);
    });
    await _groupsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Text(widget.courseTitle,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.rate_review_rounded),
            tooltip: 'Crear evaluación',
            onPressed: () => Get.toNamed(
              '/professor/create-evaluation',
              arguments: {
                'courseId': widget.courseId,
                'courseName': widget.courseTitle,
                'courseCode': widget.courseCode,
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Ver resultados',
            onPressed: () => Get.toNamed(
              '/professor/evaluation-results',
              arguments: {'courseId': widget.courseId},
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _groupsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Color(0xFFB00020))),
              ),
            );
          }
          final groups = snapshot.data ?? const [];

          if (groups.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.groups_outlined,
                            size: 64, color: Color(0xFF9CA3AF)),
                        const SizedBox(height: 16),
                        const Text(
                          'Este curso aún no tiene grupos.',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF4B5563)),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Importa grupos desde Brightspace usando un archivo CSV.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () =>
                              Get.toNamed('/professor/import-groups')
                                  ?.then((_) => _reload()),
                          icon: const Icon(Icons.upload_file_rounded),
                          label: const Text('Importar CSV'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: Column(
              children: [
                // Summary bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      _SummaryChip(
                        icon: Icons.folder_rounded,
                        label: '${groups.length} grupos',
                      ),
                      const SizedBox(width: 12),
                      _SummaryChip(
                        icon: Icons.people_rounded,
                        label: '${groups.fold<int>(0, (s, g) => s + ((g['memberCount'] as int?) ?? 0))} estudiantes',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: groups.length,
                    itemBuilder: (ctx, i) {
                      final group = groups[i];
                      final groupName =
                          (group['groupName'] ?? 'Sin nombre')
                              .toString();
                      final members =
                          (group['members'] as List<dynamic>? ??
                                  const [])
                              .cast<Map<String, dynamic>>();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0.8,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: ExpansionTile(
                          tilePadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(14, 0, 14, 12),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFEAE7FF),
                            child: Icon(Icons.group_rounded,
                                color: Color(0xFF4B3CF0)),
                          ),
                          title: Text(groupName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          subtitle: Text(
                              '${members.length} miembro${members.length == 1 ? '' : 's'}'),
                          children: members.isEmpty
                              ? const [
                                  Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text('Sin miembros',
                                        style: TextStyle(
                                            color: Color(0xFF6B7280))),
                                  )
                                ]
                              : members
                                  .map((member) => ListTile(
                                        contentPadding:
                                            EdgeInsets.zero,
                                        dense: true,
                                        leading: const Icon(
                                            Icons.person_rounded,
                                            size: 18),
                                        title: Text(
                                            (member['name'] ?? '')
                                                .toString()),
                                        subtitle: Text(
                                            (member['email'] ?? '')
                                                .toString()),
                                      ))
                                  .toList(growable: false),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SummaryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EFFE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4B3CF0)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF4B3CF0),
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }
}