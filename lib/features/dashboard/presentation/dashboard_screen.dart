import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_content.dart';
import '../../profile/application/profile_providers.dart';
import '../../profile/data/profile.dart';
import '../application/dashboard_providers.dart';
import 'statistics_panel.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => RefreshIndicator(
    onRefresh: () async {
      ref.invalidate(categoriesProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(profileProvider);
      await ref.read(profileProvider.future);
    },
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 20 : 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TU ESPACIO PERSONAL',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          AsyncContent(
            value: ref.watch(profileProvider),
            onRetry: () => ref.invalidate(profileProvider),
            builder: (profile) => _ProfileOverview(profile: profile),
          ),
          const SizedBox(height: 32),
          if (ref.watch(profileProvider).valueOrNull case final profile?) ...[
            StatisticsPanel(
              key: ValueKey(profile.timeZone),
              timeZone: profile.timeZone,
            ),
            const SizedBox(height: 32),
          ],
          Text(
            'Cuatro áreas para crecer',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Encuentra el equilibrio entre aprender, cuidarte y crear.',
          ),
          const SizedBox(height: 18),
          AsyncContent(
            value: ref.watch(categoriesProvider),
            onRetry: () => ref.invalidate(categoriesProvider),
            builder: (categories) {
              if (categories.isEmpty) {
                return const InfoPanel(
                  icon: Icons.category_outlined,
                  title: 'Aún no hay categorías',
                  message:
                      'Las áreas de actividad aparecerán aquí cuando estén disponibles.',
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) => Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    for (final category in categories)
                      SizedBox(
                        width: constraints.maxWidth > 760
                            ? (constraints.maxWidth - 42) / 4
                            : (constraints.maxWidth - 14) / 2,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _categoryColor(category.slug),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    _categoryIcon(category.slug),
                                    color: AppTheme.ink,
                                    size: 27,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  category.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 24,
                runSpacing: 16,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Celebra cada avance',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Conoce las insignias y recompensas de tu recorrido.',
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/badges'),
                    label: const Text('Explorar insignias'),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
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

class _ProfileOverview extends StatelessWidget {
  const _ProfileOverview({required this.profile});
  final UserProfile profile;
  @override
  Widget build(BuildContext context) {
    final progress = profile.gamification;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola, ${profile.displayName.split(' ').first} 👋',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        const Text('Cada día es una nueva oportunidad para avanzar.'),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.mint,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.spa_outlined,
                    color: AppTheme.green,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vas a tu propio ritmo.',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: AppTheme.ink),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'El progreso se construye un paso a la vez. Este es el tuyo.',
                style: TextStyle(color: AppTheme.ink),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'NIVEL ${progress.level}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppTheme.ink,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${progress.totalXp} XP totales',
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress.levelProgress.clamp(0, 1),
                backgroundColor: Colors.white.withValues(alpha: .7),
                color: AppTheme.green,
                semanticsLabel: 'Progreso hacia el siguiente nivel',
              ),
              const SizedBox(height: 10),
              Text(
                progress.nextLevel == null
                    ? '¡Alcanzaste el nivel máximo!'
                    : '${progress.xpToNextLevel} XP para el nivel ${progress.nextLevel}',
                style: const TextStyle(color: AppTheme.ink, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth > 740
                ? (constraints.maxWidth - 42) / 4
                : (constraints.maxWidth - 14) / 2;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _Metric(
                  width: width,
                  icon: Icons.bolt_rounded,
                  value: '${progress.totalXp}',
                  label: 'Experiencia total',
                  color: const Color(0xFFFFF0CE),
                ),
                _Metric(
                  width: width,
                  icon: Icons.local_fire_department_outlined,
                  value: '${progress.currentStreak}',
                  label: 'Días de racha',
                  color: const Color(0xFFFFE6DD),
                ),
                _Metric(
                  width: width,
                  icon: Icons.emoji_events_outlined,
                  value: '${progress.bestStreak}',
                  label: 'Mejor racha',
                  color: const Color(0xFFE8E3F7),
                ),
                _Metric(
                  width: width,
                  icon: Icons.workspace_premium_outlined,
                  value: '${profile.badgeCount}',
                  label: 'Insignias obtenidas',
                  color: const Color(0xFFDAEEE7),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.width,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final double width;
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.ink, size: 22),
            ),
            const SizedBox(height: 16),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    ),
  );
}

IconData _categoryIcon(String slug) => switch (slug) {
  'study' => Icons.school_outlined,
  'exercise' => Icons.directions_run,
  'reading' => Icons.menu_book_outlined,
  _ => Icons.rocket_launch_outlined,
};
Color _categoryColor(String slug) => switch (slug) {
  'study' => const Color(0xFFE8E3F7),
  'exercise' => const Color(0xFFFFE6DD),
  'reading' => const Color(0xFFFFF0CE),
  _ => const Color(0xFFDAEEE7),
};
