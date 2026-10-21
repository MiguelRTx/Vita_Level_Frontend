import 'package:flutter/material.dart';
import 'package:redux/redux.dart';

enum SessionStatus { restoring, signedOut, signedIn, restoreFailed }

@immutable
class AppState {
  const AppState({
    this.status = SessionStatus.restoring,
    this.userId,
    this.themeMode = ThemeMode.light,
    this.sessionEpoch = 0,
    this.message,
  });
  final SessionStatus status;
  final String? userId;
  final ThemeMode themeMode;
  final int sessionEpoch;
  final String? message;
}

@immutable
class SessionChanged {
  const SessionChanged(this.status, {this.userId, this.message});
  final SessionStatus status;
  final String? userId;
  final String? message;
}

@immutable
class ThemeChanged {
  const ThemeChanged(this.mode);
  final ThemeMode mode;
}

AppState appReducer(AppState state, dynamic action) {
  if (action is SessionChanged) {
    return AppState(
      status: action.status,
      userId: action.userId,
      themeMode: state.themeMode,
      sessionEpoch: state.sessionEpoch + 1,
      message: action.message,
    );
  }
  if (action is ThemeChanged) {
    return AppState(
      status: state.status,
      userId: state.userId,
      themeMode: action.mode,
      sessionEpoch: state.sessionEpoch,
      message: state.message,
    );
  }
  return state;
}

Store<AppState> createAppStore() =>
    Store<AppState>(appReducer, initialState: const AppState());
