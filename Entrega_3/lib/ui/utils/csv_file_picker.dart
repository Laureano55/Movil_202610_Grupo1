import 'dart:typed_data';

import 'csv_file_picker_io.dart'
    if (dart.library.html) 'csv_file_picker_web.dart' as impl;

class PickedCsvFile {
  final String name;
  final Uint8List bytes;

  const PickedCsvFile({
    required this.name,
    required this.bytes,
  });
}

Future<PickedCsvFile?> pickCsvFile() => impl.pickCsvFile();
