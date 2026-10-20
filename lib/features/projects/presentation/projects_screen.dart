import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/dates.dart';
import '../../../core/invalidate_progress.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/widgets/async_content.dart';
import '../../../core/widgets/page_layout.dart';
import '../../activities/presentation/activities_screen.dart';
import '../../profile/application/profile_providers.dart';
import '../application/project_providers.dart';
import '../data/project.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});
  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  bool archived = false;
  int page = 1;
  @override
  Widget build(BuildContext context) {
    final query = (archived: archived, page: page);
    return PageLayout(
      title: 'Tus proyectos',
      subtitle: 'Divide una meta grande en etapas que puedas completar.',
      actions: [
        FilledButton.icon(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => const _ProjectForm(),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Crear proyecto'),
        ),
      ],
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FilterChip(
            label: const Text('Archivados'),
            selected: archived,
            onSelected: (value) => setState(() {
              archived = value;
              page = 1;
            }),
          ),
        ),
        const SizedBox(height: 16),
        AsyncContent(
          value: ref.watch(projectsProvider(query)),
          onRetry: () => ref.invalidate(projectsProvider(query)),
          builder: (result) => Column(
            children: [
              if (result.items.isEmpty)
                const InfoPanel(
                  icon: Icons.rocket_launch_outlined,
                  title: 'Dale forma a tu próxima meta',
                  message: 'Crea un proyecto y agrega sus tareas o etapas.',
                ),
              for (final project in result.items)
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => context.push('/projects/${project.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${project.completedTasks} de ${project.totalTasks} tareas · ${project.progressPercentage.toStringAsFixed(0)}%',
                          ),
                          const SizedBox(height: 14),
                          LinearProgressIndicator(
                            value: project.progressPercentage / 100,
                          ),
                          if (project.endDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text('Fecha límite: ${project.endDate}'),
                            ),
                        ],
                      ),
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
  }
}

class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  int page = 1;
  bool busy = false;
  Future<void> archive() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archivar proyecto'),
        content: const Text(
          'Se archivarán también sus tareas. Su historial y XP se conservan.',
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
    setState(() => busy = true);
    try {
      await ref.read(projectRepositoryProvider).archive(widget.id);
      if (mounted) invalidateProgress(ref);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiFailure.from(error).message)));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageLayout(
    title: 'Proyecto y etapas',
    children: [
      AsyncContent(
        value: ref.watch(projectProvider(widget.id)),
        onRetry: () => ref.invalidate(projectProvider(widget.id)),
        builder: (project) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (project.description != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(project.description!),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      '${project.completedTasks} / ${project.totalTasks} tareas · ${project.progressPercentage.toStringAsFixed(0)}%',
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: project.progressPercentage / 100,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Desde ${project.startDate}${project.endDate == null ? '' : ' hasta ${project.endDate}'}',
                    ),
                    if (project.archived)
                      const Text('Proyecto archivado')
                    else ...[
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: () => context.push(
                              '/activities/new?projectId=${project.id}',
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Añadir tarea'),
                          ),
                          OutlinedButton(
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (context) =>
                                  _ProjectForm(project: project),
                            ),
                            child: const Text('Editar proyecto'),
                          ),
                          TextButton(
                            onPressed: busy ? null : archive,
                            child: const Text('Archivar'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            AsyncContent(
              value: ref.watch(
                projectTasksProvider((id: widget.id, page: page)),
              ),
              onRetry: () => ref.invalidate(
                projectTasksProvider((id: widget.id, page: page)),
              ),
              builder: (result) => Column(
                children: [
                  if (result.items.isEmpty)
                    const InfoPanel(
                      icon: Icons.account_tree_outlined,
                      title: 'Agrega tu primera etapa',
                      message:
                          'Cada tarea tendrá una meta, progreso y fecha límite propios.',
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
        ),
      ),
    ],
  );
}

class _ProjectForm extends ConsumerStatefulWidget {
  const _ProjectForm({this.project});
  final Project? project;
  @override
  ConsumerState<_ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends ConsumerState<_ProjectForm> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title, description, start, end;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    final project = widget.project;
    title = TextEditingController(text: project?.title);
    description = TextEditingController(text: project?.description);
    start = TextEditingController(
      text:
          project?.startDate ??
          civilDate(
            localToday(
              ref.read(profileProvider).valueOrNull?.timeZone ??
                  'America/La_Paz',
            ),
          ),
    );
    end = TextEditingController(text: project?.endDate);
  }

  @override
  void dispose() {
    for (final controller in [title, description, start, end]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? validateDate(String? value) {
    final parsed = DateTime.tryParse(value ?? '');
    return parsed == null || civilDate(parsed) != value
        ? 'Usa AAAA-MM-DD con una fecha válida'
        : null;
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(projectRepositoryProvider).save({
        'title': title.text.trim(),
        'description': description.text.trim().isEmpty
            ? null
            : description.text.trim(),
        'endDate': end.text.isEmpty ? null : end.text,
        if (widget.project == null) 'startDate': start.text,
      }, id: widget.project?.id);
      if (mounted) {
        ref.invalidate(projectProvider);
        ref.invalidate(projectsProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Proyecto guardado')));
      }
    } catch (failure) {
      if (mounted) setState(() => error = ApiFailure.from(failure).message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.project == null ? 'Nuevo proyecto' : 'Editar proyecto'),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: title,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Escribe un título'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: description,
                maxLength: 2000,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: start,
                enabled: widget.project == null,
                decoration: const InputDecoration(
                  labelText: 'Inicio (AAAA-MM-DD)',
                ),
                validator: validateDate,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: end,
                decoration: const InputDecoration(
                  labelText: 'Finalización (opcional)',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? null
                    : validateDate(value) ??
                          (value.compareTo(start.text) < 0
                              ? 'Debe ser igual o posterior al inicio'
                              : null),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: busy ? null : save,
        child: Text(busy ? 'Guardando…' : 'Guardar'),
      ),
    ],
  );
}
