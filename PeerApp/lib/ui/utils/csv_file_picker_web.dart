// ignore: avoid_web_libraries_in_flutter
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'csv_file_picker.dart';

Future<PickedCsvFile?> pickCsvFile() async {
  // En web, usamos un workaround compatible con Flutter Web moderno
  // usando un plugin de file_picker que ya maneja la compatibilidad
  try {
    // Intentar usar file_picker si está disponible en web
    return await _pickWithFilePicker();
  } catch (_) {
    return null;
  }
}

Future<PickedCsvFile?> _pickWithFilePicker() async {
  // Flutter Web: usar js interop moderno via MethodChannel o dart:js_interop
  // Como dart:html está deprecado, usamos file_picker que internamente
  // maneja la compatibilidad web

  // Este método es llamado solo en web, file_picker maneja la selección
  // correctamente en Flutter Web moderno
  final completer = Completer<PickedCsvFile?>();

  try {
    // Usar el canal de plataforma para web si file_picker está disponible
    // file_picker ^10.x ya usa dart:js_interop internamente
    const channel = MethodChannel('miguelruivo.flutter.plugins.filepicker');
    
    final result = await channel.invokeMethod<Map<dynamic, dynamic>>(
      'pickFiles',
      {
        'type': 'custom',
        'allowedExtensions': ['csv'],
        'withData': true,
        'allowMultiple': false,
      },
    );

    if (result == null) {
      completer.complete(null);
      return completer.future;
    }

    final files = result['files'] as List?;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return completer.future;
    }

    final file = files.first as Map;
    final name = file['name']?.toString() ?? 'file.csv';
    final bytes = file['bytes'] as Uint8List?;

    if (bytes == null) {
      completer.complete(null);
      return completer.future;
    }

    completer.complete(PickedCsvFile(name: name, bytes: bytes));
  } catch (e) {
    debugPrint('Web file picker error: $e');
    completer.complete(null);
  }

  return completer.future;
}