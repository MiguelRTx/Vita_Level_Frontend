import 'package:dio/dio.dart';
import '../session/token_vault.dart';

class ApiClient {
  ApiClient({required this.vault, Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: const String.fromEnvironment(
                'API_BASE_URL',
                defaultValue: 'http://localhost:3000/api/v1/',
              ),
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 10),
              headers: {'Accept': 'application/json'},
            ),
          ) {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.extra['requiresAuth'] != false && vault.token != null) {
            options.headers['Authorization'] = 'Bearer ${vault.token}';
            options.extra['sessionToken'] = vault.token;
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final requestToken =
              error.requestOptions.extra['sessionToken'] as String?;
          if (error.response?.statusCode == 401 &&
              requestToken != null &&
              requestToken == vault.token) {
            await onUnauthorized?.call(requestToken);
          }
          handler.next(error);
        },
      ),
    );
  }
  final Dio dio;
  final TokenVault vault;
  Future<void> Function(String? token)? onUnauthorized;
  Future<Map<String, dynamic>> getObject(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      path,
      queryParameters: query,
    );
    return Map<String, dynamic>.from(response.data!['data'] as Map);
  }

  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      path,
      queryParameters: query,
    );
    return (response.data!['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> health() async {
    final url = Uri.parse(
      dio.options.baseUrl,
    ).replace(path: '/health', query: null);
    await dio.getUri<void>(
      url,
      options: Options(extra: {'requiresAuth': false}),
    );
  }
}
