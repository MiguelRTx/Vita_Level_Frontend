import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/data/page_result.dart';
import '../../activities/data/activity.dart';
import '../data/project.dart';
import '../data/project_repository.dart';

final projectRepositoryProvider = Provider(
  (ref) => ProjectRepository(ref.watch(apiClientProvider)),
);
final projectsProvider =
    FutureProvider.family<PageResult<Project>, ({bool archived, int page})>(
      (ref, filter) => ref
          .watch(projectRepositoryProvider)
          .list(filter.archived, filter.page),
    );
final projectProvider = FutureProvider.family<Project, String>(
  (ref, id) => ref.watch(projectRepositoryProvider).get(id),
);
final projectTasksProvider =
    FutureProvider.family<PageResult<Activity>, ({String id, int page})>(
      (ref, filter) =>
          ref.watch(projectRepositoryProvider).tasks(filter.id, filter.page),
    );
