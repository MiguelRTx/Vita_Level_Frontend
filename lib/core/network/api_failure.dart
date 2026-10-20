import 'package:dio/dio.dart';

class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.code});
  final String message;
  final String? code;
  factory ApiFailure.from(Object error) {
    if (error is ApiFailure) return error;
    if (error is DioException) {
      final body = error.response?.data;
      final code = body is Map && body['error'] is Map
          ? body['error']['code'] as String?
          : null;
      final message = switch (code) {
        'INVALID_CREDENTIALS' => 'El correo o la contraseña no son correctos.',
        'EMAIL_IN_USE' =>
          'Este correo ya está registrado. Inicia sesión con tu cuenta.',
        'SESSION_EXPIRED' ||
        'AUTH_REQUIRED' => 'Tu sesión terminó. Vuelve a iniciar sesión.',
        'TIME_ZONE_CHANGE_BLOCKED' =>
          'Podrás cambiar la zona horaria 48 horas después de tu último cumplimiento.',
        'VALIDATION_ERROR' =>
          'Revisa las cantidades, fechas y campos del formulario. Las fechas deben respetar los límites de la actividad o proyecto.',
        'ACTIVITY_NOT_EDITABLE' =>
          'Esta actividad tiene cambios pendientes, ya tiene progreso o su periodo terminó.',
        'OCCURRENCE_CLOSED' =>
          'Este periodo ya terminó o todavía no comenzó. Actualiza la actividad.',
        'UNIT_ALREADY_COMPLETED' =>
          'Esta sesión ya fue completada. Tus datos se actualizarán.',
        'ACTIVITY_ARCHIVED' || 'PROJECT_ARCHIVED' =>
          'Este elemento está archivado y conserva su historial.',
        'IDEMPOTENCY_KEY_REUSED' =>
          'Este envío ya se utilizó para otro progreso. Actualiza la actividad.',
        'NOT_FOUND' => 'El elemento no existe o no pertenece a tu cuenta.',
        'RATE_LIMITED' =>
          'Hubo demasiados intentos. Espera unos minutos antes de volver a intentar.',
        'DATABASE_UNAVAILABLE' || 'CATALOG_NOT_READY' =>
          'El servicio no está disponible en este momento. Inténtalo más tarde.',
        'ORIGIN_NOT_ALLOWED' =>
          'Esta dirección de la aplicación no está autorizada para conectarse.',
        _ =>
          error.response == null
              ? 'No pudimos conectar con el servicio. Comprueba tu conexión e inténtalo otra vez.'
              : 'No se pudo completar la solicitud. Inténtalo otra vez.',
      };
      return ApiFailure(message, code: code);
    }
    return const ApiFailure(
      'No se pudo completar la operación. Inténtalo otra vez.',
    );
  }
  @override
  String toString() => message;
}
