import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/data/page_result.dart';
import '../../dashboard/data/dashboard.dart';
import '../data/history_item.dart';

typedef HistoryFilter = ({StatisticsFilter dates, int page, String kind});
final historyProvider =
    FutureProvider.family<PageResult<HistoryItem>, HistoryFilter>((
      ref,
      filter,
    ) async {
      final response = await ref
          .watch(apiClientProvider)
          .dio
          .get<Map<String, dynamic>>(
            'history/${filter.kind}',
            queryParameters: {
              ...statisticsQuery(filter.dates),
              'page': filter.page,
            },
          );
      return PageResult.fromJson(response.data!, HistoryItem.fromJson);
    });
