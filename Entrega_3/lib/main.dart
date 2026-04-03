import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ui/bindings/app_bindings.dart';
import 'ui/views/auth/login_page.dart';
import 'ui/views/home/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PeerApp',
      debugShowCheckedModeBanner: false,
      initialBinding: AppBindings(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4B3CF0)),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/home', page: () => const HomePage()),
      ],
    );
  }
}
