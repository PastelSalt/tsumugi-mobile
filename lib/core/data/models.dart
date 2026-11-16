// Immutable records for the individual workspace (website `data/fixtures.js`).
// One person owns everything: there are no users, assignees, owners, roles or access states.
// Dates are ISO strings ("2026-11-12" or "2026-11-12T10:42:00") exactly as in the website data,
// so string comparison orders them correctly.

List<String> _strings(Object? v) => [
  for (final e in (v as List? ?? const [])) e as String,
];

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.category,
    required this.kind,
    required this.status,
    required this.tone,
    required this.tags,
    required this.description,
    required this.objective,
    required this.start,
    required this.end,
    required this.updatedAt,
    required this.lastOpenedAt,
    required this.phases,
    required this.phaseIndex,
    this.archived = false,
    this.archivedAt,
    this.session = false,
  });

  final String id;
  final String name;
  final String category;
  final String kind;
  final String status;
  final String tone;
  final List<String> tags;
  final String description;
  final String objective;
  final String start;
  final String end;
  final String updatedAt;
  final String lastOpenedAt;
  final List<String> phases;
  final int phaseIndex;
  final bool archived;
  final String? archivedAt;
  final bool session;

  factory Project.fromJson(Map<String, dynamic> j) => Project(
    id: j['id'] as String,
    name: j['name'] as String,
    category: j['category'] as String,
    kind: j['kind'] as String,
    status: j['status'] as String,
    tone: j['tone'] as String,
    tags: _strings(j['tags']),
    description: j['description'] as String,
    objective: j['objective'] as String,
    start: j['start'] as String,
    end: j['end'] as String,
    updatedAt: j['updatedAt'] as String,
    lastOpenedAt: j['lastOpenedAt'] as String,
    phases: _strings(j['phases']),
    phaseIndex: j['phaseIndex'] as int,
    archived: j['archived'] as bool? ?? false,
    archivedAt: j['archivedAt'] as String?,
  );
}

class Milestone {
  const Milestone({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.start,
    required this.due,
    required this.phase,
    this.done = false,
    this.blocked = false,
    this.afterId,
    this.session = false,
  });

  final String id;
  final String projectId;
  final String title;
  final String description;
  final String start;
  final String due;
  final int phase;
  final bool done;
  final bool blocked;
  final String? afterId;
  final bool session;

  factory Milestone.fromJson(Map<String, dynamic> j) => Milestone(
    id: j['id'] as String,
    projectId: j['projectId'] as String,
    title: j['title'] as String,
    description: j['description'] as String,
    start: j['start'] as String,
    due: j['due'] as String,
    phase: j['phase'] as int,
    done: j['done'] as bool? ?? false,
    blocked: j['blocked'] as bool? ?? false,
    afterId: j['afterId'] as String?,
  );
}

class Subtask {
  const Subtask(this.text, this.done);
  final String text;
  final bool done;

  factory Subtask.fromJson(Map<String, dynamic> j) =>
      Subtask(j['text'] as String, j['done'] as bool);
}

class Task {
  const Task({
    required this.id,
    required this.projectId,
    required this.title,
    this.milestoneId,
    this.notes = '',
    this.status = 'To do',
    this.priority = 'normal',
    this.due,
    this.blocked = false,
    this.subtasks = const [],
    this.requirementIds = const [],
    this.fileIds = const [],
    this.changeIds = const [],
    this.session = false,
  });

  final String id;
  final String projectId;
  final String? milestoneId;
  final String title;
  final String notes;

  /// "To do", "Doing" or "Done".
  final String status;

  /// "normal" or "high".
  final String priority;
  final String? due;
  final bool blocked;
  final List<Subtask> subtasks;
  final List<String> requirementIds;
  final List<String> fileIds;
  final List<String> changeIds;
  final bool session;

