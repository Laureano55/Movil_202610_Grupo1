import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'roble_config.dart';

class RobleDatabaseService {
  final http.Client httpClient;

  RobleDatabaseService({http.Client? client})
      : httpClient = client ?? http.Client();

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found. Please login again.');
    }
    return token;
  }

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] != null) return body['message'].toString();
    } catch (_) {}
    return 'HTTP ${response.statusCode}: ${response.body}';
  }

  /// Lee todos los registros de una tabla, con filtros opcionales.
  Future<List<Map<String, dynamic>>> read(
    String tableName, {
    Map<String, String>? filters,
  }) async {
    final token = await _getToken();
    final params = <String, String>{'tableName': tableName, ...?filters};
    final uri = Uri.parse('${RobleConfig.databaseUrl}/read')
        .replace(queryParameters: params);

    final response = await httpClient.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Read $tableName failed: ${_errorMessage(response)}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Inserta uno o más registros en una tabla.
  Future<void> insert(
    String tableName,
    List<Map<String, dynamic>> records,
  ) async {
    if (records.isEmpty) return;
    final token = await _getToken();

    final response = await httpClient.post(
      Uri.parse('${RobleConfig.databaseUrl}/insert'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'tableName': tableName, 'records': records}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Insert into $tableName failed: ${_errorMessage(response)}');
    }
  }

  /// Actualiza un registro por su ID.
  Future<void> update(
    String tableName, {
    required String idColumn,
    required String idValue,
    required Map<String, dynamic> updates,
  }) async {
    final token = await _getToken();

    final response = await httpClient.put(
      Uri.parse('${RobleConfig.databaseUrl}/update'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'tableName': tableName,
        'idColumn': idColumn,
        'idValue': idValue,
        'updates': updates,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Update $tableName failed: ${_errorMessage(response)}');
    }
  }

  /// Elimina un registro por su ID.
  Future<void> delete(
    String tableName, {
    required String idColumn,
    required String idValue,
  }) async {
    final token = await _getToken();

    final response = await httpClient.delete(
      Uri.parse('${RobleConfig.databaseUrl}/delete'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'tableName': tableName,
        'idColumn': idColumn,
        'idValue': idValue,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Delete from $tableName failed: ${_errorMessage(response)}');
    }
  }
}