import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamification_app/core/dates.dart';
import 'package:gamification_app/core/network/api_client.dart';
import 'package:gamification_app/core/session/token_vault.dart';
import 'package:gamification_app/features/activities/application/progress_coordinator.dart';
import 'package:gamification_app/features/dashboard/data/dashboard.dart';
import 'package:gamification_app/features/dashboard/presentation/statistics_panel.dart';

const summary = {
  'totalXp': 100,
  'level': 2,
  'xpInLevel': 0,
  'xpRequiredForNextLevel': 300,
  'xpToNextLevel': 300,
  'nextLevel': 3,
  'levelProgress': 0,
  'currentStreak': 1,
  'bestStreak': 1,
};
Map<String, dynamic> progressBody() => {
  'data': {
    'xpGranted': 20,
    'gamification': summary,
    'newBadges': [
      {'name': 'Primer paso'},
    ],
    'newRewards': [],
  },
};

class QueueAdapter implements HttpClientAdapter {
  QueueAdapter(this.statuses);
  final List<int> statuses;
  final List<({String key, Object? data})> requests = [];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add((
      key: options.headers['Idempotency-Key'] as String,
      data: options.data,
    ));
    final status = statuses.removeAt(0);
    return ResponseBody.fromString(
      jsonEncode(
        status == 201
            ? progressBody()
            : {
                'error': {'code': 'TEST_ERROR'},
              },
      ),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

DashboardData dashboardFixture({bool empty = false}) => DashboardData.fromJson({
  'profile': summary,
  'timeZone': 'America/La_Paz',
  'planning': {
    'completionPercentage': empty ? 0 : 50,
    'plannedOccurrences': empty ? 0 : 2,
    'byCategory': [
      for (final name in [
        'Estudio',
        'Ejercicio físico',
        'Lectura',
        'Proyectos personales',
      ])
        {
          'categoryName': name,
          'planned': empty ? 0 : 2,
          'completed': empty ? 0 : 1,
        },
    ],
    'statusDistribution': [
      for (final status in ['COMPLETED', 'PENDING', 'OVERDUE'])
        {
          'status': status,
          'count': empty ? 0 : 1,
          'percentage': empty ? 0 : 33.33,
        },
    ],
  },
  'earned': {
    'goalsReached': empty ? 0 : 1,
    'completionCount': empty ? 0 : 2,
    'xpEarned': empty ? 0 : 40,
    'openingXp': empty ? 0 : 60,
    'xpSeries': [
      for (var day = 1; day <= 3; day++)
        {
          'startDate': '2026-10-0$day',
          'endDate': '2026-10-0$day',
          'earnedXp': empty ? 0 : 20,
          'cumulativeXp': empty ? 0 : 60 + 20 * day,
        },
    ],
    'heatmap': [
      for (var day = 1; day <= 7; day++)
        {'date': '2026-10-0$day', 'count': empty ? 0 : day % 3},
    ],
  },
});
void main() {
  test(
    'retry preserves idempotency key and amount after uncertain server failure',
    () async {
      final adapter = QueueAdapter([503, 201]);
      final dio = Dio()..httpClientAdapter = adapter;
      final coordinator = ProgressCoordinator(
        ApiClient(vault: TokenVault(MemoryTokenPersistence()), dio: dio),
      );
      await expectLater(
        coordinator.record('unit-a', '10.000'),
        throwsA(isA<DioException>()),
      );
      expect(coordinator.pending['unit-a']!.amount, '10.000');
      final result = await coordinator.record('unit-a', '99');
      expect(adapter.requests[0].key, adapter.requests[1].key);
      expect(adapter.requests[0].data, adapter.requests[1].data);
      expect(coordinator.pending, isEmpty);
      expect(result.summary.totalXp, 100);
      expect(result.summary.level, 2);
      expect(result.newAchievements, ['Primer paso']);
      dio.close();
    },
  );
  test(
    'definitive validation failure permits a corrected new intention',
    () async {
      final adapter = QueueAdapter([422, 201]);
      final dio = Dio()..httpClientAdapter = adapter;
      final coordinator = ProgressCoordinator(
        ApiClient(vault: TokenVault(MemoryTokenPersistence()), dio: dio),
      );
      await expectLater(
        coordinator.record('unit-b', '100'),
        throwsA(isA<DioException>()),
      );
      expect(coordinator.pending, isEmpty);
      await coordinator.record('unit-b', '1');
      expect(adapter.requests[0].key, isNot(adapter.requests[1].key));
      dio.close();
    },
  );
  test(
    'decimal UI formatting uses integer thousandths without cumulative float errors',
    () {
      expect(
        quantityMillis('0.1') + quantityMillis('0.2'),
        quantityMillis('0.300'),
      );
      expect(quantityMillis('999999999.999'), 999999999999);
    },
  );
  for (final width in [390.0, 1366.0]) {
    for (final empty in [true, false]) {
      testWidgets('charts and empty states render at $width, empty=$empty', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: DashboardCharts(data: dashboardFixture(empty: empty)),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Acumulado'));
        await tester.tap(find.text('Acumulado'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Calendario de constancia'));
        await tester.pumpAndSettle();
        expect(
          find.text('Menos  ░ ▒ ▓  Más · máximo ${empty ? 0 : 2} por día'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
