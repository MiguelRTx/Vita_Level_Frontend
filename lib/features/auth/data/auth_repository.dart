import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/web/page_metadata.dart';

class AuthResult {
  const AuthResult({
    required this.accessToken,
    required this.expiresAt,
    required this.userId,
  });
  final String accessToken;
  final DateTime expiresAt;
  final String userId;
  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    accessToken: json['accessToken'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    userId: (json['user'] as Map)['id'] as String,
  );
}

class AuthRepository {
  AuthRepository(this.api);
  final ApiClient api;
  Future<AuthResult> login(String email, String password) =>
      _authenticate('auth/login', {'email': email, 'password': password});
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String timeZone,
  }) => _authenticate('auth/register', {
    'displayName': name,
    'email': email,
    'password': password,
    'timeZone': timeZone,
  });
  Future<AuthResult> _authenticate(
    String path,
    Map<String, String> body,
  ) async {
    final response = await api.dio.post<Map<String, dynamic>>(
      path,
      data: {
        ...body,
        if (formHoneypotValue().isNotEmpty) 'website': formHoneypotValue(),
      },
      options: Options(extra: {'requiresAuth': false}),
    );
    return AuthResult.fromJson(
      Map<String, dynamic>.from(response.data!['data'] as Map),
    );
  }

  Future<String> currentUserId() async =>
      (await api.getObject('me'))['id'] as String;
  Future<void> logout() async {
    await api.dio.post<void>('auth/logout');
  }
}
