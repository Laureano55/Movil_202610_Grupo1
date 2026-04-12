import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RobleDatabaseService {
  final http.Client httpClient;
  final String contract;

  RobleDatabaseService({http.Client? client, String? contract})
      : httpClient = client ?? http.Client(),
        contract = (contract ??
                const String.fromEnvironment(
                  'ROBLE_PROJECT_ID',
                  defaultValue: 'fluttergrupo1_359a0b93fc',
                ))
            .trim();

  late final String _baseUrl =
      'https://roble-api.openlab.uninorte.edu.co/database/$contract';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<String> _token() async {
    final prefs = await _prefs;
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      throw Exception('No token found');
    }
    return token;
  }

  Future<String?> currentEmail() async {
    final prefs = await _prefs;
    return prefs.getString('email');
  }

  Future<List<Map<String, dynamic>>> read(
    String tableName, {
    Map<String, String>? filters,
  }) async {
    final token = await _token();
    final params = <String, String>{'tableName': tableName, ...?filters};
    final uri = Uri.parse('$_baseUrl/read').replace(queryParameters: params);

    final response = await httpClient.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Read $tableName failed: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      return <Map<String, dynamic>>[];
    }

    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> insert(String tableName, List<Map<String, dynamic>> records) async {
    if (records.isEmpty) return;

    final token = await _token();
    final uri = Uri.parse('$_baseUrl/insert');
    final response = await httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'tableName': tableName,
        'records': records,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Insert $tableName failed: ${response.body}');
    }
  }

  Future<void> delete(
    String tableName, {
    required String idColumn,
    required String idValue,
  }) async {
    final token = await _token();
    final uri = Uri.parse('$_baseUrl/delete');
    final response = await httpClient.delete(
      uri,
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
      throw Exception('Delete $tableName failed: ${response.body}');
    }
  }
}
