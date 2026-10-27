import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, this.signedIn = false});
  final bool signedIn;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.explore_off_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text('404', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 12),
                Text(
                  'Este camino todavía no existe',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                const Text(
                  'La dirección puede haber cambiado o estar incompleta. Volvamos a tu espacio.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () =>
                      context.go(signedIn ? '/dashboard' : '/login'),
                  child: const Text('Volver a Ritmo'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
