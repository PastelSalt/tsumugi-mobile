import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tsumugi_mobile/app/app.dart';
import 'package:tsumugi_mobile/core/docs/markdown_doc.dart';
import 'package:tsumugi_mobile/core/state/dev_tools.dart';
import 'package:tsumugi_mobile/core/data/workspace_store.dart';

import '../support/fixtures.dart';

Future<(GoRouter, ProviderContainer)> _app(
  WidgetTester tester, [
  String location = '/home',
  Size size = const Size(1080, 2600),
]) async {
  tester.view.physicalSize = size;
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

final _vertical = find.byWidgetPredicate(
  (w) => w is Scrollable && w.axis == Axis.vertical,
);

Future<void> _scrollTo(WidgetTester tester, Finder target) =>
    tester.scrollUntilVisible(target, 400, scrollable: _vertical.first);

void main() {
  group('Markdown documents', () {
    test(
      'parseDocument reads title, metadata, notice and numbered sections',
      () {
        final doc = parseDocument(
          File('assets/docs/privacy-policy.md').readAsStringSync(),
        );
        expect(doc.title, 'Privacy Policy / Privacy Notice');
        expect(doc.meta.first.$1, 'Draft status');
        expect(
          doc.meta.map((m) => m.$1),
          containsAll(['Service', 'Operator', 'Contact']),
        );
        expect(
          doc.notice,
          startsWith('This document is a product-planning draft'),
        );
        expect(doc.sections.first.heading, '1. Who this notice applies to');
        expect(doc.sections.first.plainHeading, 'Who this notice applies to');
        expect(doc.sections.first.number, '01');
        expect(doc.sections.first.id, 'who-this-notice-applies-to');
      },
    );

    test('the guide copy has all its sections and no desktop-only wording', () {
      final source = File('assets/docs/individual-workspace-guide.md')
          .readAsStringSync();
      final doc = parseDocument(source);
      expect(doc.sections.length, 18);
      for (final banned in [
        'Ctrl+K',
        'Cmd+K',
        'left rail',
        '?dev',
        'address bar',
        'Hover',
      ]) {
        expect(source.contains(banned), isFalse, reason: banned);
      }
    });
  });

  group('Library', () {
    testWidgets('grid, type filter and list layout come from the URL', (
      tester,
    ) async {
      final (router, _) = await _app(tester);
      router.go('/library');
      await tester.pumpAndSettle();
      expect(find.text('Add file'), findsOneWidget);
      expect(find.text('opening-scene-notes.md'), findsOneWidget);

      router.go('/library?kind=link');
      await tester.pumpAndSettle();
      expect(find.text('tsumugi-api repository'), findsOneWidget);
      expect(find.text('opening-scene-notes.md'), findsNothing);

      router.go('/library?mode=list&final=1');
      await tester.pumpAndSettle();
      expect(find.text('style-guide.pdf'), findsOneWidget);
      expect(find.text('cover-art-v2.png'), findsNothing);
    });

    testWidgets('a plain file opens its detail sheet', (tester) async {
      final (router, _) = await _app(tester);
      router.go('/library?select=a-cover');
      await tester.pumpAndSettle();
      expect(find.text('Mark as final file'), findsOneWidget);
    });

    testWidgets('tapping a Markdown document opens the reader', (tester) async {
      final (router, _) = await _app(tester);
      router.go('/library');
      await tester.pumpAndSettle();
      await _scrollTo(tester, find.text('Opening brief'));
      await tester.ensureVisible(find.text('Opening brief'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Opening brief'));
      await tester.pumpAndSettle();
      expect(find.text('Back to Library'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);
    });

    testWidgets('the reader shows the document, a Source mode and its links', (
      tester,
    ) async {
      final (router, _) = await _app(tester);
      router.go('/library/doc/d-brief');
      await tester.pumpAndSettle();
      expect(find.text('Opening brief'), findsWidgets);
      expect(find.textContaining('v4'), findsWidgets);
      expect(find.text('Outline'), findsOneWidget);

      await tester.tap(find.text('Source'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('# Opening brief', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Outline'), findsNothing);

      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();
      await _scrollTo(tester, find.text('Why it exists'));
      expect(find.text('What it becomes'), findsOneWidget);
    });

    testWidgets('an unknown or non-document id shows the not-found state', (
      tester,
    ) async {
      final (router, _) = await _app(tester);
      router.go('/library/doc/nope');
      await tester.pumpAndSettle();
      expect(find.text('Document not found'), findsOneWidget);
      router.go('/library/doc/a-cover');
      await tester.pumpAndSettle();
      expect(find.text('Document not found'), findsOneWidget);
    });
  });

  group('Insights', () {
    testWidgets('shows progress, coverage and overdue from the sample data', (
      tester,
    ) async {
      final (router, _) = await _app(tester);
      router.go('/insights');
      await tester.pumpAndSettle();
      expect(find.text('20%'), findsOneWidget); // 3 of 15 tasks done
      expect(find.text('2/9'), findsOneWidget);
      expect(find.text('7 requirements with gaps'), findsOneWidget);
      expect(find.text('3'), findsWidgets); // overdue
      expect(find.text('Overdue items'), findsOneWidget);
    });

    testWidgets('the project filter recomputes every number', (tester) async {
      final (router, _) = await _app(tester);
      router.go('/insights?project=tsumugi-api');
      await tester.pumpAndSettle();
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('Nothing is late.'), findsOneWidget);
      expect(find.text('Overdue items'), findsNothing);
    });
  });

  group('Account', () {
    testWidgets('edits show Edited and Reset; nothing is saved', (
      tester,
    ) async {
      final (router, _) = await _app(tester);
      router.go('/account');
      await tester.pumpAndSettle();
      expect(find.text('Edited'), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextField, 'Demo user'),
        'Mika',
      );
      await tester.pumpAndSettle();
      expect(find.text('Edited'), findsOneWidget);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.text('Edited'), findsNothing);
      expect(find.text('Demo user'), findsWidgets);
    });

    testWidgets(
      'developer tools switch reveals the preview-state picker in the account menu',
      (tester) async {
        final (_, container) = await _app(tester);
        await tester.tap(find.byTooltip('Account menu'));
        await tester.pumpAndSettle();
        expect(find.text('Developer: preview state'), findsNothing);
        container.read(devToolsProvider.notifier).set(true);
        await tester.pumpAndSettle();
        expect(find.text('Developer: preview state'), findsOneWidget);
        expect(find.text('Widget gallery'), findsOneWidget);
      },
    );

    testWidgets('Reset session data clears added tasks', (tester) async {
      final (router, container) = await _app(tester);
      container.read(sessionProvider.notifier).addTask(title: 'Temp');
      router.go('/account');
      await tester.pumpAndSettle();
      await _scrollTo(
        tester,
        find.widgetWithText(OutlinedButton, 'Reset session data (1)'),
      );
      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Reset session data (1)'),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Reset session data (1)'),
      );
      await tester.pumpAndSettle();
      expect(container.read(sessionProvider).count, 0);
    });
  });

  group('Help and Legal', () {
    testWidgets('Help renders the guide with a contents list', (tester) async {
      final (router, _) = await _app(tester);
      router.go('/help');
      await tester.pumpAndSettle();
      expect(find.text('Tsumugi individual workspace guide'), findsOneWidget);
      expect(find.text('On this page'), findsOneWidget);
      expect(find.text('What the individual workspace is'), findsWidgets);
    });

    testWidgets(
      'a policy shows the draft banner, cleaned details and numbered sections',
      (tester) async {
        final (router, _) = await _app(tester);
        router.go('/legal/privacy-policy');
        await tester.pumpAndSettle();
        expect(find.textContaining('Planning draft'), findsWidgets);
        expect(
          find.text('A clear thread for your information.'),
          findsOneWidget,
        );
        expect(find.text('0.1 (draft)'), findsOneWidget);
        expect(
          find.text('To be confirmed'),
          findsWidgets,
        ); // bracketed placeholders are cleaned
        expect(find.text('Who this notice applies to'), findsWidgets);
      },
    );

    testWidgets(
      'the cookie policy ends with a storage inventory that says nothing is stored',
      (tester) async {
        final (router, _) = await _app(tester);
        router.go('/legal/cookie-and-local-storage-policy');
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.textContaining('None. This version of Tsumugi'),
          600,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          find.textContaining('None. This version of Tsumugi'),
          findsOneWidget,
        );
      },
    );

    testWidgets('an unknown policy shows a clear message', (tester) async {
      final (router, _) = await _app(tester);
      router.go('/legal/nope');
      await tester.pumpAndSettle();
      expect(find.text('Policy not found'), findsWidgets);
    });
  });

  group('Search', () {
    testWidgets(
      'empty query lists actions and pages; typing filters and opens a project',
      (tester) async {
        final (router, _) = await _app(tester);
        await tester.tap(find.byTooltip('Search or jump to'));
        await tester.pumpAndSettle();
        expect(find.text('Quick add a task'), findsOneWidget);
        expect(find.text('Insights'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'garden');
        await tester.pumpAndSettle();
        expect(find.text('Project Garden'), findsOneWidget);
        expect(find.text('Insights'), findsNothing);

        await tester.tap(find.text('Project Garden'));
        await tester.pumpAndSettle();
        expect(find.text('Overview'), findsOneWidget);
        expect(router.routerDelegate.currentConfiguration.uri.path, isNotEmpty);
      },
    );

    testWidgets('no matches shows a message', (tester) async {
      await _app(tester);
      await tester.tap(find.byTooltip('Search or jump to'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pumpAndSettle();
      expect(find.textContaining('No matches for'), findsOneWidget);
    });
  });

  group('Welcome and auth', () {
    testWidgets('the app opens on Welcome; the demo button goes to Home', (
      tester,
    ) async {
      await _app(tester, '/');
      expect(find.text('Continue as demo user'), findsOneWidget);
      expect(
        find.textContaining('Weaving ideas into', findRichText: true),
        findsOneWidget,
      );
      await tester.tap(find.text('Continue as demo user'));
      await tester.pumpAndSettle();
      expect(find.text('Up now'), findsOneWidget);
    });

    testWidgets('login preview states show their banners and field errors', (
      tester,
    ) async {
      final (router, _) = await _app(tester, '/');
      router.go('/login?preview=invalid');
      await tester.pumpAndSettle();
      expect(find.text('Email or password not recognized'), findsOneWidget);
      router.go('/login?preview=errors');
      await tester.pumpAndSettle();
      expect(find.text('Check the highlighted fields'), findsOneWidget);
      expect(find.text('Enter your email address.'), findsOneWidget);
      router.go('/login');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
      expect(find.text('Up now'), findsOneWidget);
    });

    testWidgets(
      'register shows live password rules and the pending and success layouts',
      (tester) async {
        final (router, _) = await _app(tester, '/register');
        expect(
          find.textContaining('At least 12 characters (not met yet)'),
          findsOneWidget,
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Password'),
          'Abcdefghijk1',
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('(not met yet)'), findsNothing);
        expect(
          find.textContaining('At least 12 characters (met)'),
          findsOneWidget,
        );

        router.go('/register?preview=pending');
        await tester.pumpAndSettle();
        expect(find.text('Confirm your email address'), findsOneWidget);
        router.go('/register?preview=success');
        await tester.pumpAndSettle();
        expect(find.text('Account created'), findsOneWidget);
      },
    );

    testWidgets('forgot and reset password layouts and their states', (
      tester,
    ) async {
      final (router, _) = await _app(tester, '/forgot-password');
      expect(find.text('Forgot your password?'), findsOneWidget);
      router.go('/forgot-password?preview=sent');
      await tester.pumpAndSettle();
      expect(
        find.text('If an account exists, a link is on its way'),
        findsOneWidget,
      );
      router.go('/reset-password?preview=expired');
      await tester.pumpAndSettle();
      expect(find.text('Request a new link'), findsOneWidget);
      router.go('/reset-password?preview=mismatch');
      await tester.pumpAndSettle();
      expect(find.text('The passwords do not match.'), findsOneWidget);
    });

    testWidgets('submitting the demo forms explains that nothing is sent', (
      tester,
    ) async {
      final (router, _) = await _app(tester, '/forgot-password');
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();
      expect(find.text('No email is sent in this demo'), findsOneWidget);
      router.go('/reset-password');
      await tester.pumpAndSettle();
    });
  });
}
