import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../net/live_store.dart';
import 'models.dart';

/// Loads the sample data bundled from the website (`assets/data/fixtures.json`).
Future<Fixtures> loadFixtures([AssetBundle? bundle]) async {
  final text = await (bundle ?? rootBundle).loadString(
    'assets/data/fixtures.json',
  );
  return Fixtures.fromJson(jsonDecode(text) as Map<String, dynamic>);
}

/// The fixed sample data. Overridden in `main()` once the asset has loaded (and in tests).
final fixturesProvider = Provider<Fixtures>(
  (ref) => throw UnimplementedError('fixturesProvider must be overridden'),
);

/// Everything the person has done in this run, kept **in memory only** (docs/PLAN-MOBILE-UI.md,
/// section 1a). It is an overlay on top of the pristine sample data:
///
/// - records added with Quick add or a template ([projects], [milestones], [tasks]);
/// - edits to any task, sample or added, as whole replacement records in [taskOverrides];
/// - deletions of sample tasks in [deletedTaskIds].
///
/// The sample data is never mutated, so "Reset session data" restores it exactly. Nothing is saved:
/// closing the app discards all of it.
class SessionState {
  const SessionState({
    this.projects = const [],
    this.milestones = const [],
    this.tasks = const [],
    this.taskOverrides = const {},
    this.deletedTaskIds = const {},
    this.touchedId,
    this.touchedAt,
  });

  /// The task changed last and when: lets a tile that has just arrived in a new group animate in
  /// (docs/PLAN-UX.md, M-1 and M-2). Never saved; not part of the data.
  final String? touchedId;
  final DateTime? touchedAt;

  final List<Project> projects;
  final List<Milestone> milestones;
  final List<Task> tasks;
  final Map<String, Task> taskOverrides;
  final Set<String> deletedTaskIds;

  SessionState copyWith({
    List<Project>? projects,
    List<Milestone>? milestones,
    List<Task>? tasks,
    Map<String, Task>? taskOverrides,
    Set<String>? deletedTaskIds,
    String? touchedId,
    DateTime? touchedAt,
  }) => SessionState(
    projects: projects ?? this.projects,
    milestones: milestones ?? this.milestones,
    tasks: tasks ?? this.tasks,
    taskOverrides: taskOverrides ?? this.taskOverrides,
    deletedTaskIds: deletedTaskIds ?? this.deletedTaskIds,
    touchedId: touchedId ?? this.touchedId,
    touchedAt: touchedAt ?? this.touchedAt,
  );

  /// Number of changes made in this session (shown on "Reset session data").
  int get count =>
      projects.length +
      tasks.length +
      taskOverrides.length +
      deletedTaskIds.length;
}

class SessionNotifier extends Notifier<SessionState> {
  int _sequence = 0;
  static const _historyLimit = 20;
  final List<_Entry> _history = [];

  @override
  SessionState build() => const SessionState();

  // ---- undo ----

  /// Whether there is an action to undo.
  bool get canUndo => _history.isNotEmpty;

  /// Reverts the latest change (add, edit or delete). Up to 20 steps. Signed in, the change is also undone on the
  /// server (an edit is patched back, a delete is restored, an added task is deleted).
  void undo() {
    if (_history.isEmpty) return;
    final entry = _history.removeLast();
    state = entry.before;
    final inverse = entry.inverse;
    if (inverse != null) _runLive(inverse);
  }

  void _remember({Future<void> Function()? inverse}) {
    _history.add(_Entry(state, inverse));
    if (_history.length > _historyLimit) _history.removeAt(0);
  }

  // ---- signed in: the same actions, also saved to the server ----

  /// True while the person is signed in and the workspace came from the server.
  bool get _isLive => ref.read(liveProvider) != null;

  LiveGateway get _gateway => ref.read(liveGatewayProvider);

  /// Runs a server call. A failure shows the message. Either way the server's version is then reloaded and
  /// [onDone] drops the local stand-in for the change, so the server's truth is what stays on screen.
  Future<void> _runLive(
    Future<void> Function() call, {
    void Function()? onDone,
  }) async {
    try {
      await call();
    } catch (e) {
      ref.read(liveErrorProvider.notifier).report(e);
    }
    await _gateway.refresh();
    onDone?.call();
  }

