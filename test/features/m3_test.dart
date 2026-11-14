// M3 of docs/PLAN-MOBILE-UI.md: Quick add v2 with picker chips, a remembered project, a one-time
// syntax tip and the long-press create menu.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsumugi_mobile/app/app.dart';
import 'package:tsumugi_mobile/core/data/models.dart';
import 'package:tsumugi_mobile/core/data/selectors.dart';
import 'package:tsumugi_mobile/core/data/workspace_store.dart';
import 'package:tsumugi_mobile/features/quickadd/quick_add_sheet.dart';

import '../support/fixtures.dart';

Future<ProviderContainer> _app(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 800) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: fixtureOverrides(),
      child: TsumugiApp(initialLocation: '/home'),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Quick add'));
  await tester.pumpAndSettle();
}

Finder _inSheet(Finder f) =>
    find.descendant(of: find.byType(QuickAddSheet), matching: f);

Task _added(ProviderContainer c, String title) => c
    .read(workspaceDataProvider)
    .tasks
    .firstWhere((t) => t.title == title && t.session);

void main() {
  testWidgets(
    'project, date and priority are set by tapping, no typing syntax',
    (tester) async {
      final c = await _app(tester);
      await _open(tester);
      await tester.enterText(find.byType(TextField).last, 'Order paint');
      await tester.pumpAndSettle();

      await tester.tap(_inSheet(find.text('No date')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tomorrow').last);
      await tester.pumpAndSettle();
      expect(_inSheet(find.text('13 Nov')), findsOneWidget);

      await tester.tap(_inSheet(find.text('Normal priority')));
      await tester.pumpAndSettle();
      expect(_inSheet(find.text('High priority')), findsOneWidget);

      final projects = c.read(workspaceDataProvider).activeProjects;
      final other = projects.last;
      await tester.tap(_inSheet(find.textContaining(projects.first.name)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(other.name).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add task'));
      await tester.pumpAndSettle();
      final task = _added(c, 'Order paint');
      expect(task.due, '2026-11-13');
      expect(task.priority, 'high');
      expect(task.projectId, other.id);
    },
  );

  testWidgets('"Next week" and "Pick a date" set the due date', (tester) async {
    final c = await _app(tester);
    await _open(tester);
    await tester.enterText(find.byType(TextField).last, 'Plan trip');
    await tester.pumpAndSettle();
    await tester.tap(_inSheet(find.text('No date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next week'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();
    expect(_added(c, 'Plan trip').due, '2026-11-19');

    await tester.enterText(find.byType(TextField).last, 'Book flights');
    await tester.pumpAndSettle();
    await tester.tap(_inSheet(find.text('No date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pick a date…'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(_added(c, 'Plan trip').due, isNotNull);
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();
    expect(_added(c, 'Book flights').due, '2026-11-12');
  });

  testWidgets('typed syntax still fills the chips, and a tapped chip wins', (
    tester,
  ) async {
    final c = await _app(tester);
    await _open(tester);
    await tester.enterText(find.byType(TextField).last, 'Buy ink today !');
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    expect(_inSheet(find.text('12 Nov')), findsOneWidget);
    expect(_inSheet(find.text('High priority')), findsOneWidget);

    await tester.tap(_inSheet(find.text('High priority')));
    await tester.pumpAndSettle();
    expect(_inSheet(find.text('Normal priority')), findsOneWidget);
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();
    expect(_added(c, 'Buy ink').priority, 'normal');
  });

  testWidgets('the project carries over to the next task and the next sheet', (
    tester,
  ) async {
    final c = await _app(tester);
    final projects = c.read(workspaceDataProvider).activeProjects;
    final other = projects.last;
    await _open(tester);
    await tester.enterText(find.byType(TextField).last, 'First one');
    await tester.pumpAndSettle();
    await tester.tap(_inSheet(find.textContaining(projects.first.name)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(other.name).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Second one');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();
    expect(_added(c, 'Second one').projectId, other.id);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await _open(tester);
    expect(_inSheet(find.text(other.name)), findsOneWidget);
  });

  testWidgets('the syntax tip shows once and stays dismissed', (tester) async {
    await _app(tester);
    await _open(tester);
    expect(find.textContaining('Tip:'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tip:'), findsNothing);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await _open(tester);
    expect(find.textContaining('Tip:'), findsNothing);
  });

  testWidgets('long-pressing + offers New task, New project and New note', (
    tester,
  ) async {
    await _app(tester);
    await tester.longPress(find.bySemanticsLabel('Quick add'));
    await tester.pumpAndSettle();
    expect(find.text('New task'), findsWidgets);
    expect(find.text('New project'), findsWidgets);
    expect(find.text('New note'), findsOneWidget);

    await tester.tap(find.text('New note'));
    await tester.pumpAndSettle();
    expect(find.text('Preview only'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    await tester.longPress(find.bySemanticsLabel('Quick add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New task').last);
    await tester.pumpAndSettle();
    expect(find.text('Quick add a task'), findsOneWidget);
  });

  testWidgets('chips are 48 dp targets and the draft guard still works', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _app(tester);
    await _open(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await tester.enterText(find.byType(TextField).last, 'Half done');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard this task?'), findsOneWidget);
    handle.dispose();
  });
}
