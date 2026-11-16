import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/format.dart';
import '../data/models.dart';
import 'api_client.dart';

/// The signed-in person's workspace as the server last sent it. While this is non-null the whole app reads it instead
/// of the bundled sample data (`workspaceDataProvider` in `workspace_store.dart`). The demo never sets it.
class LiveState {
  const LiveState({required this.fixtures, required this.today});

  final Fixtures fixtures;

  /// The server's "today" in the account's time zone.
  final String today;
}

class LiveNotifier extends Notifier<LiveState?> {
  @override
  LiveState? build() => null;

  /// Loads the whole workspace in one request (plus the project templates) and makes it the app's data.
  Future<void> load() async {
    final api = ref.read(apiClientProvider);
    final results = await Future.wait([
      api.get('/workspace/snapshot'),
      api.get('/templates'),
    ]);
    final snapshot = results[0].map;
    final fixtures = Fixtures.fromApi(snapshot, results[1].list);
    final today = snapshot['today'] as String;
    setClock(today);
    state = LiveState(fixtures: fixtures, today: today);
  }

  /// Reloads after a write. Failures keep what is on screen.
  Future<void> refresh() async {
    try {
      await load();
    } on ApiError {
      // The change itself succeeded; the next refresh will catch up.
    }
  }

  /// Back to the demo's fixed clock and bundled data (sign-out, or entering the demo).
  void clear() {
    resetClock();
    state = null;
  }
}

final liveProvider = NotifierProvider<LiveNotifier, LiveState?>(
  LiveNotifier.new,
);

/// A message to show the person (a failed save, for example). The app shell shows it as a snack bar and clears it.
class LiveErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void report(Object error) {
    state = error is ApiError
        ? error.message
        : 'Something went wrong. Please try again.';
  }

  void clear() => state = null;
}

final liveErrorProvider = NotifierProvider<LiveErrorNotifier, String?>(
  LiveErrorNotifier.new,
);

/// Writes to the server. Kept apart from the in-memory overlay so the overlay code stays simple.
class LiveGateway {
  LiveGateway(this.ref);
  final Ref ref;

  ApiClient get _api => ref.read(apiClientProvider);

  Future<Map<String, dynamic>> patchTask(
    String id,
    Map<String, Object?> patch,
  ) async => (await _api.patch('/tasks/$id', body: patch)).map;

  Future<Map<String, dynamic>> createTask({
    required String projectId,
    required String title,
    String priority = 'normal',
    String? due,
  }) async => (await _api.post(
    '/tasks',
    body: {
      'projectId': projectId,
      'title': title,
      'priority': priority,
      'due': ?due,
    },
  )).map;

  Future<void> deleteTask(String id) => _api.delete('/tasks/$id');

  Future<void> restoreTask(String id) => _api.post('/tasks/$id/restore');

  Future<String> createProject({
    required String name,
    required String templateKind,
  }) async =>
      (await _api.post(
            '/projects',
            body: {'name': name, 'templateKind': templateKind},
          )).map['id']
          as String;

  Future<void> refresh() => ref.read(liveProvider.notifier).refresh();
}

final liveGatewayProvider = Provider<LiveGateway>(LiveGateway.new);
