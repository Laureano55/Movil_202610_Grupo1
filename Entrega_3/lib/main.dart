import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ui/bindings/app_bindings.dart';
import 'ui/views/auth/login_page.dart';
import 'ui/views/home/home_page.dart';
import 'ui/views/professor/create_evaluation_page.dart';
import 'ui/views/professor/evaluation_results_page.dart';
import 'ui/views/professor/course_groups_page.dart';
import 'ui/views/professor/import_groups_page.dart';
import 'ui/views/student/active_evaluations_page.dart';
import 'ui/views/student/evaluation_form_page.dart';
import 'ui/views/student/my_results_page.dart';
import 'ui/views/student/student_course_classmates_page.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4B3CF0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/home', page: () => const HomePage()),
        // Professor pages
        GetPage(
          name: '/professor/create-evaluation',
          page: () => const CreateEvaluationPage(),
        ),
        GetPage(
          name: '/professor/evaluation-results',
          page: () => const EvaluationResultsPage(),
        ),
        GetPage(
          name: '/professor/course-groups',
          page: () {
            final args =
                Get.arguments as Map<String, dynamic>? ?? {};
            return CourseGroupsPage(
              courseId: args['courseId'] ?? '',
              courseTitle: args['courseTitle'] ?? 'Curso',
              courseCode: args['courseCode'] ?? '',
            );
          },
        ),
        GetPage(
          name: '/professor/import-groups',
          page: () => const ImportGroupsPage(),
        ),
        // Student pages
        GetPage(
          name: '/student/active-evaluations',
          page: () => const ActiveEvaluationsPage(),
        ),
        GetPage(
          name: '/student/evaluation-form',
          page: () => const EvaluationFormPage(),
        ),
        GetPage(
          name: '/student/my-results',
          page: () => const MyResultsPage(),
        ),
        GetPage(
          name: '/student/classmates',
          page: () {
            final args =
                Get.arguments as Map<String, dynamic>? ?? {};
            return StudentCourseClassmatesPage(
              courseId: args['courseId'] ?? '',
              courseTitle: args['courseTitle'] ?? 'Curso',
              courseCode: args['courseCode'] ?? '',
            );
          },
        ),
      ],
    );
  }
}