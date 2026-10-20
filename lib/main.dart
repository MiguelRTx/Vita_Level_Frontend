import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'app/store/app_store.dart';
import 'core/network/api_client.dart';
import 'core/session/token_vault.dart';
import 'features/auth/application/session_controller.dart';
import 'features/auth/data/auth_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = createAppStore();
  final vault = TokenVault(
    kIsWeb ? MemoryTokenPersistence() : SecureTokenPersistence(),
  );
  final api = ApiClient(vault: vault);
  final session = SessionController(
    store: store,
    vault: vault,
    repository: AuthRepository(api),
  );
  api.onUnauthorized = session.expire;
  runApp(RitmoApp(store: store, api: api, session: session));
  unawaited(session.restore());
}
