import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../data/profile.dart';
import '../data/profile_repository.dart';

final profileRepositoryProvider = Provider(
  (ref) => ProfileRepository(ref.watch(apiClientProvider)),
);
final profileProvider = FutureProvider.autoDispose<UserProfile>(
  (ref) => ref.watch(profileRepositoryProvider).getProfile(),
);
