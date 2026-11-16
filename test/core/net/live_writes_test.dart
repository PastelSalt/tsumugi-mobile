import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsumugi_mobile/core/data/models.dart';
import 'package:tsumugi_mobile/core/data/workspace_store.dart';
import 'package:tsumugi_mobile/core/net/api_client.dart';
import 'package:tsumugi_mobile/core/net/auth_state.dart';
import 'package:tsumugi_mobile/core/net/live_store.dart';

import '../../support/fake_api.dart';
import '../../support/fixtures.dart';

/// Signed in against the in-memory server, with the workspace loaded.
Future<(ProviderContainer, SampleServer)> _signedIn() async {
  final server = SampleServer();
  final c = ProviderContainer(
    overrides: [...fixtureOverrides(), ...serverOverrides(server)],
  );
  addTearDown(c.dispose);
  await c.read(authProvider.notifier).login('demo@tsumugi.local', 'demo-password-1');
  server.adapter.requests.clear();
  return (c, server);
}

Task _first(ProviderContainer c, bool Function(Task) test) =>
    c.read(workspaceDataProvider).tasks.firstWhere(test);

void main() {
  test('completing a task shows at once, is saved with PATCH, and the server’s version replaces it', () async {
    final (c, server) = await _signedIn();
    final task = _first(c, (t) => t.status == 'To do');
    c.read(sessionProvider.notifier).setTaskStatus(task.id, 'Done');
    // Optimistic: visible before the server has answered.
    expect(_first(c, (t) => t.id == task.id).status, 'Done');
    await pumpEventQueue();
    expect(server.adapter.calls, contains('PATCH /tasks/${task.id}'));
    expect(server.adapter.requests.firstWhere((r) => r.method == 'PATCH').data, {'status': 'Done'});
    expect(server.adapter.calls, contains('GET /workspace/snapshot'), reason: 'refreshed after the write');
    expect(_first(c, (t) => t.id == task.id).status, 'Done');
    expect(c.read(sessionProvider).taskOverrides, isEmpty, reason: 'the server\'s copy is now the only one');
  });

  test('Undo patches the old values back', () async {
    final (c, server) = await _signedIn();
    final task = _first(c, (t) => t.status == 'To do' && t.due != null);
    final notifier = c.read(sessionProvider.notifier);
    notifier.rescheduleTask(task.id, '2030-01-01');
    await pumpEventQueue();
    expect(_first(c, (t) => t.id == task.id).due, '2030-01-01');
    server.adapter.requests.clear();

    notifier.undo();
    await pumpEventQueue();
    final patch = server.adapter.requests.firstWhere((r) => r.method == 'PATCH');
    expect(patch.data, {'due': task.due});
    expect(_first(c, (t) => t.id == task.id).due, task.due);
  });

  test('a failed save shows a plain message and the server’s version wins', () async {
    final (c, server) = await _signedIn();
    final task = _first(c, (t) => t.status == 'To do');
    server.override = (o) => o.method == 'PATCH'
        ? Reply.error(422, 'rule_violation', 'That could not be saved.')
        : null;
    c.read(sessionProvider.notifier).setTaskStatus(task.id, 'Done');
    await pumpEventQueue();
    expect(c.read(liveErrorProvider), 'That could not be saved.');
    // The change did not save, so the server's version is what shows again.
    expect(server.adapter.calls, contains('GET /workspace/snapshot'));
    expect(_first(c, (t) => t.id == task.id).status, 'To do');
    expect(c.read(sessionProvider).taskOverrides, isEmpty);
  });

  test('offline: the change is reported, not lost silently', () async {
    final (c, server) = await _signedIn();
    final task = _first(c, (t) => t.status == 'To do');
    server.override = (o) => const Reply(0);
    c.read(sessionProvider.notifier).setTaskStatus(task.id, 'Done');
    await pumpEventQueue();
    expect(c.read(liveErrorProvider), contains('Can’t reach'));
  });

  test('deleting calls DELETE and Undo restores the task on the server', () async {
    final (c, server) = await _signedIn();
    final task = _first(c, (_) => true);
    final notifier = c.read(sessionProvider.notifier);
    expect(notifier.deleteTask(task.id), isTrue);
    expect(c.read(workspaceDataProvider).tasks.any((t) => t.id == task.id), isFalse);
    await pumpEventQueue();
    expect(server.adapter.calls, contains('DELETE /tasks/${task.id}'));
    server.adapter.requests.clear();
    notifier.undo();
    await pumpEventQueue();
    expect(server.adapter.calls, contains('POST /tasks/${task.id}/restore'));
  });

  test('Quick add creates the task on the server and shows the saved one, not a duplicate', () async {
    final (c, server) = await _signedIn();
    final project = c.read(workspaceDataProvider).projects.first;
    final before = c.read(workspaceDataProvider).tasks.length;
    c.read(sessionProvider.notifier).addTask(title: 'Write the outline', projectId: project.id, priority: 'high', due: '2026-12-01');
    expect(c.read(workspaceDataProvider).tasks, hasLength(before + 1), reason: 'shown at once');
    await pumpEventQueue();
    final post = server.adapter.requests.firstWhere((r) => r.method == 'POST' && r.path == '/tasks');
    expect(post.data, {'projectId': project.id, 'title': 'Write the outline', 'priority': 'high', 'due': '2026-12-01'});
    final tasks = c.read(workspaceDataProvider).tasks;
    expect(tasks, hasLength(before + 1), reason: 'the temporary copy is replaced by the saved one');
    expect(tasks.where((t) => t.title == 'Write the outline'), hasLength(1));
    expect(tasks.firstWhere((t) => t.title == 'Write the outline').id, 'aaaaaaaaaaaaaaaaaaaaaaaa');
  });

  test('a project created from a template comes from the server', () async {
    final (c, server) = await _signedIn();
    server.override = (o) => o.method == 'POST' && o.path == '/projects'
        ? Reply(201, {'data': {'id': 'bbbbbbbbbbbbbbbbbbbbbbbb'}})
        : null;
    final id = await c.read(liveGatewayProvider).createProject(name: 'My Novel', templateKind: 'creative');
    expect(id, 'bbbbbbbbbbbbbbbbbbbbbbbb');
    expect(server.adapter.requests.last.data, {'name': 'My Novel', 'templateKind': 'creative'});
  });

  test('ApiError carries what the screens need', () {
    const e = ApiError(409, 'auth.email_taken', 'That email is already in use.');
    expect(e.code, 'auth.email_taken');
    expect(e.isOffline, isFalse);
  });
}
