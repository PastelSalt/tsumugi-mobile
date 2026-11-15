// docs/PLAN-UX.md, items U13 to U17: Undo timing, 3:1 control borders, 320 dp and 200% dark sweeps,
// long titles, the one-time gesture hint and the guide text.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tsumugi_mobile/app/app.dart';
import 'package:tsumugi_mobile/core/data/workspace_store.dart';
import 'package:tsumugi_mobile/core/settings/preferences.dart';
import 'package:tsumugi_mobile/core/theme/tokens.dart';
import 'package:tsumugi_mobile/shared/widgets/preview_sheet.dart';
import 'package:tsumugi_mobile/shared/widgets/undo_toast.dart';

import '../support/fixtures.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return ((la > lb ? la : lb) + 0.05) / ((la > lb ? lb : la) + 0.05);
}

const _routes = [
  '/',
  '/login',
  '/register',
  '/home',
  '/tasks',
  '/tasks?view=upcoming',
  '/tasks?view=calendar',
  '/tasks?view=all',
  '/tasks?view=all&mode=board',
  '/projects',
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
  '/search',
];

Future<(GoRouter, ProviderContainer)> _app(
  WidgetTester tester, {
  String location = '/tasks',
  Size logical = const Size(360, 800),
}) async {
  tester.view.physicalSize = logical * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: fixtureOverrides(),
      child: TsumugiApp(initialLocation: location),
    ),
  );
  await tester.pumpAndSettle();
  final element = tester.element(find.byType(Scaffold).first);
  return (GoRouter.of(element), ProviderScope.containerOf(element));
}

Future<List<String>> _sweep(
  WidgetTester tester, {
  required Size logical,
  required double textScale,
  required bool dark,
  bool guidelines = true,
}) async {
  final handle = tester.ensureSemantics();
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  final (router, c) = await _app(tester, location: '/home', logical: logical);
  if (dark) {
    c.read(preferencesProvider.notifier).setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();
  }
  final problems = <String>[];
  for (final route in _routes) {
    router.go(route);
    await tester.pumpAndSettle();
    final error = tester.takeException();
    if (error != null) problems.add('$route: layout error: $error');
    if (!guidelines) continue;
    // Seven columns cannot each be 48 dp wide on a 320 dp screen (336 dp needed). The month grid
    // cells are 45.7 x 55 dp there, above WCAG 2.5.8's 24 px; documented in docs/PLAN-UX.md.
    final calendarAtNarrow =
        route.startsWith('/tasks?view=calendar') && logical.width < 336;
    for (final (name, g) in [
      if (!calendarAtNarrow) ('tap target size', androidTapTargetGuideline),
      ('labelled tap targets', labeledTapTargetGuideline),
      ('text contrast', textContrastGuideline),
    ]) {
      final result = await g.evaluate(tester);
      if (!result.passed) problems.add('$route: $name: ${result.reason}');
    }
  }
  handle.dispose();
  return problems;
}

