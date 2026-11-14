// M5 of docs/PLAN-MOBILE-UI.md: dark mode on every screen, the theme preference, text size and
// reduced motion applied at once.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tsumugi_mobile/app/app.dart';
import 'package:tsumugi_mobile/core/settings/preferences.dart';
import 'package:tsumugi_mobile/core/theme/tokens.dart';

import '../support/fixtures.dart';

const _routes = [
  '/',
  '/login',
  '/register',
  '/forgot-password',
  '/reset-password',
  '/home',
  '/tasks',
  '/tasks?view=upcoming',
  '/tasks?view=calendar',
  '/tasks?view=all',
  '/tasks?view=all&mode=board',
  '/projects',
  '/projects?view=timeline',
  '/projects/project-garden',
  '/projects/project-garden?view=work',
  '/projects/project-garden?view=specs',
  '/projects/project-garden?view=files',
  '/projects/project-garden?view=history',
  '/library',
  '/library/doc/d-brief',
  '/insights',
  '/account',
  '/help',
  '/legal/privacy-policy',
  '/search',
];

Future<(GoRouter, ProviderContainer)> _app(
  WidgetTester tester, {
  Size logical = const Size(360, 800),
}) async {
  tester.view.physicalSize = logical * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: fixtureOverrides(),
      child: const TsumugiApp(initialLocation: '/home'),
    ),
  );
  await tester.pumpAndSettle();
  final element = tester.element(find.byType(Scaffold).first);
  return (GoRouter.of(element), ProviderScope.containerOf(element));
}

void main() {
  group('Theme preference', () {
    testWidgets('Dark switches the whole app at once, Light switches back', (
      tester,
    ) async {
      final (_, c) = await _app(tester);
      AppTokens tokens() =>
          Theme.of(tester.element(find.byType(Scaffold).first))
              .extension<AppTokens>()!;
      expect(tokens().isDark, isFalse);
      c.read(preferencesProvider.notifier).setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(tokens().isDark, isTrue);
      c.read(preferencesProvider.notifier).setThemeMode(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(tokens().isDark, isFalse);
    });

    testWidgets('System follows the device brightness', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await _app(tester);
      final tokens = Theme.of(tester.element(find.byType(Scaffold).first))
          .extension<AppTokens>()!;
      expect(tokens.isDark, isTrue);
    });

    testWidgets(
      'the Account page changes the theme, text size and week start',
      (tester) async {
        final (router, c) = await _app(tester);
        router.go('/account');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Dark'));
        await tester.pumpAndSettle();
        expect(c.read(preferencesProvider).themeMode, ThemeMode.dark);

        await tester.tap(find.widgetWithText(ChoiceChip, 'Large'));
        await tester.pumpAndSettle();
        expect(c.read(preferencesProvider).textScale, 1.15);

        await tester.ensureVisible(find.text('Weeks start on Sunday'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weeks start on Sunday'));
        await tester.pumpAndSettle();
        expect(c.read(preferencesProvider).weekStartsSunday, isTrue);

        await tester.scrollUntilVisible(
          find.text('Reset preferences'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset preferences'));
        await tester.pumpAndSettle();
        expect(c.read(preferencesProvider).isDefault, isTrue);
      },
    );
  });

  group('Text size and motion', () {
    testWidgets('the Large setting enlarges text on top of the device size', (
      tester,
    ) async {
      final (_, c) = await _app(tester);
      double size() => tester.getSize(find.text('Due today')).height;
      final before = size();
      c.read(preferencesProvider.notifier).setTextScale(1.3);
      await tester.pumpAndSettle();
      expect(size(), greaterThan(before * 1.2));
    });

    testWidgets('Reduce motion turns animations off for the whole app', (
      tester,
    ) async {
      final (_, c) = await _app(tester);
      bool off() => MediaQuery.disableAnimationsOf(
        tester.element(find.byType(Scaffold).first),
      );
      expect(off(), isFalse);
      c.read(preferencesProvider.notifier).setReduceMotion(true);
      await tester.pumpAndSettle();
      expect(off(), isTrue);
    });

    testWidgets('Sunday week start moves Sunday to the first column', (
      tester,
    ) async {
      final (router, c) = await _app(tester);
      router.go('/tasks?view=calendar');
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Mon')).dx,
        lessThan(tester.getTopLeft(find.text('Sun')).dx),
      );
      c.read(preferencesProvider.notifier).setWeekStartsSunday(true);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Sun')).dx,
        lessThan(tester.getTopLeft(find.text('Mon')).dx),
      );
    });
  });

  for (final scale in [1.0, 1.6]) {
    testWidgets(
      'dark: every screen lays out and meets the accessibility guidelines at text ${(scale * 100).round()}%',
      (tester) async {
        final handle = tester.ensureSemantics();
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final (router, c) = await _app(tester);
        c.read(preferencesProvider.notifier).setThemeMode(ThemeMode.dark);
        await tester.pumpAndSettle();

        final problems = <String>[];
        for (final route in _routes) {
          router.go(route);
          await tester.pumpAndSettle();
          final error = tester.takeException();
          if (error != null) problems.add('$route: layout error: $error');
          for (final (name, guideline) in [
            ('tap target size', androidTapTargetGuideline),
            ('labelled tap targets', labeledTapTargetGuideline),
            ('text contrast', textContrastGuideline),
          ]) {
            final result = await guideline.evaluate(tester);
            if (!result.passed) {
              problems.add('$route: $name: ${result.reason}');
            }
          }
        }
        handle.dispose();
        expect(problems, isEmpty, reason: problems.join('\n'));
      },
    );
  }
}
