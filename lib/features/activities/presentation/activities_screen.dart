import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/async_content.dart';
import '../../../core/widgets/page_layout.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../application/activity_providers.dart';
import '../data/activity.dart';

class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});
  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen> {
  String? categoryId, frequency;
  bool archived = false;
  int page = 1;
  @override
  Widget build(BuildContext context) {
    final filter = (
      categoryId: categoryId,
      frequency: frequency,
      archived: archived,
      page: page,
    );
    return PageLayout(
      title: 'Tus actividades',
      subtitle: 'Pequeñas acciones, grandes avances.',
      actions: [
        FilledButton.icon(
          onPressed: () => context.push('/activities/new'),
          icon: const Icon(Icons.add),
          label: const Text('Crear actividad'),
        ),
      ],
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 230,
              child: DropdownButtonFormField<String>(
                initialValue: categoryId ?? '',
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Todas las categorías'),
                  ),
                  for (final category
                      in ref.watch(categoriesProvider).valueOrNull ?? [])
                    DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    ),
                ],
                onChanged: (value) => setState(() {
                  categoryId = value == '' ? null : value;
                  page = 1;
                }),
              ),
            ),
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<String>(
                initialValue: frequency ?? '',
                decoration: const InputDecoration(labelText: 'Frecuencia'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Todas')),
                  for (final value in ['ONCE', 'DAILY', 'WEEKLY'])
                    DropdownMenuItem(
                      value: value,
                      child: Text(frequencyLabel(value)),
                    ),
                ],
                onChanged: (value) => setState(() {
                  frequency = value == '' ? null : value;
                  page = 1;
                }),
              ),
            ),
            FilterChip(
              label: const Text('Archivadas'),
              selected: archived,
              onSelected: (value) => setState(() {
                archived = value;
                page = 1;
              }),
            ),
            IconButton(
              tooltip: 'Actualizar actividades',
              onPressed: () => ref.invalidate(activitiesProvider(filter)),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 22),
        AsyncContent(
          value: ref.watch(activitiesProvider(filter)),
          onRetry: () => ref.invalidate(activitiesProvider(filter)),
          builder: (result) => Column(
            children: [
              if (result.items.isEmpty)
                const InfoPanel(
                  icon: Icons.checklist_rounded,
                  title: 'Tu próximo paso empieza aquí',
                  message:
                      'Crea una actividad o cambia los filtros para ver tus metas.',
                ),
              for (final activity in result.items)
                ActivityCard(activity: activity),
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
  }
}

class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.activity});
  final Activity activity;
  @override
  Widget build(BuildContext context) {
    final revision = activity.currentRevision;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: CircleAvatar(
          child: Icon(
            activity.archived ? Icons.archive_outlined : Icons.flag_outlined,
          ),
        ),
        title: Text(
          revision.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${revision.category.name} · ${frequencyLabel(activity.frequency)}\n${revision.targetQuantity} ${revision.unit}${activity.frequency == 'WEEKLY' ? ' × ${revision.targetCount} sesiones' : ''} · ${revision.xpPerCompletion} XP por sesión',
          ),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/activities/${activity.id}'),
      ),
    );
  }
}
