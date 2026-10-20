import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:gamification_app/app/store/app_store.dart';
import 'package:gamification_app/core/network/api_client.dart';
import 'package:gamification_app/core/session/token_vault.dart';
import 'package:gamification_app/features/auth/application/session_controller.dart';
import 'package:gamification_app/features/auth/data/auth_repository.dart';

void main() {
  test('expired and malformed persisted sessions are discarded', () async {
    final persistence = MemoryTokenPersistence();
    final vault = TokenVault(persistence);
    await persistence.write(
      jsonEncode({
        'token': 'expired',
        'expiresAt': DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
      }),
    );
    expect(await vault.restore(), isFalse);
    expect(await persistence.read(), isNull);
    await persistence.write('{broken');
    expect(await vault.restore(), isFalse);
  });
  test('login stores the token privately and authenticates Redux', () async {
    final harness = Harness();
    addTearDown(harness.dispose);
    harness.adapter.onPost(
      'auth/login',
      (server) => server.reply(200, {'data': authData()}),
      data: {'email': 'a@example.test', 'password': 'password'},
    );
    await harness.session.login('a@example.test', 'password');
    expect(harness.store.state.status, SessionStatus.signedIn);
    expect(harness.store.state.userId, 'user-a');
    expect(harness.vault.token, 'test-token');
  });
  test('authenticated 401 clears token and session once', () async {
    final harness = Harness();
    addTearDown(harness.dispose);
    await harness.vault.save(
      'old-token',
      DateTime.now().add(const Duration(hours: 1)),
    );
    harness.store.dispatch(
      const SessionChanged(SessionStatus.signedIn, userId: 'user-a'),
    );
    harness.adapter.onGet(
      'me',
      (server) => server.reply(401, {
        'error': {'code': 'SESSION_EXPIRED'},
      }),
    );
    await expectLater(
      harness.api.getObject('me'),
      throwsA(isA<DioException>()),
    );
    expect(harness.vault.token, isNull);
    expect(harness.store.state.status, SessionStatus.signedOut);
    expect(await harness.persistence.read(), isNull);
  });
  test(
    'a login error does not trigger expiration of another session',
    () async {
      final harness = Harness();
      addTearDown(harness.dispose);
      harness.adapter.onPost(
        'auth/login',
        (server) => server.reply(401, {
          'error': {'code': 'INVALID_CREDENTIALS'},
        }),
        data: {'email': 'a@example.test', 'password': 'wrong'},
      );
      await expectLater(
        harness.session.login('a@example.test', 'wrong'),
        throwsA(isA<DioException>()),
      );
      expect(harness.store.state.message, isNull);
    },
  );
  test(
    'failed logout keeps the session so revocation can be retried',
    () async {
      final harness = Harness();
      addTearDown(harness.dispose);
      await harness.vault.save(
        'test-token',
        DateTime.now().add(const Duration(hours: 1)),
      );
      harness.store.dispatch(
        const SessionChanged(SessionStatus.signedIn, userId: 'user-a'),
      );
      harness.adapter.onPost('auth/logout', (server) => server.reply(503, {}));
      await expectLater(harness.session.logout(), throwsA(isA<DioException>()));
      expect(harness.store.state.status, SessionStatus.signedIn);
      expect(harness.vault.token, 'test-token');
    },
  );
  test(
    'successful logout removes persisted credentials and clears identity',
    () async {
      final harness = Harness();
      addTearDown(harness.dispose);
      await harness.vault.save(
        'test-token',
        DateTime.now().add(const Duration(hours: 1)),
      );
      harness.store.dispatch(
        const SessionChanged(SessionStatus.signedIn, userId: 'user-a'),
      );
      harness.adapter.onPost(
        'auth/logout',
        (server) => server.reply(204, null),
      );
      await harness.session.logout();
      expect(harness.store.state.status, SessionStatus.signedOut);
      expect(harness.store.state.userId, isNull);
      expect(await harness.persistence.read(), isNull);
    },
  );
  test(
    'network failure while restoring preserves the encrypted session for retry',
    () async {
      final harness = Harness();
      addTearDown(harness.dispose);
      await harness.vault.save(
        'test-token',
        DateTime.now().add(const Duration(hours: 1)),
      );
      harness.adapter.onGet('me', (server) => server.reply(503, {}));
      await harness.session.restore();
      expect(harness.store.state.status, SessionStatus.restoreFailed);
      expect(harness.vault.token, 'test-token');
    },
  );
  test(
    'late expiration from a previous token cannot close a new session',
    () async {
      final harness = Harness();
      addTearDown(harness.dispose);
      await harness.vault.save(
        'new-token',
        DateTime.now().add(const Duration(hours: 1)),
      );
      harness.store.dispatch(
        const SessionChanged(SessionStatus.signedIn, userId: 'new-user'),
      );
      await harness.session.expire('old-token');
      expect(harness.vault.token, 'new-token');
      expect(harness.store.state.userId, 'new-user');
    },
  );
}

Map<String, dynamic> authData() => {
  'accessToken': 'test-token',
  'expiresAt': DateTime.now()
      .add(const Duration(hours: 1))
      .toUtc()
      .toIso8601String(),
  'user': {'id': 'user-a'},
};

class Harness {
  final store = createAppStore();
  final persistence = MemoryTokenPersistence();
  late final vault = TokenVault(persistence);
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api/v1/'));
  late final adapter = DioAdapter(dio: dio);
  late final api = ApiClient(vault: vault, dio: dio);
  late final session = SessionController(
    store: store,
    vault: vault,
    repository: AuthRepository(api),
  );
  Harness() {
    store.dispatch(const SessionChanged(SessionStatus.signedOut));
    api.onUnauthorized = session.expire;
  }
  void dispose() {
    session.dispose();
    dio.close(force: true);
  }
}
