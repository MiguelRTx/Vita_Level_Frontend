import '../../../core/data/page_result.dart';
import '../../../core/network/api_client.dart';
import 'activity.dart';

class ActivityRepository {
  ActivityRepository(this.api);
  final ApiClient api;
  Future<PageResult<Activity>> list(Map<String, dynamic> query) async {
    final result = await api.dio.get<Map<String, dynamic>>(
      'activities',
      queryParameters: query,
    );
    return PageResult.fromJson(result.data!, Activity.fromJson);
  }

  Future<Activity> get(String id) async =>
      Activity.fromJson(await api.getObject('activities/$id'));
  Future<Activity> save(Map<String, dynamic> input, {String? id}) async {
    final result = id == null
        ? await api.dio.post<Map<String, dynamic>>('activities', data: input)
        : await api.dio.patch<Map<String, dynamic>>(
            'activities/$id',
            data: input,
          );
    return Activity.fromJson(
      Map<String, dynamic>.from(result.data!['data'] as Map),
    );
  }

  Future<void> archive(String id) async {
    await api.dio.post<void>('activities/$id/archive');
  }

  Future<PageResult<Occurrence>> occurrences(
    String id,
    Map<String, dynamic> query,
  ) async {
    final result = await api.dio.get<Map<String, dynamic>>(
      'activities/$id/occurrences',
      queryParameters: query,
    );
    return PageResult.fromJson(result.data!, Occurrence.fromJson);
  }
}
