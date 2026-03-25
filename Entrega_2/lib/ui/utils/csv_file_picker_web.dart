import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'csv_file_picker.dart';

Future<PickedCsvFile?> pickCsvFile() {
  final completer = Completer<PickedCsvFile?>();

  final input = html.FileUploadInputElement();
  input.accept = '.csv,text/csv';
  input.multiple = false;

  input.onChange.listen((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      return;
    }

    final file = files.first;
    final reader = html.FileReader();

    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is! List<int>) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        return;
      }

      if (!completer.isCompleted) {
        completer.complete(
          PickedCsvFile(
            name: file.name,
            bytes: result is Uint8List ? result : Uint8List.fromList(result),
          ),
        );
      }
    });

    reader.onError.listen((_) {
      if (!completer.isCompleted) {
        completer.completeError(reader.error ?? 'No se pudo leer el archivo CSV');
      }
    });

    reader.readAsArrayBuffer(file);
  });

  input.click();
  return completer.future;
}
