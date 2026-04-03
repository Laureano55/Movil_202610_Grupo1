import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/authentication_user.dart';
import 'i_authentication_source.dart';

class AuthenticationSourceServiceRoble implements IAuthenticationSource {
  final http.Client httpClient;
  final String contract;

  late final String _authBaseUrl =
      'https://roble-api.openlab.uninorte.edu.co/auth/$contract';
  late final String _dbBaseUrl =
      'https://roble-api.openlab.uninorte.edu.co/database/$contract';

  AuthenticationSourceServiceRoble({http.Client? client, String? contract})
      : httpClient = client ?? http.Client(),
        contract = (contract ??
                const String.fromEnvironment(
                  'ROBLE_PROJECT_ID',
                  defaultValue: 'fluttergrupo1_359a0b93fc',
                ))
            .trim();

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  void _validateContract() {
    if (contract.isEmpty) {
      throw Exception(
        'ROBLE_PROJECT_ID no configurado. Ejecuta con --dart-define=ROBLE_PROJECT_ID=tu_token_contract',
      );
    }
  }

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final message = body['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
        if (message is List) {
          return message.map((e) => e.toString()).join(', ');
        }
        if (body['error'] is String) {
          return body['error'] as String;
        }
      }
      if (body is List && body.isNotEmpty) {
        return body.map((e) => e.toString()).join(', ');
      }
    } catch (_) {
      if (response.body.trim().isNotEmpty) {
        return response.body;
      }
    }
    return 'Error HTTP ${response.statusCode}';
  }

  @override
  Future<void> login(String email, String password) async {
    _validateContract();
    final response = await http.post(
      Uri.parse('$_authBaseUrl/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      final user = data['user'] as Map<String, dynamic>?;
      final userId = user?['id'] as String?;

      if (token == null || refreshToken == null) {
        throw Exception('Respuesta de login inválida: faltan tokens');
      }

      final prefs = await _prefs;
      await prefs.setString('token', token);
      await prefs.setString('refreshToken', refreshToken);
      await prefs.setString('email', email);
      if (userId != null && userId.isNotEmpty) {
        await prefs.setString('userId', userId);
      }
      return Future.value();
    } else {
      return Future.error(_errorMessage(response));
    }
  }

  @override
  Future<void> signUp(
    String email,
    String password,
    String name,
    bool direct, {
    String lastName = '',
    String role = 'Estudiante',
  }) async {
    _validateContract();
    final endpoint = direct ? '$_authBaseUrl/signup-direct' : '$_authBaseUrl/signup';
    final normalizedName = name.trim();
    final normalizedLastName = lastName.trim();
    final fullName = [normalizedName, normalizedLastName]
        .where((part) => part.isNotEmpty)
        .join(' ');

    final response = await http.post(
      Uri.parse(endpoint),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "email": email,
        "name": fullName.isEmpty ? normalizedName : fullName,
        "password": password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      await login(email, password);
      try {
        await addUser(email, fullName.isEmpty ? normalizedName : fullName);
      } catch (_) {
        // El usuario en Auth ya fue creado; el perfil en tabla Users es complementario.
      }

      await addUserToRoleTable(
        role: role,
        name: normalizedName,
        lastName: normalizedLastName,
        email: email,
      );

      return Future.value();
    } else {
      return Future.error(
        'No se pudo crear la cuenta en Roble Auth: ${_errorMessage(response)}',
      );
    }
  }

  @override
  Future<bool> logOut() async {
    _validateContract();
    final prefs = await _prefs;
    final token = prefs.getString('token');
    if (token == null) {
      return Future.error('No token found');
    }

    final response = await httpClient.post(
      Uri.parse('$_authBaseUrl/logout'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      await prefs.remove('token');
      await prefs.remove('refreshToken');
      await prefs.remove('userId');
      await prefs.remove('email');
      return Future.value(true);
    } else {
      return Future.error(_errorMessage(response));
    }
  }

  @override
  Future<bool> validate(String email, String validationCode) async {
    _validateContract();
    final response = await httpClient.post(
      Uri.parse('$_authBaseUrl/verify-email'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "email": email,
        "code": validationCode,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Future.value(true);
    } else {
      return Future.error(_errorMessage(response));
    }
  }

  @override
  Future<bool> refreshToken() async {
    _validateContract();
    final prefs = await _prefs;
    final refreshToken = prefs.getString('refreshToken');
    if (refreshToken == null) {
      return Future.value(false);
    }

    final response = await http.post(
      Uri.parse('$_authBaseUrl/refresh-token'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'refreshToken': refreshToken,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final newToken = data['accessToken'];
      if (newToken is String && newToken.isNotEmpty) {
        await prefs.setString('token', newToken);
      }
      return Future.value(true);
    } else {
      return Future.error(_errorMessage(response));
    }
  }

  @override
  Future<bool> forgotPassword(String email) async {
    _validateContract();
    final response = await httpClient.post(
      Uri.parse('$_authBaseUrl/forgot-password'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "email": email,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Future.value(true);
    } else {
      return Future.error(_errorMessage(response));
    }
  }

  @override
  Future<String?> getAccountRoleByEmail(String email) async {
    _validateContract();
    final prefs = await _prefs;
    final token = prefs.getString('token');
    if (token == null) {
      return Future.error('No token found');
    }

    final isTeacher = await _existsByEmail(
      tableName: 'teachers',
      email: email,
      token: token,
    );
    final isStudent = await _existsByEmail(
      tableName: 'students',
      email: email,
      token: token,
    );

    if (isTeacher && !isStudent) {
      return 'Docente';
    }
    if (isStudent && !isTeacher) {
      return 'Estudiante';
    }
    if (isTeacher && isStudent) {
      return Future.error(
        'El usuario existe en teachers y students. Corrige los datos en ROBLE.',
      );
    }
    return null;
  }

  Future<bool> _existsByEmail({
    required String tableName,
    required String email,
    required String token,
  }) async {
    final uri = Uri.parse('$_dbBaseUrl/read').replace(
      queryParameters: {
        'tableName': tableName,
        'email': email,
      },
    );

    final response = await httpClient.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      return Future.error(
        'No se pudo consultar tabla $tableName: ${_errorMessage(response)}',
      );
    }

    final List<dynamic> records = jsonDecode(response.body);
    return records.isNotEmpty;
  }

  @override
  Future<bool> resetPassword(
      String email, String newPassword, String validationCode) async {
    _validateContract();
    final response = await httpClient.post(
      Uri.parse('$_authBaseUrl/reset-password'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'token': validationCode,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }
    return Future.error(_errorMessage(response));
  }

  @override
  Future<bool> verifyToken() async {
    _validateContract();
    final prefs = await _prefs;
    final token = prefs.getString('token');
    if (token == null) {
      return Future.value(false);
    }

    final response = await httpClient.get(
      Uri.parse('$_authBaseUrl/verify-token'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Future.value(true);
    }
    return Future.value(false);
  }

  Future<bool> addUser(String email, String name) async {
    _validateContract();
    final uri = Uri.parse('$_dbBaseUrl/insert');
    final prefs = await _prefs;
    final token = prefs.getString('token');
    if (token == null) {
      return Future.error('No token found');
    }

    final userId = prefs.getString('userId');
    final record = {
      'email': email,
      'name': name,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
    };

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      "tableName": 'Users',
      "records": [record],
    });

    final response = await httpClient.post(uri, headers: headers, body: body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Future.value(true);
    } else {
      return Future.error(
        'No se pudo crear perfil en tabla Users: ${_errorMessage(response)}',
      );
    }
  }

  Future<bool> addUserToRoleTable({
    required String role,
    required String name,
    required String lastName,
    required String email,
  }) async {
    _validateContract();
    final prefs = await _prefs;
    final token = prefs.getString('token');
    if (token == null) {
      return Future.error('No token found');
    }

    final normalizedRole = role.trim().toLowerCase();
    final tableName = normalizedRole == 'docente' || normalizedRole == 'teacher'
        ? 'teachers'
        : 'students';

    final uri = Uri.parse('$_dbBaseUrl/insert');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'tableName': tableName,
      'records': [
        {
          'name': name,
          'last_name': lastName,
          'email': email,
        }
      ],
    });

    final response = await httpClient.post(uri, headers: headers, body: body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }

    return Future.error(
      'No se pudo crear perfil en $tableName: ${_errorMessage(response)}',
    );
  }

  @override
  Future<AuthenticationUser> getLoggedUser() async {
    _validateContract();
    final prefs = await _prefs;
    final email = prefs.getString('email');
    final userId = prefs.getString('userId');
    final token = prefs.getString('token');

    if (token == null) {
      return Future.error('No token found');
    }
    if (email == null && userId == null) {
      return Future.error('No user identifier found');
    }

    final params = <String, String>{'tableName': 'Users'};
    if (email != null) {
      params['email'] = email;
    } else if (userId != null) {
      params['userId'] = userId;
    }

    final uri = Uri.parse('$_dbBaseUrl/read').replace(queryParameters: params);

    final response =
        await httpClient.get(uri, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      final List<dynamic> decodedJson = jsonDecode(response.body);
      List<AuthenticationUser> users = List<AuthenticationUser>.from(
          decodedJson.map((x) => AuthenticationUser.fromJson(x)));
      if (users.isEmpty) {
        return Future.error('No se encontro perfil en tabla Users');
      }
      return Future.value(users.first);
    } else {
      return Future.error(_errorMessage(response));
    }
  }

  @override
  Future<List<AuthenticationUser>> getUsers() async {
    _validateContract();
    final prefs = await _prefs;
    final token = prefs.getString('token');
    if (token == null) {
      return Future.error('No token found');
    }

    final uri =
        Uri.parse('$_dbBaseUrl/read').replace(queryParameters: {'tableName': 'Users'});
    final response =
        await httpClient.get(uri, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      final List<dynamic> decodedJson = jsonDecode(response.body);
      List<AuthenticationUser> users = List<AuthenticationUser>.from(
          decodedJson.map((x) => AuthenticationUser.fromJson(x)));
      return Future.value(users);
    } else {
      return Future.error(_errorMessage(response));
    }
  }
}
