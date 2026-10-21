import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamification_app/app/store/app_store.dart';
import 'package:gamification_app/app/router/app_router.dart';

void main() {
  test('the Redux reducer is deterministic and preserves its input state', () {
    const state = AppState(
      status: SessionStatus.signedIn,
      userId: 'original-user',
      sessionEpoch: 4,
      message: 'original-message',
    );
    Object snapshot(AppState value) => (
      value.status,
      value.userId,
      value.themeMode,
      value.sessionEpoch,
      value.message,
    );
    final before = snapshot(state);
    for (final action in [
      const ThemeChanged(ThemeMode.dark),
      const SessionChanged(SessionStatus.signedOut),
      Object(),
    ]) {
      final first = appReducer(state, action);
      final second = appReducer(state, action);
      expect(snapshot(first), snapshot(second));
      expect(snapshot(state), before);
    }
  });
  test(
    'Redux clears account identity and changes cache epoch when signing out',
    () {
      final store = createAppStore();
      store.dispatch(
        const SessionChanged(SessionStatus.signedIn, userId: 'first-user'),
      );
      final epoch = store.state.sessionEpoch;
      store.dispatch(const ThemeChanged(ThemeMode.dark));
      expect(store.state.userId, 'first-user');
      expect(store.state.sessionEpoch, epoch);
      store.dispatch(const SessionChanged(SessionStatus.signedOut));
      expect(store.state.userId, isNull);
      expect(store.state.themeMode, ThemeMode.dark);
      expect(store.state.sessionEpoch, greaterThan(epoch));
    },
  );
  test(
    'GoRouter protects private routes and exits login after authentication',
    () {
      expect(sessionRedirect(SessionStatus.signedOut, '/profile'), '/login');
      expect(sessionRedirect(SessionStatus.signedOut, '/register'), isNull);
      expect(
        sessionRedirect(SessionStatus.restoring, '/dashboard'),
        '/loading',
      );
      expect(sessionRedirect(SessionStatus.restoreFailed, '/loading'), isNull);
      expect(sessionRedirect(SessionStatus.signedIn, '/login'), '/dashboard');
      expect(sessionRedirect(SessionStatus.signedIn, '/badges'), isNull);
    },
  );
}
