import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/data/page_result.dart';
import '../data/activity.dart';
import '../data/activity_repository.dart';

typedef ActivityFilter = ({
  String? categoryId,
  String? frequency,
  bool archived,
  int page,
});
typedef OccurrenceFilter = ({
  String activityId,
  String from,
  String to,
  int page,
});
final activityRepositoryProvider = Provider(
  (ref) => ActivityRepository(ref.watch(apiClientProvider)),
);
final activityProvider = FutureProvider.family<Activity, String>(
  (ref, id) => ref.watch(activityRepositoryProvider).get(id),
);
final activitiesProvider =
    FutureProvider.family<PageResult<Activity>, ActivityFilter>(
      (ref, filter) => ref.watch(activityRepositoryProvider).list({
        if (filter.categoryId != null) 'categoryId': filter.categoryId,
        if (filter.frequency != null) 'frequency': filter.frequency,
        'archived': '${filter.archived}',
        'page': filter.page,
      }),
    );
final occurrencesProvider =
    FutureProvider.family<PageResult<Occurrence>, OccurrenceFilter>(
      (ref, filter) => ref.watch(activityRepositoryProvider).occurrences(
        filter.activityId,
        {'from': filter.from, 'to': filter.to, 'page': filter.page},
      ),
    );
