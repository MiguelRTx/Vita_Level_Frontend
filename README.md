# Frontend Flutter de Ritmo

Este es el proyecto Flutter independiente. Consume la API de `../backend` por HTTP; no accede a PostgreSQL.

La [guía de ejecución principal](../README.md) incluye los comandos para esta computadora y para una instalación nueva. El [contrato API](../docs/02-api-contract.md) define los nombres y tipos de los DTO Dart.

## Estado y organización

- `app/store`: Redux para identidad de sesión pública, expiración/cambio de cuenta y tema.
- `core/session`: token en memoria para web y almacenamiento seguro para Android/iOS.
- `features/*/data`: DTO y repositorios de acceso HTTP.
- `features/*/application`: Riverpod para consultas y coordinación de operaciones.
- `features/*/presentation`: pantallas y widgets responsive.
- `core/invalidate_progress.dart`: actualización conjunta de actividades, perfil, dashboard, historial y logros tras una mutación.

El cambio de sesión destruye el contenedor de datos anterior para evitar que aparezcan datos de otra cuenta. El coordinador de progreso conserva una misma clave UUID y cantidad ante un error de red o respuesta incierta; nunca suma XP localmente.

## Pantallas

Login/registro, dashboard, listado/formulario/detalle de actividades, proyectos y tareas, historial, insignias, recompensas y perfil. Las pantallas muestran carga, errores recuperables y estados vacíos. El dashboard usa `fl_chart` para líneas, barras y dona; el calendario de calor usa widgets Flutter con columnas semanales, etiquetas, desplazamiento horizontal y ayudas accesibles.

## Ejecución

Desde esta carpeta, con un SDK sin problemas de espacios en su ruta:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --web-port 5173 --dart-define-from-file=config/development.json
```

En esta computadora utiliza `..\scripts\flutter.ps1` desde aquí o `.\scripts\flutter.ps1` desde la raíz. Selecciona el alias corto del SDK instalado, porque las herramientas de assets nativos de esta versión fallan al lanzar Dart desde algunas rutas con espacios. No se modificó la instalación global de Flutter.

Web usa `config/development.json`; el emulador Android usa `config/android-emulator.json`. No guardes secretos en `dart-define`: esos valores forman parte del cliente compilado. La sesión web termina al recargar la página, una decisión explícita del MVP para evitar persistir el JWT en el navegador.
