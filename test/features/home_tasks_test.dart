import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tsumugi_mobile/app/app.dart';
import 'package:tsumugi_mobile/core/state/preview_state.dart';
import 'package:tsumugi_mobile/features/quickadd/quick_add_sheet.dart';

import '../support/fixtures.dart';

Future<(GoRouter, ProviderContainer)> _app(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2600);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: fixtureOverrides(),
      child: TsumugiApp(initialLocation: '/home'),
    ),
  );
  await tester.pumpAndSettle();
  final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
  final container = ProviderScope.containerOf(
    tester.element(find.byType(Scaffold).first),
  );
  return (router, container);
}

void main() {
  group('Home', () {
    testWidgets(
      'shows the three figures and the today list from the sample data',
      (tester) async {
        await _app(tester);
        expect(find.text('Due today'), findsOneWidget);
        expect(find.text('Overdue'), findsWidgets);
        expect(find.text('Needs a look'), findsOneWidget);
        // Overdue (t3, t4), today (t1), doing (t7, t10, t11): six rows, as on the website.
        for (final title in [
          'Write character profiles',
          'Collect reference art',
          'Review opening scene notes',
          'Map sign-in states',
        ]) {
          expect(find.text(title), findsWidgets, reason: title);
        }
        expect(find.text('Your projects'), findsOneWidget);
      },
    );

    testWidgets('first-run layout appears for the empty preview state', (
      tester,
    ) async {
      final (_, container) = await _app(tester);
      container.read(previewStateProvider.notifier).set(PreviewState.empty);
      await tester.pumpAndSettle();
      expect(find.text('Welcome. Nothing here yet.'), findsOneWidget);
      expect(find.text('Create a project'), findsOneWidget);
    });

    testWidgets(
      'Quick add parses the line, adds a session task and Home reflects it',
      (tester) async {
        await _app(tester);
        await tester.tap(find.bySemanticsLabel('Quick add'));
        await tester.pumpAndSettle();
        expect(find.text('Quick add a task'), findsOneWidget);

        await tester.enterText(
          find.byType(TextField),
          'Buy ink #garden today !',
        );
        await tester.pumpAndSettle();
        expect(find.text('Project Garden'), findsWidgets);
        expect(find.text('12 Nov'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(QuickAddSheet),
            matching: find.text('High priority'),
          ),
          findsOneWidget,
        );

        await tester.tap(find.text('Add task'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining(
            'Added “Buy ink” to Project Garden for this session.',
          ),
          findsOneWidget,
        );

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(find.text('Buy ink'), findsOneWidget);
        expect(find.text('Session only'), findsWidgets);
      },
    );
  });

  group('Tasks', () {
    testWidgets('Today groups tasks and inline add creates a session task', (
      tester,
    ) async {
      final (router, _) = await _app(tester);
      router.go('/tasks');
      await tester.pumpAndSettle();
      expect(find.text('Overdue'), findsWidgets);
      expect(find.text('In progress'), findsWidgets);

      await tester.enterText(
        find.widgetWithText(TextField, '').last,
        'Water the plants',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Water the plants'), findsOneWidget);
    });

    testWidgets(
      'tabs update the URL and Upcoming groups by day with milestones',
      (tester) async {
        final (router, _) = await _app(tester);
        router.go('/tasks');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Upcoming'));
        await tester.pumpAndSettle();
        expect(router.state.uri.queryParameters['view'], 'upcoming');
        expect(find.text('Tomorrow'), findsWidgets);
        expect(
          find.text('Chapter one review'),
          findsWidgets,
        ); // milestone due 13 Nov

        await tester.tap(find.text('Today').first);
        await tester.pumpAndSettle();
        expect(router.state.uri.queryParameters.containsKey('view'), isFalse);
      },
    );

    testWidgets(
      'Calendar shows the month, and selecting a day lists its items',
      (tester) async {
        final (router, _) = await _app(tester);
        router.go('/tasks?view=calendar');
        await tester.pumpAndSettle();
        expect(find.text('November 2026'), findsOneWidget);
        await tester.tap(find.bySemanticsLabel(RegExp(r'^13 Nov')));
        await tester.pumpAndSettle();
        expect(find.text('Reconcile character names'), findsOneWidget);
        expect(find.textContaining('Milestone ·'), findsOneWidget);

        await tester.tap(find.byTooltip('Next month'));
        await tester.pumpAndSettle();
        expect(find.text('December 2026'), findsOneWidget);
        expect(router.state.uri.queryParameters['month'], '2026-12');
        await tester.tap(find.widgetWithText(OutlinedButton, 'Today'));
        await tester.pumpAndSettle();
        expect(find.text('November 2026'), findsOneWidget);
      },
    );

    testWidgets('All shows open tasks, a Done fold and a Board layout', (
      tester,
    ) async {
      final (router, _) = await _app(tester);
      router.go('/tasks?view=all');
      await tester.pumpAndSettle();
      expect(find.textContaining('Done ('), findsOneWidget);
      await tester.tap(find.text('Board'));
      await tester.pumpAndSettle();
      expect(router.state.uri.queryParameters['mode'], 'board');
      expect(find.textContaining('To do', findRichText: true), findsWidgets);
      expect(find.text('Nothing here'), findsNothing);
    });

    testWidgets('project filter in the URL narrows the list', (tester) async {
      final (router, _) = await _app(tester);
      router.go('/tasks?project=tsumugi-api');
      await tester.pumpAndSettle();
      expect(find.text('Map sign-in states'), findsOneWidget);
      expect(find.text('Write character profiles'), findsNothing);
    });

    testWidgets(
      'select in the URL opens the task sheet and closing clears it',
      (tester) async {
        final (router, _) = await _app(tester);
        router.go('/tasks?select=t1');
        await tester.pumpAndSettle();
        expect(find.text('Edit task'), findsOneWidget);

        await tester.tapAt(
          const Offset(40, 80),
        ); // outside the sheet, closes it
        await tester.pumpAndSettle();
        expect(find.text('Edit task'), findsNothing);
        expect(router.state.uri.queryParameters.containsKey('select'), isFalse);
      },
    );
  });
}
