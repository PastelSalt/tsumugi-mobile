// M2 of docs/PLAN-MOBILE-UI.md: the task tile and in-session actions (complete, reschedule, undo),
// swipe, long-press menu, accessibility actions, and the session overlay staying out of the
// pristine sample data.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tsumugi_mobile/app/app.dart';
import 'package:tsumugi_mobile/core/data/format.dart';
import 'package:tsumugi_mobile/core/data/models.dart';
import 'package:tsumugi_mobile/core/data/selectors.dart';
import 'package:tsumugi_mobile/core/data/workspace_store.dart';
import 'package:tsumugi_mobile/core/settings/preferences.dart';
import 'package:tsumugi_mobile/shared/widgets/task_tile.dart';
import 'package:tsumugi_mobile/shared/widgets/undo_toast.dart';

import '../support/fixtures.dart';

const _t1 = 'Review opening scene notes'; // t1: Doing, high priority, due today

Future<(GoRouter, ProviderContainer)> _app(
  WidgetTester tester, {
  String location = '/tasks',
}) async {
  tester.view.physicalSize = const Size(360, 800) * 3;
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
  final container = ProviderScope.containerOf(element);
  // The one-time gesture hint would push the tiles down; these tests are about the tiles.
  container.read(gestureHintDismissedProvider.notifier).dismiss();
  await tester.pumpAndSettle();
  return (GoRouter.of(element), container);
}

Task _task(ProviderContainer c, String id) =>
    c.read(workspaceDataProvider).taskById(id)!;

Finder _circle(String id) =>
    find.byWidgetPredicate((w) => w is StatusCircle && w.task.id == id);

/// Dismisses the Undo toast so no timer is left running when the test ends.
Future<void> _settle(WidgetTester tester) async {
  UndoToast.hide();
  await tester.pumpAndSettle();
}