  /// Fields of [t] by the names the server uses, so an edit can be undone by sending the old values back.
  Map<String, Object?> _fieldsOf(Task t, Iterable<String> keys) => {
    for (final k in keys)
      k: switch (k) {
        'status' => t.status,
        'due' => t.due,
        'priority' => t.priority,
        'blocked' => t.blocked,
        'title' => t.title,
        'notes' => t.notes,
        'subtasks' => [
          for (final s in t.subtasks) {'text': s.text, 'done': s.done},
        ],
        _ => null,
      },
  };

  void _commit(SessionState next) {
    _remember();
    state = next;
  }

  // ---- task actions (all in memory) ----

  /// Looks the task up from the fixtures and this overlay directly. (Reading `workspaceDataProvider`
  /// here would make the session depend on a provider that depends on the session.)
  Task? _task(String id) {
    if (state.deletedTaskIds.contains(id)) return null;
    final override = state.taskOverrides[id];
    if (override != null) return override;
    final Fixtures base =
        ref.read(liveProvider)?.fixtures ?? ref.read(fixturesProvider);
    for (final t in [...base.data.tasks, ...state.tasks]) {
      if (t.id == id) return t;
    }
    return null;
  }

  bool _edit(
    String id,
    Task Function(Task) change, {
    Map<String, Object?>? patch,
  }) {
    final task = _task(id);
    if (task == null) return false;
    final edited = change(task);
    if (_isLive && patch != null) {
      final undo = _fieldsOf(task, patch.keys);
      _remember(inverse: () => _gateway.patchTask(id, undo));
      state = state.copyWith(
        taskOverrides: {...state.taskOverrides, id: edited},
        touchedId: id,
        touchedAt: DateTime.now(),
      );
      _runLive(
        () => _gateway.patchTask(id, patch),
        onDone: () {
          // Drop the stand-in, unless a newer edit has replaced it meanwhile.
          if (identical(state.taskOverrides[id], edited)) {
            state = state.copyWith(
              taskOverrides: {...state.taskOverrides}..remove(id),
            );
          }
        },
      );
      return true;
    }
    _commit(
      state.copyWith(
        taskOverrides: {...state.taskOverrides, id: edited},
        touchedId: id,
        touchedAt: DateTime.now(),
      ),
    );
    return true;
  }

  /// Sets "To do", "Doing" or "Done".
  bool setTaskStatus(String id, String status) => _edit(
    id,
    (t) => t.copyWith(status: status),
    patch: {'status': status},
  );

  /// Done becomes "To do" again; anything else becomes Done. Returns the new status, or null if the
  /// task does not exist.
  String? toggleComplete(String id) {
    final task = _task(id);
    if (task == null) return null;
    final next = task.status == 'Done' ? 'To do' : 'Done';
    setTaskStatus(id, next);
    return next;
  }

  /// Moves the due date (null clears it).
  bool rescheduleTask(String id, String? due) => _edit(
    id,
    (t) => due == null ? t.copyWith(clearDue: true) : t.copyWith(due: due),
    patch: {'due': due},
  );

  /// "normal" or "high".
  bool setTaskPriority(String id, String priority) => _edit(
    id,
    (t) => t.copyWith(priority: priority),
    patch: {'priority': priority},
  );

  bool setTaskBlocked(String id, bool blocked) => _edit(
    id,
    (t) => t.copyWith(blocked: blocked),
    patch: {'blocked': blocked},
  );

  bool editTask(String id, {String? title, String? notes}) => _edit(
    id,
    (t) => t.copyWith(title: title, notes: notes),
    patch: {
      'title': ?title,
      'notes': ?notes,
    },
  );

  bool toggleSubtask(String id, int index) {
    final task = _task(id);
    if (task == null || index < 0 || index >= task.subtasks.length) {
      return _edit(id, (t) => t);
    }
    final next = [
      for (var i = 0; i < task.subtasks.length; i++)
        i == index
            ? Subtask(task.subtasks[i].text, !task.subtasks[i].done)
            : task.subtasks[i],
    ];
    return _edit(
      id,
      (t) => t.copyWith(subtasks: next),
      patch: {
        'subtasks': [
          for (final s in next) {'text': s.text, 'done': s.done},
        ],
      },
    );
  }

