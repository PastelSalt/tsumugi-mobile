import 'format.dart';
import 'models.dart';

// All derived numbers (counts, progress, states, gaps) are computed here so Home, Insights and the
// project page can never disagree. Port of the website `data/selectors.js`; selectors read a
// WorkspaceData and never mutate it.

/// Stable sort (Dart's List.sort is not stable; the website relies on stable ordering for ties).
List<T> stableSorted<T>(Iterable<T> items, int Function(T a, T b) compare) {
  final indexed = [
    for (var i = 0; i < items.length; i++) (i, items.elementAt(i)),
  ];
  indexed.sort((a, b) {
    final c = compare(a.$2, b.$2);
    return c != 0 ? c : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}

class Progress {
  const Progress(this.done, this.total);
  final int done;
  final int total;

  /// Whole-number percent, or null when there is nothing to count.
  int? get pct => total == 0 ? null : (done / total * 100).round();
}

class ProjectCounts {
  const ProjectCounts({
    required this.tasks,
    required this.milestones,
    required this.requirements,
    required this.files,
    required this.changes,
  });
  final int tasks;
  final int milestones;
  final int requirements;
  final int files;
  final int changes;
}

class TodayList {
  const TodayList({
    required this.overdue,
    required this.today,
    required this.doing,
    required this.doneToday,
  });
  final List<Task> overdue;
  final List<Task> today;
  final List<Task> doing;
  final List<Task> doneToday;
}

/// A task or milestone coming up, for "Up next" and Upcoming.
class UpNextItem {
  const UpNextItem.task(Task this.task) : milestone = null;
  const UpNextItem.milestone(Milestone this.milestone) : task = null;

  final Task? task;
  final Milestone? milestone;

  bool get isTask => task != null;
  String get id => task?.id ?? milestone!.id;
  String get title => task?.title ?? milestone!.title;
  String get projectId => task?.projectId ?? milestone!.projectId;
  String get due => task?.due ?? milestone!.due;
}

class Figures {
  const Figures({
    required this.dueToday,
    required this.overdue,
    required this.doing,
  });
  final int dueToday;
  final int overdue;
  final int doing;
}

class RecentItem {
  const RecentItem(this.type, this.id, this.title, this.at);
  final String type;
  final String id;
  final String title;
  final String at;
}

class RequirementLinks {
  const RequirementLinks({
    required this.tasks,
    required this.files,
    required this.changes,
    required this.milestone,
    required this.gapTask,
    required this.gapFile,
  });
  final List<Task> tasks;
  final List<WorkFile> files;
  final List<Change> changes;
  final Milestone? milestone;

  /// No task is linked yet.
  final bool gapTask;

  /// No final file is linked yet.
  final bool gapFile;
}

class Coverage {
  const Coverage(this.total, this.complete, this.withGaps);
  final int total;
  final int complete;
  final int withGaps;
}

class CriteriaProgress {
  const CriteriaProgress(this.met, this.total);
  final int met;
  final int total;
}

/// An overdue task or milestone ("Task" or "Milestone").
class OverdueItem {
  const OverdueItem(this.type, this.id, this.title, this.projectId, this.due);
  final String type;
  final String id;
  final String title;
  final String projectId;
  final String due;
}

int _byDue(Task a, Task b) => (a.due ?? '9999').compareTo(b.due ?? '9999');

bool isOpen(Task t) => t.status != 'Done';
bool isOverdue(Task t) =>
    isOpen(t) && t.due != null && t.due!.compareTo(demoToday) < 0;
bool dueSoon(Task t, {int days = 7}) {
  if (!isOpen(t) || t.due == null) return false;
  final d = daysFromToday(t.due!);
  return d >= 0 && d <= days;
}

String milestoneState(Milestone m) {
  if (m.done) return 'Done';
  if (m.due.compareTo(demoToday) < 0) return 'Overdue';
  if (m.start.compareTo(demoToday) <= 0) return 'Doing';
  return 'Upcoming';
}

/// A file is "final" when a document has status Final, or any other file is flagged final.
bool isFinalFile(WorkFile f) =>
    f.body != null ? f.status == 'Final' : f.isFinal;

CriteriaProgress criteriaProgress(Requirement r) => CriteriaProgress(
  r.acceptance.where((c) => c.met).length,
  r.acceptance.length,
);

extension Selectors on WorkspaceData {
  /* ---------- Lookups ---------- */
  Project? projectById(String id) => _first(projects, (p) => p.id == id);
  Milestone? milestoneById(String id) => _first(milestones, (m) => m.id == id);
  Task? taskById(String id) => _first(tasks, (t) => t.id == id);
  Requirement? requirementById(String id) =>
      _first(requirements, (r) => r.id == id);
  WorkFile? fileById(String id) => _first(files, (f) => f.id == id);
  Change? changeById(String id) => _first(changes, (c) => c.id == id);

  /// Record type ("Task", "Milestone", "Requirement", "File" or "Change") for an id, or null.
  String? recordTypeOf(String id) {
    if (taskById(id) != null) return 'Task';
    if (milestoneById(id) != null) return 'Milestone';
    if (requirementById(id) != null) return 'Requirement';
    if (fileById(id) != null) return 'File';
    if (changeById(id) != null) return 'Change';
    return null;
  }

  List<Project> get activeProjects => [
    for (final p in projects)
      if (!p.archived) p,
  ];

  /// Items of one project, or all of them when [projectId] is null or "all".
  List<T> scoped<T>(
    List<T> list,
    String? projectId,
    String Function(T) projectOf,
  ) => projectId == null || projectId == 'all'
      ? list
      : [
          for (final i in list)
            if (projectOf(i) == projectId) i,
        ];

  List<Task> tasksIn(String? projectId) =>
      scoped(tasks, projectId, (t) => t.projectId);
  List<Milestone> milestonesIn(String? projectId) =>
      scoped(milestones, projectId, (m) => m.projectId);
  List<Requirement> requirementsIn(String? projectId) =>
      scoped(requirements, projectId, (r) => r.projectId);
  List<WorkFile> filesIn(String? projectId) =>
      scoped(files, projectId, (f) => f.projectId);
  List<Change> changesIn(String? projectId) =>
      scoped(changes, projectId, (c) => c.projectId);

  /* ---------- Work ---------- */
  List<Task> tasksOfMilestone(String milestoneId) => [
    for (final t in tasks)
      if (t.milestoneId == milestoneId) t,
  ];

  Progress milestoneProgress(String milestoneId) {
    final list = tasksOfMilestone(milestoneId);
    return Progress(list.where((t) => t.status == 'Done').length, list.length);
  }

  Progress projectProgress(String projectId) {
    final list = tasks.where((t) => t.projectId == projectId).toList();
    return Progress(list.where((t) => t.status == 'Done').length, list.length);
  }

  /// "At risk" when any task of the project is overdue, otherwise "On track".
  String projectHealth(String projectId) =>
      tasks.any((t) => t.projectId == projectId && isOverdue(t))
      ? 'At risk'
      : 'On track';

  ProjectCounts projectCounts(String projectId) => ProjectCounts(
    tasks: tasks.where((i) => i.projectId == projectId).length,
    milestones: milestones.where((i) => i.projectId == projectId).length,
    requirements: requirements.where((i) => i.projectId == projectId).length,
    files: files.where((i) => i.projectId == projectId).length,
    changes: changes.where((i) => i.projectId == projectId).length,
  );

  Milestone? nextMilestone(String projectId) {
    final open = [
      for (final m in milestones)
        if (m.projectId == projectId && !m.done) m,
    ];
    final sorted = stableSorted(open, (a, b) => a.due.compareTo(b.due));
    return sorted.isEmpty ? null : sorted.first;
  }

  /* ---------- Home and Tasks horizons ---------- */
  TodayList todayList([String? projectId]) {
    final all = tasksIn(projectId);
    final open = all.where(isOpen).toList();
    return TodayList(
      overdue: stableSorted(open.where(isOverdue), _byDue),
      today: [
        for (final t in open)
          if (t.due == demoToday) t,
      ],
      doing: stableSorted(
        open.where(
          (t) =>
              t.status == 'Doing' &&
              (t.due == null || t.due!.compareTo(demoToday) > 0),
        ),
        _byDue,
      ),
      doneToday: [
        for (final t in all)
          if (t.status == 'Done' && t.due == demoToday) t,
      ],
    );
  }

  /// Tasks and milestones due after today, within [days], as one list sorted by due date.
  List<UpNextItem> upNext([int days = 7, String? projectId]) {
    bool within(String? due) {
      if (due == null) return false;
      final d = daysFromToday(due);
      return d > 0 && d <= days;
    }

    final items = <UpNextItem>[
      for (final t in tasksIn(projectId))
        if (isOpen(t) && within(t.due)) UpNextItem.task(t),
      for (final m in milestonesIn(projectId))
        if (!m.done && within(m.due)) UpNextItem.milestone(m),
    ];
    return stableSorted(items, (a, b) => a.due.compareTo(b.due));
  }

  Figures figures() {
    final open = tasks.where(isOpen).toList();
    return Figures(
      dueToday: open.where((t) => t.due == demoToday).length,
      overdue: open.where(isOverdue).length,
      doing: open.where((t) => t.status == 'Doing').length,
    );
  }

  List<Project> recentProjects([int limit = 4]) {
    final sorted = stableSorted(
      activeProjects,
      (a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt),
    );
    return sorted.take(limit).toList();
  }

  List<RecentItem> recents([int limit = 6]) {
    final items = [
      for (final p in activeProjects)
        RecentItem('Project', p.id, p.name, p.lastOpenedAt),
      for (final f in files)
        RecentItem('File', f.id, f.name, '${f.updatedAt}T00:00:00'),
      for (final c in changes) RecentItem('Change', c.id, c.summary, c.at),
    ];
    return stableSorted(
      items,
      (a, b) => b.at.compareTo(a.at),
    ).take(limit).toList();
  }

  /* ---------- Specs ---------- */
  RequirementLinks requirementLinks(Requirement req) {
    final linkedTasks = [
      for (final t in tasks)
        if (t.requirementIds.contains(req.id)) t,
    ];
    final linkedFiles = [
      for (final f in files)
        if (f.requirementIds.contains(req.id)) f,
    ];
    final linkedChanges = [
      for (final c in changes)
        if (c.requirementIds.contains(req.id)) c,
    ];
    return RequirementLinks(
      tasks: linkedTasks,
      files: linkedFiles,
      changes: linkedChanges,
      milestone: req.milestoneId == null
          ? null
          : milestoneById(req.milestoneId!),
      gapTask: linkedTasks.isEmpty,
      gapFile: !linkedFiles.any(isFinalFile),
    );
  }

  /// Complete means Met, verified, and not missing a task or a final file (website definition).
  Coverage coverage([String? projectId]) {
    final list = requirementsIn(projectId);
    final complete = list.where((r) => r.status == 'Met' && r.verified).length;
    final withGaps = list.where((r) {
      final l = requirementLinks(r);
      return l.gapTask || l.gapFile;
    }).length;
    return Coverage(list.length, complete, withGaps);
  }

  List<OverdueItem> overdueRecords([String? projectId]) => [
    for (final t in tasksIn(projectId))
      if (isOverdue(t)) OverdueItem('Task', t.id, t.title, t.projectId, t.due!),
    for (final m in milestonesIn(projectId))
      if (milestoneState(m) == 'Overdue')
        OverdueItem('Milestone', m.id, m.title, m.projectId, m.due),
  ];

  /* ---------- Links ---------- */

  /// In-app location of a record (website `recordHref`), expressed as a route path with query.
  String recordHref(String type, String id) {
    switch (type) {
      case 'Project':
        return '/projects/$id';
      case 'Task':
        return '/tasks?select=$id';
      case 'File':
        final f = fileById(id);
        if (f == null) return '/home';
        return f.body != null ? '/library?doc=$id' : '/library?select=$id';
      case 'Requirement':
        final r = requirementById(id);
        return r == null
            ? '/home'
            : '/projects/${r.projectId}?view=specs&select=$id';
      case 'Milestone':
        final m = milestoneById(id);
        return m == null
            ? '/home'
            : '/projects/${m.projectId}?view=work&select=$id';
      case 'Change':
        final c = changeById(id);
        return c == null
            ? '/home'
            : '/projects/${c.projectId}?view=history&select=$id';
    }
    return '/home';
  }

  String recordTitle(String type, String id) =>
      switch (type) {
        'Project' => projectById(id)?.name,
        'Task' => taskById(id)?.title,
        'Milestone' => milestoneById(id)?.title,
        'Requirement' => requirementById(id)?.title,
        'File' => fileById(id)?.name,
        'Change' => changeById(id)?.summary,
        _ => null,
      } ??
      id;
}

T? _first<T>(List<T> list, bool Function(T) test) {
  for (final item in list) {
    if (test(item)) return item;
  }
  return null;
}
