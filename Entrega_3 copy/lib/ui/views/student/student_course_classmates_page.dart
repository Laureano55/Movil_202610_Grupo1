import 'package:flutter/material.dart';

import '../../data/demo_course_store.dart';

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
  final DemoCourseStore _store = DemoCourseStore();
  late Future<Map<String, dynamic>> _classmatesFuture;

  @override
  void initState() {
    super.initState();
    _classmatesFuture = _loadClassmates();
  }

  Future<Map<String, dynamic>> _loadClassmates() async {
    final email = (await _store.currentEmail())?.trim();
    if (email == null || email.isEmpty) {
      return {
        'myGroup': 'Sin grupo',
        'classmates': <Map<String, String>>[],
      };
    }

    return _store.studentCourseClassmates(
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
        title: Text(widget.courseTitle),
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
                child: Text(
                  'No se pudieron cargar tus compañeros.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFB00020)),
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
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEAE7FF),
                      child: Icon(Icons.group_rounded, color: Color(0xFF4B3CF0)),
                    ),
                    title: const Text(
                      'Tu grupo',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(myGroup),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Compañeros de tu grupo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                      ),
                ),
                const SizedBox(height: 8),
                if (classmates.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Aún no hay compañeros en tu grupo.',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ),
                  )
                else
                  ...classmates.map(
                    (mate) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.person_rounded),
                        title: Text((mate['name'] ?? '').toString()),
                        subtitle: Text((mate['email'] ?? '').toString()),
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
