# Propuesta individual – Jhoreinis Anaya Díaz
# UniFlow – Plataforma de Organización Estudiantil Universitaria

## Problemática
En el contexto universitario, los estudiantes participan en:

-	Grupos de estudio
-	Proyectos académicos
-	Semilleros de investigación
-	Representación estudiantil
-	Eventos y actividades extracurriculares

Sin embargo, se podría presentar problemas frecuentes como:
-	Desorganización en la asignación de tareas.
-	Falta de claridad en responsabilidades.
-	Poca visibilidad del avance grupal.
-	Comunicación dispersa (WhatsApp, correo, Classroom, etc.).
-	Dificultad para que docentes hagan seguimiento al trabajo en equipo.

## Referentes

1. Trello: Herramienta de gestión de tareas basada en tableros Kanban.
   
Aportes:

-	Visualización clara del flujo de trabajo.
-	Organización por columnas (pendiente, en proceso, finalizado).
-	Asignación de responsables.

Limitación en contexto universitario:

-	No está diseñada específicamente para entornos académicos.
-  No integra seguimiento docente formal.

3. Notion: Plataforma de organización y documentación colaborativa.
   
Aportes:

-	Centralización de información.
-	Espacios colaborativos personalizables.
-	Gestión flexible de proyectos.

Limitación:

-	Curva de aprendizaje alta.
-	No ofrece métricas automáticas de participación académica.
 
## Propuesta de Solución

Se propone UniFlow, una aplicación móvil diseñada específicamente para la organización de proyectos estudiantiles universitarios, con seguimiento docente integrado.

Se propone:

-	Una aplicación móvil única con manejo de roles (estudiante y docente).
Justificación
-	Los estudiantes usan principalmente dispositivos móviles.
-	Los docentes prefieren pantallas grandes para visualizar reportes.
-	Permite centralizar base de datos y autenticación.
-	Facilita mantenimiento y escalabilidad.

## Arquitectura Propuesta
Se implementará bajo arquitectura en tres capas (Clean Architecture).

Capa de Presentación
-	Aplicación móvil en Flutter.
-	Interfaces diferenciadas por rol.
-	Notificaciones push.

Capa de Dominio
Entidades principales:
-	Usuario
-	Proyecto
-	Grupo
-	Tarea
-	Entrega
-	Comentario
-	Métrica de participación

Casos de uso:
-	Crear proyecto
-	Crear grupo
-	Asignar tareas
-	Actualizar estado
-	Subir entregables
-	Generar métricas
-	Visualizar reportes

Capa de Datos
-	API REST
-	Base de datos PostgreSQL
-	Autenticación institucional (OAuth2)
-	Sistema de almacenamiento en la nube

Flujo Funcional Detallado

1. Inicio de sesión: El usuario accede con credenciales institucionales.
   
El sistema identifica el rol:
-	Docente
-	Estudiante

2. Flujo del Docente
   
1.	Crea un proyecto académico.
2.	Define:
-	Objetivos
-	Fecha de entrega
-	Criterios de evaluación

3.	Crea o importa grupos.

4.	Habilito seguimiento.

5.	Monitorea avance en tiempo real:
-	Tareas completadas
-	Participación individual
-	Entregas parciales
  
6.	Visualiza métricas finales.
   
3. Flujo del Estudiante
   
1.	Accede a proyectos activos.
   
2.	Visualiza tablero tipo Kanban:
-	Pendiente
-	En progreso
-	Finalizado
  
3.	Asigna o recibe tareas.

4.	Actualiza estado.

5.	Adjunta evidencias.

6.	Comenta avances.

7.	Consultas métricas personales.
   
4. Métricas Automáticas
   
El sistema calcula:
-	Número de tareas completadas por usuario.
-	Tiempo promedio de cumplimiento.
-	Nivel de participación.
-	Interacciones en el proyecto.
-	Cumplimiento de fechas.

6. Visualización de Resultados
   
Para el docente:
-	Ranking de participación.
-	Alertas de baja actividad.
-	Exportación de reportes.
Para el estudiante:
-	Indicador de contribución personal.
-	Comparación con promedio del grupo.
-	Historial de desempeño.

## Prototipo

## Justificación de la Propuesta

La propuesta se fundamenta en:

-	La organización visual de Trello.
-	La centralización documental de Notion.
-	La comunicación integrada de Microsoft Teams.

Sin embargo, UniFlow mejora estos referentes porque:

-	Está diseñada específicamente para contexto universitario.
-	Integra métricas automáticas de participación.
-	Permite seguimiento docente en tiempo real.
-	Reduce la dispersión de herramientas.
-	Mejora la trazabilidad del trabajo col
