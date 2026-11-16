import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsumugi_mobile/core/data/format.dart';
import 'package:tsumugi_mobile/core/data/models.dart';
import 'package:tsumugi_mobile/core/data/workspace_store.dart';
import 'package:tsumugi_mobile/core/net/api_client.dart';
import 'package:tsumugi_mobile/core/net/auth_state.dart';
import 'package:tsumugi_mobile/core/net/live_store.dart';
import 'package:tsumugi_mobile/core/net/session_cookie_store.dart';

import '../../support/fake_api.dart';
import '../../support/fixtures.dart';

ProviderContainer _container(SampleServer server, {InMemoryCookieStore? cookies}) {
  final c = ProviderContainer(
    overrides: [...fixtureOverrides(), ...serverOverrides(server, cookies: cookies)],
  );
  addTearDown(() {
    resetClock();
    c.dispose();
  });
  return c;
}

void main() {
  test('the real API snapshot and templates parse into the app models (shapes captured from the server)', () {
    final server = SampleServer();
    final fixtures = Fixtures.fromApi(server.snapshot, server.templates);
    expect(fixtures.data.projects, hasLength(6));
    expect(fixtures.data.tasks, hasLength(15));
    expect(fixtures.data.requirements, hasLength(9));
    expect(fixtures.data.files.any((f) => f.body != null), isTrue, reason: 'documents carry a body');
    expect(fixtures.data.files.any((f) => f.body == null), isTrue, reason: 'files do not');
    expect(fixtures.templates.map((t) => t.kind), contains('software'));
    // The server gives requirements a readable key; the label is what people read.
    final r = fixtures.data.requirements.first;
    expect(r.id, hasLength(24));
    expect(r.key, startsWith('REQ-'));
    expect(r.label, r.key);
    // Sample data has no key: the id is already readable.
    expect(testFixtures().data.requirements.first.label, testFixtures().data.requirements.first.id);
  });

  test('signing in loads the workspace, uses the server’s today, and signing out puts the demo clock back', () async {
    final server = SampleServer();
    final c = _container(server);
    expect(c.read(authProvider).status, AuthStatus.unknown);
    expect(demoToday, '2026-11-12');

    await c.read(authProvider.notifier).login('demo@tsumugi.local', 'demo-password-1');
    expect(c.read(authProvider).isSignedIn, isTrue);
    expect(c.read(authProvider).user?.email, 'demo@tsumugi.local');
    expect(demoToday, server.snapshot['today']);
    final data = c.read(workspaceDataProvider);
    expect(data.projects.first.id, hasLength(24), reason: 'the app now reads the server workspace');
    expect(c.read(templatesProvider).map((t) => t.kind), contains('creative'));
    expect(data.tasks, hasLength(15));

    await c.read(authProvider.notifier).logout();
    expect(c.read(authProvider).status, AuthStatus.signedOut);
    expect(c.read(liveProvider), isNull);
    expect(demoToday, '2026-11-12');
    expect(c.read(workspaceDataProvider).projects.first.id, testFixtures().data.projects.first.id);
  });

  test('a new account still on the UTC placeholder gets the device time zone; a chosen one is left alone', () async {
    final server = SampleServer();
    final c = ProviderContainer(
      overrides: [...fixtureOverrides(), ...serverOverrides(server, zone: 'Asia/Taipei')],
    );
    addTearDown(() {
      resetClock();
      c.dispose();
    });
    await c.read(authProvider.notifier).login('a@b.co', 'x');
    final patch = server.adapter.requests.firstWhere((r) => r.method == 'PATCH' && r.path == '/me');
    expect(patch.data, {
      'preferences': {'timeZone': 'Asia/Taipei'},
    });

    final chosen = SampleServer();
    (chosen.user['preferences'] as Map)['timeZone'] = 'Europe/Paris';
    final c2 = ProviderContainer(
      overrides: [...fixtureOverrides(), ...serverOverrides(chosen, zone: 'Asia/Taipei')],
    );
    addTearDown(c2.dispose);
    await c2.read(authProvider.notifier).login('a@b.co', 'x');
    expect(chosen.adapter.calls, isNot(contains('PATCH /me')), reason: 'never override a time zone the person set');
  });

  test('the demo makes no network calls at all', () {
    final server = SampleServer();
    final c = _container(server);
    c.read(authProvider.notifier).enterDemo();
    expect(c.read(authProvider).isDemo, isTrue);
    // Reading data, completing a task, and adding one all work on the bundled data.
    final tasks = c.read(workspaceDataProvider).tasks;
    c.read(sessionProvider.notifier)
      ..toggleComplete(tasks.first.id)
      ..addTask(title: 'Demo task');
    expect(c.read(workspaceDataProvider).tasks.length, tasks.length + 1);
    c.read(sessionProvider.notifier).undo(); // takes the added task back out
    expect(c.read(workspaceDataProvider).tasks.length, tasks.length);
    expect(server.adapter.requests, isEmpty, reason: 'the demo must never reach the server');
  });

  test('a saved session is resumed at launch; an expired one lands on signed out; a missing one does not call the server', () async {
    final server = SampleServer()..signedIn = true;
    final cookies = InMemoryCookieStore();
    await cookies.write('saved');
    final resumed = _container(server, cookies: cookies);
    await resumed.read(authProvider.notifier).bootstrap();
    expect(resumed.read(authProvider).isSignedIn, isTrue);
    expect(server.adapter.calls, contains('GET /workspace/snapshot'));

    final expired = SampleServer();
    final c2 = _container(expired, cookies: InMemoryCookieStore()..write('stale'));
    await c2.read(authProvider.notifier).bootstrap();
    expect(c2.read(authProvider).status, AuthStatus.signedOut);

    final none = SampleServer();
    final c3 = _container(none);
    await c3.read(authProvider.notifier).bootstrap();
    expect(c3.read(authProvider).status, AuthStatus.signedOut);
    expect(none.adapter.requests, isEmpty, reason: 'nothing saved, so nothing to ask');
  });

  test('a session that ends elsewhere (401) signs the person out and clears the workspace', () async {
    final server = SampleServer();
    final c = _container(server);
    await c.read(authProvider.notifier).login('a@b.co', 'x');
    server.override = (o) => o.path == '/tasks/zzz'
        ? Reply.error(401, 'unauthenticated', 'Please log in.')
        : null;
    await expectLater(c.read(apiClientProvider).get('/tasks/zzz'), throwsA(anything));
    expect(c.read(authProvider).status, AuthStatus.signedOut);
    expect(c.read(liveProvider), isNull);
  });
}
