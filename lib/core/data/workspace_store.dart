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

/// Records added during this run (Quick add, templates). Nothing is persisted: it all disappears
/// when the app restarts, and every such record carries `session: true`.
class SessionState {
  const SessionState({
    this.projects = const [],
    this.milestones = const [],
    this.tasks = const [],
  });

  final List<Project> projects;
  final List<Milestone> milestones;
  final List<Task> tasks;

  int get count => projects.length + tasks.length;
}

class SessionNotifier extends Notifier<SessionState> {
  int _sequence = 0;

  @override
  SessionState build() => const SessionState();

  /// Adds a task for this session only and returns its id.
  String addTask({
    required String title,
    String projectId = 'project-garden',
    String priority = 'normal',
    String? due,
  }) {
    final id = 's-t${++_sequence}';
    state = SessionState(
      projects: state.projects,
      milestones: state.milestones,
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
    state = SessionState(
      projects: [...state.projects, project],
      milestones: [...state.milestones, ...newMilestones],
      tasks: [...state.tasks, ...newTasks],
    );
    return id;
  }

  void reset() => state = const SessionState();
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
    tasks: [...base.tasks, ...session.tasks],
    requirements: base.requirements,
    files: base.files,
    changes: base.changes,
  );
});

final templatesProvider = Provider<List<ProjectTemplate>>(
  (ref) => ref.watch(fixturesProvider).templates,
);