  /// A copy with some fields changed. [due] and [milestoneId] can be cleared with [clearDue] and
  /// [clearMilestone] (passing null alone means "keep").
  Task copyWith({
    String? title,
    String? notes,
    String? status,
    String? priority,
    String? due,
    bool clearDue = false,
    String? milestoneId,
    bool clearMilestone = false,
    bool? blocked,
    List<Subtask>? subtasks,
  }) => Task(
    id: id,
    projectId: projectId,
    milestoneId: clearMilestone ? null : (milestoneId ?? this.milestoneId),
    title: title ?? this.title,
    notes: notes ?? this.notes,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    due: clearDue ? null : (due ?? this.due),
    blocked: blocked ?? this.blocked,
    subtasks: subtasks ?? this.subtasks,
    requirementIds: requirementIds,
    fileIds: fileIds,
    changeIds: changeIds,
    session: session,
  );

  factory Task.fromJson(Map<String, dynamic> j) => Task(
    id: j['id'] as String,
    projectId: j['projectId'] as String,
    milestoneId: j['milestoneId'] as String?,
    title: j['title'] as String,
    notes: j['notes'] as String? ?? '',
    status: j['status'] as String,
    priority: j['priority'] as String,
    due: j['due'] as String?,
    blocked: j['blocked'] as bool? ?? false,
    subtasks: [
      for (final s in (j['subtasks'] as List? ?? const []))
        Subtask.fromJson(s as Map<String, dynamic>),
    ],
    requirementIds: _strings(j['requirementIds']),
    fileIds: _strings(j['fileIds']),
    changeIds: _strings(j['changeIds']),
  );
}

class Criterion {
  const Criterion(this.text, this.met);
  final String text;
  final bool met;

  factory Criterion.fromJson(Map<String, dynamic> j) =>
      Criterion(j['text'] as String, j['met'] as bool);
}

class Requirement {
  const Requirement({
    required this.id,
    this.key,
    required this.projectId,
    required this.title,
    required this.type,
    required this.status,
    required this.verified,
    required this.description,
    required this.acceptance,
    this.milestoneId,
  });

  final String id;

  /// The readable label ("REQ-001") the server gives each requirement. The sample data has none; its `id` is already
  /// readable. Show [label].
  final String? key;
  final String projectId;
  final String title;

  /// "Functional" or "Non-functional".
  final String type;

  /// "Open" or "Met".
  final String status;
  final bool verified;
  final String? milestoneId;
  final String description;
  final List<Criterion> acceptance;

  /// What people read: the server key, or the sample data's id.
  String get label => key ?? id;

  factory Requirement.fromJson(Map<String, dynamic> j) => Requirement(
    id: j['id'] as String,
    key: j['key'] as String?,
    projectId: j['projectId'] as String,
    title: j['title'] as String,
    type: j['type'] as String,
    status: j['status'] as String,
    verified: j['verified'] as bool,
    milestoneId: j['milestoneId'] as String?,
    description: j['description'] as String,
    acceptance: [
      for (final c in (j['acceptance'] as List? ?? const []))
        Criterion.fromJson(c as Map<String, dynamic>),
    ],
  );
}

/// Assets and documents merged (the website's "File"). Markdown documents carry a [body].
class WorkFile {
  const WorkFile({
    required this.id,
    required this.projectId,
    required this.name,
    required this.kind,
    required this.ext,
    required this.bytes,
    required this.tags,
    required this.updatedAt,
    required this.description,
    this.requirementIds = const [],
    this.taskIds = const [],
    this.milestoneId,
    this.isFinal = false,
    this.progress,
    this.host,
    this.status,
    this.version,
    this.body,
  });

  final String id;
  final String projectId;
  final String name;

  /// document, image, media, data or link.
  final String kind;
  final String ext;
  final int bytes;
  final List<String> tags;
  final String updatedAt;
  final String description;
  final List<String> requirementIds;
  final List<String> taskIds;
  final String? milestoneId;
  final bool isFinal;

  /// Upload progress in percent for a file still being added (sample only).
  final int? progress;
  final String? host;

  /// "Draft" or "Final" (documents only).
  final String? status;
  final int? version;
  final String? body;

  factory WorkFile.fromJson(Map<String, dynamic> j) => WorkFile(
    id: j['id'] as String,
    projectId: j['projectId'] as String,
    name: j['name'] as String,
    kind: j['kind'] as String,
    ext: j['ext'] as String,
    bytes: j['bytes'] as int,
    tags: _strings(j['tags']),
    updatedAt: j['updatedAt'] as String,
    description: j['description'] as String,
    requirementIds: _strings(j['requirementIds']),
    taskIds: _strings(j['taskIds']),
    milestoneId: j['milestoneId'] as String?,
    isFinal: j['isFinal'] as bool? ?? false,
    progress: j['progress'] as int?,
    host: j['host'] as String?,
    status: j['status'] as String?,
    version: j['version'] as int?,
    body: j['body'] as String?,
  );
}

