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
        backgroundColor: const Color(0xFF4B3CF0),
        foregroundColor: Colors.white,
        title: Text(widget.courseTitle),
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
                child: Text(
                  'No se pudieron cargar los grupos.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFB00020)),
                ),
              ),
            );
          }

          final groups = snapshot.data ?? const [];
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.groups_outlined, size: 56, color: Color(0xFF9CA3AF)),
                  const SizedBox(height: 12),
                  const Text(
                    'Este curso no tiene grupos todavía.',
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Importar grupos desde CSV'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                final groupName = (group['groupName'] ?? 'Sin nombre').toString();
                final members = (group['members'] as List<dynamic>? ?? const [])
                    .cast<Map<String, dynamic>>();

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0.8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEAE7FF),
                      child: Icon(Icons.group_rounded, color: Color(0xFF4B3CF0)),
                    ),
                    title: Text(
                      groupName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('${members.length} miembro${members.length == 1 ? '' : 's'}'),
                    children: members.isEmpty
                        ? const [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Sin miembros',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            ),
                          ]
                        : members
                            .map(
                              (member) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                leading: const Icon(Icons.person_rounded, size: 18),
                                title: Text((member['name'] ?? '').toString()),
                                subtitle: Text((member['email'] ?? '').toString()),
                              ),
                            )
                            .toList(growable: false),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
