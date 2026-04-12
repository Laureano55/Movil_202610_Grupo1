import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<Directory?> _findProjectRoot() async {
  var current = Directory.current.absolute;

  while (true) {
    final pubspec = File('${current.path}${Platform.pathSeparator}pubspec.yaml');
    if (await pubspec.exists()) {
      return current;
    }

    final parent = current.parent;
    if (parent.path == current.path) {
      return null;
    }
    current = parent;
  }
}

Future<File> _backupFile() async {
  final projectRoot = await _findProjectRoot();

  final dir = projectRoot != null
      ? Directory('${projectRoot.path}${Platform.pathSeparator}data')
      : Directory(
          '${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}course_store',
        );

  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  return File('${dir.path}${Platform.pathSeparator}course_store.json');
}

Future<Map<String, dynamic>?> jsonBackupRead() async {
  try {
    final file = await _backupFile();
    if (!await file.exists()) {
      return null;
    }

    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
  } catch (_) {
    // Ignora errores de respaldo para no romper la app.
  }

  return null;
}

Future<void> jsonBackupWrite(Map<String, dynamic> data) async {
  try {
    final file = await _backupFile();
    await file.writeAsString(jsonEncode(data), flush: true);
  } catch (_) {
    // Ignora errores de respaldo para no romper la app.
  }
}
