import '../../../core/network/api_client.dart';
import 'profile.dart';

class ProfileRepository {
  ProfileRepository(this.api);
  final ApiClient api;
  Future<UserProfile> getProfile() async =>
      UserProfile.fromJson(await api.getObject('me'));
  Future<UserProfile> updateProfile({
    required String name,
    required String timeZone,
  }) async {
    final response = await api.dio.patch<Map<String, dynamic>>(
      'me',
      data: {'displayName': name, 'timeZone': timeZone},
    );
    return UserProfile.fromJson(
      Map<String, dynamic>.from(response.data!['data'] as Map),
    );
  }
}
