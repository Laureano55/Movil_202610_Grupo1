import '../models/authentication_user.dart';

abstract class IAuthRepository {
  Future<void> login(String email, String password);

  Future<void> signUp(
    String email,
    String password,
    String name,
    bool direct, {
    String lastName = '',
    String role = 'Estudiante',
  });

  Future<bool> logOut();

  Future<bool> validate(String email, String validationCode);

  Future<bool> validateToken();

  Future<void> forgotPassword(String email);

  Future<String?> getAccountRoleByEmail(String email);

  Future<AuthenticationUser> getLoggedUser();

  Future<List<AuthenticationUser>> getUsers();
}
