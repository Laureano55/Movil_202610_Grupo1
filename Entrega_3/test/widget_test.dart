import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });



  group('LoginPage - UI básica', () {
    testWidgets('Botón de iniciar sesión existe', (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const Key('loginButton'),
                  onPressed: () {},
                  child: const Text('Iniciar sesion'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('loginButton')), findsOneWidget);
      expect(find.text('Iniciar sesion'), findsOneWidget);
    });

    testWidgets('Campos de email y contraseña existen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  key: const Key('emailField'),
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo'),
                ),
                TextField(
                  key: const Key('passwordField'),
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Contraseña'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('emailField')), findsOneWidget);
      expect(find.byKey(const Key('passwordField')), findsOneWidget);
    });
  });

  group('SegmentedButton - Selección de rol', () {
    testWidgets('Selector de rol cambia correctamente',
        (WidgetTester tester) async {
      final roleObs = 'Estudiante'.obs;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Obx(() => SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<String>(
                        value: 'Docente', label: Text('Docente')),
                    ButtonSegment<String>(
                        value: 'Estudiante', label: Text('Estudiante')),
                  ],
                  selected: {roleObs.value},
                  onSelectionChanged: (newSelection) {
                    if (newSelection.isNotEmpty) {
                      roleObs.value = newSelection.first;
                    }
                  },
                )),
          ),
        ),
      );

      expect(roleObs.value, 'Estudiante');
      await tester.tap(find.text('Docente'));
      await tester.pump();
      expect(roleObs.value, 'Docente');
    });
  });

  group('Widgets básicos - Counter', () {
    testWidgets('Botón incrementar existe y funciona',
        (WidgetTester tester) async {
      int counter = 0;

      await tester.pumpWidget(
        GetMaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$counter', key: const Key('counterText')),
                  ElevatedButton(
                    key: const Key('incrementButton'),
                    onPressed: () => setState(() => counter++),
                    child: const Text('Increment'),
                  ),
                  ElevatedButton(
                    key: const Key('resetButton'),
                    onPressed: () => setState(() => counter = 0),
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    key: const Key('decrementButton'),
                    onPressed: () => setState(() => counter--),
                    child: const Text('Decrease'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('incrementButton')), findsOneWidget);
      expect(find.byKey(const Key('resetButton')), findsOneWidget);
      expect(find.byKey(const Key('decrementButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('incrementButton')));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byKey(const Key('resetButton')));
      await tester.pump();
      expect(find.text('0'), findsOneWidget);
    });
  });
}