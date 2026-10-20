import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:redux/redux.dart';
import '../../../app/store/app_store.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/session/token_vault.dart';
import '../data/auth_repository.dart';

class SessionController extends ChangeNotifier {
  SessionController({
    required this.store,
    required this.vault,
    required this.repository,
  });
  final Store<AppState> store;
  final TokenVault vault;
  final AuthRepository repository;
  Timer? _expirationTimer;
  Future<void>? _clearing;
  int _operation = 0;
  void _dispatch(SessionChanged action) {
    store.dispatch(action);
    notifyListeners();
  }

  Future<void> restore() async {
    final operation = ++_operation;
    _dispatch(const SessionChanged(SessionStatus.restoring));
    try {
      if (!await vault.restore()) {
        if (operation == _operation) {
          _dispatch(const SessionChanged(SessionStatus.signedOut));
        }
        return;
      }
      final userId = await repository.currentUserId();
      if (operation != _operation) return;
      _dispatch(SessionChanged(SessionStatus.signedIn, userId: userId));
      _scheduleExpiration();
    } catch (error) {
      if (operation != _operation) return;
      if (vault.token == null ||
          (error is DioException && error.response?.statusCode == 401)) {
        await expire(vault.token);
      } else {
        _dispatch(
          SessionChanged(
            SessionStatus.restoreFailed,
            message: ApiFailure.from(error).message,
          ),
        );
      }
    }
  }

  Future<void> login(String email, String password) async =>
      _accept(await repository.login(email, password));
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String timeZone,
  }) async => _accept(
    await repository.register(
      name: name,
      email: email,
      password: password,
      timeZone: timeZone,
    ),
  );
  Future<void> _accept(AuthResult result) async {
    ++_operation;
    await vault.save(result.accessToken, result.expiresAt);
    _dispatch(SessionChanged(SessionStatus.signedIn, userId: result.userId));
    _scheduleExpiration();
  }

  void _scheduleExpiration() {
    _expirationTimer?.cancel();
    final remaining = vault.expiresAt!.difference(DateTime.now());
    final token = vault.token;
    _expirationTimer = Timer(
      remaining.isNegative ? Duration.zero : remaining,
      () => unawaited(expire(token)),
    );
  }

  Future<void> logout() async {
    // Network failures keep the session visible so the user can retry revocation.
    try {
      await repository.logout();
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) rethrow;
    }
    await _clear(null);
  }

  Future<void> expire(String? token) async {
    if (token != null && token != vault.token) return;
    await _clear('Tu sesión terminó. Vuelve a iniciar sesión.');
  }

  Future<void> _clear(String? message) =>
      _clearing ??= _clearOnce(message).whenComplete(() => _clearing = null);
  Future<void> _clearOnce(String? message) async {
    ++_operation;
    _expirationTimer?.cancel();
    try {
      await vault.clear();
    } catch (_) {
      /* Memory is already cleared; the API rejects stale saved JWTs. */
    }
    _dispatch(SessionChanged(SessionStatus.signedOut, message: message));
  }

  @override
  void dispose() {
    _expirationTimer?.cancel();
    super.dispose();
  }
}
