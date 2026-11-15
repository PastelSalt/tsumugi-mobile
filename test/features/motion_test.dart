// docs/PLAN-UX.md section 9.1 (motion plan, U19 to U29): the tokens, the reduced-motion rule, and
// that each moment really animates, with a plain fade or an instant change when motion is reduced.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tsumugi_mobile/app/app.dart';
import 'package:tsumugi_mobile/core/data/selectors.dart';
import 'package:tsumugi_mobile/core/data/workspace_store.dart';
import 'package:tsumugi_mobile/core/settings/preferences.dart';
import 'package:tsumugi_mobile/core/theme/motion.dart';
import 'package:tsumugi_mobile/shared/widgets/badges.dart';
import 'package:tsumugi_mobile/shared/widgets/motion_widgets.dart';
import 'package:tsumugi_mobile/shared/widgets/task_tile.dart';
import 'package:tsumugi_mobile/shared/widgets/undo_toast.dart';

import '../support/fixtures.dart';

Future<(GoRouter, ProviderContainer)> _app(
  WidgetTester tester, {
  String location = '/home',
  bool reduce = false,
}) async {
  Entrance.reset();
  tester.view.physicalSize = const Size(360, 800) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: fixtureOverrides(),
      child: TsumugiApp(initialLocation: location),
    ),
  );
  final element = tester.element(find.byType(Scaffold).first);
  final container = ProviderScope.containerOf(element);
  if (reduce) {
    container.read(preferencesProvider.notifier).setReduceMotion(true);
  }
  await tester.pumpAndSettle();
  container.read(gestureHintDismissedProvider.notifier).dismiss();
  await tester.pumpAndSettle();
  return (GoRouter.of(element), container);
}

double _tabOpacity(WidgetTester tester, int i) => tester
    .widget<Opacity>(find.byKey(ValueKey('tab-fade-$i'), skipOffstage: false))
    .opacity;

