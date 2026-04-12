import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/auth_utils.dart';
import '../../../domain/repositories/i_course_repository.dart';

class StudentCourseClassmatesPage extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String courseCode;

  const StudentCourseClassmatesPage({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.courseCode,
  });

  @override
  State<StudentCourseClassmatesPage> createState() =>
      _StudentCourseClassmatesPageState();
}

class _StudentCourseClassmatesPageState
    extends State<StudentCourseClassmatesPage> {
  ICourseRepository get _repo => Get.find<ICourseRepository>();

  late Future<Map<String, dynamic>> _classmatesFuture;

  @override
  void initState() {
    super.initState();
    _classmatesFuture = _loadClassmates();
  }

  Future<Map<String, dynamic>> _loadClassmates() async {
    final email = (await getCurrentEmail())?.trim();
    if (email == null || email.isEmpty) {
      return {
        'myGroup': 'Sin grupo',
        'classmates': <Map<String, String>>[],
      };
    }

    return _repo.studentCourseClassmates(
      courseId: widget.courseId,
      email: email,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _classmatesFuture = _loadClassmates();
    });
    await _classmatesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B3CF0),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.courseTitle,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            if (widget.courseCode.isNotEmpty)
              Text(widget.courseCode,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reload,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _classmatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFB00020), size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'No se pudieron cargar tus compañeros.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFB00020)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data ?? const {};
          final myGroup = (data['myGroup'] ?? 'Sin grupo').toString();
          final classmates = (data['classmates'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>();

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // Mi grupo card
                Card(
                  elevation: 0.8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEAE7FF),
                      child: Icon(Icons.group_rounded,
                          color: Color(0xFF4B3CF0)),
                    ),
                    title: const Text(
                      'Tu grupo',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(myGroup),
                  ),
                ),
                const SizedBox(height: 16),

                // Título compañeros
                Row(
                  children: [
                    const Icon(Icons.people_rounded,
                        color: Color(0xFF4B3CF0), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Compañeros de tu grupo',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAE7FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${classmates.length}',
                        style: const TextStyle(
                            color: Color(0xFF4B3CF0),
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (classmates.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.group_off_rounded,
                            size: 40, color: Color(0xFF9CA3AF)),
                        const SizedBox(height: 12),
                        Text(
                          myGroup == 'Sin grupo'
                              ? 'Aún no estás asignado a ningún grupo.'
                              : 'No hay compañeros en tu grupo todavía.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  )
                else
                  ...classmates.map(
                    (mate) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2)),
                        ],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFEAE7FF),
                          child: Text(
                            ((mate['name'] ?? '').toString().isNotEmpty
                                ? (mate['name'] as String)[0]
                                    .toUpperCase()
                                : '?'),
                            style: const TextStyle(
                                color: Color(0xFF4B3CF0),
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(
                          (mate['name'] ?? '').toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          (mate['email'] ?? '').toString(),
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ),
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