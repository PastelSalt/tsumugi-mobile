// M6 of docs/PLAN-MOBILE-UI.md: the project page with a collapsing header and pinned tabs, the reader
// (progress, text size, outline sheet, line numbers) and settings that apply at once.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tsumugi_mobile/app/app.dart';

import '../support/fixtures.dart';

Future<GoRouter> _app(
  WidgetTester tester,
  String location, {
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

void main() {
  group('Project page', () {
    testWidgets('shows its content in the first 40% of a small phone', (
      tester,
    ) async {
      await _app(tester, '/projects/project-garden');
      // The phase stepper opens the Overview body; it must start above 40% of 640 dp.
      final y = tester.getTopLeft(find.text('Overview').first).dy;
      expect(y, lessThan(640 * 0.4), reason: 'tabs are within the top 40%');
      final bodyTop = tester.getTopLeft(find.textContaining('tasks done')).dy;
      expect(
        bodyTop,
        lessThan(640),
        reason: 'numbers visible without scrolling',
      );
    });

    testWidgets('the header collapses and the five tabs stay pinned', (
      tester,
    ) async {
      await _app(tester, '/projects/project-garden');
      final before = tester.getTopLeft(find.text('Specs')).dy;
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
      final after = tester.getTopLeft(find.text('Specs')).dy;
      expect(after, lessThan(before));
      expect(find.text('Specs').hitTestable(), findsOneWidget);
    });

    testWidgets(
      'back returns to the Projects list, and the logo bar is hidden',
      (tester) async {
        final router = await _app(tester, '/projects');
        expect(find.text('tsumugi'), findsOneWidget);
        await tester.tap(find.text('Project Garden').first);
        await tester.pumpAndSettle();
        expect(find.text('tsumugi'), findsNothing);
        await tester.tap(find.byTooltip('Back to Projects'));
        await tester.pumpAndSettle();
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          '/projects',
        );
        expect(find.text('tsumugi'), findsOneWidget);
      },
    );

    testWidgets('an unknown project says so', (tester) async {
      await _app(tester, '/projects/nope');
      expect(find.textContaining('couldn’t find that project'), findsOneWidget);
    });
  });

  group('Reader', () {
    testWidgets('shows reading progress that grows as you scroll', (
      tester,
    ) async {
      await _app(tester, '/library/doc/d-brief');
      double progress() => tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value!;
      expect(progress(), 0);
      await tester.drag(find.byType(ListView).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(progress(), greaterThan(0));
    });

    testWidgets('the Outline button opens a sheet and jumps to a section', (
      tester,
    ) async {
      await _app(tester, '/library/doc/d-brief');
      await tester.tap(find.text('Outline'));
      await tester.pumpAndSettle();
      expect(find.text('On this page'), findsOneWidget);
      await tester.tap(find.text('Open questions').last);
      await tester.pumpAndSettle();
      expect(find.text('On this page'), findsNothing);
      expect(find.text('Open questions').hitTestable(), findsWidgets);
    });

    testWidgets('A+ and A- change the document text size', (tester) async {
      await _app(tester, '/library/doc/d-brief');
      double h() => tester.getSize(find.text('Overview').last).height;
      final before = h();
      await tester.tap(find.byTooltip('Larger text'));
      await tester.pumpAndSettle();
      expect(h(), greaterThan(before));
      await tester.tap(find.byTooltip('Smaller text'));
      await tester.tap(find.byTooltip('Smaller text'));
      await tester.pumpAndSettle();
      expect(h(), lessThan(before));
    });

    testWidgets('Source mode shows line numbers in monospace', (tester) async {
      await _app(tester, '/library/doc/d-brief');
      await tester.tap(find.text('Source'));
      await tester.pumpAndSettle();
      expect(find.text('Outline'), findsNothing);
      expect(
        find.textContaining('1\n2\n3', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('# Opening brief', findRichText: true),
        findsOneWidget,
      );
    });
  });
}
