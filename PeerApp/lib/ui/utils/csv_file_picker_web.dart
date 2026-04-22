// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'csv_file_picker.dart';

Future<PickedCsvFile?> pickCsvFile() async {
  final completer = Completer<PickedCsvFile?>();
  bool completed = false;

  try {
    // Crear input de archivo HTML
    final input = html.FileUploadInputElement();
    input.accept = '.csv';
    input.multiple = false;

    // Listener para cuando se selecciona un archivo
    void handleChange(_) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        if (!completed) {
          completed = true;
          completer.complete(null);
        }
        return;
      }

      final file = files.first;
      final reader = html.FileReader();

      // Cuando termina de leer el archivo
      reader.onLoadEnd.listen((_) {
        if (completed) return;

        try {
          // Convertir ByteBuffer a Uint8List
          final result = reader.result;
          Uint8List bytes;

          if (result is Uint8List) {
            bytes = result;
          } else if (result is ByteBuffer) {
            bytes = result.asUint8List();
          } else {
            if (!completed) {
              completed = true;
              completer.complete(null);
            }
            return;
          }

          if (!completed) {
            completed = true;
            completer.complete(
              PickedCsvFile(name: file.name, bytes: bytes),
            );
          }
        } catch (e) {
          if (!completed) {
            completed = true;
            completer.complete(null);
          }
        }
      });

      // Si ocurre error durante la lectura
      reader.onError.listen((_) {
        if (!completed) {
          completed = true;
          completer.complete(null);
        }
      });

      // Iniciar lectura como array buffer
      reader.readAsArrayBuffer(file);
    }

    input.onChange.listen(handleChange);

    // Abrir diálogo de selección
    input.click();

    // Timeout de 2 minutos por si el usuario no responde
    return completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () => null,
    );
  } catch (e) {
    if (!completed) {
      completed = true;
      completer.complete(null);
    }
    return completer.future;
  }
}