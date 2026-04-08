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
  late final CsvImportController controller;
  final ProfessorController professorController = Get.find<ProfessorController>();

  String? selectedCourseId;
  String? selectedCourseCode;

  @override
  void initState() {
    super.initState();
    // Usar findOrPut para evitar duplicados si ya fue registrado
    controller = Get.isRegistered<CsvImportController>()
        ? Get.find<CsvImportController>()
        : Get.put(CsvImportController());

    final first = professorController.courses.firstOrNull;
    if (first != null) {
      selectedCourseId = first['id'] as String?;
      selectedCourseCode = first['code'] as String?;
    }
  }

  @override
  Widget build(BuildContext context) {
    final courses = professorController.courses;

    // Sincronizar selección si courses cambió y no hay selección
    if (selectedCourseId == null && courses.isNotEmpty) {
      final first = courses.first;
      selectedCourseId = first['id'] as String?;
      selectedCourseCode = first['code'] as String?;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B3CF0),
        foregroundColor: Colors.white,
        title: const Text(
          'Importar grupos CSV',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isUploading.value) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF4B3CF0)),
                SizedBox(height: 16),
                Text(
                  'Procesando CSV...',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card sobre el formato CSV
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EFFE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4B3CF0).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: Color(0xFF4B3CF0), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Formato CSV requerido',
                          style: TextStyle(
                            color: Color(0xFF4B3CF0),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'El archivo CSV debe tener las columnas:\n'
                      '• Group Category Name (o Group Name)\n'
                      '• Email Address\n'
                      '• First Name, Last Name (opcional)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.indigo.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Compatible con exportaciones de Brightspace.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.indigo.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Selector de curso
              if (courses.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange.shade700, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        'No hay cursos creados',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Crea primero un curso para poder importar grupos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await professorController.createCourse(
                              'Curso Demo', 'DEMO-001');
                          final first = professorController.courses.firstOrNull;
                          if (first != null) {
                            setState(() {
                              selectedCourseId = first['id'] as String?;
                              selectedCourseCode = first['code'] as String?;
                            });
                          }
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Crear curso demo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4B3CF0),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const Text(
                  'Seleccionar curso',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCourseId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  hint: const Text('Elige un curso'),
                  items: courses
                      .map(
                        (course) => DropdownMenuItem<String>(
                          value: course['id'] as String,
                          child: Text(
                            '${course['title']} (${course['code']})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    final selected = courses.firstWhereOrNull(
                      (c) => c['id'] == value,
                    );
                    setState(() {
                      selectedCourseId = value;
                      selectedCourseCode =
                          (selected?['code'] ?? '').toString();
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Botón de subir CSV
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: selectedCourseId == null
                        ? null
                        : () async {
                            await controller.uploadCSV(
                              courseId: selectedCourseId!,
                              courseCode: selectedCourseCode ?? '',
                            );
                            await professorController.loadCourses();
                          },
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text(
                      'Seleccionar y subir CSV',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4B3CF0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Resultado de importación
                if (controller.importedCount.value > 0 ||
                    controller.importedCategories.value > 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: Colors.green.shade700, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Importación exitosa',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF166534)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Grupos nuevos: ${controller.importedCategories.value}  ·  '
                                'Miembros nuevos: ${controller.importedCount.value}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        );
      }),
    );
  }
}