import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tsumugi_mobile/app/app.dart';

import '../support/fixtures.dart';

/// Every screen at 360 x 640 dp, at normal and 1.5x text size, with no layout errors.
const _routes = [
  '/',
  '/login',
  '/login?preview=errors',
  '/login?preview=locked',
  '/register',
  '/register?preview=errors',
  '/register?preview=pending',
  '/forgot-password',
  '/forgot-password?preview=sent',
  '/reset-password',
  '/reset-password?preview=weak',
  '/reset-password?preview=expired',
  '/home',
  '/tasks',
  '/tasks?view=upcoming',
  '/tasks?view=calendar',
  '/tasks?view=all',
  '/tasks?view=all&mode=board',
  '/projects',
  '/projects?view=timeline',
  '/projects/project-garden',
  '/library',
  '/library?mode=list',
  '/library/doc/d-brief',
  '/library/doc/f-script',
  '/insights',
  '/account',
  '/help',
  '/legal/privacy-policy',
  '/legal/terms-of-service',
  '/legal/cookie-and-local-storage-policy',
  '/search',
  '/gallery',
];

void main() {
  for (final scale in [1.0, 1.5]) {
    testWidgets(
      'every screen lays out at 360 x 640 dp with text scale $scale',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 3;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        await tester.pumpWidget(
          ProviderScope(
            overrides: fixtureOverrides(),
            child: const TsumugiApp(initialLocation: '/home'),
          ),
        );
        await tester.pumpAndSettle();
        final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
        final failing = <String>[];
        for (final route in _routes) {
          router.go(route);
          await tester.pumpAndSettle();
          if (tester.takeException() != null) failing.add(route);
        }
        expect(failing, isEmpty, reason: 'text scale $scale');
      },
    );
  }
}
