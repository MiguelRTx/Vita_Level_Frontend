import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/dates.dart';
import '../../../core/invalidate_progress.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/async_content.dart';
import '../../../core/widgets/date_filter.dart';
import '../../../core/widgets/page_layout.dart';
import '../../dashboard/data/dashboard.dart';
import '../application/activity_providers.dart';
import '../application/progress_coordinator.dart';
import '../data/activity.dart';

class ActivityDetailScreen extends ConsumerStatefulWidget {
  const ActivityDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<ActivityDetailScreen> createState() =>
      _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends ConsumerState<ActivityDetailScreen> {
  StatisticsFilter? filter;
  int page = 1;
  bool archiving = false;
  Future<void> archive() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archivar actividad'),
        content: const Text(
          'Se dejará de programar y no podrás registrar más progreso. El historial y el XP se conservan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archivar'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() => archiving = true);
    try {
      await ref.read(activityRepositoryProvider).archive(widget.id);
      if (mounted) {
        invalidateProgress(ref);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Actividad archivada')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiFailure.from(error).message)));
      }
    } finally {
      if (mounted) setState(() => archiving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageLayout(
    title: 'Detalle de actividad',
    actions: [
      IconButton(
        tooltip: 'Actualizar',
        onPressed: () => invalidateProgress(ref),
        icon: const Icon(Icons.refresh),
      ),
    ],
    children: [
      AsyncContent(
        value: ref.watch(activityProvider(widget.id)),
        onRetry: () => ref.invalidate(activityProvider(widget.id)),
        builder: (activity) {
          final today = localToday(activity.scheduleTimeZone);
          final selected =
              filter ??
              (
                from: civilDate(daysBefore(today, 29)),
                to: civilDate(today),
                categoryId: null,
                interval: 'WEEK',
              );
          final query = (
            activityId: widget.id,
            from: selected.from,
            to: selected.to,
            page: page,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.currentRevision.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${activity.currentRevision.category.name} · ${frequencyLabel(activity.frequency)} · ${activity.scheduleTimeZone}',
                      ),
                      if (activity.currentRevision.description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(activity.currentRevision.description!),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        '${activity.currentRevision.targetQuantity} ${activity.currentRevision.unit} por sesión · ${activity.currentRevision.xpPerCompletion} XP',
                      ),
                      if (activity.archived)
                        const Padding(
                          padding: EdgeInsets.only(top: 14),
                          child: Text('Archivada · historial conservado'),
                        ),
                      if (activity.pendingRevision != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(
                            'Cambios programados para ${activity.pendingRevision!.effectiveFrom}: ${activity.pendingRevision!.title}',
                          ),
                        ),
                      if (!activity.archived) ...[
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 12,
                          children: [
                            OutlinedButton.icon(
                              onPressed: activity.pendingRevision != null
                                  ? null
                                  : () => context.push(
                                      '/activities/${activity.id}/edit',
                                    ),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Editar'),
                            ),
                            TextButton.icon(
                              onPressed: archiving ? null : archive,
                              icon: const Icon(Icons.archive_outlined),
                              label: Text(
                                archiving ? 'Archivando…' : 'Archivar',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Periodos y sesiones',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              DateFilterBar(
                value: selected,
                today: today,
                showCategory: false,
                showInterval: false,
                onChanged: (value) => setState(() {
                  filter = value;
                  page = 1;
                }),
              ),
              const SizedBox(height: 18),
              AsyncContent(
                value: ref.watch(occurrencesProvider(query)),
                onRetry: () => ref.invalidate(occurrencesProvider(query)),
                builder: (result) => Column(
                  children: [
                    if (result.items.isEmpty)
                      const InfoPanel(
                        icon: Icons.event_available_outlined,
                        title: 'Sin periodos en este rango',
                        message:
                            'Las actividades futuras estarán disponibles desde su fecha de inicio.',
                      ),
                    for (final occurrence in result.items)
                      Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  Text(
                                    occurrence.scheduledDate,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Chip(
                                    label: Text(statusLabel(occurrence.status)),
                                  ),
                                ],
                              ),
                              Text(
                                '${occurrence.revision.title} · ${occurrence.revision.targetCount} sesión(es)',
                              ),
                              const SizedBox(height: 14),
                              for (final unit in occurrence.units)
                                _UnitCard(
                                  key: ValueKey(unit.id),
                                  unit: unit,
                                  label: occurrence.revision.unit,
                                  enabled:
                                      occurrence.status == 'PENDING' &&
                                      !activity.archived,
                                ),
                            ],
                          ),
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

class _UnitCard extends ConsumerStatefulWidget {
  const _UnitCard({
    super.key,
    required this.unit,
    required this.label,
    required this.enabled,
  });
  final OccurrenceUnit unit;
  final String label;
  final bool enabled;
  @override
  ConsumerState<_UnitCard> createState() => _UnitCardState();
}

class _UnitCardState extends ConsumerState<_UnitCard> {
  final amount = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final pending = ref
        .read(progressCoordinatorProvider)
        .pending[widget.unit.id];
    final value = pending?.amount ?? amount.text;
    if (!RegExp(r'^(0|[1-9]\d{0,8})(\.\d{1,3})?$').hasMatch(value) ||
        quantityMillis(value) <= 0) {
      setState(
        () => error = 'Ingresa una cantidad positiva, hasta tres decimales.',
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await ref
          .read(progressCoordinatorProvider)
          .record(widget.unit.id, value);
      if (!mounted) return;
      amount.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.xpGranted == 0
                ? 'Progreso guardado'
                : '¡Sesión completada! +${result.xpGranted} XP · Nivel ${result.summary.level}${result.newAchievements.isEmpty ? '' : '\nDesbloqueaste: ${result.newAchievements.join(', ')}'}',
          ),
        ),
      );
      invalidateProgress(ref);
    } catch (failure) {
      if (mounted) {
        setState(() => error = ApiFailure.from(failure).message);
        if (ApiFailure.from(failure).code == 'UNIT_ALREADY_COMPLETED') {
          invalidateProgress(ref);
        }
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref
        .read(progressCoordinatorProvider)
        .pending[widget.unit.id];
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.unit.completed
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sesión ${widget.unit.position} · ${widget.unit.progressQuantity} / ${widget.unit.targetQuantity} ${widget.label}',
                ),
              ),
              IconButton(
                tooltip: 'Ver registros de progreso',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) =>
                      _ProgressHistory(unitId: widget.unit.id),
                ),
                icon: const Icon(Icons.history, size: 20),
              ),
            ],
          ),
          LinearProgressIndicator(
            value:
                (quantityMillis(widget.unit.progressQuantity) /
                        quantityMillis(widget.unit.targetQuantity))
                    .clamp(0, 1),
          ),
          if ((!widget.unit.completed && widget.enabled) ||
              pending != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: amount,
                    enabled: !busy && pending == null,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: pending == null
                          ? 'Añadir ${widget.label}'
                          : 'Envío: ${pending.amount}',
                      hintText: widget.unit.remainingQuantity,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: busy ? null : submit,
                  child: Text(
                    busy
                        ? 'Guardando…'
                        : pending != null
                        ? 'Reintentar envío'
                        : 'Registrar progreso',
                  ),
                ),
              ],
            ),
          ],
          if (pending != null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'El envío anterior no tiene confirmación. Reintentar conserva la misma operación.',
              ),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressHistory extends ConsumerStatefulWidget {
  const _ProgressHistory({required this.unitId});
  final String unitId;
  @override
  ConsumerState<_ProgressHistory> createState() => _ProgressHistoryState();
}

class _ProgressHistoryState extends ConsumerState<_ProgressHistory> {
  int page = 1;
  late Future<Map<String, dynamic>> request;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    request = ref
        .read(apiClientProvider)
        .dio
        .get<Map<String, dynamic>>(
          'occurrence-units/${widget.unitId}/progress',
          queryParameters: {'page': page},
        )
        .then((response) => response.data!);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Registros de progreso'),
    content: SizedBox(
      width: 440,
      child: FutureBuilder(
        future: request,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(ApiFailure.from(snapshot.error!).message);
          }
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final data = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if ((data['data'] as List).isEmpty)
                  const Text('Todavía no hay registros.'),
                for (final item in data['data'] as List)
                  ListTile(
                    title: Text('+${item['amount']}'),
                    subtitle: Text(
                      '${item['localDate']} · ${item['timeZone']}',
                    ),
                  ),
                PaginationControls(
                  page: page,
                  totalPages: (data['pagination'] as Map)['totalPages'] as int,
                  onChanged: (value) => setState(() {
                    page = value;
                    load();
                  }),
                ),
              ],
            ),
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => setState(load),
        child: const Text('Actualizar'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cerrar'),
      ),
    ],
  );
}
