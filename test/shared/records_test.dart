import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tsumugi_mobile/app/app.dart';
import 'package:tsumugi_mobile/app/query_params.dart';
import 'package:tsumugi_mobile/core/data/selectors.dart';
import 'package:tsumugi_mobile/core/data/workspace_store.dart';
import 'package:tsumugi_mobile/core/theme/theme.dart';
import 'package:tsumugi_mobile/shared/widgets/filters.dart';
import 'package:tsumugi_mobile/shared/widgets/records.dart';
import 'package:tsumugi_mobile/shared/widgets/task_tile.dart';

import '../support/fixtures.dart';

Widget _host(Widget Function(WidgetRef ref) build) => ProviderScope(
  overrides: fixtureOverrides(),
  child: MaterialApp(
    theme: buildTheme(),
    home: Scaffold(
      body: SingleChildScrollView(
        child: Consumer(builder: (context, ref, _) => build(ref)),
      ),
    ),
  ),
);

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('TaskTile shows project, flags and due wording', (tester) async {
    _tall(tester);
    await tester.pumpWidget(
      _host((ref) {
        final d = ref.watch(workspaceDataProvider);
        return Column(
          children: [
            TaskTile(task: d.taskById('t7')!, showProject: true),
            TaskTile(task: d.taskById('t3')!),
          ],
        );
      }),
    );
    expect(find.text('Map sign-in states'), findsOneWidget);
    expect(find.text('Tsumugi API'), findsOneWidget);
    expect(find.text('Blocked'), findsOneWidget);
    expect(find.text('High'), findsWidgets);
    expect(
      find.textContaining('3 days overdue', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets(
    'tapping a task opens its sheet and a relation chip opens the linked record',
    (tester) async {
      _tall(tester);
      await tester.pumpWidget(
        _host(
          (ref) =>
              TaskTile(task: ref.watch(workspaceDataProvider).taskById('t1')!),
        ),
      );
      await tester.tap(find.text('Review opening scene notes'));
      await tester.pumpAndSettle();
      expect(find.text('Edit task'), findsOneWidget);
      expect(find.text('Why it exists'), findsOneWidget);
      expect(find.text('What it becomes'), findsOneWidget);

      final chip = find.widgetWithText(RelationChip, 'REQ-001');
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(find.text('Acceptance criteria'), findsOneWidget);
      expect(find.text('Mark met'), findsOneWidget);
    },
  );

  testWidgets('MilestoneGroup lists its tasks and progress', (tester) async {
    _tall(tester);
    await tester.pumpWidget(
      _host((ref) {
        final d = ref.watch(workspaceDataProvider);
        return MilestoneGroup(
          milestone: d.milestoneById('m1')!,
          tasks: d.tasksOfMilestone('m1'),
        );
      }),
    );
    expect(find.text('Chapter one review'), findsWidgets);
    expect(find.text('Reconcile character names'), findsOneWidget);
    expect(find.text('Doing'), findsWidgets);
  });

  testWidgets('FileTile shows upload progress and a Final flag', (
    tester,
  ) async {
    _tall(tester);
    await tester.pumpWidget(
      _host((ref) {
        final d = ref.watch(workspaceDataProvider);
        return Column(
          children: [
            FileTile(file: d.fileById('a-upload')!),
            FileTile(file: d.fileById('a-style')!),
          ],
        );
      }),
    );
    expect(find.text('62% uploaded'), findsOneWidget);
    expect(find.text('Final file'), findsOneWidget);
  });

  testWidgets('filter sheet changes a choice and closes with Done', (
    tester,
  ) async {
    _tall(tester);
    var value = 'all';
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showFilterSheet(
              context,
              builder: (context, refresh) => FilterField(
                label: 'Status',
                value: value,
                options: const [('all', 'Any status'), ('Doing', 'Doing')],
                onChanged: (v) {
                  value = v;
                  refresh();
                },
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Doing'));
    await tester.pumpAndSettle();
    expect(value, 'Doing');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Filters'), findsNothing);
  });

  group('routes', () {
    Future<GoRouter> app(WidgetTester tester) async {
      _tall(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: fixtureOverrides(),
          child: TsumugiApp(initialLocation: '/home'),
        ),
      );
      await tester.pumpAndSettle();
      return GoRouter.of(tester.element(find.byType(Scaffold).first));
    }

    testWidgets(
      'project route reads real data and an unknown id shows the not-found state',
      (tester) async {
        final router = await app(tester);
        router.go('/projects/project-garden?view=work');
        await tester.pumpAndSettle();
        expect(find.text('Project Garden'), findsWidgets);
        expect(router.state.uri.queryParameters['view'], 'work');

        router.go('/projects/nope');
        await tester.pumpAndSettle();
        expect(find.text('Project not found'), findsOneWidget);
      },
    );

    testWidgets(
      'account menu opens a pushed page and back returns to the tab',
      (tester) async {
        await app(tester);
        await tester.tap(find.byTooltip('Account menu'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Insights').last);
        await tester.pumpAndSettle();
        expect(find.text('Progress'), findsWidgets);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Up now'), findsOneWidget);
      },
    );

    testWidgets('setQueryParams updates and clears query parameters', (
      tester,
    ) async {
      final router = await app(tester);
      router.go('/tasks');
      await tester.pumpAndSettle();
      final ctx = tester.element(find.text('Upcoming'));
      ctx.setQueryParams({'view': 'calendar', 'project': 'tsumugi-api'});
      await tester.pumpAndSettle();
      expect(router.state.uri.queryParameters, {
        'view': 'calendar',
        'project': 'tsumugi-api',
      });
      tester.element(find.text('Upcoming')).setQueryParams({
        'view': null,
        'project': null,
      });
      await tester.pumpAndSettle();
      expect(router.state.uri.toString(), '/tasks');
    });
  });
}
