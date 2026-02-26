# UniFlow – Plataforma de Organización Estudiantil Universitaria
## Propuesta individual – Jhoreinis Anaya Díaz

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
    - Visualización clara del flujo de trabajo.
    - Organización por columnas (pendiente, en proceso, finalizado).
    - Asignación de responsables.

   Limitación en contexto universitario:
    - No está diseñada específicamente para entornos académicos.
    - No integra seguimiento docente formal.

2. Notion: Plataforma de organización y documentación colaborativa.

   Aportes:
    - Centralización de información.
    - Espacios colaborativos personalizables.
    - Gestión flexible de proyectos.

   Limitación:
    - Curva de aprendizaje alta.
    - No ofrece métricas automáticas de participación académica.
 
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
Entidades principales
-	Usuario
-	Proyecto
-	Grupo
-	Tarea
-	Entrega
-	Comentario
-	Métrica de participación

Casos de uso
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

## Flujo Funcional Detallado
1. Inicio de sesión: El usuario accede con credenciales institucionales.

   - El sistema identifica el rol:
     -	Docente
     -	Estudiante

2. Flujo del Docente: Crea un proyecto académico.
   
   - Define:
      -	Objetivos
      -	Fecha de entrega
      -	Criterios de evaluación

   - Crea o importa grupos.

   - Habilito seguimiento.

   - Monitorea avance en tiempo real:
      - Tareas completadas
      -	Participación individual
      -	Entregas parciales
  
   - Visualiza métricas finales.
   
3. Flujo del Estudiante
   
   - Accede a proyectos activos.
   
   - Visualiza tablero tipo Kanban:
      - Pendiente
      - En progreso
      - Finalizado
  
   - Asigna o recibe tareas.

   - Actualiza estado.

   - Adjunta evidencias.

	- Comenta avances.

   - Consultas métricas personales.
   
4. Métricas Automáticas
   
   - El sistema calcula:
      - Número de tareas completadas por usuario.
	   - Tiempo promedio de cumplimiento.
	   - Nivel de participación.
	   - Interacciones en el proyecto.
	   - Cumplimiento de fechas.

5. Visualización de Resultados
   - Para el docente:
      - Ranking de participación.
	   - Alertas de baja actividad.
	   - Exportación de reportes.
       
   - Para el estudiante:
      - Indicador de contribución personal.
      - Comparación con promedio del grupo.
      - Historial de desempeño.

## Prototipo

Link: https://www.figma.com/make/cMtQ0q0AMVik3iQJhTRSqd/Academic-Project-Management-App?p=f&t=p5Iqqk2mf5hlpu0f-0&fullscreen=1

<img width="400" height="484" alt="image" src="https://github.com/user-attachments/assets/abfeac6a-5af7-4cf5-9660-bb177ee52947" />
<img width="450" height="546" alt="image" src="https://github.com/user-attachments/assets/9cff419d-d887-44ec-9a59-8a9d565b0a5d" />
<img width="406" height="556" alt="image" src="https://github.com/user-attachments/assets/d06ec807-a402-47ca-88bb-814797b59f53" />
<img width="438" height="537" alt="image" src="https://github.com/user-attachments/assets/f5238864-f0a9-4b26-983a-7fb20d5e4627" />
<img width="434" height="540" alt="image" src="https://github.com/user-attachments/assets/adbfd491-6971-476f-b1de-5e63cff378d9" />
<img width="462" height="549" alt="image" src="https://github.com/user-attachments/assets/32d98dfa-66d5-4ea2-b167-8f67a68bd579" />
<img width="442" height="555" alt="image" src="https://github.com/user-attachments/assets/38a3005f-bb48-49a0-806d-52c566fc3133" />

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
