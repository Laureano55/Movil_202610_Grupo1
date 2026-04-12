class RobleConfig {
  static const String dbName = 'fluttergrupo1_359a0b93fc';
  static const String baseUrl = 'https://roble-api.openlab.uninorte.edu.co';
  static String get databaseUrl => '$baseUrl/database/$dbName';
  static String get authUrl => '$baseUrl/auth/$dbName';
}