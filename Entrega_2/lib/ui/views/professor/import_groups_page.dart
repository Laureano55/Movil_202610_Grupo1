import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../viewmodels/csv_import_controller.dart';

class ImportGroupsPage extends StatelessWidget {

  final CsvImportController controller = Get.put(CsvImportController());

  final String courseId = "movil_course";

  ImportGroupsPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Importar CSV de grupos"),
      ),
      body: Center(
        child: Obx(() {

          if (controller.isUploading.value) {
            return const CircularProgressIndicator();
          }

          return ElevatedButton(
            onPressed: () {
              controller.uploadCSV(courseId);
            },
            child: const Text("Seleccionar y subir CSV"),
          );

        }),
      ),
    );
  }
}