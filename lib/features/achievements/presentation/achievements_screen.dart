import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_content.dart';
import '../application/achievements_providers.dart';
import '../data/achievement.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key, this.rewards = false});
  final bool rewards;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = rewards ? rewardsProvider : badgesProvider;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(provider);
        await ref.read(provider.future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 20 : 40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rewards ? 'Hechas para ti.' : 'Cada logro cuenta.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            Text(
              rewards
                  ? 'Títulos y detalles visuales que se desbloquean con tu progreso. Tu XP siempre se conserva.'
                  : 'Pequeños hitos que cuentan una gran historia: la tuya.',
            ),
            const SizedBox(height: 28),
            AsyncContent(
              value: ref.watch(provider),
              onRetry: () => ref.invalidate(provider),
              builder: (items) {
                if (items.isEmpty) {
                  return InfoPanel(
                    icon: Icons.auto_awesome_outlined,
                    title: rewards
                        ? 'Sin recompensas todavía'
                        : 'Sin insignias todavía',
                    message: 'Los hitos disponibles aparecerán aquí.',
                  );
                }
                final unlocked = items
                    .where((item) => item.unlockedAt != null)
                    .length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(
                        '$unlocked de ${items.length} ${rewards ? 'desbloqueadas' : 'obtenidas'}',
                      ),
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) => Wrap(
                        spacing: 18,
                        runSpacing: 18,
                        children: [
                          for (final item in items)
                            SizedBox(
                              width: constraints.maxWidth > 950
                                  ? (constraints.maxWidth - 36) / 3
                                  : constraints.maxWidth > 580
                                  ? (constraints.maxWidth - 18) / 2
                                  : constraints.maxWidth,
                              child: _AchievementCard(item: item),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.item});
  final Achievement item;
  @override
  Widget build(BuildContext context) {
    final unlocked = item.unlockedAt != null;
    final icon = item.kind == 'PROFILE_FRAME'
        ? Icons.filter_frames_outlined
        : item.kind == 'PROFILE_TITLE'
        ? Icons.person_pin_outlined
        : switch (item.rule) {
            'STREAK_DAYS' => Icons.local_fire_department_outlined,
            'LEVEL_REACHED' => Icons.landscape_outlined,
            'CATEGORY_COUNT' => Icons.explore_outlined,
            _ => Icons.workspace_premium_outlined,
          };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: unlocked
                        ? AppTheme.mint
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: unlocked
                        ? AppTheme.green
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Icon(
                  unlocked ? Icons.check_circle : Icons.lock_outline,
                  size: 19,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(item.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(item.description),
            const SizedBox(height: 24),
            Text(
              unlocked
                  ? 'Obtenida el ${DateFormat('dd/MM/yyyy').format(item.unlockedAt!.toLocal())}'
                  : 'Por descubrir',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
