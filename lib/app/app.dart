import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:redux/redux.dart';
import '../core/network/api_client.dart';
import '../core/providers.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/async_content.dart';
import '../features/auth/application/session_controller.dart';
import 'router/app_router.dart';
import 'store/app_store.dart';

class RitmoApp extends StatefulWidget {
  const RitmoApp({
    super.key,
    required this.store,
    required this.api,
    required this.session,
  });
  final Store<AppState> store;
  final ApiClient api;
  final SessionController session;
  @override
  State<RitmoApp> createState() => _RitmoAppState();
}

class _RitmoAppState extends State<RitmoApp> with WidgetsBindingObserver {
  late final GoRouter router = createAppRouter(widget.session);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        widget.store.state.status == SessionStatus.signedIn &&
        widget.api.vault.isExpired) {
      widget.session.expire(widget.api.vault.token);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StoreProvider<AppState>(
    store: widget.store,
    child: StoreBuilder<AppState>(
      builder: (context, store) => ProviderScope(
        key: ValueKey(store.state.sessionEpoch),
        overrides: [
          apiClientProvider.overrideWithValue(widget.api),
          sessionControllerProvider.overrideWithValue(widget.session),
        ],
        child: MaterialApp.router(
          title: 'Ritmo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.create(Brightness.light),
          darkTheme: AppTheme.create(Brightness.dark),
          themeMode: store.state.themeMode,
          routerConfig: router,
        ),
      ),
    ),
  );
}

class RestoreSessionScreen extends StatelessWidget {
  const RestoreSessionScreen({super.key, required this.session});
  final SessionController session;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: session.store.state.status == SessionStatus.restoreFailed
              ? InfoPanel(
                  icon: Icons.cloud_off_rounded,
                  title: 'Volvamos a conectar',
                  message: session.store.state.message!,
                  action: FilledButton(
                    onPressed: session.restore,
                    child: const Text('Reintentar'),
                  ),
                )
              : const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Preparando tu espacio…'),
                  ],
                ),
        ),
      ),
    ),
  );
}
