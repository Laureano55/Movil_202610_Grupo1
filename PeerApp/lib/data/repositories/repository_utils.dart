String normalizeEmail(Object? value) {
  return (value ?? '').toString().toLowerCase().trim();
}

String buildDisplayNameFromRow(
  Map<String, dynamic> row, {
  required String fallbackEmail,
}) {
  final firstName = (row['name'] ?? '').toString().trim();
  final lastName = (row['last_name'] ?? '').toString().trim();
  final fullName = '$firstName $lastName'.trim();
  return fullName.isEmpty ? fallbackEmail : fullName;
}

String computeEvaluationStatus(Map<String, dynamic> evalJson) {
  final start = DateTime.tryParse(evalJson['start_date']?.toString() ?? '');
  final end = DateTime.tryParse(evalJson['end_date']?.toString() ?? '');
  if (start == null || end == null) return 'draft';

  final now = DateTime.now();
  if (now.isAfter(end)) return 'closed';
  if (now.isAfter(start)) return 'active';
  return 'draft';
}