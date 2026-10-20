import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/application/session_controller.dart';
import 'network/api_client.dart';

final apiClientProvider = Provider<ApiClient>(
  (ref) => throw StateError('ApiClient must be provided at bootstrap'),
);
final sessionControllerProvider = Provider<SessionController>(
  (ref) => throw StateError('SessionController must be provided at bootstrap'),
);
final healthProvider = FutureProvider.autoDispose<void>(
  (ref) => ref.watch(apiClientProvider).health(),
);
