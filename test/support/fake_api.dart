import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:tsumugi_mobile/core/net/api_client.dart';
import 'package:tsumugi_mobile/core/net/auth_state.dart';
import 'package:tsumugi_mobile/core/net/session_cookie_store.dart';

/// What the fake server answers.
class Reply {
  const Reply(this.status, [this.body, this.cookies = const []]);

  /// A `{ "data": … }` success.
  Reply.ok(Object? data, {List<String> cookies = const []})
    : this(200, {'data': data}, cookies);

  /// A `{ "error": … }` failure.
  Reply.error(int status, String code, String message, {Object? details})
    : this(status, {
        'error': {
          'code': code,
          'message': message,
          'details': ?details,
        },
      });

  final int status;
  final Object? body;
  final List<String> cookies;
}

typedef Handler = Reply Function(RequestOptions request);

/// A server in memory: records every request and answers from [handler]. No socket is ever opened.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  Handler handler;
  final List<RequestOptions> requests = [];

  List<String> get calls => [for (final r in requests) '${r.method} ${r.path}'];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final reply = handler(options);
    if (reply.status == 0) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    final headers = <String, List<String>>{
      Headers.contentTypeHeader: [Headers.jsonContentType],
      if (reply.cookies.isNotEmpty) 'set-cookie': reply.cookies,
    };
    if (reply.status == 204) {
      return ResponseBody.fromString('', 204, headers: headers);
    }
    return ResponseBody.fromString(
      jsonEncode(reply.body),
      reply.status,
      headers: headers,
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A client wired to [adapter] with an in-memory cookie store.
ApiClient fakeClient(FakeAdapter adapter, {SessionCookieStore? cookies}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1'))
    ..httpClientAdapter = adapter;
  return ApiClient(dio: dio, cookies: cookies);
}

Map<String, dynamic> sampleJson(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;

List<Map<String, dynamic>> sampleList(String name) => [
  for (final e in jsonDecode(File('test/fixtures/$name').readAsStringSync()) as List)
    e as Map<String, dynamic>,
];

/// A server that behaves like the real one for the calls the app makes: sign in, load the workspace, and echo task
/// patches back. Tests change [tasks] responses by replacing handlers.
class SampleServer {
  SampleServer() {
    adapter = FakeAdapter(_handle);
  }

  late final FakeAdapter adapter;
  final snapshot = sampleJson('api_snapshot.demo.json');
  final templates = sampleList('api_templates.json');
  final user = sampleJson('api_user.json');
  bool signedIn = false;

  /// Extra behaviour for a test: return a Reply to override, or null to fall through.
  Reply? Function(RequestOptions)? override;

  Reply _handle(RequestOptions o) {
    final custom = override?.call(o);
    if (custom != null) return custom;
    final key = '${o.method} ${o.path}';
    switch (key) {
      case 'POST /auth/login':
        signedIn = true;
        return Reply.ok(user, cookies: ['tsumugi_sid=abc123; Path=/; HttpOnly']);
      case 'POST /auth/register':
        signedIn = true;
        return Reply(201, {'data': user}, ['tsumugi_sid=new456; Path=/; HttpOnly']);
      case 'GET /auth/session':
        return signedIn
            ? Reply.ok(user)
            : Reply.error(401, 'unauthenticated', 'Please log in.');
      case 'POST /auth/logout':
        signedIn = false;
        return const Reply(204, null, [
          'tsumugi_sid=; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT',
        ]);
      case 'GET /workspace/snapshot':
        return Reply.ok(snapshot);
      case 'GET /templates':
        return Reply.ok(templates);
      case 'PATCH /me':
        return Reply.ok(user);
    }
    if (o.method == 'PATCH' && o.path.startsWith('/tasks/')) {
      final id = o.path.substring('/tasks/'.length);
      final tasks = (snapshot['tasks'] as List).cast<Map<String, dynamic>>();
      final task = tasks.firstWhere((t) => t['id'] == id);
      task.addAll((o.data as Map).cast<String, dynamic>());
      return Reply.ok(task);
    }
    if (o.method == 'POST' && o.path == '/tasks') {
      final body = (o.data as Map).cast<String, dynamic>();
      final created = <String, dynamic>{
        'id': 'aaaaaaaaaaaaaaaaaaaaaaaa',
        'notes': '',
        'status': 'To do',
        'blocked': false,
        'subtasks': [],
        'requirementIds': [],
        'fileIds': [],
        'changeIds': [],
        'milestoneId': null,
        'due': null,
        ...body,
      };
      (snapshot['tasks'] as List).add(created);
      return Reply(201, {'data': created});
    }
    if (o.method == 'DELETE' && o.path.startsWith('/tasks/')) {
      final id = o.path.substring('/tasks/'.length);
      (snapshot['tasks'] as List).removeWhere((t) => (t as Map)['id'] == id);
      return const Reply(204);
    }
    return Reply.error(404, 'not_found', 'Not found in the fake server.');
  }
}

List<Override> serverOverrides(
  SampleServer server, {
  SessionCookieStore? cookies,
  String? zone,
}) => [
  apiClientProvider.overrideWithValue(
    fakeClient(server.adapter, cookies: cookies),
  ),
  // No platform channel in tests: the device zone is whatever the test says.
  deviceZoneProvider.overrideWithValue(() async => zone),
];
