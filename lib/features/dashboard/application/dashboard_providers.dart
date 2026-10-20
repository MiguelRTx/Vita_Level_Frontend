import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../data/category.dart';
import '../data/dashboard.dart';

final categoriesProvider = FutureProvider.autoDispose<List<ActivityCategory>>(
  (ref) async => (await ref.watch(apiClientProvider).getList('categories'))
      .map(ActivityCategory.fromJson)
      .toList(),
);
final dashboardProvider =
    FutureProvider.family<DashboardData, StatisticsFilter>(
      (ref, filter) async => DashboardData.fromJson(
        await ref
            .watch(apiClientProvider)
            .getObject('dashboard', query: statisticsQuery(filter)),
      ),
    );
