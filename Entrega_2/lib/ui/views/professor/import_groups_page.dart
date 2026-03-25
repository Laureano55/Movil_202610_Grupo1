import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../viewmodels/csv_import_controller.dart';
import '../../viewmodels/professor_controller.dart';

class ImportGroupsPage extends StatefulWidget {
  const ImportGroupsPage({super.key});

  @override
  State<ImportGroupsPage> createState() => _ImportGroupsPageState();
}

class _ImportGroupsPageState extends State<ImportGroupsPage> {
  final CsvImportController controller = Get.put(CsvImportController());
  final ProfessorController professorController = Get.find<ProfessorController>();

  String? selectedCourseId;
  String? selectedCourseCode;

  @override
  void initState() {
    super.initState();
    final first = professorController.courses.firstOrNull;
    if (first != null) {
      selectedCourseId = first['id'] as String?;
      selectedCourseCode = first['code'] as String?;
    }
  }

  @override
  Widget build(BuildContext context) {
    final courses = professorController.courses;
    if (selectedCourseId == null && courses.isNotEmpty) {
      final first = courses.first;
      selectedCourseId = first['id'] as String?;
      selectedCourseCode = first['code'] as String?;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Importar CSV de grupos"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Obx(() {

          if (controller.isUploading.value) {
            return const CircularProgressIndicator();
          }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (courses.isEmpty) ...[
                  const Text(
                    'No hay cursos creados. Crea primero el curso para cargar CSV.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await professorController.createCourse('Curso Móvil', 'MOVIL-001');
                        final first = professorController.courses.firstOrNull;
                        if (first != null) {
                          setState(() {
                            selectedCourseId = first['id'] as String?;
                            selectedCourseCode = first['code'] as String?;
                          });
                        }
                      },
                      child: const Text('Crear curso demo (Curso Móvil)'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                DropdownButtonFormField<String>(
                  value: selectedCourseId,
                  decoration: const InputDecoration(
                    labelText: 'Curso',
                    border: OutlineInputBorder(),
                  ),
                  items: courses
                      .map(
                        (course) => DropdownMenuItem<String>(
                          value: course['id'] as String,
                          child: Text('${course['title']} (${course['code']})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    final selected = courses.firstWhereOrNull(
                      (c) => c['id'] == value,
                    );
                    setState(() {
                      selectedCourseId = value;
                      selectedCourseCode = (selected?['code'] ?? '').toString();
                    });
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedCourseId == null || courses.isEmpty
                        ? null
                        : () async {
                            await controller.uploadCSV(
                              courseId: selectedCourseId!,
                              courseCode: selectedCourseCode ?? '',
                            );
                            await professorController.loadCourses();
                          },
                    child: const Text('Seleccionar y subir CSV'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Miembros importados: ${controller.importedCount.value} | '
                  'Categorías nuevas: ${controller.importedCategories.value}',
                ),
              ],
            );

          }),
        ),
      ),
    );
  }
}