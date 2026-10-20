import '../../../core/network/api_client.dart';
import 'achievement.dart';

class AchievementsRepository {
  AchievementsRepository(this.api);
  final ApiClient api;
  Future<List<Achievement>> getBadges() async =>
      (await api.getList('badges')).map(Achievement.fromJson).toList();
  Future<List<Achievement>> getRewards() async =>
      (await api.getList('rewards')).map(Achievement.fromJson).toList();
}
