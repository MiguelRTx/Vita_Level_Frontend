import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../profile/data/profile.dart';

class ProgressResult {
  ProgressResult.fromJson(Map<String, dynamic> json)
    : xpGranted = json['xpGranted'] as int,
      summary = GamificationSummary.fromJson(
        Map<String, dynamic>.from(json['gamification'] as Map),
      ),
      newAchievements = [
        ...(json['newBadges'] as List),
        ...(json['newRewards'] as List),
      ].map((item) => (item as Map)['name'] as String).toList();
  final int xpGranted;
  final GamificationSummary summary;
  final List<String> newAchievements;
}

typedef ProgressIntent = ({String key, String amount});

class ProgressCoordinator {
  ProgressCoordinator(this.api);
  final ApiClient api;
  // Survives navigation. Session-scoped ProviderScope drops these on account change.
  final Map<String, ProgressIntent> pending = {};
  Future<ProgressResult> record(String unitId, String amount) async {
    final intent = pending.putIfAbsent(
      unitId,
      () => (key: const Uuid().v4(), amount: amount),
    );
    try {
      final response = await api.dio.post<Map<String, dynamic>>(
        'occurrence-units/$unitId/progress',
        data: {'amount': intent.amount},
        options: Options(headers: {'Idempotency-Key': intent.key}),
      );
      final result = ProgressResult.fromJson(
        Map<String, dynamic>.from(response.data!['data'] as Map),
      );
      pending.remove(unitId);
      return result;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      // A transport failure/5xx has an uncertain outcome: retry the same intent.
      if (status != null && status >= 400 && status < 500) {
        pending.remove(unitId);
      }
      rethrow;
    }
  }
}

final progressCoordinatorProvider = Provider(
  (ref) => ProgressCoordinator(ref.watch(apiClientProvider)),
);
