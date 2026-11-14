import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tsumugi_mobile/app/app.dart';
import 'package:tsumugi_mobile/core/data/workspace_store.dart';

import '../support/fixtures.dart';

Future<GoRouter> _app(
  WidgetTester tester, {
  Size size = const Size(1080, 2600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: fixtureOverrides(),
      child: TsumugiApp(initialLocation: '/home'),
    ),
  );
  await tester.pumpAndSettle();
  return GoRouter.of(tester.element(find.byType(Scaffold).first));
}

void main() {
  group('Projects list', () {
    testWidgets('shows active projects as cards and hides the archived one', (
      tester,
    ) async {
      final router = await _app(tester);
      router.go('/projects');
      await tester.pumpAndSettle();
      expect(find.text('Project Garden'), findsOneWidget);
      expect(find.text('Atlas Zine'), findsOneWidget);
      expect(find.text('Field Notes 2025'), findsNothing);
      expect(
        find.textContaining('Next: Character bible, 10 Nov'),
        findsOneWidget,
      );
    });

    testWidgets('filters in the URL narrow the list; archived can be shown', (
      tester,
    ) async {
      final router = await _app(tester);
      router.go('/projects?status=Planning');
      await tester.pumpAndSettle();
      expect(find.text('Tsumugi API'), findsOneWidget);
      expect(find.text('Sketchbook Sprint'), findsOneWidget);
      expect(find.text('Project Garden'), findsNothing);

      router.go('/projects?archived=1&category=Research');
      await tester.pumpAndSettle();
      expect(find.text('Field Notes 2025'), findsOneWidget);
      expect(find.text('Color & Memory'), findsOneWidget);
      expect(find.text('Atlas Zine'), findsNothing);

      router.go('/projects?status=On%20hold&category=Software');
      await tester.pumpAndSettle();
      expect(find.text('Nothing matches'), findsOneWidget);
    });

    testWidgets(
      'timeline view lists milestones with a Today marker; tapping opens the sheet',
      (tester) async {
        final router = await _app(tester);
        router.go('/projects?view=timeline');
        await tester.pumpAndSettle();
        expect(find.textContaining('Today · 12 Nov'), findsOneWidget);
        expect(find.text('Auth flow map'), findsOneWidget);
        await tester.ensureVisible(find.text('Auth flow map'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Auth flow map'));
        await tester.pumpAndSettle();
        expect(find.text('Edit milestone'), findsOneWidget);
      },
    );

    testWidgets(
      'a template project is created, opened, and appears in the list',
      (tester) async {
        final router = await _app(tester);
        router.go('/projects');
        await tester.pumpAndSettle();
        await tester.tap(find.text('New project').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Research'));
        await tester.enterText(
          find.widgetWithText(TextField, 'Project name'),
          'Moss study',
        );
        await tester.ensureVisible(find.text('Create project'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Create project'));
        await tester.pumpAndSettle();
        expect(find.text('Moss study'), findsWidgets);
        expect(
          find.textContaining('Created for this session only'),
          findsOneWidget,
        );
        expect(
          find.text('Overview'),
          findsOneWidget,
        ); // the project page is open

        router.go('/projects');
        await tester.pumpAndSettle();
        expect(find.text('Moss study'), findsOneWidget);
        expect(find.text('Session only'), findsOneWidget);
      },
    );
  });

  group('Project page', () {
    testWidgets(
      'Overview shows phases, numbers, next milestone and recent changes',
      (tester) async {
        final router = await _app(tester);
        router.go('/projects/project-garden');
        await tester.pumpAndSettle();
        expect(find.text('Chapter one'), findsOneWidget); // current phase
        expect(find.text('Tasks done'), findsOneWidget);
        expect(
          find.text('1/7'),
          findsOneWidget,
        ); // project-garden: 1 of 7 tasks done
        expect(find.text('Next milestone'), findsOneWidget);
        expect(find.text('Recent changes'), findsOneWidget);
        expect(
          find.text('Updated scope and goals in the Opening brief'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Work shows milestone groups and a timeline mode; a task opens from the URL',
      (tester) async {
        final router = await _app(tester);
        router.go('/projects/project-garden?view=work');
        await tester.pumpAndSettle();
        expect(find.text('Chapter one review'), findsWidgets);
        expect(find.text('Character bible'), findsWidgets);

        await tester.tap(find.text('Timeline'));
        await tester.pumpAndSettle();
        expect(router.state.uri.queryParameters['mode'], 'timeline');
        expect(find.textContaining('Today · 12 Nov'), findsOneWidget);

        router.go('/projects/project-garden?view=work&select=t2');
        await tester.pumpAndSettle();
        expect(find.text('Edit task'), findsOneWidget);
      },
    );

    testWidgets('Specs, Files and History open record sheets by URL', (
      tester,
    ) async {
      final router = await _app(tester);
      router.go('/projects/project-garden?view=specs&select=REQ-001');
      await tester.pumpAndSettle();
      expect(find.text('Acceptance criteria'), findsOneWidget);
      await tester.tapAt(const Offset(40, 80));
      await tester.pumpAndSettle();
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // the selection is cleared just after the sheet closes
      await tester.pumpAndSettle();
      expect(router.state.uri.queryParameters.containsKey('select'), isFalse);

      router.go('/projects/project-garden?view=files&select=a-cover');
      await tester.pumpAndSettle();
      expect(find.text('Mark as final file'), findsOneWidget);
      await tester.tapAt(const Offset(40, 80));
      await tester.pumpAndSettle();
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // the selection is cleared just after the sheet closes
      await tester.pumpAndSettle();

      router.go('/projects/project-garden?view=history&select=r1');
      await tester.pumpAndSettle();
      expect(find.text('Open comparison'), findsOneWidget);
    });

    testWidgets(
      'History groups by day and the comparison shows added and removed lines',
      (tester) async {
        final router = await _app(tester);
        router.go('/projects/project-garden?view=history');
        await tester.pumpAndSettle();
        expect(find.text('Today'), findsWidgets);
        expect(find.text('Yesterday'), findsOneWidget);

        router.go('/projects/project-garden?view=history&mode=compare&rev=r1');
        await tester.pumpAndSettle();
        expect(find.text('Back to history'), findsOneWidget);
        // The diff lines are markdown bullets, so the line text itself starts with '- '.
        expect(
          find.text('- Establish tone in the first scene'),
          findsOneWidget,
        ); // removed
        expect(
          find.text('- Establish tone and setting in the first page'),
          findsOneWidget,
        ); // added
        await tester.tap(find.text('Back to history'));
        await tester.pumpAndSettle();
        expect(router.state.uri.queryParameters.containsKey('mode'), isFalse);
      },
    );

    testWidgets('unknown project shows the not-found state with a way back', (
      tester,
    ) async {
      final router = await _app(tester);
      router.go('/projects/nope');
      await tester.pumpAndSettle();
      expect(find.text('Project not found'), findsOneWidget);
      await tester.tap(find.text('Back to Projects'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/projects');
    });

    testWidgets(
      'every project renders every tab on a small phone without layout errors',
      (tester) async {
        final router = await _app(
          tester,
          size: const Size(1080, 1920),
        ); // 360 x 640 dp
        final ids = [for (final p in testFixtures().data.projects) p.id];
        for (final id in ids) {
          for (final view in [
            'overview',
            'work',
            'specs',
            'files',
            'history',
          ]) {
            router.go('/projects/$id?view=$view');
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: '$id / $view');
          }
          router.go('/projects/$id?view=work&mode=timeline');
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$id / timeline');
        }
      },
    );

    testWidgets(
      'a template project shows an empty Work tab and an empty Specs tab',
      (tester) async {
        final router = await _app(tester);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(Scaffold).first),
        );
        final id = container
            .read(sessionProvider.notifier)
            .addProject(
              name: 'Blank one',
              kind: 'blank',
              category: 'Other',
              phases: ['Plan'],
            );
        router.go('/projects/$id?view=work');
        await tester.pumpAndSettle();
        expect(find.text('No work yet'), findsOneWidget);
        router.go('/projects/$id?view=specs');
        await tester.pumpAndSettle();
        expect(find.text('No requirements yet'), findsOneWidget);
        router.go('/projects/$id?view=history');
        await tester.pumpAndSettle();
        expect(find.text('No history yet'), findsOneWidget);
      },
    );
  });
}
