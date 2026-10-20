import '../../../core/network/api_client.dart';
import '../../../core/data/page_result.dart';
import '../../activities/data/activity.dart';
import 'project.dart';

class ProjectRepository {
  ProjectRepository(this.api);
  final ApiClient api;
  Future<PageResult<Project>> list(bool archived, int page) async {
    final result = await api.dio.get<Map<String, dynamic>>(
      'projects',
      queryParameters: {'archived': '$archived', 'page': page},
    );
    return PageResult.fromJson(result.data!, Project.fromJson);
  }

  Future<Project> get(String id) async =>
      Project.fromJson(await api.getObject('projects/$id'));
  Future<PageResult<Activity>> tasks(String id, int page) async {
    final result = await api.dio.get<Map<String, dynamic>>(
      'projects/$id/tasks',
      queryParameters: {'page': page},
    );
    return PageResult.fromJson(result.data!, Activity.fromJson);
  }

  Future<void> save(Map<String, dynamic> input, {String? id}) async {
    if (id == null) {
      await api.dio.post<void>('projects', data: input);
    } else {
      await api.dio.patch<void>('projects/$id', data: input);
    }
  }

  Future<void> archive(String id) async {
    await api.dio.post<void>('projects/$id/archive');
  }
}
