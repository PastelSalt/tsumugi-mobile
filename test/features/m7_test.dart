// M7 of docs/PLAN-MOBILE-UI.md: launcher shortcuts and links, Android 12 splash, a 500-task
// benchmark for the lazy Tasks list, and the Undo message staying readable in both themes.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tsumugi_mobile/app/app.dart';
import 'package:tsumugi_mobile/core/data/selectors.dart';
import 'package:tsumugi_mobile/core/data/workspace_store.dart';
import 'package:tsumugi_mobile/core/settings/preferences.dart';
import 'package:tsumugi_mobile/core/theme/tokens.dart';
import 'package:tsumugi_mobile/features/quickadd/quick_add_sheet.dart';
import 'package:tsumugi_mobile/shared/widgets/task_tile.dart';

import '../support/fixtures.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return ((la > lb ? la : lb) + 0.05) / ((la > lb ? lb : la) + 0.05);
}

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
  return (GoRouter.of(element), ProviderScope.containerOf(element));
}

void main() {
  group('Android integration (files)', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    test('three launcher shortcuts open Add task, Today and Search', () {
      expect(manifest, contains('android.app.shortcuts'));
      final xml = File('android/app/src/main/res/xml/shortcuts.xml')
          .readAsStringSync();
      for (final target in [
        'tsumugi:///add',
        'tsumugi:///tasks',
        'tsumugi:///search',
      ]) {
        expect(xml, contains(target));
      }
      expect(manifest, contains('android:scheme="tsumugi"'));
    });

    test('the links add no permissions and no network access', () {
      expect(manifest.contains('uses-permission'), isFalse);
    });

    test('Android 12 splash is set for light and dark', () {
      final light = File('android/app/src/main/res/values-v31/styles.xml')
          .readAsStringSync();
      final dark = File('android/app/src/main/res/values-night-v31/styles.xml')
          .readAsStringSync();
      expect(light, contains('windowSplashScreenBackground">#F8F6FB'));
      expect(dark, contains('windowSplashScreenBackground">#17141C'));
      expect(light, contains('windowSplashScreenAnimatedIcon'));
    });

    test('the launcher icon mark fills most of the safe area', () {
      final script = File('tool/render_launcher_icons_test.dart')
          .readAsStringSync();
      expect(script, contains('mark: 650'));
      expect(script, contains('textScale: 1.9'));
    });
  });

  group('Shortcut routes', () {
    testWidgets('/add opens Home with Quick add on top', (tester) async {
      await _app(tester, location: '/add');
      expect(find.byType(QuickAddSheet), findsOneWidget);
      expect(find.text('Quick add a task'), findsOneWidget);
    });

    testWidgets('/tasks opens Today', (tester) async {
      await _app(tester, location: '/tasks');
      expect(find.text('Upcoming'), findsOneWidget);
    });

    testWidgets('/search opens Search', (tester) async {
      await _app(tester, location: '/search');
      expect(find.text('Search or jump to'), findsWidgets);
    });
  });

  group('Undo message', () {
    for (final dark in [false, true]) {
      test(
        'its text and button are readable in the ${dark ? 'dark' : 'light'} theme',
        () {
          final t = dark ? AppTokens.dark : const AppTokens();
          final background = t.onSurface; // the toast background
          final undo = t.isDark
              ? t.surface
              : t.butter; // matches undo_toast.dart
          expect(_contrast(t.surface, background), greaterThanOrEqualTo(4.5));
          expect(_contrast(undo, background), greaterThanOrEqualTo(4.5));
        },
      );
    }
  });

  group('500 tasks', () {
    Future<ProviderContainer> big(WidgetTester tester, String location) async {
      final (_, c) = await _app(tester, location: location);
      final session = c.read(sessionProvider.notifier);
      for (var i = 0; i < 500; i++) {
        session.addTask(
          title: 'Synthetic task $i',
          due: i % 3 == 0 ? '2026-11-12' : '2026-11-${13 + i % 15}',
          projectId: 'project-garden',
        );
      }
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets('Today builds only the rows near the screen', (tester) async {
      await big(tester, '/tasks');
      final built = find.byType(TaskTile).evaluate().length;
      expect(built, lessThan(40), reason: 'lazy list: $built of 500+ built');
    });

    testWidgets('All builds lazily and scrolls the whole list without errors', (
      tester,
    ) async {
      await big(tester, '/tasks?view=all');
      expect(find.byType(TaskTile).evaluate().length, lessThan(40));
      final watch = Stopwatch()..start();
      for (var i = 0; i < 40; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
        await tester.pump();
      }
      watch.stop();
      expect(tester.takeException(), isNull);
      // A very loose bound that still catches a list that builds everything on every frame.
      expect(watch.elapsedMilliseconds, lessThan(20000));
    });

    testWidgets(
      'completing a task in a long list updates the badge and Undo works',
      (tester) async {
        final c = await big(tester, '/tasks');
        final before = c.read(workspaceDataProvider).figures().dueToday;
        c.read(sessionProvider.notifier).toggleComplete('t1');
        await tester.pumpAndSettle();
        expect(c.read(workspaceDataProvider).figures().dueToday, before - 1);
        c.read(sessionProvider.notifier).undo();
        await tester.pumpAndSettle();
        expect(c.read(workspaceDataProvider).figures().dueToday, before);
      },
    );
  });

  testWidgets('dark theme and large text together still lay out on Tasks', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    final (_, c) = await _app(tester);
    c.read(preferencesProvider.notifier).setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