  /// Deletes a task for this session. A sample task comes back on reset; a task added this session
  /// is gone for good.
  bool deleteTask(String id) {
    if (_task(id) == null) return false;
    final addedHere = state.tasks.any((t) => t.id == id);
    if (_isLive && !addedHere) {
      _remember(inverse: () => _gateway.restoreTask(id));
      state = state.copyWith(
        taskOverrides: {...state.taskOverrides}..remove(id),
        deletedTaskIds: {...state.deletedTaskIds, id},
      );
      _runLive(
        () => _gateway.deleteTask(id),
        onDone: () => state = state.copyWith(
          deletedTaskIds: {...state.deletedTaskIds}..remove(id),
        ),
      );
      return true;
    }
    _commit(
      state.copyWith(
        tasks: [
          for (final t in state.tasks)
            if (t.id != id) t,
        ],
        taskOverrides: {...state.taskOverrides}..remove(id),
        deletedTaskIds: addedHere
            ? state.deletedTaskIds
            : {...state.deletedTaskIds, id},
      ),
    );
    return true;
  }

  /// Adds a task for this session only and returns its id.
  String addTask({
    required String title,
    String projectId = 'project-garden',
    String priority = 'normal',
    String? due,
  }) {
    final id = 's-t${++_sequence}';
    final live = _isLive;
    String? serverId; // known once the server has saved the task, so Undo can delete it
    _remember(
      inverse: live
          ? () async {
              if (serverId != null) await _gateway.deleteTask(serverId!);
            }
          : null,
    );
    state = state.copyWith(
      tasks: [
        ...state.tasks,
        Task(
          id: id,
          projectId: projectId,
          title: title,
          priority: priority,
          due: due,
          session: true,
        ),
      ],
    );
    if (live) {
      _runLive(() async {
        try {
          final saved = await _gateway.createTask(
            projectId: projectId,
            title: title,
            priority: priority,
            due: due,
          );
          serverId = saved['id'] as String?;
        } finally {
          // Either way the temporary task goes: the refresh brings the saved one (or nothing, if it failed).
          state = state.copyWith(
            tasks: [
              for (final t in state.tasks)
                if (t.id != id) t,
            ],
          );
        }
      });
    }
    return id;
  }

  /// Adds a project (with starter milestones and tasks) for this session only and returns its id.
  String addProject({
    required String name,
    required String kind,
    required String category,
    required List<String> phases,
    String description = '',
    List<({String title, String due})> milestones = const [],
    List<String> taskTitles = const [],
  }) {
    final id = 's-p${++_sequence}';
    final project = Project(
      id: id,
      name: name,
      category: category,
      kind: kind,
      status: 'Planning',
      tone: 'pink',
      tags: const [],
      description: description,
      objective: '',
      start: '2026-11-12',
      end: '2027-02-12',
      updatedAt: '2026-11-12',
      lastOpenedAt: '2026-11-12T12:00:00',
      phases: phases,
      phaseIndex: 0,
      session: true,
    );
    final newMilestones = [
      for (final m in milestones)
        Milestone(
          id: 's-m${++_sequence}',
          projectId: id,
          title: m.title,
          description: '',
          start: '2026-11-12',
          due: m.due,
          phase: 0,
          session: true,
        ),
    ];
    final newTasks = [
      for (final t in taskTitles)
        Task(id: 's-t${++_sequence}', projectId: id, title: t, session: true),
    ];
    _remember();
    state = state.copyWith(
      projects: [...state.projects, project],
      milestones: [...state.milestones, ...newMilestones],
      tasks: [...state.tasks, ...newTasks],
    );
    return id;
  }

  void reset() {
    _history.clear();
    state = const SessionState();
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(
  SessionNotifier.new,
);

/// Fixed data plus session additions. Every screen and selector reads this one value.
final workspaceDataProvider = Provider<WorkspaceData>((ref) {
  final Fixtures source =
      ref.watch(liveProvider)?.fixtures ?? ref.watch(fixturesProvider);
  final base = source.data;
  final session = ref.watch(sessionProvider);
  return WorkspaceData(
    projects: [...base.projects, ...session.projects],
    milestones: [...base.milestones, ...session.milestones],
    tasks: [
      for (final t in [
        ...base.tasks.where((t) => !session.deletedTaskIds.contains(t.id)),
        ...session.tasks,
      ])
        session.taskOverrides[t.id] ?? t,
    ],
    requirements: base.requirements,
    files: base.files,
    changes: base.changes,
  );
});

final templatesProvider = Provider<List<ProjectTemplate>>((ref) {
  final Fixtures source =
      ref.watch(liveProvider)?.fixtures ?? ref.watch(fixturesProvider);
  return source.templates;
});

/// One step of Undo: the overlay as it was, and (signed in only) how to undo it on the server.
class _Entry {
  const _Entry(this.before, this.inverse);
  final SessionState before;
  final Future<void> Function()? inverse;
}
