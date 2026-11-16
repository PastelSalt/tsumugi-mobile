// Runs the app's real networking code against a real Tsumugi server. Skipped unless a server address is given:
//
//   1. in the website repo:   npm run dev --prefix Server        (API on http://127.0.0.1:3001)
//   2. here:                  flutter test test/integration --dart-define=TSUMUGI_API=http://127.0.0.1:3001/api/v1
//
// It registers a throwaway account, so run it against a development database only. It checks what the fake server
// in the other tests can only imitate: that the server's real responses parse into the app's models, that the session
// cookie round-trips through the real Set-Cookie header, and that task writes and Undo behave against real rules.
@Timeout(Duration(seconds: 60))
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsumugi_mobile/core/data/models.dart';
import 'package:tsumugi_mobile/core/data/workspace_store.dart';
import 'package:tsumugi_mobile/core/net/api_client.dart';
import 'package:tsumugi_mobile/core/net/auth_state.dart';
import 'package:tsumugi_mobile/core/net/live_store.dart';
import 'package:tsumugi_mobile/core/net/session_cookie_store.dart';

import '../support/fixtures.dart';

const _api = String.fromEnvironment('TSUMUGI_API');

void main() {
  final skip = _api.isEmpty ? 'set --dart-define=TSUMUGI_API to run against a server' : null;

  test('register, load the real workspace, write and undo, sign out, sign back in', () async {
    final cookies = InMemoryCookieStore();
    final client = ApiClient(baseUrl: _api, cookies: cookies);
    final container = ProviderContainer(
      overrides: [
        ...fixtureOverrides(),
        apiClientProvider.overrideWithValue(client),
        deviceZoneProvider.overrideWithValue(() async => 'Asia/Taipei'),
      ],
    );
    addTearDown(container.dispose);
    final auth = container.read(authProvider.notifier);
    final email = 'mobile-${DateTime.now().microsecondsSinceEpoch}@example.com';
    const password = 'a mobile integration passphrase';

    // Register: the real server sets the cookie and the app stores it.
    await auth.register(email: email, password: password, displayName: 'Mobile Test');
    expect(container.read(authProvider).isSignedIn, isTrue);
    expect(await cookies.read(), isNotNull);

    // A new account starts empty; create a project from a template on the server.
    expect(container.read(workspaceDataProvider).projects, isEmpty);
    final projectId = await container.read(liveGatewayProvider).createProject(name: 'Mobile project', templateKind: 'software');
    await container.read(liveGatewayProvider).refresh();
    final data = container.read(workspaceDataProvider);
    expect(data.projects.single.id, projectId);
    expect(data.tasks, hasLength(3), reason: 'the template’s starter tasks');
    expect(container.read(templatesProvider).map((t) => t.kind), containsAll(['software', 'creative']));

    // The server's "today" is in the account's zone (the device zone was applied at sign-up).
    final me = (await client.get('/me')).map;
    expect((me['preferences'] as Map)['timeZone'], 'Asia/Taipei');

    // Quick add, complete, Undo: all against real rules.
    final session = container.read(sessionProvider.notifier);
    session.addTask(title: 'Written on the phone', projectId: projectId, priority: 'high', due: '2030-01-01');
    await pumpEventQueue(times: 50);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final added = container.read(workspaceDataProvider).tasks.firstWhere((t) => t.title == 'Written on the phone');
    expect(added.id, hasLength(24), reason: 'the saved task, with its real id');
    expect(added.priority, 'high');
    expect(added.due, '2030-01-01');

    session.setTaskStatus(added.id, 'Done');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(container.read(workspaceDataProvider).tasks.firstWhere((t) => t.id == added.id).status, 'Done');
    session.undo();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(container.read(workspaceDataProvider).tasks.firstWhere((t) => t.id == added.id).status, 'To do');

    // A rule the server enforces comes back as a message, not a crash.
    await expectLater(
      client.patch('/tasks/${added.id}', body: {'due': 'not-a-date'}),
      throwsA(isA<ApiError>().having((e) => e.status, 'status', 400)),
    );

    // Everything the server sent parses into the app's models, including documents and files.
    await client.post('/documents', body: {'projectId': projectId, 'title': 'Notes', 'body': '# Notes\n\nFrom the phone.'});
    await container.read(liveGatewayProvider).refresh();
    final files = container.read(workspaceDataProvider).files;
    expect(files.single.body, '# Notes\n\nFrom the phone.');
    expect(files.single.status, 'Draft');

    // Sign out clears the session; the old cookie no longer works; signing in again works.
    await auth.logout();
    expect(container.read(authProvider).status, AuthStatus.signedOut);
    expect(await cookies.read(), isNull);
    await expectLater(ApiClient(baseUrl: _api, cookies: cookies).get('/me'), throwsA(isA<ApiError>().having((e) => e.status, 'status', 401)));
    await auth.login(email, password);
    expect(container.read(authProvider).isSignedIn, isTrue);
    expect(container.read(workspaceDataProvider).tasks, hasLength(4));

    // Clean up: delete the throwaway account.
    await client.post('/me/delete', body: {'password': password, 'confirm': 'DELETE'});
  }, skip: skip);

  test('the seeded demo account’s whole snapshot parses into the app models', () async {
    final client = ApiClient(baseUrl: _api);
    try {
      await client.post('/auth/login', body: {'email': 'demo@tsumugi.local', 'password': 'demo-password-1'});
    } on ApiError {
      markTestSkipped('run `npm run seed` in the website repo to create the demo account');
      return;
    }
    final snapshot = (await client.get('/workspace/snapshot')).map;
    final templates = (await client.get('/templates')).list;
    final fixtures = Fixtures.fromApi(snapshot, templates);
    expect(fixtures.data.projects, isNotEmpty);
    expect(fixtures.data.requirements.every((r) => r.key != null && r.key!.startsWith('REQ-')), isTrue);
    await client.post('/auth/logout');
  }, skip: skip);
}
