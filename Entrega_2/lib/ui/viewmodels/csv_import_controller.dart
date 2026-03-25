import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class CsvImportController extends GetxController {

  var isUploading = false.obs;

  Future<void> uploadCSV(String courseId) async {

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null) {
      Get.snackbar("Cancelado", "No se seleccionó archivo");
      return;
    }

    final file = result.files.single;

    try {

      isUploading.value = true;

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("http://localhost:3000/api/courses/$courseId/import-groups")
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          file.bytes!,
          filename: file.name
        )
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        Get.snackbar("Éxito", "CSV subido correctamente");
      } else {
        Get.snackbar("Error", "No se pudo subir el CSV");
      }

    } catch (e) {

      Get.snackbar("Error", e.toString());

    } finally {

      isUploading.value = false;

    }
  }
}
