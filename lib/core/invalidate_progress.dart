import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/activities/application/activity_providers.dart';
import '../features/profile/application/profile_providers.dart';
import '../features/dashboard/application/dashboard_providers.dart';
import '../features/achievements/application/achievements_providers.dart';
import '../features/projects/application/project_providers.dart';
import '../features/history/application/history_providers.dart';

void invalidateProgress(WidgetRef ref) {
  ref.invalidate(activityProvider);
  ref.invalidate(activitiesProvider);
  ref.invalidate(occurrencesProvider);
  ref.invalidate(profileProvider);
  ref.invalidate(dashboardProvider);
  ref.invalidate(historyProvider);
  ref.invalidate(badgesProvider);
  ref.invalidate(rewardsProvider);
  ref.invalidate(projectProvider);
  ref.invalidate(projectsProvider);
  ref.invalidate(projectTasksProvider);
}
