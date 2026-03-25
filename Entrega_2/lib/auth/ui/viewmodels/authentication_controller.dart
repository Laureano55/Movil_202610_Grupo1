import 'package:get/get.dart';

import '../../domain/models/authentication_user.dart';
import '../../domain/repositories/i_auth_repository.dart';

class AuthenticationController extends GetxController {
  final IAuthRepository authentication;
  final logged = false.obs;
  final _loggedUser = Rxn<AuthenticationUser>();
  final RxBool isLoading = false.obs;

  AuthenticationController(this.authentication);

  AuthenticationUser? get loggedUser => _loggedUser.value;

  set loggedUser(AuthenticationUser? user) {
    _loggedUser.value = user;
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    logged.value = await validateToken();
  }

  bool get isLogged => logged.value;

  Future<bool> login(email, password) async {
    await authentication.login(email, password);
    await getLoggedUser();
    logged.value = true;

    return true;
  }

  Future<bool> signUp(name, email, password, bool direct) async {
    await authentication.signUp(email, password, name, direct);
    return true;
  }

  Future<bool> validate(String email, String validationCode) async {
    var rta = await authentication.validate(email, validationCode);
    return rta;
  }

  Future<void> logOut() async {
    logged.value = false;
    await authentication.logOut();
    logged.value = false;
  }

  Future<bool> validateToken() async {
    var rta = await authentication.validateToken();
    if (rta) {
      await getLoggedUser();
    }
    return rta;
  }

  Future<void> forgotPassword(String email) async {
    await authentication.forgotPassword(email);
  }

  Future<AuthenticationUser> getLoggedUser() async {
    isLoading.value = true;
    var rta = await authentication.getLoggedUser();
    _loggedUser.value = rta;
    isLoading.value = false;
    return rta;
  }

  Future<List<AuthenticationUser>> getUsers() async {
    var rta = await authentication.getUsers();
    return rta;
  }
}
