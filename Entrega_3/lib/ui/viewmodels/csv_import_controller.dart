import 'package:get/get.dart';
import 'package:csv/csv.dart';

import '../data/demo_course_store.dart';
import '../utils/csv_file_picker.dart';

class CsvImportController extends GetxController {
  final DemoCourseStore _store;

  CsvImportController({DemoCourseStore? demoCourseStore})
      : _store = demoCourseStore ?? DemoCourseStore();

  var isUploading = false.obs;
  final importedCount = 0.obs;
  final importedCategories = 0.obs;

  Future<void> uploadCSV({
    required String courseId,
    required String courseCode,
  }) async {

    final pickedFile = await pickCsvFile();
    if (pickedFile == null) {
      Get.snackbar("Cancelado", "No se seleccionó archivo");
      return;
    }

    try {

      isUploading.value = true;

      final csvText = String.fromCharCodes(pickedFile.bytes);
      final rows = const CsvToListConverter(eol: '\n').convert(csvText);
      if (rows.length < 2) {
        throw Exception('El CSV no contiene registros');
      }

      final headers = rows.first
          .map((e) => e.toString().trim().toLowerCase())
          .toList(growable: false);

      String normalize(String value) {
        return value
            .toLowerCase()
            .trim()
            .replaceAll('_', ' ')
            .replaceAll(RegExp(r'\s+'), ' ');
      }

      int idxOf(List<String> keys) {
        final normalizedHeaders = headers.map(normalize).toList(growable: false);
        for (final key in keys.map(normalize)) {
          for (var i = 0; i < normalizedHeaders.length; i++) {
            final h = normalizedHeaders[i];
            if (h == key || h.contains(key) || key.contains(h)) {
              return i;
            }
          }
        }
        return -1;
      }

      final groupNameIdx = idxOf(['group name', 'grupo', 'group']);
      final groupCategoryIdx = idxOf([
        'group category name',
        'category',
        'categoria',
      ]);
      final emailIdx = idxOf(['email address', 'email', 'correo']);
      final nameIdx = idxOf(['first name', 'name', 'nombre', 'first_name']);
      final lastNameIdx = idxOf(['last name', 'last_name', 'apellido']);

      if ((groupNameIdx == -1 && groupCategoryIdx == -1) || emailIdx == -1) {
        throw Exception(
          'El CSV debe incluir Group Name (o Group Category Name) y Email Address.',
        );
      }

      final categories = <String>{};
      final members = <Map<String, dynamic>>[];

      for (final row in rows.skip(1)) {
        if (row.isEmpty) continue;

        String valueAt(int idx) {
          if (idx < 0 || idx >= row.length) return '';
          return row[idx].toString().trim();
        }

        final groupName = valueAt(groupNameIdx);
        final groupCategory = valueAt(groupCategoryIdx);
        final category = groupName.isNotEmpty ? groupName : groupCategory;
        final email = valueAt(emailIdx).toLowerCase();
        final name = valueAt(nameIdx);
        final lastName = valueAt(lastNameIdx);

        if (category.isEmpty || email.isEmpty) continue;
        categories.add(category);

        members.add({
          'courseId': courseId,
          'courseCode': courseCode,
          'category': category,
          'email': email,
          'name': name,
          'last_name': lastName,
        });
      }

      final beforeSummary = await _store.professorCourseSummaries();
      final beforeCourse = beforeSummary.firstWhere(
        (c) => '${c['id']}' == courseId,
        orElse: () => {'studentCount': 0, 'groupCount': 0},
      );

      await _store.importCsvData(
        courseId: courseId,
        courseCode: courseCode,
        categories: categories,
        members: members,
      );

      final afterSummary = await _store.professorCourseSummaries();
      final afterCourse = afterSummary.firstWhere(
        (c) => '${c['id']}' == courseId,
        orElse: () => {'studentCount': 0, 'groupCount': 0},
      );

      importedCategories.value =
          (afterCourse['groupCount'] as int) - (beforeCourse['groupCount'] as int);
      importedCount.value =
          (afterCourse['studentCount'] as int) - (beforeCourse['studentCount'] as int);
      Get.snackbar(
        'Éxito',
        'CSV procesado. Categorías nuevas: ${importedCategories.value}, miembros nuevos: ${importedCount.value}',
      );

    } catch (e) {

      Get.snackbar("Error", e.toString());

    } finally {

      isUploading.value = false;

    }
  }
}