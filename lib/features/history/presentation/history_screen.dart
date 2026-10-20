import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/dates.dart';
import '../../../core/widgets/async_content.dart';
import '../../../core/widgets/date_filter.dart';
import '../../../core/widgets/page_layout.dart';
import '../../dashboard/data/dashboard.dart';
import '../../profile/application/profile_providers.dart';
import '../application/history_providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  StatisticsFilter? filter;
  String kind = 'completions';
  int page = 1;
  @override
  Widget build(BuildContext context) => PageLayout(
    title: 'Tu recorrido',
    subtitle: 'Cada registro conserva su fecha real, categoría y XP concedido.',
    children: [
      AsyncContent(
        value: ref.watch(profileProvider),
        onRetry: () => ref.invalidate(profileProvider),
        builder: (profile) {
          final today = localToday(profile.timeZone);
          final selected =
              filter ??
              (
                from: civilDate(daysBefore(today, 29)),
                to: civilDate(today),
                categoryId: null,
                interval: 'WEEK',
              );
          final query = (dates: selected, page: page, kind: kind);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'completions',
                      label: Text('Cumplimientos'),
                    ),
                    ButtonSegment(value: 'xp', label: Text('Movimientos XP')),
                  ],
                  selected: {kind},
                  onSelectionChanged: (selection) => setState(() {
                    kind = selection.first;
                    page = 1;
                  }),
                ),
              ),
              const SizedBox(height: 20),
              DateFilterBar(
                value: selected,
                today: today,
                showInterval: false,
                onChanged: (value) => setState(() {
                  filter = value;
                  page = 1;
                }),
              ),
              const SizedBox(height: 20),
              AsyncContent(
                value: ref.watch(historyProvider(query)),
                onRetry: () => ref.invalidate(historyProvider(query)),
                builder: (result) => Column(
                  children: [
                    if (result.items.isEmpty)
                      const InfoPanel(
                        icon: Icons.history_rounded,
                        title: 'Todavía no hay registros',
                        message:
                            'Completa una sesión o cambia el rango de fechas para ver tu recorrido.',
                      ),
                    for (final item in result.items)
                      Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          leading: const Icon(Icons.check_circle_outline),
                          title: Text(item.title),
                          subtitle: Text(
                            '${item.categoryName}${item.position == null ? '' : ' · Sesión ${item.position}'}\n${item.localDate} · ${item.timeZone}',
                          ),
                          trailing: Text(
                            '+${item.xp} XP',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          isThreeLine: true,
                          onTap: () =>
                              context.push('/activities/${item.activityId}'),
                        ),
                      ),
                    PaginationControls(
                      page: page,
                      totalPages: result.totalPages,
                      onChanged: (value) => setState(() => page = value),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ],
  );
}