void main() {
  group('Complete, reschedule and undo from Today', () {
    testWidgets(
      'tapping the circle completes a task, and Undo brings it back',
      (tester) async {
        final (_, c) = await _app(tester);
        expect(_task(c, 't1').status, 'Doing');

        await tester.tap(_circle('t1'));
        await tester.pumpAndSettle();
        expect(_task(c, 't1').status, 'Done');
        expect(find.textContaining('Completed'), findsOneWidget);
        expect(find.text('Undo'), findsOneWidget);
        expect(c.read(sessionProvider.notifier).canUndo, isTrue);

        await tester.tap(find.text('Undo'));
        await tester.pumpAndSettle();
        expect(_task(c, 't1').status, 'Doing');
        expect(find.text('Undo'), findsNothing);
        await _settle(tester);
      },
    );

    testWidgets(
      'a finished task joins "Done this session" and can be reopened',
      (tester) async {
        final (_, c) = await _app(tester);
        await tester.tap(_circle('t1'));
        await tester.pumpAndSettle();
        UndoToast.hide();
        await tester.scrollUntilVisible(
          find.textContaining('Done this session', findRichText: true),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(_t1), findsOneWidget);

        await tester.tap(_circle('t1'));
        await tester.pumpAndSettle();
        expect(_task(c, 't1').status, isNot('Done'));
        expect(find.textContaining('Reopened'), findsOneWidget);
        await _settle(tester);
      },
    );

    testWidgets('swiping right completes and swiping left moves to tomorrow', (
      tester,
    ) async {
      final (_, c) = await _app(tester);
      await tester.drag(find.text(_t1), const Offset(320, 0));
      await tester.pumpAndSettle();
      expect(_task(c, 't1').status, 'Done');

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(_task(c, 't1').status, 'Doing');

      await tester.drag(find.text(_t1), const Offset(-320, 0));
      await tester.pumpAndSettle();
      expect(_task(c, 't1').due, tomorrowIso);
      expect(find.textContaining('tomorrow'), findsWidgets);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(_task(c, 't1').due, '2026-11-12');
      await _settle(tester);
    });

    testWidgets('long press opens the action menu: reschedule, block, status', (
      tester,
    ) async {
      final (_, c) = await _app(tester);
      await tester.longPress(find.text(_t1));
      await tester.pumpAndSettle();
      for (final label in [
        'Mark done',
        'Move to tomorrow',
        'Pick a date…',
        'Mark blocked',
        'Edit title and notes',
        'Open details',
        'Delete',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }

      await tester.tap(find.text('Mark blocked'));
      await tester.pumpAndSettle();
      expect(_task(c, 't1').blocked, isTrue);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(_task(c, 't1').blocked, isFalse);
      await _settle(tester);
    });

    testWidgets('the menu can change the status', (tester) async {
      final (_, c) = await _app(tester);
      await tester.longPress(find.text(_t1));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'To do'));
      await tester.pumpAndSettle();
      expect(_task(c, 't1').status, 'To do');
      await _settle(tester);
    });

    testWidgets('the menu can edit the title, and Undo reverts it', (
      tester,
    ) async {
      final (_, c) = await _app(tester);
      await tester.longPress(find.text(_t1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit title and notes'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Title'),
        'Review the opening scene again',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(_task(c, 't1').title, 'Review the opening scene again');
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(_task(c, 't1').title, _t1);
      await _settle(tester);
    });

    testWidgets('Delete removes a task and Undo restores it', (tester) async {
      final (_, c) = await _app(tester);
      await tester.longPress(find.text(_t1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(c.read(workspaceDataProvider).taskById('t1'), isNull);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(c.read(workspaceDataProvider).taskById('t1'), isNotNull);
      await _settle(tester);
    });

    testWidgets('undo walks back through several actions, newest first', (
      tester,
    ) async {
      final (_, c) = await _app(tester);
      final session = c.read(sessionProvider.notifier);
      session.setTaskPriority('t1', 'normal');
      session.rescheduleTask('t1', '2026-11-20');
      session.toggleComplete('t1');
      expect(_task(c, 't1').status, 'Done');

      session.undo();
      expect(_task(c, 't1').status, isNot('Done'));
      expect(_task(c, 't1').due, '2026-11-20');
      session.undo();
      expect(_task(c, 't1').due, '2026-11-12');
      session.undo();
      expect(_task(c, 't1').priority, 'high');
      expect(session.canUndo, isFalse);
    });
  });

  group('Accessibility', () {
    testWidgets(
      'every tile offers the actions as custom accessibility actions',
      (tester) async {
        final handle = tester.ensureSemantics();
        final (_, c) = await _app(tester);
        final node = tester.getSemantics(
          find
              .ancestor(of: find.text(_t1), matching: find.byType(Dismissible))
              .first,
        );
        final labels = [
          for (final id
              in node.getSemanticsData().customSemanticsActionIds ?? [])
            CustomSemanticsAction.getAction(id)?.label,
        ];
        expect(
          labels,
          containsAll([
            'Mark done',
            'Move to tomorrow',
            'Mark blocked',
            'More actions',
            'Delete',
          ]),
        );

        final complete = [
          for (final id
              in node.getSemanticsData().customSemanticsActionIds ?? <int>[])
            if (CustomSemanticsAction.getAction(id)?.label == 'Mark done') id,
        ].single;
        tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
          node.id,
          SemanticsAction.customAction,
          complete,
        );
        await tester.pumpAndSettle();
        expect(_task(c, 't1').status, 'Done');
        await _settle(tester);
        handle.dispose();
      },
    );

    testWidgets('the status circle describes the task and what a tap does', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _app(tester);
      expect(
        find.bySemanticsLabel(RegExp('Doing\\. Double tap to complete $_t1')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('the circle and the tile meet the 48 dp touch target', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _app(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  group('The task panel acts for real', () {
    testWidgets('Mark done in the detail sheet completes the task', (
      tester,
    ) async {
      final (_, c) = await _app(tester, location: '/tasks?select=t1');
      expect(find.text('Mark done'), findsOneWidget);
      await tester.tap(find.text('Mark done'));
      await tester.pumpAndSettle();
      expect(_task(c, 't1').status, 'Done');
      expect(find.text('Reopen'), findsWidgets);
      await _settle(tester);
    });

    testWidgets('tapping a subtask in the sheet toggles it for this session', (
      tester,
    ) async {
      final (_, c) = await _app(tester, location: '/tasks?select=t1');
      final before = _task(c, 't1').subtasks.map((s) => s.done).toList();
      final last = find.text(_task(c, 't1').subtasks.last.text);
      await tester.ensureVisible(last);
      await tester.pumpAndSettle();
      await tester.tap(last);
      await tester.pumpAndSettle();
      final after = _task(c, 't1').subtasks.map((s) => s.done).toList();
      expect(after.last, !before.last);
      await _settle(tester);
    });
  });

  group('The session overlay never touches the sample data', () {
    testWidgets('actions change the merged view only, and Reset restores it', (
      tester,
    ) async {
      final (_, c) = await _app(tester);
      final pristine = c
          .read(fixturesProvider)
          .data
          .tasks
          .firstWhere((t) => t.id == 't1');
      c.read(sessionProvider.notifier)
        ..toggleComplete('t1')
        ..rescheduleTask('t1', '2026-12-01')
        ..deleteTask('t3');
      expect(_task(c, 't1').status, 'Done');
      expect(c.read(workspaceDataProvider).taskById('t3'), isNull);
      expect(pristine.status, 'Doing', reason: 'fixtures are untouched');
      expect(
        c.read(fixturesProvider).data.tasks.any((t) => t.id == 't3'),
        isTrue,
      );

      c.read(sessionProvider.notifier).reset();
      expect(_task(c, 't1').status, 'Doing');
      expect(_task(c, 't1').due, '2026-11-12');
      expect(c.read(workspaceDataProvider).taskById('t3'), isNotNull);
      expect(c.read(sessionProvider.notifier).canUndo, isFalse);
      await _settle(tester);
    });
  });
}
