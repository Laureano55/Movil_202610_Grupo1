import 'package:f_getxstate_demo/ui/viewmodels/auth_controller.dart';
import 'package:f_getxstate_demo/ui/views/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../support/fakes.dart';

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('LoginPage renderiza controles principales y cambia rol',
      (tester) async {
    final fakeAuthRepo = FakeAuthRepository()..role = 'Docente';
    Get.put<AuthController>(AuthController(fakeAuthRepo));

    await tester.pumpWidget(
      GetMaterialApp(
        getPages: [
          GetPage(name: '/home', page: () => const Scaffold(body: Text('home'))),
        ],
        home: const LoginPage(),
      ),
    );

    expect(find.text('PeerApp'), findsOneWidget);
    expect(find.text('Iniciar sesion'), findsOneWidget);
    expect(find.text('Docente'), findsOneWidget);
    expect(find.text('Estudiante'), findsOneWidget);

    await tester.tap(find.text('Docente'));
    await tester.pump();

    final controller = Get.find<AuthController>();
    expect(controller.selectedRole.value, 'Docente');
  });

  testWidgets('Login navega a /home con credenciales validas', (tester) async {
    final fakeAuthRepo = FakeAuthRepository()
      ..role = 'Docente'
      ..shouldFailLogin = false;
    final controller = AuthController(fakeAuthRepo);
    controller.selectRole('Docente');
    Get.put<AuthController>(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/login',
        getPages: [
          GetPage(name: '/login', page: () => const LoginPage()),
          GetPage(name: '/home', page: () => const Scaffold(body: Text('home'))),
        ],
      ),
    );

    await tester.enterText(
      find.byType(TextField).first,
      'docente@uninorte.edu.co',
    );
    await tester.tap(find.text('Iniciar sesion'));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });
}
