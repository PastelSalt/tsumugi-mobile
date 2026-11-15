import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final List<SessionState> _history = [];

  @override
  SessionState build() => const SessionState();

  // ---- undo ----

  /// Whether there is an action to undo.
  bool get canUndo => _history.isNotEmpty;

  /// Reverts the latest change (add, edit or delete). Up to 20 steps.
  void undo() {
    if (_history.isEmpty) return;
    state = _history.removeLast();
  }

  void _remember() {
    _history.add(state);
    if (_history.length > _historyLimit) _history.removeAt(0);
  }

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
    for (final t in [
      ...ref.read(fixturesProvider).data.tasks,
      ...state.tasks,
    ]) {
      if (t.id == id) return t;
    }
    return null;
  }

  bool _edit(String id, Task Function(Task) change) {
    final task = _task(id);
    if (task == null) return false;
    _commit(
      state.copyWith(
        taskOverrides: {...state.taskOverrides, id: change(task)},
        touchedId: id,
        touchedAt: DateTime.now(),
      ),
    );
    return true;
  }

  /// Sets "To do", "Doing" or "Done".
  bool setTaskStatus(String id, String status) =>
      _edit(id, (t) => t.copyWith(status: status));

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
  );

  /// "normal" or "high".
  bool setTaskPriority(String id, String priority) =>
      _edit(id, (t) => t.copyWith(priority: priority));

  bool setTaskBlocked(String id, bool blocked) =>
      _edit(id, (t) => t.copyWith(blocked: blocked));

  bool editTask(String id, {String? title, String? notes}) =>
      _edit(id, (t) => t.copyWith(title: title, notes: notes));

  bool toggleSubtask(String id, int index) => _edit(id, (t) {
    if (index < 0 || index >= t.subtasks.length) return t;
    return t.copyWith(
      subtasks: [
        for (var i = 0; i < t.subtasks.length; i++)
          i == index
              ? Subtask(t.subtasks[i].text, !t.subtasks[i].done)
              : t.subtasks[i],
      ],
    );
  });

  /// Deletes a task for this session. A sample task comes back on reset; a task added this session
  /// is gone for good.
  bool deleteTask(String id) {
    if (_task(id) == null) return false;
    final addedHere = state.tasks.any((t) => t.id == id);
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
    _remember();
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
  final base = ref.watch(fixturesProvider).data;
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

final templatesProvider = Provider<List<ProjectTemplate>>(
  (ref) => ref.watch(fixturesProvider).templates,
);
