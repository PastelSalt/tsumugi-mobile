import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsumugi_mobile/app/app.dart';
import 'package:tsumugi_mobile/core/net/auth_state.dart';

import '../support/fake_api.dart';
import '../support/fixtures.dart';

Future<ProviderContainer> _app(
  WidgetTester tester,
  SampleServer server,
  String location,
) async {
  tester.view.physicalSize = const Size(1080, 5200); // tall, so the whole form is on screen
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...fixtureOverrides(), ...serverOverrides(server)],
      child: TsumugiApp(initialLocation: location),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
}

void main() {
  group('Welcome', () {
    testWidgets('"Continue as demo user" opens the sample workspace and touches no network', (tester) async {
      final server = SampleServer();
      final c = await _app(tester, server, '/');
      await tester.ensureVisible(find.text('Continue as demo user'));
      await tester.tap(find.text('Continue as demo user'));
      await tester.pumpAndSettle();
      expect(c.read(authProvider).isDemo, isTrue);
      expect(find.text('2 tasks need you'), findsOneWidget); // the fixed-date sample data
      expect(server.adapter.requests, isEmpty);
    });

    testWidgets('Log in and Create account lead to the real sign-in and sign-up screens', (tester) async {
      final server = SampleServer();
      await _app(tester, server, '/');
      await tester.ensureVisible(find.text('Log in'));
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome back to the thread.'), findsOneWidget);
      // The real screen has no "demo only" password hint.
      expect(find.textContaining('Demo only'), findsNothing);
    });
  });

  group('Sign in', () {
    testWidgets('a valid sign-in loads the server workspace and opens Home', (tester) async {
      final server = SampleServer();
      final c = await _app(tester, server, '/sign-in');
      await tester.enterText(find.widgetWithText(TextField, 'Email address'), 'demo@tsumugi.local');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'demo-password-1');
      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pumpAndSettle();
      expect(server.adapter.calls, containsAllInOrder(['POST /auth/login', 'GET /workspace/snapshot', 'GET /templates']));
      expect(server.adapter.requests.first.data, {'email': 'demo@tsumugi.local', 'password': 'demo-password-1'});
      expect(c.read(authProvider).isSignedIn, isTrue);
      expect(find.text('Welcome back to the thread.'), findsNothing); // moved on to the workspace
    });

    testWidgets('wrong credentials show a plain message and stay on the screen', (tester) async {
      final server = SampleServer()
        ..override = (o) => o.path == '/auth/login'
            ? Reply.error(401, 'auth.invalid_credentials', 'Email or password not recognized.')
            : null;
      final c = await _app(tester, server, '/sign-in');
      await tester.enterText(find.widgetWithText(TextField, 'Email address'), 'a@b.co');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'wrong password here');
      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pumpAndSettle();
      expect(find.text('Email or password not recognized'), findsOneWidget);
      expect(find.text('Welcome back to the thread.'), findsOneWidget);
      expect(c.read(authProvider).isSignedIn, isFalse);
    });

    testWidgets('missing fields are caught before any request is made', (tester) async {
      final server = SampleServer();
      await _app(tester, server, '/sign-in');
      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your email address.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
      expect(server.adapter.requests, isEmpty);
    });

    testWidgets('an unreachable server says so instead of failing silently', (tester) async {
      final server = SampleServer()..override = (o) => const Reply(0);
      await _app(tester, server, '/sign-in');
      await tester.enterText(find.widgetWithText(TextField, 'Email address'), 'a@b.co');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'some password 12');
      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pumpAndSettle();
      expect(find.text('Can’t reach Tsumugi'), findsOneWidget);
    });
  });

  group('Sign up', () {
    testWidgets('validates locally, then registers with the terms accepted', (tester) async {
      final server = SampleServer();
      final c = await _app(tester, server, '/sign-up');
      await tester.enterText(find.widgetWithText(TextField, 'Display name'), 'Ada');
      await tester.enterText(find.widgetWithText(TextField, 'Email address'), 'ada@example.com');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'a long test passphrase');
      await tester.enterText(find.widgetWithText(TextField, 'Confirm password'), 'a long test passphrase');
      // Terms not accepted yet: nothing is sent.
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create account'));
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Accept the Terms of Service to continue.'), findsOneWidget);
      expect(server.adapter.requests, isEmpty);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();
      final register = server.adapter.requests.firstWhere((r) => r.path == '/auth/register');
      expect(register.data, containsPair('acceptTerms', true));
      expect(register.data, containsPair('email', 'ada@example.com'));
      expect(c.read(authProvider).isSignedIn, isTrue);
    });

    testWidgets('an email that is already taken is explained', (tester) async {
      final server = SampleServer()
        ..override = (o) => o.path == '/auth/register'
            ? Reply.error(409, 'auth.email_taken', 'That email is already in use.')
            : null;
      await _app(tester, server, '/sign-up');
      await tester.enterText(find.widgetWithText(TextField, 'Display name'), 'Ada');
      await tester.enterText(find.widgetWithText(TextField, 'Email address'), 'ada@example.com');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'a long test passphrase');
      await tester.enterText(find.widgetWithText(TextField, 'Confirm password'), 'a long test passphrase');
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create account'));
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();
      expect(find.text('That email is already in use'), findsOneWidget);
    });
  });
}
