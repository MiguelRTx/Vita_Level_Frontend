import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/dates.dart';
import '../../../core/invalidate_progress.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/widgets/async_content.dart';
import '../../../core/widgets/page_layout.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../application/activity_providers.dart';
import '../data/activity.dart';
import '../../dashboard/data/category.dart';

class ActivityFormScreen extends ConsumerWidget {
  const ActivityFormScreen({super.key, this.id, this.projectId});
  final String? id, projectId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => PageLayout(
    title: id == null ? 'Nueva actividad' : 'Editar actividad',
    subtitle: 'Elige una meta concreta y una frecuencia que puedas sostener.',
    children: [
      AsyncContent(
        value: ref.watch(profileProvider),
        onRetry: () => ref.invalidate(profileProvider),
        builder: (profile) => AsyncContent(
          value: ref.watch(categoriesProvider),
          onRetry: () => ref.invalidate(categoriesProvider),
          builder: (categories) => id == null
              ? _ActivityForm(
                  categories: categories,
                  timeZone: profile.timeZone,
                  projectId: projectId,
                )
              : AsyncContent(
                  value: ref.watch(activityProvider(id!)),
                  onRetry: () => ref.invalidate(activityProvider(id!)),
                  builder: (activity) => _ActivityForm(
                    key: ValueKey(
                      activity.currentRevision.effectiveFrom +
                          activity.currentRevision.title,
                    ),
                    categories: categories,
                    timeZone: profile.timeZone,
                    activity: activity,
                  ),
                ),
        ),
      ),
    ],
  );
}

class _ActivityForm extends ConsumerStatefulWidget {
  const _ActivityForm({
    super.key,
    required this.categories,
    required this.timeZone,
    this.activity,
    this.projectId,
  });
  final List<ActivityCategory> categories;
  final String timeZone;
  final Activity? activity;
  final String? projectId;
  @override
  ConsumerState<_ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends ConsumerState<_ActivityForm> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title,
      description,
      quantity,
      unit,
      count,
      start,
      end;
  late String frequency, categoryId;
  bool busy = false;
  String? error;
  bool get task =>
      widget.projectId != null || widget.activity?.projectId != null;
  @override
  void initState() {
    super.initState();
    final revision = widget.activity?.currentRevision;
    title = TextEditingController(text: revision?.title);
    description = TextEditingController(text: revision?.description);
    quantity = TextEditingController(
      text: revision?.targetQuantity ?? (task ? '1' : '30'),
    );
    unit = TextEditingController(
      text: revision?.unit ?? (task ? 'tarea' : 'minutos'),
    );
    count = TextEditingController(text: '${revision?.targetCount ?? 3}');
    start = TextEditingController(
      text:
          widget.activity?.startDate ?? civilDate(localToday(widget.timeZone)),
    );
    end = TextEditingController(
      text: revision?.endDate ?? (task ? start.text : ''),
    );
    frequency = widget.activity?.frequency ?? (task ? 'ONCE' : 'DAILY');
    categoryId =
        revision?.category.id ??
        (task
            ? widget.categories
                  .firstWhere(
                    (category) => category.slug == 'personal-projects',
                  )
                  .id
            : widget.categories.first.id);
  }

  @override
  void dispose() {
    for (final controller in [
      title,
      description,
      quantity,
      unit,
      count,
      start,
      end,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'Completa este campo' : null;
  String? dateError(String? value, {bool optional = false}) {
    if (optional && (value == null || value.isEmpty)) return null;
    final parsed = DateTime.tryParse(value ?? '');
    return parsed == null || civilDate(parsed) != value
        ? 'Usa una fecha válida: AAAA-MM-DD'
        : null;
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final input = <String, dynamic>{
        'title': title.text.trim(),
        'description': description.text.trim().isEmpty
            ? null
            : description.text.trim(),
        'categoryId': categoryId,
        'targetQuantity': quantity.text,
        'unit': unit.text.trim(),
        'targetCount': frequency == 'WEEKLY' ? int.parse(count.text) : 1,
        'endDate': end.text.isEmpty ? null : end.text,
      };
      if (widget.activity == null) {
        input.addAll({
          'frequency': frequency,
          'startDate': start.text,
          if (widget.projectId != null) 'projectId': widget.projectId,
        });
      }
      final saved = await ref
          .read(activityRepositoryProvider)
          .save(input, id: widget.activity?.id);
      invalidateProgress(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              saved.pendingRevision == null
                  ? 'Actividad guardada'
                  : 'Cambios programados para ${saved.pendingRevision!.effectiveFrom}',
            ),
          ),
        );
        context.go('/activities/${saved.id}');
      }
    } catch (failure) {
      if (mounted) setState(() => error = ApiFailure.from(failure).message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topLeft,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: title,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: requiredText,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: description,
                  maxLength: 2000,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: categoryId,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: widget.categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: task
                      ? null
                      : (value) => setState(() => categoryId = value!),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: frequency,
                  decoration: const InputDecoration(labelText: 'Frecuencia'),
                  items: ['ONCE', 'DAILY', 'WEEKLY']
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(frequencyLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: task || widget.activity != null
                      ? null
                      : (value) => setState(() => frequency = value!),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Cantidad por sesión',
                    helperText: 'Ejemplo: 30 minutos o 20 páginas',
                  ),
                  validator: (value) =>
                      value == null ||
                          !RegExp(
                            r'^(0|[1-9]\d{0,8})(\.\d{1,3})?$',
                          ).hasMatch(value) ||
                          (double.tryParse(value) ?? 0) <= 0
                      ? 'Usa una cantidad positiva, hasta 3 decimales'
                      : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: unit,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'Unidad (minutos, páginas, tarea…)',
                  ),
                  validator: requiredText,
                ),
                const SizedBox(height: 14),
                if (frequency == 'WEEKLY') ...[
                  TextFormField(
                    controller: count,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sesiones por semana',
                      helperText: 'Cada sesión tiene su propio progreso y XP.',
                    ),
                    validator: (value) {
                      final number = int.tryParse(value ?? '');
                      return number == null || number < 1 || number > 20
                          ? 'Entre 1 y 20 sesiones'
                          : null;
                    },
                  ),
                  const SizedBox(height: 18),
                ],
                TextFormField(
                  controller: start,
                  enabled: widget.activity == null,
                  decoration: const InputDecoration(
                    labelText: 'Fecha de inicio',
                    hintText: 'AAAA-MM-DD',
                  ),
                  validator: dateError,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: end,
                  decoration: InputDecoration(
                    labelText: frequency == 'ONCE'
                        ? 'Fecha límite'
                        : 'Fecha final (opcional)',
                    hintText: 'AAAA-MM-DD',
                  ),
                  validator: (value) {
                    final error = dateError(
                      value,
                      optional: frequency != 'ONCE',
                    );
                    if (error != null) return error;
                    return value != null &&
                            value.isNotEmpty &&
                            value.compareTo(start.text) < 0
                        ? 'Debe ser igual o posterior al inicio'
                        : null;
                  },
                ),
                const SizedBox(height: 18),
                Text(
                  widget.activity == null
                      ? 'Las semanas empiezan el lunes. El servidor asigna el XP por sesión.'
                      : 'Los cambios recurrentes se aplican al siguiente periodo. El historial conserva sus valores.',
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: busy ? null : save,
                  child: Text(busy ? 'Guardando…' : 'Guardar actividad'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
