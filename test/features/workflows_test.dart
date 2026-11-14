// Walks the "Everyday workflows" of the guide (section 13) through the real UI, end to end.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tsumugi_mobile/app/app.dart';
import 'package:tsumugi_mobile/features/quickadd/quick_add_sheet.dart';

import '../support/fixtures.dart';

Future<GoRouter> _app(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2600);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: fixtureOverrides(),
      child: const TsumugiApp(initialLocation: '/home'),
    ),
  );
  await tester.pumpAndSettle();
  return GoRouter.of(tester.element(find.byType(Scaffold).first));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('13.1 Start a new project: search, template, Work and Specs', (
    tester,
  ) async {
    await _app(tester);
    await tester.tap(find.byTooltip('Search or jump to'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'New project');
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(ListTile),
        matching: find.text('New project'),
      ),
    );
    await tester.pumpAndSettle();

    await _tap(tester, find.text('Creative'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Project name'),
      'Moss zine',
    );
    await _tap(tester, find.text('Create project'));
    expect(find.text('Moss zine'), findsWidgets);

    await _tap(tester, find.text('Work'));
    expect(find.text('Write the one-page brief'), findsOneWidget);
    expect(find.text('Collect references'), findsOneWidget);

    await _tap(tester, find.text('Specs'));
    expect(find.text('No requirements yet'), findsOneWidget);
  });

  testWidgets(
    '13.2 Plan your week: calendar, a heavy day, Quick add with a day word',
    (tester) async {
      final router = await _app(tester);
      await tester.tap(find.text('Tasks').last);
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Calendar'));
      expect(find.text('November 2026'), findsOneWidget);

      await _tap(tester, find.bySemanticsLabel(RegExp(r'^13 Nov')));
      expect(find.text('Reconcile character names'), findsOneWidget);
      expect(find.textContaining('Milestone ·'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Quick add'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(QuickAddSheet),
          matching: find.byType(TextField),
        ),
        'Order prints fri',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add task'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.text('Order prints'),
        find.byType(ListView).first,
        const Offset(0, -300),
      );
      expect(
        find.text('Order prints'),
        findsOneWidget,
      ); // added to Friday 13 Nov, in the agenda

      router.go('/tasks');
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Overdue', findRichText: true),
        findsWidgets,
      ); // back to Today each morning
    },
  );

  testWidgets(
    '13.3 Clear what is overdue: Home, open the task, check Insights',
    (tester) async {
      final router = await _app(tester);
      expect(find.text('Needs a look'), findsOneWidget);
      await _tap(tester, find.text('Write character profiles').first);
      expect(find.text('Change status'), findsOneWidget);
      expect(find.text('3 days overdue'), findsWidgets);
      await tester.tapAt(const Offset(40, 80));
      await tester.pumpAndSettle();
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // the selection is cleared just after the sheet closes
      await tester.pumpAndSettle();

      router.go('/insights');
      await tester.pumpAndSettle();
      expect(find.text('Overdue items'), findsOneWidget);
      expect(find.text('Write character profiles'), findsOneWidget);
    },
  );

  testWidgets('13.4 Trace a requirement: requirement, task, file', (
    tester,
  ) async {
    final router = await _app(tester);
    router.go('/projects/project-garden?view=specs');
    await tester.pumpAndSettle();
    await _tap(tester, find.textContaining('Opening scene sets the tone'));
    expect(find.text('Acceptance criteria'), findsOneWidget);

    await _tap(
      tester,
      find.widgetWithText(InkWell, 'Review opening scene notes').first,
    );
    expect(find.text('Edit task'), findsOneWidget);
    expect(
      find.text('What it becomes'),
      findsWidgets,
    ); // the task sheet over the requirement sheet

    await _tap(
      tester,
      find.widgetWithText(InkWell, 'opening-scene-notes.md').first,
    );
    expect(find.text('Mark as final file'), findsOneWidget);
  });

  testWidgets('13.5 Review what changed: history, a change, the comparison', (
    tester,
  ) async {
    final router = await _app(tester);
    router.go('/projects/project-garden?view=history');
    await tester.pumpAndSettle();
    await _tap(
      tester,
      find.text('Updated scope and goals in the Opening brief'),
    );
    expect(find.text('Open comparison'), findsOneWidget);
    await _tap(tester, find.text('Open comparison'));
    expect(find.text('Back to history'), findsOneWidget);
    expect(
      find.text('- Establish tone and setting in the first page'),
      findsOneWidget,
    );
  });

  testWidgets(
    '13.6 Finish a project: its Done badge and progress are on the project page',
    (tester) async {
      final router = await _app(tester);
      router.go('/projects/atlas-zine');
      await tester.pumpAndSettle();
      expect(find.text('Done'), findsWidgets);
      expect(find.text('1/1'), findsOneWidget); // its one task is done
      expect(find.text('Edit project'), findsOneWidget);
    },
  );
}
