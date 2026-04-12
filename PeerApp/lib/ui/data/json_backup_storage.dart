import 'json_backup_storage_io.dart'
    if (dart.library.html) 'json_backup_storage_web.dart';

class JsonBackupStorage {
  Future<Map<String, dynamic>?> read() => jsonBackupRead();

  Future<void> write(Map<String, dynamic> data) => jsonBackupWrite(data);
}
