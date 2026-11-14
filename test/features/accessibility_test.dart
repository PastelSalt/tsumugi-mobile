// Automated accessibility audit: every screen is checked against Flutter's accessibility guidelines
// (48 dp tap targets, labelled tap targets, text contrast) with the semantics tree switched on.
// This does not replace a TalkBack pass on a device (Phase 8 manual checklist), but it catches the
// mechanical problems early.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tsumugi_mobile/app/app.dart';

import '../support/fixtures.dart';

const _routes = [
  '/',
  '/login',
  '/register',
  '/forgot-password',
  '/reset-password',
  '/home',
  '/tasks',
  '/tasks?view=upcoming',
  '/tasks?view=calendar',
  '/tasks?view=all',
  '/projects',
  '/projects?view=timeline',
  '/projects/project-garden',
  '/projects/project-garden?view=work',
  '/projects/project-garden?view=specs',
  '/projects/project-garden?view=files',
  '/projects/project-garden?view=history',
  '/library',
  '/library/doc/d-brief',
  '/insights',
  '/account',
  '/help',
  '/legal/privacy-policy',
  '/search',
];

void main() {
  testWidgets('every screen meets tap-target, label and contrast guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: fixtureOverrides(),
        child: const TsumugiApp(initialLocation: '/home'),
      ),
    );
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));

    final problems = <String>[];
    for (final route in _routes) {
      router.go(route);
      await tester.pumpAndSettle();
      for (final (name, guideline) in [
        ('tap target size', androidTapTargetGuideline),
        ('labelled tap targets', labeledTapTargetGuideline),
        ('text contrast', textContrastGuideline),
      ]) {
        final result = await guideline.evaluate(tester);
        if (!result.passed) problems.add('$route: $name: ${result.reason}');
      }
    }
    handle.dispose();
    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}
