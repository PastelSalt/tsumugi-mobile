import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tsumugi_mobile/app/app.dart';
import 'package:tsumugi_mobile/core/state/preview_state.dart';
import 'package:tsumugi_mobile/core/theme/motion.dart';
import 'package:tsumugi_mobile/core/theme/theme.dart';
import 'package:tsumugi_mobile/core/theme/tokens.dart';
import 'package:tsumugi_mobile/shared/widgets/states.dart';

import '../support/fixtures.dart';

Future<(GoRouter, ProviderContainer)> _app(
  WidgetTester tester, {
  String location = '/home',
  Size logical = const Size(360, 867),
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
  final ctx = tester.element(find.byType(Scaffold).first);
  return (GoRouter.of(ctx), ProviderScope.containerOf(ctx));
}

const _tablet = Size(1280, 800);

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return ((la > lb ? la : lb) + 0.05) / ((la > lb ? lb : la) + 0.05);
}

void main() {
  group('Wide layout (tablet)', () {
    testWidgets(
      'shows a side rail with five destinations instead of the bottom bar',
      (tester) async {
        await _app(tester, logical: _tablet);
        for (final label in [
          'Home',
          'Projects',
          'Tasks',
          'Library',
          'Insights',
        ]) {
          expect(find.text(label), findsWidgets, reason: label);
        }
        expect(find.byTooltip('Search or jump to'), findsOneWidget);
        expect(find.byTooltip('Account menu'), findsOneWidget);
        expect(find.bySemanticsLabel('Quick add'), findsOneWidget);
      },
    );

    testWidgets(
      'a selected task is docked beside the list, not shown in a sheet',
      (tester) async {
        final (router, _) = await _app(tester, logical: _tablet);
        router.go('/tasks?select=t1');
        await tester.pumpAndSettle();
        expect(find.text('Edit task'), findsOneWidget);
        expect(find.byTooltip('Close details'), findsOneWidget);
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.text('Tasks'), findsWidgets); // the list is still there

        await tester.tap(find.byTooltip('Close details'));
        await tester.pumpAndSettle();
        expect(find.text('Edit task'), findsNothing);
        expect(router.state.uri.queryParameters.containsKey('select'), isFalse);
      },
    );

    testWidgets(
      'tapping rows docks other records too: project work, specs and library files',
      (tester) async {
        final (router, _) = await _app(tester, logical: _tablet);
        router.go('/projects/project-garden?view=specs&select=REQ-001');
        await tester.pumpAndSettle();
        expect(find.text('Acceptance criteria'), findsOneWidget);
        expect(find.byType(BottomSheet), findsNothing);

        router.go('/library?select=a-cover');
        await tester.pumpAndSettle();
        expect(find.text('Mark as final file'), findsOneWidget);
        expect(find.byType(BottomSheet), findsNothing);

        await tester.tap(find.text('cover-art-v2.png').first);
        await tester.pumpAndSettle();
        expect(find.text('Mark as final file'), findsOneWidget);
      },
    );

    testWidgets(
      'phones still use the bottom bar and a sheet at the same URLs',
      (tester) async {
        final (router, _) = await _app(tester);
        expect(find.byTooltip('Close details'), findsNothing);
        router.go('/tasks?select=t1');
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.text('Edit task'), findsOneWidget);
      },
    );

    testWidgets('the rail navigates between tabs and opens Insights', (
      tester,
    ) async {
      final (router, _) = await _app(tester, logical: _tablet);
      await tester.tap(find.text('Tasks').first);
      await tester.pumpAndSettle();
      expect(
        find.text('Everything you have to do, across all projects.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Insights').first);
      await tester.pumpAndSettle();
      expect(
        find.text('Three numbers that tell you where things stand.'),
        findsOneWidget,
      );
      expect(router.canPop(), isTrue);
    });

    testWidgets(
      'every main screen lays out on a tablet in portrait and landscape',
      (tester) async {
        final (router, _) = await _app(tester, logical: const Size(800, 1280));
        for (final route in [
          '/home',
          '/tasks',
          '/tasks?view=calendar',
          '/projects',
          '/projects/project-garden',
          '/library',
          '/tasks?select=t3',
          '/library?select=a-cover',
        ]) {
          router.go(route);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$route portrait');
        }
        tester.view.physicalSize = _tablet * 3;
        await tester.pumpAndSettle();
        for (final route in [
          '/home',
          '/tasks',
          '/tasks?select=t3',
          '/projects/project-garden?view=work&select=m1',
        ]) {
          router.go(route);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$route landscape');
        }
      },
    );
  });

  group('Motion and themes', () {
    testWidgets('page transitions are skipped when animations are disabled', (
      tester,
    ) async {
      late Widget built;
      final child = const SizedBox(key: ValueKey('page'));
      for (final disabled in [true, false]) {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(disableAnimations: disabled),
            child: Builder(
              builder: (context) {
                built = const TsumugiPageTransitionsBuilder()
                    .buildTransitions<void>(
                      MaterialPageRoute<void>(builder: (_) => child),
                      context,
                      const AlwaysStoppedAnimation(0.5),
                      const AlwaysStoppedAnimation(0),
                      child,
                    );
                return const SizedBox();
              },
            ),
          ),
        );
        expect(
          built is FadeTransition,
          !disabled,
          reason: 'disableAnimations=$disabled',
        );
      }
    });

    testWidgets(
      'small animations use a zero duration when animations are disabled',
      (tester) async {
        late Duration d;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (c) {
                d = motionDuration(c);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(d, Duration.zero);
      },
    );

    test('the dark theme scaffold builds and keeps readable contrast', () {
      final theme = buildDarkTheme();
      expect(theme.brightness, Brightness.dark);
      expect(theme.extension<AppTokens>()!.paper, AppTokens.dark.paper);
      const d = AppTokens.dark;
      expect(_contrast(d.ink, d.paper), greaterThanOrEqualTo(4.5));
      expect(_contrast(d.muted, d.paper), greaterThanOrEqualTo(4.5));
      expect(_contrast(d.ink, d.canvas), greaterThanOrEqualTo(4.5));
      expect(_contrast(d.pink, d.paper), greaterThanOrEqualTo(4.5));
      expect(
        _contrast(d.canvas, d.pink),
        greaterThanOrEqualTo(4.5),
      ); // button text on the accent
    });
  });

  group('Preview states on every screen', () {
    const gated = [
      '/home',
      '/tasks',
      '/tasks?view=calendar',
      '/tasks?view=all',
      '/projects',
      '/projects/project-garden',
      '/projects/project-garden?view=work',
      '/library',
      '/insights',
      '/account',
    ];

    for (final state in [
      PreviewState.loading,
      PreviewState.empty,
      PreviewState.error,
    ]) {
      testWidgets(
        '${state.name}: each list screen shows a designed layout without layout errors',
        (tester) async {
          final (router, container) = await _app(tester);
          container.read(previewStateProvider.notifier).set(state);
          await tester.pumpAndSettle();
          for (final route in gated) {
            router.go(route);
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '$route / ${state.name}',
            );
            if (state == PreviewState.error) {
              expect(
                find.text('Something went wrong'),
                findsOneWidget,
                reason: route,
              );
            }
            if (state == PreviewState.loading) {
              expect(find.byType(LoadingState), findsOneWidget, reason: route);
            }
          }
        },
      );
    }

    testWidgets('empty states give a title and a way forward', (tester) async {
      final (router, container) = await _app(tester);
      container.read(previewStateProvider.notifier).set(PreviewState.empty);
      await tester.pumpAndSettle();
      final expectations = {
        '/home': 'Welcome. Nothing here yet.',
        '/tasks': 'No tasks yet',
        '/projects': 'No projects yet',
        '/library': 'Your library is empty',
        '/insights': 'No data yet',
      };
      for (final MapEntry(key: route, value: text) in expectations.entries) {
        router.go(route);
        await tester.pumpAndSettle();
        expect(find.text(text), findsOneWidget, reason: route);
      }
    });
  });
}
