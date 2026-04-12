import 'package:file_picker/file_picker.dart';

import 'csv_file_picker.dart';

Future<PickedCsvFile?> pickCsvFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
    withData: true,
  );

  if (result == null || result.files.isEmpty) {
    return null;
  }

  final file = result.files.single;
  final bytes = file.bytes;
  if (bytes == null) {
    return null;
  }

  return PickedCsvFile(name: file.name, bytes: bytes);
}
