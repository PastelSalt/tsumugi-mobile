// M4 of docs/PLAN-MOBILE-UI.md: Home ("Up now", glance chips, Continue, carousel), the overdue badge
// on the Tasks tab, and Search v2 (type chips, tasks, counts, recent searches).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tsumugi_mobile/app/app.dart';
import 'package:tsumugi_mobile/core/data/selectors.dart';
import 'package:tsumugi_mobile/core/data/workspace_store.dart';
import 'package:tsumugi_mobile/features/insights/insights_screen.dart';
import 'package:tsumugi_mobile/shared/widgets/task_tile.dart';

import '../support/fixtures.dart';

Future<(GoRouter, ProviderContainer)> _app(
  WidgetTester tester, {
  String location = '/home',
  Size logical = const Size(360, 640),
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

Finder _navBadge() =>
    find.byWidgetPredicate((w) => w is Badge && w.isLabelVisible);

void main() {
  group('Home', () {
    testWidgets('answers "what now" in the first viewport on a small phone', (
      tester,
    ) async {
      await _app(tester);
      expect(find.text('Up now'), findsOneWidget);
      // The first task tile is on screen (within 640 dp) without scrolling.
      final y = tester.getTopLeft(find.text('Write character profiles')).dy;
      expect(y, lessThan(640));
      expect(find.text('2 tasks need you').hitTestable(), findsOneWidget);
    });

    testWidgets('Up now shows three tiles and a count on the link', (
      tester,
    ) async {
      await _app(tester, logical: const Size(360, 1400));
      expect(find.textContaining('All tasks ('), findsOneWidget);
      expect(find.byType(TaskTile), findsNWidgets(3));
    });

    testWidgets('the headline opens Tasks and "See insights" opens Insights', (
      tester,
    ) async {
      final (router, _) = await _app(tester);
      await tester.tap(find.text('2 tasks need you'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/tasks');

      router.go('/home');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('See insights'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('See insights'));
      await tester.pumpAndSettle();
      expect(find.byType(InsightsScreen), findsOneWidget);
    });

    testWidgets('one headline leads; the sections under it stay quiet', (
      tester,
    ) async {
      await _app(tester, logical: const Size(360, 1400));
      final headline = tester.getSize(find.text('2 tasks need you')).height;
      final section = tester.getSize(find.text('Up now')).height;
      expect(
        headline,
        greaterThan(section * 1.4),
        reason: 'size sets the order',
      );
      // Home no longer repeats the same figures in four boxes, a carousel and a recent list.
      expect(find.text('Recent'), findsNothing);
      expect(find.text('Your projects'), findsNothing);
      expect(find.text('Needs a look'), findsNothing);
    });

    testWidgets('Continue shows the latest project with its next milestone', (
      tester,
    ) async {
      final (_, c) = await _app(tester, logical: const Size(360, 1400));
      final data = c.read(workspaceDataProvider);
      final project = data.recentProjects(1).first;
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text(project.name), findsWidgets);
      expect(find.textContaining('Next: '), findsOneWidget);
    });

    testWidgets('pull to refresh settles', (tester) async {
      await _app(tester);
      await tester.fling(
        find.byType(ListView).first,
        const Offset(0, 400),
        1000,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(RefreshProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(RefreshProgressIndicator), findsNothing);
    });
  });

  group('Navigation badge', () {
    testWidgets('Tasks shows the overdue count and says it aloud', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final (_, c) = await _app(tester);
      final overdue = c.read(workspaceDataProvider).figures().overdue;
      expect(overdue, greaterThan(0));
      expect(_navBadge(), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Tasks.*$overdue overdue')),
        findsWidgets,
      );
      handle.dispose();
    });

    testWidgets(
      'the badge follows the list: completing every overdue task removes it',
      (tester) async {
        final (_, c) = await _app(tester);
        final session = c.read(sessionProvider.notifier);
        for (final t in c.read(workspaceDataProvider).tasks.where(isOverdue)) {
          session.toggleComplete(t.id);
        }
        await tester.pumpAndSettle();
        expect(_navBadge(), findsNothing);
      },
    );
  });

  group('Search', () {
    Future<void> openSearch(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Search or jump to'));
      await tester.pumpAndSettle();
    }

    testWidgets('finds tasks by title and groups results with counts', (
      tester,
    ) async {
      await _app(tester);
      await openSearch(tester);
      await tester.enterText(find.byType(TextField), 'review');
      await tester.pumpAndSettle();
      expect(find.textContaining('Tasks ('), findsOneWidget);
      expect(find.text('Review opening scene notes'), findsOneWidget);
    });

    testWidgets('type chips narrow the results', (tester) async {
      await _app(tester);
      await openSearch(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Projects'));
      await tester.pumpAndSettle();
      expect(find.text('Review opening scene notes'), findsNothing);
      expect(find.text('Project Garden'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Tasks'));
      await tester.pumpAndSettle();
      expect(find.text('Project Garden'), findsNothing);
      expect(find.text('Review opening scene notes'), findsOneWidget);
    });

    testWidgets(
      'picking a result remembers the search, and a recent search can be reused and cleared',
      (tester) async {
        await _app(tester);
        await openSearch(tester);
        await tester.enterText(find.byType(TextField), 'garden');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Project Garden').first);
        await tester.pumpAndSettle();

        await openSearch(tester);
        expect(find.text('Recent searches'), findsOneWidget);
        expect(find.text('garden'), findsOneWidget);
        await tester.tap(find.text('garden'));
        await tester.pumpAndSettle();
        expect(find.text('Project Garden'), findsWidgets);

        await tester.enterText(find.byType(TextField), '');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();
        expect(find.text('Recent searches'), findsNothing);
      },
    );

    testWidgets('a search with no match says so', (tester) async {
      await _app(tester);
      await openSearch(tester);
      await tester.enterText(find.byType(TextField), 'zzzzzz');
      await tester.pumpAndSettle();
      expect(find.textContaining('No matches'), findsOneWidget);
    });
  });
}
