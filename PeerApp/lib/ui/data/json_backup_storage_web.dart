import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _backupStorageKey = 'course_store_backup_json';

Future<Map<String, dynamic>?> jsonBackupRead() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_backupStorageKey);
    if (raw == null || raw.trim().isEmpty) {
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backupStorageKey, jsonEncode(data));
  } catch (_) {
    // Ignora errores de respaldo para no romper la app.
  }
}
