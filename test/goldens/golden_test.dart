// Golden screenshots of the key screens with the real fonts and icons.
// Regenerate after an intentional visual change:  flutter test --update-goldens test/goldens
// Goldens are rendered by the host platform's text engine; they were generated on Windows, so
// expect small differences if they are compared on another operating system.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tsumugi_mobile/app/app.dart';

import '../support/fixtures.dart';
import '../support/fonts.dart';

Future<void> _shot(
  WidgetTester tester,
  String route,
  String name, {
  Size logical = const Size(390, 844),
  double textScale = 1,
  bool dark = false,
}) async {
  tester.view.physicalSize = logical * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  if (dark) {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
  }
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    ProviderScope(
      overrides: fixtureOverrides(),
      child: const TsumugiApp(initialLocation: '/home'),
    ),
  );
  await tester.pumpAndSettle();
  if (route != '/home') {
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(route);
    await tester.pumpAndSettle();
  }
  expect(tester.takeException(), isNull, reason: '$name has layout errors');
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('$name.png'));
}

void main() {
  setUpAll(loadAppFonts);

  group('phone 390 x 844', () {
    for (final (name, route) in [
      ('welcome', '/'),
      ('home', '/home'),
      ('tasks_today', '/tasks'),
      ('tasks_calendar', '/tasks?view=calendar'),
      ('projects', '/projects'),
      ('project_overview', '/projects/project-garden'),
      ('project_history', '/projects/project-garden?view=history'),
      ('library', '/library'),
      ('reader', '/library/doc/d-brief'),
      ('insights', '/insights'),
      ('account', '/account'),
      ('login', '/login'),
    ]) {
      testWidgets(name, (tester) => _shot(tester, route, name));
    }
  });

  group('dark theme, phone 390 x 844', () {
    for (final (name, route) in [
      ('dark_home', '/home'),
      ('dark_tasks', '/tasks'),
      ('dark_project', '/projects/project-garden'),
      ('dark_library', '/library'),
    ]) {
      testWidgets(name, (tester) => _shot(tester, route, name, dark: true));
    }
  });

  group('large text (200%) on a small phone, 360 x 640', () {
    for (final (name, route) in [
      ('large_home', '/home'),
      ('large_tasks', '/tasks'),
      ('large_project', '/projects/project-garden'),
    ]) {
      testWidgets(
        name,
        (tester) => _shot(
          tester,
          route,
          name,
          logical: const Size(360, 640),
          textScale: 2,
        ),
      );
    }
  });

  testWidgets(
    'tablet 1280 x 800 with a docked task',
    (tester) => _shot(
      tester,
      '/tasks?select=t1',
      'tablet_tasks',
      logical: const Size(1280, 800),
    ),
  );
}
