import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamification_app/app/app.dart';
import 'session_test.dart' show Harness;

void main() {
  for (final size in [const Size(390, 844), const Size(1366, 900)]) {
    testWidgets(
      'login renders and validates without overflow at ${size.width}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final harness = Harness();
        harness.adapter.onGet(
          'http://localhost:3000/health',
          (server) => server.reply(200, {
            'data': {'status': 'ok', 'database': 'up'},
          }),
        );
        addTearDown(harness.dispose);
        await tester.pumpWidget(
          RitmoApp(
            store: harness.store,
            api: harness.api,
            session: harness.session,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Iniciar sesión'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.byKey(const Key('submit-auth')));
        await tester.tap(find.byKey(const Key('submit-auth')));
        await tester.pumpAndSettle();
        expect(find.text('Escribe un correo válido.'), findsOneWidget);
        expect(find.text('Escribe tu contraseña.'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
