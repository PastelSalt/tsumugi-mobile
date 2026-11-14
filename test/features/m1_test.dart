// M1 of docs/PLAN-MOBILE-UI.md: mobile-native foundations (collapsing large title, semantic tokens,
// type scale, edge-to-edge, predictive back, draft protection).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tsumugi_mobile/app/app.dart';
import 'package:tsumugi_mobile/core/theme/theme.dart';
import 'package:tsumugi_mobile/core/theme/tokens.dart';
import 'package:tsumugi_mobile/shared/widgets/large_title_scaffold.dart';

import '../support/fixtures.dart';

Future<GoRouter> _app(
  WidgetTester tester, {
  String location = '/tasks',
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
  return GoRouter.of(tester.element(find.byType(Scaffold).first));
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return ((la > lb ? la : lb) + 0.05) / ((la > lb ? lb : la) + 0.05);
}

void main() {
  group('Large-title scaffold on Tasks', () {
    testWidgets(
      'shows the screen title instead of the logo, and Home keeps the logo',
      (tester) async {
        final router = await _app(tester);
        expect(find.text('Tasks'), findsWidgets);
        expect(find.text('tsumugi'), findsNothing);
        router.go('/home');
        await tester.pumpAndSettle();
        expect(find.text('tsumugi'), findsOneWidget);
      },
    );

    testWidgets(
      'the title collapses as the list scrolls and the view tabs stay pinned',
      (tester) async {
        await _app(tester);
        final tabsBefore = tester.getTopLeft(find.text('Upcoming')).dy;

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
        await tester.pumpAndSettle();
        final tabsAfter = tester.getTopLeft(find.text('Upcoming')).dy;

        expect(
          tabsAfter,
          lessThan(tabsBefore),
          reason: 'the large title collapsed, so the tabs moved up',
        );
        expect(
          find.text('Upcoming').hitTestable(),
          findsOneWidget,
          reason: 'tabs stay on screen and tappable',
        );
        expect(
          find.text('Tasks'),
          findsWidgets,
          reason: 'the collapsed title is still in the bar',
        );
      },
    );

    testWidgets('pull to refresh shows the indicator and settles', (
      tester,
    ) async {
      await _app(tester);
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 400),
        1000,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(RefreshProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(RefreshProgressIndicator), findsNothing);
    });

    testWidgets(
      'search and account stay reachable in the large bar on phones, and only once on tablets',
      (tester) async {
        await _app(tester);
        expect(find.byTooltip('Search or jump to'), findsOneWidget);
        expect(find.byTooltip('Account menu'), findsOneWidget);
      },
    );

    testWidgets('tablet: the page bar does not repeat the rail buttons', (
      tester,
    ) async {
      await _app(tester, logical: const Size(1280, 800));
      expect(
        find.byTooltip('Search or jump to'),
        findsOneWidget,
      ); // only the rail's
    });

    testWidgets(
      'scroll position is restored after the app is restarted by the system',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640) * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            restorationScopeId: 'root',
            theme: buildTheme(),
            home: LargeTitleScaffold(
              title: 'Long list',
              restorationId: 'long',
              slivers: [
                SliverList.builder(
                  itemCount: 80,
                  itemBuilder: (context, i) =>
                      SizedBox(height: 56, child: Text('Row $i')),
                ),
              ],
            ),
          ),
        );
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
        await tester.pumpAndSettle();
        final before = tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .pixels;
        expect(before, greaterThan(300));

        await tester.restartAndRestore();
        await tester.pumpAndSettle();
        final after = tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .pixels;
        expect(after, closeTo(before, 1));
      },
    );
  });

  group('Tokens and type scale', () {
    test('dark and light palettes both define every colour and a readable pair for each role', () {
      for (final t in [const AppTokens(), AppTokens.dark]) {
        for (final (fg, bg) in [
          (t.onSurface, t.surface),
          (t.onSurface, t.background),
          (t.onSurfaceMuted, t.surface),
          (t.onAccent, t.accent),
          (t.danger, t.surface),
          (t.warning, t.warningContainer),
          (t.success, t.successContainer),
          (t.info, t.infoContainer),
          (t.danger, t.dangerContainer),
        ]) {
          expect(
            _contrast(fg, bg),
            greaterThanOrEqualTo(4.5),
            reason: '${t.brightness.name}: $fg on $bg',
          );
        }
      }
    });

    test('roles map onto the palette', () {
      const t = AppTokens();
      expect(t.background, t.canvas);
      expect(t.surface, t.paper);
      expect(t.accent, t.pink);
      expect(t.isDark, isFalse);
      expect(AppTokens.dark.isDark, isTrue);
    });

    test('the type scale: display 32/700, title 20/600, row title 16/500, body 15, meta 13', () {
      final text = buildTheme().textTheme;
      expect(
        (text.headlineMedium!.fontSize, text.headlineMedium!.fontWeight),
        (32, FontWeight.w700),
      );
      expect(
        (text.titleLarge!.fontSize, text.titleLarge!.fontWeight),
        (20, FontWeight.w600),
      );
      expect(
        (text.titleSmall!.fontSize, text.titleSmall!.fontWeight),
        (16, FontWeight.w500),
      );
      expect(text.bodyMedium!.fontSize, 15);
      expect(text.bodySmall!.fontSize, 13);
      for (final s in [
        text.headlineMedium,
        text.titleLarge,
        text.titleMedium,
        text.titleSmall,
        text.bodyMedium,
        text.bodySmall,
        text.labelSmall,
      ]) {
        expect(s!.fontSize, greaterThanOrEqualTo(12));
        expect(s.fontFamily, 'Fredoka');
      }
    });

    test('Fredoka 500 and 600 are bundled and registered', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final f in ['Fredoka-Medium.ttf', 'Fredoka-SemiBold.ttf']) {
        expect(pubspec, contains(f));
        expect(File('assets/fonts/$f').existsSync(), isTrue);
        expect(File('assets/fonts/$f').lengthSync(), greaterThan(20000));
      }
    });

    test('no literal colours outside the token file (and the logo)', () {
      final offenders = <String>[];
      for (final file
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final path = file.path.replaceAll('\\', '/');
        if (path.endsWith('core/theme/tokens.dart') ||
            path.endsWith('shared/widgets/brand_mark.dart')) {
          continue;
        }
        final text = file.readAsStringSync();
        if (RegExp(r'Color\(0x').hasMatch(text)) {
          offenders.add('$path: Color(0x...)');
        }
        if (RegExp(r'Colors\.(white|black)\b').hasMatch(text)) {
          offenders.add('$path: Colors.white/black');
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });

  group('Edge-to-edge and predictive back', () {
    testWidgets('the app draws behind transparent system bars', (tester) async {
      await _app(tester, location: '/home');
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
      );
      expect(region.value.statusBarColor, Colors.transparent);
      expect(region.value.systemNavigationBarColor, Colors.transparent);
      expect(
        region.value.statusBarIconBrightness,
        Brightness.dark,
      ); // dark icons on the light theme
    });

    test('the Android manifest opts in to predictive back and requests no permissions', () {
      final manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      expect(manifest, contains('android:enableOnBackInvokedCallback="true"'));
      expect(manifest.contains('uses-permission'), isFalse);
    });
  });

  group('Draft protection', () {
    Future<void> openQuickAdd(WidgetTester tester) async {
      await tester.tap(find.bySemanticsLabel('Quick add'));
      await tester.pumpAndSettle();
    }

    testWidgets('Close with nothing typed closes at once', (tester) async {
      await _app(tester, location: '/home');
      await openQuickAdd(tester);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Quick add a task'), findsNothing);
      expect(find.text('Discard this task?'), findsNothing);
    });

    testWidgets(
      'Close or back with text asks first; Keep writing keeps the draft; Discard closes',
      (tester) async {
        await _app(tester, location: '/home');
        await openQuickAdd(tester);
        await tester.enterText(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(TextField),
          ),
          'Half a thought',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(find.text('Discard this task?'), findsOneWidget);
        await tester.tap(find.text('Keep writing'));
        await tester.pumpAndSettle();
        expect(find.text('Quick add a task'), findsOneWidget);
        expect(find.text('Half a thought'), findsOneWidget);

        await tester.binding.handlePopRoute(); // the system back gesture
        await tester.pumpAndSettle();
        expect(find.text('Discard this task?'), findsOneWidget);
        await tester.tap(find.text('Discard'));
        await tester.pumpAndSettle();
        expect(find.text('Quick add a task'), findsNothing);
      },
    );

    testWidgets(
      'after adding a task the draft is empty, so closing needs no confirmation',
      (tester) async {
        await _app(tester, location: '/home');
        await openQuickAdd(tester);
        await tester.enterText(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(TextField),
          ),
          'Water plants today',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add task'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(find.text('Discard this task?'), findsNothing);
        expect(find.text('Quick add a task'), findsNothing);
      },
    );

    testWidgets('New project asks before discarding a typed name', (
      tester,
    ) async {
      await _app(tester, location: '/projects');
      await tester.tap(find.text('New project').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Project name'),
        'Moss',
      );
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Discard this project?'), findsOneWidget);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Discard this project?'), findsNothing);
    });
  });
}