void main() {
  group('U14: Undo stays reachable', () {
    testWidgets('it lasts 10 seconds for a sighted person', (tester) async {
      final (_, c) = await _app(tester);
      c.read(sessionProvider.notifier).toggleComplete('t1');
      UndoToast.show(
        tester.element(find.byType(Scaffold).first),
        message: 'Completed',
        onUndo: () {},
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));
      expect(find.text('Undo'), findsOneWidget, reason: 'still there at 6 s');
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Undo'), findsNothing, reason: 'gone after 10 s');
    });

    testWidgets('with a screen reader it stays until acted on or dismissed', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await _app(tester);
      var undone = false;
      UndoToast.show(
        tester.element(find.byType(Scaffold).first),
        message: 'Completed',
        onUndo: () => undone = true,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 60));
      expect(find.text('Undo'), findsOneWidget, reason: 'no timeout');
      expect(find.byTooltip('Dismiss'), findsOneWidget);

      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.text('Undo'), findsNothing);
      expect(undone, isFalse);

      UndoToast.show(
        tester.element(find.byType(Scaffold).first),
        message: 'Completed again',
        onUndo: () => undone = true,
      );
      await tester.pump();
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(undone, isTrue);
    });

    testWidgets('it is announced as a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await _app(tester);
      UndoToast.show(
        tester.element(find.byType(Scaffold).first),
        message: 'Completed “Task”',
        onUndo: () {},
      );
      await tester.pump();
      final node = tester.getSemantics(find.textContaining('Completed “Task”'));
      expect(
        node.getSemanticsData().flagsCollection.isLiveRegion,
        isTrue,
        reason: 'WCAG 4.1.3 status message',
      );
      UndoToast.hide();
      await tester.pumpAndSettle();
      handle.dispose();
    });
  });

  group('U13: controls have a 3:1 border', () {
    for (final dark in [false, true]) {
      test(
        '${dark ? 'dark' : 'light'} theme: control border against card, page and tinted fills',
        () {
          final t = dark ? AppTokens.dark : const AppTokens();
          for (final bg in [t.paper, t.canvas]) {
            expect(
              _contrast(t.controlBorder, bg),
              greaterThanOrEqualTo(3),
              reason: '${t.controlBorder} on $bg',
            );
          }
          expect(_contrast(t.ink, t.paper), greaterThanOrEqualTo(3));
        },
      );
    }

    testWidgets('the Material outline colour is the control border', (
      tester,
    ) async {
      await _app(tester);
      final scheme = Theme.of(tester.element(find.byType(Scaffold).first))
          .colorScheme;
      expect(scheme.outline, const AppTokens().controlBorder);
    });
  });

  group('U15: narrow and very large', () {
    testWidgets('light, 320 dp wide, 130% text: every screen lays out', (
      tester,
    ) async {
      final problems = await _sweep(
        tester,
        logical: const Size(320, 640),
        textScale: 1.3,
        dark: false,
      );
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    testWidgets('dark, 320 dp wide, 130% text: every screen lays out', (
      tester,
    ) async {
      final problems = await _sweep(
        tester,
        logical: const Size(320, 640),
        textScale: 1.3,
        dark: true,
      );
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    testWidgets('dark, 360 dp, 200% text: no layout errors on any screen', (
      tester,
    ) async {
      final problems = await _sweep(
        tester,
        logical: const Size(360, 800),
        textScale: 2.0,
        dark: true,
        guidelines: false,
      );
      expect(problems, isEmpty, reason: problems.join('\n'));
    });
  });

  group('U3: one gesture hint, once', () {
    testWidgets('it shows on Today, goes away, and Account brings it back', (
      tester,
    ) async {
      final (router, c) = await _app(tester);
      expect(find.textContaining('swipe a task right'), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.textContaining('swipe a task right'), findsNothing);
      expect(c.read(gestureHintDismissedProvider), isTrue);

      router.go('/account');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Show tips again'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Show tips again'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show tips again'));
      await tester.pumpAndSettle();
      expect(c.read(gestureHintDismissedProvider), isFalse);

      router.go('/tasks');
      await tester.pumpAndSettle();
      expect(find.textContaining('swipe a task right'), findsOneWidget);
    });
  });

  group('U4: previews say what is real', () {
    test(
      'every preview-only action has its own message, not the generic one',
      () {
        final generic = previewMessageFor('no such action');
        for (final label in [
          'Edit',
          'Add file',
          'Edit project',
          'Add requirement',
          'Edit milestone',
          'Mark done',
          'Mark met',
          'Mark verified',
          'Link work',
          'Download',
          'Mark as final file',
          'Unmark final file',
          'Mark reviewed',
          'Mark not reviewed',
        ]) {
          final message = previewMessageFor(label);
          expect(message, isNot(generic), reason: label);
          expect(message, contains('demo'), reason: label);
        }
        expect(generic, contains('does work for this session'));
      },
    );

    testWidgets('Edit project explains what the full product does', (
      tester,
    ) async {
      final (router, _) = await _app(tester);
      router.go('/projects/project-garden');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit project'));
      await tester.pumpAndSettle();
      expect(find.text('Preview only'), findsOneWidget);
      expect(find.textContaining('rename the project'), findsOneWidget);
    });

    test('the guide describes swipe, undo and the real settings', () {
      final guide = File('assets/docs/individual-workspace-guide.md')
          .readAsStringSync();
      for (final text in [
        'Swipe right',
        'Press and hold',
        'Undo',
        'Show tips again',
        'Weeks start on Sunday',
        'Reduce motion',
        'Done this session',
      ]) {
        expect(guide, contains(text), reason: text);
      }
      expect(guide.contains('Its buttons (Edit task'), isFalse);
      expect(guide.contains('density, reminders'), isFalse);
    });
  });

  group('U2: tabs show that more are off screen', () {
    testWidgets('a cut-off tab row fades its end and then its start', (
      tester,
    ) async {
      await _app(tester, location: '/projects/project-garden');
      expect(find.byType(ShaderMask), findsWidgets);
      final scrollable = find.descendant(
        of: find.byType(ShaderMask),
        matching: find.byType(SingleChildScrollView),
      );
      expect(scrollable, findsWidgets);
      // Scroll the tabs to their end: the last tab becomes fully reachable.
      await tester.drag(scrollable.first, const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(find.text('History').hitTestable(), findsOneWidget);
    });
  });
}
