import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.isRegistration = false});
  final bool isRegistration;
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  final timeZone = TextEditingController(text: 'America/La_Paz');
  bool busy = false;
  bool obscure = true;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    timeZone.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !formKey.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final session = ref.read(sessionControllerProvider);
      if (widget.isRegistration) {
        await session.register(
          name: name.text.trim(),
          email: email.text.trim(),
          password: password.text,
          timeZone: timeZone.text.trim(),
        );
      } else {
        await session.login(email.text.trim(), password.text);
      }
      TextInput.finishAutofillContext();
    } catch (exception) {
      if (mounted) setState(() => error = ApiFailure.from(exception).message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final register = widget.isRegistration;
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 1200 && size.height >= 780;
    final sessionMessage = ref
        .read(sessionControllerProvider)
        .store
        .state
        .message;
    final form = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: AutofillGroup(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!wide) ...[const Brand(), const SizedBox(height: 36)],
                Text(
                  register
                      ? 'Tu primer paso\nempieza aquí.'
                      : 'Qué bueno\nverte de nuevo.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 14),
                Text(
                  register
                      ? 'Crea tu espacio para crecer, a tu ritmo.'
                      : 'Entra a tu espacio y sigue construyendo tu mejor versión.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 30),
                if (sessionMessage != null && error == null && !register) ...[
                  _Notice(message: sessionMessage),
                  const SizedBox(height: 18),
                ],
                if (register) ...[
                  TextFormField(
                    controller: name,
                    enabled: !busy,
                    maxLength: 80,
                    autofillHints: const [AutofillHints.name],
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Tu nombre',
                      prefixIcon: Icon(Icons.person_outline),
                      counterText: '',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Escribe tu nombre.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  key: const Key('email'),
                  controller: email,
                  enabled: !busy,
                  maxLength: 254,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'tu@correo.com',
                    prefixIcon: Icon(Icons.alternate_email),
                    counterText: '',
                  ),
                  validator: (value) =>
                      value == null ||
                          !RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(value.trim())
                      ? 'Escribe un correo válido.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('password'),
                  controller: password,
                  enabled: !busy,
                  maxLength: 128,
                  obscureText: obscure,
                  enableSuggestions: false,
                  autocorrect: false,
                  autofillHints: [
                    register
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  textInputAction: register
                      ? TextInputAction.next
                      : TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!register) submit();
                  },
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    counterText: '',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: obscure
                          ? 'Mostrar contraseña'
                          : 'Ocultar contraseña',
                      onPressed: () => setState(() => obscure = !obscure),
                      icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.length < (register ? 12 : 1)
                      ? (register
                            ? 'Usa al menos 12 caracteres.'
                            : 'Escribe tu contraseña.')
                      : null,
                ),
                if (register) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: timeZone,
                    enabled: !busy,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => submit(),
                    decoration: const InputDecoration(
                      labelText: 'Zona horaria',
                      helperText: 'Por ejemplo, America/La_Paz o Europe/Madrid',
                      prefixIcon: Icon(Icons.public),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Indica tu zona horaria.'
                        : null,
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 18),
                  _Notice(message: error!, isError: true),
                ],
                const SizedBox(height: 26),
                FilledButton(
                  key: const Key('submit-auth'),
                  onPressed: busy ? null : submit,
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                register ? 'Crear mi cuenta' : 'Iniciar sesión',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      register
                          ? '¿Ya tienes una cuenta?'
                          : '¿Es tu primera vez?',
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => context.go(register ? '/login' : '/register'),
                      child: Text(
                        register ? 'Inicia sesión' : 'Crea tu cuenta',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Consumer(
                  builder: (context, ref, child) => ref
                      .watch(healthProvider)
                      .when(
                        data: (_) => const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 15,
                              color: AppTheme.green,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Servicio disponible',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        loading: () => const Text(
                          'Comprobando conexión…',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                        error: (_, _) => TextButton.icon(
                          onPressed: () => ref.invalidate(healthProvider),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Sin conexión · Reintentar'),
                        ),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (wide) const Expanded(child: _WelcomePanel()),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 56 : 26,
                  vertical: 40,
                ),
                child: form,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, this.isError = false});
  final String message;
  final bool isError;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError
              ? Theme.of(context).colorScheme.onErrorContainer
              : Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    ),
  );
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppTheme.ink,
      borderRadius: BorderRadius.circular(30),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        children: [
          Positioned(
            right: -130,
            bottom: -100,
            child: Container(
              width: 470,
              height: 470,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .08),
                  width: 70,
                ),
              ),
            ),
          ),
          Positioned(
            left: -130,
            top: 110,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .035),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Brand(light: true),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'PEQUEÑOS PASOS. GRANDES CAMBIOS.',
                      style: TextStyle(
                        color: AppTheme.mint,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Haz espacio\npara lo que\nte hace crecer.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 47,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -1.8,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Estudia, muévete, lee y da vida a tus proyectos.\nCada paso cuenta en tu propia aventura.',
                    style: TextStyle(
                      color: Color(0xFFBBD4C5),
                      fontSize: 16,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 34),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final icon in [
                        Icons.school_outlined,
                        Icons.directions_run,
                        Icons.menu_book_outlined,
                        Icons.rocket_launch_outlined,
                      ])
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .09),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(icon, color: AppTheme.mint, size: 27),
                        ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'Tu progreso. Tus metas. Tu ritmo.',
                    style: TextStyle(color: Color(0xFFBBD4C5), fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
