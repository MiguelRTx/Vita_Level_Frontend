import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/store/app_store.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/providers.dart';
import '../../../core/invalidate_progress.dart';
import '../../../core/widgets/async_content.dart';
import '../application/profile_providers.dart';
import '../data/profile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => SingleChildScrollView(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 20 : 40),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('A tu manera.', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 12),
        const Text('Tu perfil, tus preferencias y tu tiempo.'),
        const SizedBox(height: 28),
        AsyncContent(
          value: ref.watch(profileProvider),
          onRetry: () => ref.invalidate(profileProvider),
          builder: (profile) => _ProfileForm(
            key: ValueKey(
              '${profile.id}-${profile.displayName}-${profile.timeZone}',
            ),
            profile: profile,
          ),
        ),
      ],
    ),
  );
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({super.key, required this.profile});
  final UserProfile profile;
  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final formKey = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.profile.displayName);
  late final timeZone = TextEditingController(text: widget.profile.timeZone);
  bool saving = false;
  bool loggingOut = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    timeZone.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate() || saving) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            name: name.text.trim(),
            timeZone: timeZone.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu perfil se guardó correctamente.')),
      );
      invalidateProgress(ref);
    } catch (exception) {
      if (mounted) setState(() => error = ApiFailure.from(exception).message);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> logout() async {
    setState(() {
      loggingOut = true;
      error = null;
    });
    try {
      await ref.read(sessionControllerProvider).logout();
    } catch (exception) {
      if (mounted) setState(() => error = ApiFailure.from(exception).message);
    } finally {
      if (mounted) setState(() => loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 720),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        child: Text(
                          widget.profile.displayName
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.profile.displayName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              widget.profile.email,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: name,
                    enabled: !saving && !loggingOut,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.person_outline),
                      counterText: '',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Escribe tu nombre.'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: timeZone,
                    enabled: !saving && !loggingOut,
                    decoration: const InputDecoration(
                      labelText: 'Zona horaria',
                      prefixIcon: Icon(Icons.public),
                      helperText: 'Por ejemplo, America/La_Paz o Europe/Madrid',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Indica una zona horaria.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tu zona horaria determina los días de tu racha. Para proteger tu historial, los cambios se permiten 48 horas después del último cumplimiento.',
                    style: TextStyle(fontSize: 12, height: 1.6),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: saving || loggingOut ? null : save,
                      icon: saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(saving ? 'Guardando…' : 'Guardar cambios'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: StoreBuilder<AppState>(
            builder: (context, store) => SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Modo oscuro'),
              subtitle: const Text('Elige cómo se ve tu espacio.'),
              value: store.state.themeMode == ThemeMode.dark,
              onChanged: (enabled) => store.dispatch(
                ThemeChanged(enabled ? ThemeMode.dark : ThemeMode.light),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: loggingOut || saving ? null : logout,
          icon: const Icon(Icons.logout),
          label: Text(loggingOut ? 'Cerrando sesión…' : 'Cerrar sesión'),
        ),
      ],
    ),
  );
}
