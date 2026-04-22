# Movil_202610_Grupo1

## Descripción de la aplicación

Esta aplicación móvil web y multiplataforma está orientada a la gestión de cursos, grupos y evaluaciones académicas dentro de un entorno universitario. Su propósito es facilitar el seguimiento del desempeño de estudiantes y grupos, permitir la creación y respuesta de evaluaciones, y ofrecer a docentes y estudiantes una interfaz clara para consultar información relevante en tiempo real.

### Funcionalidades principales

- Inicio de sesión y navegación según el rol del usuario.
- Gestión de cursos para docentes y visualización de cursos inscritos para estudiantes.
- Creación, consulta y seguimiento de evaluaciones por curso y por grupo.
- Visualización de resultados generales, por evaluación, por estudiante y por grupo.
- Caché persistente de datos para mejorar la experiencia y conservar información entre sesiones.
- Pruebas automatizadas de widget e integración para validar los flujos principales.

### Alcance

El alcance del proyecto cubre la interacción entre docentes y estudiantes dentro del flujo académico básico: autenticación, administración de cursos, respuesta de evaluaciones y consulta de resultados. No está orientado a reemplazar un sistema institucional completo, sino a demostrar una solución funcional centrada en el seguimiento y análisis de evaluaciones dentro de un contexto controlado.

## Instalación y ejecución

### Requisitos

- Flutter SDK compatible con Dart 3.10.7 o superior.
- Un emulador, dispositivo físico o navegador compatible para ejecutar la aplicación.

### Instalar dependencias

Desde la carpeta `PeerApp`, ejecuta:

```bash
flutter pub get
```

### Ejecutar la aplicación

Para iniciar la app en modo desarrollo:

```bash
flutter run
```

Si deseas ejecutar la versión web:

```bash
flutter run -d chrome
```

## Pruebas

El repositorio incluye pruebas unitarias, de widget e integración para validar los flujos principales de la aplicación.

### Ejecutar todas las pruebas

```bash
flutter test
```

### Ejecutar una prueba específica

```bash
flutter test test/widgets/evaluation_results_page_widget_test.dart
```

### Pruebas de integración

```bash
flutter test integration_test/professor_student_flow_test.dart
```