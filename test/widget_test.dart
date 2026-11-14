import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsumugi_mobile/app/app.dart';

import 'support/fixtures.dart';

Future<void> _boot(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: fixtureOverrides(),
      child: TsumugiApp(initialLocation: '/home'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('boots to Home with the bottom bar and brand logo', (
    tester,
  ) async {
    await _boot(tester);
    expect(find.text('tsumugi'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    for (final label in ['Projects', 'Tasks', 'Library']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.bySemanticsLabel('Quick add'), findsOneWidget);
  });

  testWidgets('switching tabs shows each screen', (tester) async {
    await _boot(tester);
    await tester.tap(find.text('Tasks').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Everything you have to do, across all projects.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Notes, documents, and files from every project in one place.'),
      findsOneWidget,
    );
  });
}
