import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamification_app/app/router/route_metadata.dart';
import 'package:gamification_app/app/router/app_router.dart';
import 'package:gamification_app/app/store/app_store.dart';
import 'package:gamification_app/core/theme/app_theme.dart';
import 'package:gamification_app/core/widgets/not_found_screen.dart';

double contrast(Color a, Color b) {
  final first = a.computeLuminance(), second = b.computeLuminance();
  return (math.max(first, second) + .05) / (math.min(first, second) + .05);
}

void main() {
  test(
    'primary text and controls meet WCAG AA contrast in light and dark themes',
    () {
      for (final mode in Brightness.values) {
        final theme = AppTheme.create(mode),
            colors = AppTheme.create(mode).colorScheme;
        expect(
          contrast(colors.onSurface, theme.scaffoldBackgroundColor),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(
            colors.onSurfaceVariant,
            theme.inputDecorationTheme.fillColor!,
          ),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(colors.onPrimary, colors.primary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(AppTheme.ink, AppTheme.mint),
          greaterThanOrEqualTo(4.5),
        );
        expect(theme.textTheme.bodyMedium!.fontFamily, 'Roboto');
      }
    },
  );
  test(
    'section titles and descriptions are meaningful and unknown routes retain the 404',
    () {
      expect(routeMetadata('/activities/new').title, 'Tus actividades · Ritmo');
      expect(
        routeMetadata('/register').description,
        contains('Crea tu cuenta'),
      );
      expect(routeMetadata('/unknown').title, 'Página no encontrada · Ritmo');
      expect(sessionRedirect(SessionStatus.signedOut, '/unknown'), isNull);
      expect(sessionRedirect(SessionStatus.signedOut, '/activities'), '/login');
    },
  );
  for (final width in [320.0, 768.0, 1366.0]) {
    testWidgets('404 remains usable at width $width with enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.create(Brightness.light),
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 600),
              textScaler: const TextScaler.linear(2),
            ),
            child: const NotFoundScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Volver a Ritmo'));
      expect(tester.takeException(), isNull);
    });
  }
}
