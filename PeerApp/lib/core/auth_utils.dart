import 'package:shared_preferences/shared_preferences.dart';

/// Retorna el correo del usuario autenticado desde SharedPreferences.
Future<String?> getCurrentEmail() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('email');
}