void main() {
  group('U19: tokens and the reduced-motion rule', () {
    test('no duration is over 400 ms except page travel-free loops', () {
      for (final d in [
        Motion.press,
        Motion.fast,
        Motion.short,
        Motion.tab,
        Motion.page,
        Motion.number,
        Motion.stagger,
        Motion.reducedFade,
      ]) {
        expect(d.inMilliseconds, lessThanOrEqualTo(400));
      }
      expect(Motion.press.inMilliseconds, lessThanOrEqualTo(100));
    });

    testWidgets(
      'reduced motion: states are instant, meaningful changes become a short fade',
      (tester) async {
        for (final reduced in [false, true]) {
          late Duration state;
          late Duration change;
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: Builder(
                builder: (context) {
                  state = motionDuration(context);
                  change = fadeDuration(context);
                  return const SizedBox();
                },
              ),
            ),
          );
          expect(
            state,
            reduced ? Duration.zero : const Duration(milliseconds: 150),
          );
          expect(change, reduced ? Motion.reducedFade : Motion.short);
        }
      },
    );

    testWidgets(
      'the Account switch and the system setting both reduce motion',
      (tester) async {
        final (_, c) = await _app(tester);
        bool reduced() =>
            motionReduced(tester.element(find.byType(Scaffold).first));
        expect(reduced(), isFalse);
        c.read(preferencesProvider.notifier).setReduceMotion(true);
        await tester.pumpAndSettle();
        expect(reduced(), isTrue);
      },
    );
  });

  group('M-3: tab fade-through', () {
    testWidgets('the tab you switch to fades in, and everything stays alive', (
      tester,
    ) async {
      final (router, _) = await _app(tester);
      expect(_tabOpacity(tester, 0), 1);
      router.go('/library');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final mid = _tabOpacity(tester, 3);
      expect(mid, lessThan(1), reason: 'fading in at 60 ms');
      expect(mid, greaterThan(0));
      await tester.pumpAndSettle();
      expect(_tabOpacity(tester, 3), 1);
    });

    testWidgets('with reduced motion it is a 100 ms fade', (tester) async {
      final (router, _) = await _app(tester, reduce: true);
      router.go('/library');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(_tabOpacity(tester, 3), lessThan(1));
      await tester.pump(const Duration(milliseconds: 120));
      expect(_tabOpacity(tester, 3), 1);
    });

    testWidgets('a tab keeps its scroll position while another is shown', (
      tester,
    ) async {
      final (router, _) = await _app(tester, location: '/tasks');
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      final before = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels;
      router.go('/home');
      await tester.pumpAndSettle();
      router.go('/tasks');
      await tester.pumpAndSettle();
      final after = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels;
      expect(after, before);
    });
  });

  group('M-1: completing a task', () {
    Finder circle(String id) =>
        find.byWidgetPredicate((w) => w is StatusCircle && w.task.id == id);

    testWidgets(
      'the check shows first, then the tile collapses, then the task moves',
      (tester) async {
        final (_, c) = await _app(tester, location: '/tasks');
        String status() => c.read(workspaceDataProvider).taskById('t1')!.status;
        await tester.tap(circle('t1'));
        await tester.pump();
        expect(status(), 'Doing', reason: 'the change waits for the exit');
        await tester.pump(const Duration(milliseconds: 100));
        expect(status(), 'Doing');
        // The circle already shows the check while the tile is still there.
        expect(
          tester.widget<StatusCircle>(circle('t1')).task.status,
          'Done',
          reason: 'shown as done at once',
        );
        await tester.pump(const Duration(milliseconds: 400));
        expect(status(), 'Done');
        await tester.pumpAndSettle();
        UndoToast.hide(immediate: true);
        await tester.pumpAndSettle();
      },
    );

    testWidgets('with reduced motion the change is immediate', (tester) async {
      final (_, c) = await _app(tester, location: '/tasks', reduce: true);
      await tester.tap(circle('t1'));
      await tester.pump();
      expect(c.read(workspaceDataProvider).taskById('t1')!.status, 'Done');
      await tester.pumpAndSettle();
      UndoToast.hide(immediate: true);
      await tester.pumpAndSettle();
    });

    testWidgets('a tile that lands in a new group fades in', (tester) async {
      final (_, c) = await _app(tester, location: '/tasks');
      c.read(sessionProvider.notifier).toggleComplete('t1');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final touched = c.read(sessionProvider);
      expect(touched.touchedId, 't1');
      expect(touched.touchedAt, isNotNull);
      await tester.pumpAndSettle();
    });
  });

  group('M-7: numbers and bars', () {
    testWidgets('a progress bar fills over time instead of jumping', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: TsProgressBar(value: 3, max: 4, label: 'Tasks done'),
          ),
        ),
      );
      double width() => tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor!;
      expect(width(), lessThan(0.2), reason: 'starts empty');
      await tester.pump(const Duration(milliseconds: 150));
      expect(width(), inExclusiveRange(0.05, 0.75));
      await tester.pumpAndSettle();
      expect(width(), closeTo(0.75, 0.001));
    });

    testWidgets('with reduced motion the bar fills in a fade-length step', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Scaffold(
              body: TsProgressBar(value: 3, max: 4, label: 'Tasks done'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));
      expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        closeTo(0.75, 0.001),
      );
    });

    testWidgets(
      'the Home headline changes with a fade when the count changes',
      (tester) async {
        final (_, c) = await _app(tester);
        expect(find.text('2 tasks need you'), findsOneWidget);
        c.read(sessionProvider.notifier).toggleComplete('t3');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        // Both the old and the new headline are on screen part-way through the swap.
        expect(find.text('2 tasks need you'), findsOneWidget);
        expect(find.text('1 task needs you'), findsOneWidget);
        await tester.pumpAndSettle();
        expect(find.text('2 tasks need you'), findsNothing);
        expect(find.text('1 task needs you'), findsOneWidget);
      },
    );
  });

  group('M-8: first-open entrance', () {
    testWidgets('Home sections fade in one after another, once', (
      tester,
    ) async {
      Entrance.reset();
      tester.view.physicalSize = const Size(360, 800) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: fixtureOverrides(),
          child: const TsumugiApp(initialLocation: '/home'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      double opacityOf(String text) {
        final e = find.ancestor(
          of: find.text(text),
          matching: find.byType(Opacity),
        );
        return tester.widget<Opacity>(e.first).opacity;
      }

      expect(opacityOf('Up now'), lessThan(1), reason: 'still arriving');
      await tester.pumpAndSettle();
      expect(opacityOf('Up now'), 1);

      // Leaving and coming back does not replay it.
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      router.go('/projects');
      await tester.pumpAndSettle();
      router.go('/home');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      expect(opacityOf('Up now'), 1);
    });

    testWidgets('with reduced motion there is a fade and no rise', (
      tester,
    ) async {
      Entrance.reset();
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Entrance(id: 'test/x', child: Text('hello')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 30));
      final translates = tester.widgetList<Transform>(
        find.descendant(
          of: find.byType(Entrance),
          matching: find.byType(Transform),
        ),
      );
      expect(translates, isEmpty);
    });
  });

  group('M-9: toast and tip', () {
    testWidgets('the Undo message fades out instead of vanishing', (
      tester,
    ) async {
      await _app(tester);
      UndoToast.show(
        tester.element(find.byType(Scaffold).first),
        message: 'Done',
        onUndo: () {},
      );
      await tester.pumpAndSettle();
      expect(find.text('Undo'), findsOneWidget);
      UndoToast.hide();
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        find.text('Undo'),
        findsOneWidget,
        reason: 'still leaving at 50 ms',
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Undo'), findsNothing);
    });

    testWidgets('the gesture tip collapses smoothly', (tester) async {
      Entrance.reset();
      tester.view.physicalSize = const Size(360, 800) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: fixtureOverrides(),
          child: const TsumugiApp(initialLocation: '/tasks'),
        ),
      );
      await tester.pumpAndSettle();
      final before = tester
          .getTopLeft(find.textContaining('Overdue', findRichText: true))
          .dy;
      await tester.tap(find.text('Got it'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final mid = tester
          .getTopLeft(find.textContaining('Overdue', findRichText: true))
          .dy;
      await tester.pumpAndSettle();
      final after = tester
          .getTopLeft(find.textContaining('Overdue', findRichText: true))
          .dy;
      expect(mid, lessThan(before));
      expect(mid, greaterThan(after), reason: 'part-way, not a jump');
    });
  });

  group('M-13: calendar and M-5 pages', () {
    testWidgets('changing month cross-fades the grid', (tester) async {
      final (router, _) = await _app(tester, location: '/tasks?view=calendar');
      expect(find.byType(FadeSwitch), findsWidgets);
      router.go('/tasks?view=calendar&month=2026-12');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    });

    testWidgets(
      'the app theme uses the shared-axis page transition on every platform',
      (tester) async {
        await _app(tester);
        final builders = Theme.of(tester.element(find.byType(Scaffold).first))
            .pageTransitionsTheme
            .builders;
        for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
          expect(builders[platform], isA<TsumugiPageTransitionsBuilder>());
        }
      },
    );
  });

  testWidgets('the whole app still settles with every animation on', (
    tester,
  ) async {
    final (router, c) = await _app(tester);
    for (final r in ['/tasks', '/projects', '/library', '/home']) {
      router.go(r);
      await tester.pumpAndSettle(); // fails if anything animates forever
    }
    c.read(sessionProvider.notifier).toggleComplete('t3');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