class DiffLine {
  const DiffLine(this.mark, this.text);

  /// "=" unchanged, "+" added, "-" removed.
  final String mark;
  final String text;

  factory DiffLine.fromJson(Map<String, dynamic> j) =>
      DiffLine(j['mark'] as String, j['text'] as String);
}

class Change {
  const Change({
    required this.id,
    required this.projectId,
    required this.at,
    required this.summary,
    required this.recordType,
    required this.recordId,
    required this.reviewed,
    this.requirementIds = const [],
    this.taskIds = const [],
    this.fromVersion,
    this.toVersion,
    this.diff,
  });

  final String id;
  final String projectId;
  final String at;
  final String summary;

  /// File, Task, Requirement or Milestone.
  final String recordType;
  final String recordId;
  final bool reviewed;
  final List<String> requirementIds;
  final List<String> taskIds;
  final int? fromVersion;
  final int? toVersion;
  final List<DiffLine>? diff;

  factory Change.fromJson(Map<String, dynamic> j) => Change(
    id: j['id'] as String,
    projectId: j['projectId'] as String,
    at: j['at'] as String,
    summary: j['summary'] as String,
    recordType: j['recordType'] as String,
    recordId: j['recordId'] as String,
    reviewed: j['reviewed'] as bool,
    requirementIds: _strings(j['requirementIds']),
    taskIds: _strings(j['taskIds']),
    fromVersion: j['fromVersion'] as int?,
    toVersion: j['toVersion'] as int?,
    diff: j['diff'] == null
        ? null
        : [
            for (final d in j['diff'] as List)
              DiffLine.fromJson(d as Map<String, dynamic>),
          ],
  );
}

class ProjectTemplate {
  const ProjectTemplate({
    required this.kind,
    required this.label,
    required this.category,
    required this.text,
    required this.phases,
    required this.milestone,
    required this.tasks,
  });

  final String kind;
  final String label;
  final String category;
  final String text;
  final List<String> phases;
  final String? milestone;
  final List<String> tasks;

  factory ProjectTemplate.fromJson(Map<String, dynamic> j) => ProjectTemplate(
    kind: j['kind'] as String,
    label: j['label'] as String,
    category: j['category'] as String,
    text: j['text'] as String,
    phases: _strings(j['phases']),
    milestone: j['milestone'] as String?,
    tasks: _strings(j['tasks']),
  );
}

/// Everything the workspace shows: the fixed sample data plus anything added during the session.
class WorkspaceData {
  const WorkspaceData({
    required this.projects,
    required this.milestones,
    required this.tasks,
    required this.requirements,
    required this.files,
    required this.changes,
  });

  final List<Project> projects;
  final List<Milestone> milestones;
  final List<Task> tasks;
  final List<Requirement> requirements;
  final List<WorkFile> files;
  final List<Change> changes;
}

class Fixtures {
  const Fixtures({required this.data, required this.templates});

  final WorkspaceData data;
  final List<ProjectTemplate> templates;

  /// The signed-in workspace from `GET /workspace/snapshot` plus `GET /templates` (the snapshot has no
  /// templates). The snapshot's `today` and `now` are read separately by the live store.
  factory Fixtures.fromApi(
    Map<String, dynamic> snapshot,
    List<Map<String, dynamic>> templates,
  ) => Fixtures.fromJson({...snapshot, 'templates': templates});

  factory Fixtures.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) f) => [
      for (final e in j[key] as List) f(e as Map<String, dynamic>),
    ];
    return Fixtures(
      data: WorkspaceData(
        projects: list('projects', Project.fromJson),
        milestones: list('milestones', Milestone.fromJson),
        tasks: list('tasks', Task.fromJson),
        requirements: list('requirements', Requirement.fromJson),
        files: list('files', WorkFile.fromJson),
        changes: list('changes', Change.fromJson),
      ),
      templates: list('templates', ProjectTemplate.fromJson),
    );
  }
}
