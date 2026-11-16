import 'package:flutter_test/flutter_test.dart';
import 'package:tsumugi_mobile/core/net/api_client.dart';
import 'package:tsumugi_mobile/core/net/session_cookie_store.dart';

import '../../support/fake_api.dart';

void main() {
  test('unwraps the data envelope and returns meta for paginated lists', () async {
    final server = FakeAdapter(
      (o) => Reply(200, {
        'data': [
          {'id': 'a'},
        ],
        'meta': {'nextCursor': 'x', 'hasMore': true},
      }),
    );
    final res = await fakeClient(server).get('/page/tasks', query: {'limit': 1});
    expect(res.list.single['id'], 'a');
    expect((res.meta as Map)['hasMore'], true);
    expect(server.requests.single.queryParameters['limit'], 1);
  });

  test('keeps the session cookie, sends it back, and forgets it when the server clears it', () async {
    final store = InMemoryCookieStore();
    var cookie = 'tsumugi_sid=tok1; Path=/; HttpOnly; SameSite=Lax';
    final server = FakeAdapter((o) {
      if (o.path == '/auth/logout') {
        return const Reply(204, null, [
          'tsumugi_sid=; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT',
        ]);
      }
      return Reply.ok({'ok': true}, cookies: [cookie]);
    });
    final client = fakeClient(server, cookies: store);

    await client.post('/auth/login', body: {'email': 'a@b.co', 'password': 'x'});
    expect(await store.read(), 'tok1');
    expect(server.requests.first.headers['cookie'], isNull, reason: 'no cookie before sign-in');

    await client.get('/me');
    expect(server.requests.last.headers['cookie'], 'tsumugi_sid=tok1');

    await client.post('/auth/logout');
    expect(await store.read(), isNull);
    expect(await client.hasSession(), isFalse);
    await client.get('/me');
    expect(server.requests.last.headers['cookie'], isNull);

    cookie = 'tsumugi_sid=tok2; Path=/';
    await client.post('/auth/login');
    expect(await store.read(), 'tok2');
  });

  test('a new client picks the saved session up from storage', () async {
    final store = InMemoryCookieStore();
    await store.write('saved');
    final server = FakeAdapter((o) => Reply.ok({}));
    final client = fakeClient(server, cookies: store);
    expect(await client.hasSession(), isTrue);
    await client.get('/auth/session');
    expect(server.requests.single.headers['cookie'], 'tsumugi_sid=saved');
  });

  test('maps the error envelope, including field messages', () async {
    final client = fakeClient(
      FakeAdapter(
        (o) => Reply.error(
          400,
          'validation_failed',
          'Some fields need attention.',
          details: [
            {'path': 'password', 'code': 'weak_password', 'message': 'Use at least 12 characters.'},
          ],
        ),
      ),
    );
    await expectLater(
      client.post('/auth/register'),
      throwsA(
        isA<ApiError>()
            .having((e) => e.status, 'status', 400)
            .having((e) => e.code, 'code', 'validation_failed')
            .having((e) => e.fieldMessage('password'), 'password', 'Use at least 12 characters.'),
      ),
    );
  });

  test('a 401 calls the sign-out hook; an unreachable server is status 0 with a plain message', () async {
    var ended = 0;
    final unauthorized = fakeClient(
      FakeAdapter((o) => Reply.error(401, 'unauthenticated', 'Please log in.')),
    )..onUnauthenticated = () => ended++;
    await expectLater(unauthorized.get('/me'), throwsA(isA<ApiError>()));
    expect(ended, 1);

    final offline = fakeClient(FakeAdapter((o) => const Reply(0)));
    await expectLater(
      offline.get('/me'),
      throwsA(
        isA<ApiError>()
            .having((e) => e.isOffline, 'offline', isTrue)
            .having((e) => e.message, 'message', contains('Can’t reach')),
      ),
    );
  });

  test('wrong credentials are not treated as a signed-out session', () async {
    var ended = 0;
    final client = fakeClient(
      FakeAdapter((o) => Reply.error(401, 'auth.invalid_credentials', 'Email or password not recognized.')),
    )..onUnauthenticated = () => ended++;
    await expectLater(client.post('/auth/login'), throwsA(isA<ApiError>()));
    expect(ended, 0);
  });
}
