import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand.dart';
import '../../features/profile/application/profile_providers.dart';

const destinations = [
  (path: '/dashboard', label: 'Resumen', icon: Icons.grid_view_rounded),
  (path: '/activities', label: 'Actividades', icon: Icons.checklist_rounded),
  (path: '/projects', label: 'Proyectos', icon: Icons.rocket_launch_outlined),
  (path: '/history', label: 'Historial', icon: Icons.history_rounded),
  (path: '/badges', label: 'Insignias', icon: Icons.workspace_premium_outlined),
  (path: '/rewards', label: 'Recompensas', icon: Icons.card_giftcard_rounded),
  (path: '/profile', label: 'Perfil', icon: Icons.person_outline_rounded),
];
const mobilePrimaryDestinationCount = 3;

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.path, required this.child});
  final String path;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = destinations.indexWhere(
      (item) => path == item.path || path.startsWith('${item.path}/'),
    );
    final profile = ref.watch(profileProvider).valueOrNull;
    final desktop = MediaQuery.sizeOf(context).width >= 900;
    final content = SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1220),
          child: child,
        ),
      ),
    );
    return Scaffold(
      appBar: desktop
          ? null
          : AppBar(
              title: const Brand(),
              actions: [
                IconButton(
                  tooltip: 'Ir a mi perfil',
                  onPressed: () => context.go('/profile'),
                  icon: const Icon(Icons.account_circle_outlined),
                ),
                const SizedBox(width: 8),
              ],
            ),
      bottomNavigationBar: desktop
          ? null
          : NavigationBar(
              selectedIndex:
                  selected >= 0 && selected < mobilePrimaryDestinationCount
                  ? selected
                  : mobilePrimaryDestinationCount,
              onDestinationSelected: (index) => context.go(
                index == mobilePrimaryDestinationCount
                    ? '/more'
                    : destinations[index].path,
              ),
              destinations: [
                for (final item in destinations.take(
                  mobilePrimaryDestinationCount,
                ))
                  NavigationDestination(
                    icon: Icon(item.icon),
                    label: item.label,
                  ),
                const NavigationDestination(
                  icon: Icon(Icons.more_horiz),
                  label: 'Más',
                ),
              ],
            ),
      body: desktop
          ? Row(
              children: [
                Container(
                  width: 234,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: .15),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 32, 22, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Brand(),
                          const SizedBox(height: 10),
                          const Text(
                            'Un paso cada día.',
                            style: TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'MI ESPACIO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.7,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView(
                              children: [
                                for (
                                  var index = 0;
                                  index < destinations.length;
                                  index++
                                )
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                          ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      selected: selected == index,
                                      selectedTileColor: Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                      leading: Icon(
                                        destinations[index].icon,
                                        size: 22,
                                      ),
                                      title: Text(
                                        destinations[index].label,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      onTap: () =>
                                          context.go(destinations[index].path),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (MediaQuery.sizeOf(context).height >= 900) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppTheme.mint,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.spa_outlined,
                                    color: AppTheme.green,
                                    size: 27,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'El progreso empieza\ncon un pequeño paso.',
                                    style: TextStyle(
                                      color: AppTheme.ink,
                                      height: 1.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              child: Text(
                                profile == null || profile.displayName.isEmpty
                                    ? 'R'
                                    : profile.displayName
                                          .substring(0, 1)
                                          .toUpperCase(),
                              ),
                            ),
                            title: Text(
                              profile?.displayName ?? 'Tu cuenta',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: const Text(
                              'Ver mi perfil',
                              style: TextStyle(fontSize: 12),
                            ),
                            onTap: () => context.go('/profile'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }
}
