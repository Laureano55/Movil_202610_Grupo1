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

  void _goToImport() {
    Get.toNamed('/professor/import-groups')?.then((_) => _reload());
  }

  void _goToCreateEvaluation() {
    Get.toNamed(
      '/professor/create-evaluation',
      arguments: {
        'courseId': widget.courseId,
        'courseName': widget.courseTitle,
        'courseCode': widget.courseCode,
      },
    );
  }

  void _goToResults() {
    Get.toNamed(
      '/professor/evaluation-results',
      arguments: {'courseId': widget.courseId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.courseTitle,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            Text(widget.courseCode,
                style: const TextStyle(
                    fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          // Sync Updates button (Import from Brightspace)
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Sync Updates / Import CSV',
            onPressed: _goToImport,
          ),
          IconButton(
            icon: const Icon(Icons.rate_review_rounded),
            tooltip: 'Create Evaluation',
            onPressed: _goToCreateEvaluation,
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'View Results',
            onPressed: _goToResults,
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
                  height: MediaQuery.of(context).size.height * 0.75,
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
                            child: const Icon(Icons.groups_outlined,
                                size: 64, color: Color(0xFF4B3CF0)),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No groups in this course',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Color(0xFF4B5563)),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Import groups from Brightspace using a CSV export file.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _goToImport,
                            icon: const Icon(Icons.upload_file_rounded),
                            label: const Text('Import CSV'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _goToResults,
                            icon: const Icon(Icons.sync_alt_rounded),
                            label: const Text('Sync Updates'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primary,
                              side: const BorderSide(color: _primary),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
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
            onRefresh: _reload,
            child: Column(
              children: [
                // Summary bar with import buttons
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      _SummaryChip(
                        icon: Icons.folder_rounded,
                        label: '${groups.length} groups',
                      ),
                      const SizedBox(width: 8),
                      _SummaryChip(
                        icon: Icons.people_rounded,
                        label:
                            '${groups.fold<int>(0, (s, g) => s + ((g['memberCount'] as int?) ?? 0))} students',
                      ),
                      const Spacer(),
                      // Import Selected Categories button
                      TextButton.icon(
                        onPressed: _goToImport,
                        icon: const Icon(Icons.upload_rounded, size: 16),
                        label: const Text('Import',
                            style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: _primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Action buttons row
                Container(
                  color: const Color(0xFFF9FAFB),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.rate_review_rounded,
                          label: 'Create Evaluation',
                          color: const Color(0xFF059669),
                          onTap: _goToCreateEvaluation,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.bar_chart_rounded,
                          label: 'View Results',
                          color: const Color(0xFFD97706),
                          onTap: _goToResults,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.sync_rounded,
                          label: 'Sync Updates',
                          color: _primary,
                          onTap: _goToImport,
                        ),
                      ),
                    ],
                  ),
                ),

                // Groups list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: groups.length,
                    itemBuilder: (ctx, i) {
                      final group = groups[i];
                      final groupName =
                          (group['groupName'] ?? 'Sin nombre').toString();
                      final members =
                          (group['members'] as List<dynamic>? ?? const [])
                              .cast<Map<String, dynamic>>();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0.8,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(14, 0, 14, 12),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFEAE7FF),
                            child: Text(
                              (i + 1).toString(),
                              style: const TextStyle(
                                  color: _primary,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                          title: Text(groupName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            '${members.length} member${members.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                                color: Color(0xFF6B7280), fontSize: 12),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: members.isEmpty
                                  ? Colors.grey.shade100
                                  : const Color(0xFFF0EFFE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people_alt_rounded,
                                    size: 14,
                                    color: members.isEmpty
                                        ? Colors.grey
                                        : _primary),
                                const SizedBox(width: 4),
                                Text(
                                  '${members.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: members.isEmpty
                                        ? Colors.grey
                                        : _primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          children: members.isEmpty
                              ? const [
                                  Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      'No members yet. Import a CSV to assign students.',
                                      style: TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ]
                              : members
                                  .map((member) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        dense: true,
                                        leading: CircleAvatar(
                                          radius: 16,
                                          backgroundColor:
                                              const Color(0xFFF0EFFE),
                                          child: Text(
                                            ((member['name'] ?? '')
                                                    .toString()
                                                    .isNotEmpty
                                                ? (member['name']
                                                    as String)[0]
                                                    .toUpperCase()
                                                : '?'),
                                            style: const TextStyle(
                                              color: _primary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                            (member['name'] ?? '')
                                                .toString(),
                                            style: const TextStyle(
                                                fontSize: 14)),
                                        subtitle: Text(
                                            (member['email'] ?? '')
                                                .toString(),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6B7280))),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}