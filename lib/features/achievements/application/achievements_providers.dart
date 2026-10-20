import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../data/achievement.dart';
import '../data/achievements_repository.dart';

final achievementsRepositoryProvider = Provider(
  (ref) => AchievementsRepository(ref.watch(apiClientProvider)),
);
final badgesProvider = FutureProvider.autoDispose<List<Achievement>>(
  (ref) => ref.watch(achievementsRepositoryProvider).getBadges(),
);
final rewardsProvider = FutureProvider.autoDispose<List<Achievement>>(
  (ref) => ref.watch(achievementsRepositoryProvider).getRewards(),
);
