import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/query_params.dart';
import '../../app/sheet_selection.dart';
import '../../core/data/format.dart';
import '../../core/data/models.dart';
import '../../core/data/selectors.dart';
import '../../core/data/status.dart';
import '../../core/data/workspace_store.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/badges.dart';
import '../../app/shell/shell_actions.dart';
import '../../shared/widgets/diff_view.dart';
import '../../shared/widgets/large_title_scaffold.dart';
import '../../shared/widgets/layout.dart';
import '../../shared/widgets/phase_stepper.dart';
import '../../shared/widgets/preview_sheet.dart';
import '../../shared/widgets/record_sheets.dart';
import '../../shared/widgets/records.dart';
import '../../shared/widgets/task_tile.dart';
import '../../shared/widgets/states.dart';
import '../../shared/widgets/timeline.dart';

/// Project page: Overview, Work, Specs, Files and History (website `ProjectPage`, PLAN-A-04C to 04I).
/// Query: `view` (overview|work|specs|files|history), `select` (a record id), `mode`
/// (work: groups|timeline, history: feed|compare), `rev` (change id for the comparison).
class ProjectScreen extends ConsumerStatefulWidget {
  const ProjectScreen({
    super.key,
    required this.projectId,
    required this.params,
  });

  final String projectId;
  final Map<String, String> params;

  @override
  ConsumerState<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends ConsumerState<ProjectScreen>
    with SheetSelection<ProjectScreen> {
  @override
  Map<String, String> get routeParams => widget.params;

  @override
  String sheetTypeFor(String id) {
    final d = ref.read(workspaceDataProvider);
    if (d.taskById(id) != null) return 'Task';
    if (d.milestoneById(id) != null) return 'Milestone';
    if (d.requirementById(id) != null) return 'Requirement';
    if (d.fileById(id) != null) return 'File';
    if (d.changeById(id) != null) return 'Change';
    return 'Unknown';
  }

  @override
  void initState() {
    super.initState();
    syncSelection();
  }

  @override
  void didUpdateWidget(ProjectScreen old) {
    super.didUpdateWidget(old);
    syncSelection();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(workspaceDataProvider);
    final project = data.projectById(widget.projectId);
    final back = TextButton.icon(
      onPressed: () =>
          context.canPop() ? context.pop() : context.go('/projects'),
      icon: const Icon(LucideIcons.chevronLeft, size: 16),
      label: const Text('Projects'),
    );
    if (project == null) {
      return ListView(
        padding: const EdgeInsets.all(AppTokens.pageGutter),
        children: [
          Align(alignment: Alignment.centerLeft, child: back),
          const PageHeader(title: 'Project not found'),
          EmptyState(
            title: 'We couldn’t find that project',
            body: 'It may have been removed, or the link is wrong.',
            action: OutlinedButton(
              onPressed: () => context.go('/projects'),
              child: const Text('Back to Projects'),
            ),
          ),
        ],
      );
    }

    final view = widget.params['view'] ?? 'overview';
    final counts = data.projectCounts(project.id);
    final tabs = [
      const TabItem('overview', 'Overview'),
      TabItem('work', 'Work', count: counts.tasks),
      TabItem('specs', 'Specs', count: counts.requirements),
      TabItem('files', 'Files', count: counts.files),
      TabItem('history', 'History', count: counts.changes),
    ];
    return LargeTitleScaffold(
      title: project.name,
      restorationId: 'project-${project.id}-scroll',
      expandedHeight: 96,
      leading: IconButton(
        tooltip: 'Back to Projects',
        onPressed: () =>
            context.canPop() ? context.pop() : context.go('/projects'),
        icon: const Icon(LucideIcons.chevronLeft),
      ),
      actions: shellActions(context),
      pinnedHeader: ViewTabs(
        tabs: tabs,
        value: tabs.any((t) => t.id == view) ? view : 'overview',
        margin: EdgeInsets.zero,
        onChanged: (v) => context.setQueryParams({
          'view': v == 'overview' ? null : v,
          'select': null,
          'mode': null,
          'rev': null,
        }),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.pageGutter,
            AppTokens.space3,
            AppTokens.pageGutter,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppTokens.space2,
                  runSpacing: AppTokens.space2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(
                      StatusDomain.project,
                      project.archived ? 'Archived' : project.status,
                    ),
                    if (project.status == 'Active')
                      StatusBadge(
                        StatusDomain.health,
                        data.projectHealth(project.id),
                      ),
                    const PreviewAction(
                      label: 'Edit project',
                      quiet: true,
                      icon: LucideIcons.pencil,
                    ),
                  ],
                ),
                if (project.description.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.space2),
                  Text(
                    project.description,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: context.tokens.onSurfaceMuted),
                  ),
                ],
                if (project.session)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTokens.space2),
                    child: Text(
                      'Created for this session only. It disappears when you restart the app.',
                      style: TextStyle(
                        color: context.tokens.muted,
                        fontSize: AppTokens.textMeta,
                      ),
                    ),
                  ),
                const SizedBox(height: AppTokens.space4),
                StateGate(
                  empty: const EmptyState(
                    title: 'Nothing here yet',
                    body: 'Add the first record to get started.',
                  ),
                  child: switch (view) {
                    'work' => _Work(
                      project: project,
                      data: data,
                      params: widget.params,
                      onSelect: select,
                    ),
                    'specs' => _Specs(
                      project: project,
                      data: data,
                      onSelect: select,
                    ),
                    'files' => _Files(
                      project: project,
                      data: data,
                      onSelect: select,
                    ),
                    'history' => _History(
                      project: project,
                      data: data,
                      params: widget.params,
                      onSelect: select,
                    ),
                    _ => _Overview(project: project, data: data),
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.project, required this.data});

  final Project project;
  final WorkspaceData data;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final progress = data.projectProgress(project.id);
    final next = data.nextMilestone(project.id);
    final cov = data.coverage(project.id);
    final counts = data.projectCounts(project.id);
    final recent = stableSorted(
      data.changesIn(project.id),
      (a, b) => b.at.compareTo(a.at),
    ).take(3).toList();
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // One progress statement first; the numbers that used to be three boxes are one quiet line.
        Text(
          '${progress.done} of ${progress.total} tasks done',
          style: text.headlineSmall,
        ),
        const SizedBox(height: AppTokens.space2),
        TsProgressBar(
          value: progress.done,
          max: progress.total,
          label: 'Tasks done',
          showCount: false,
        ),
        const SizedBox(height: AppTokens.space2),
        Text(
          'Requirements ${cov.complete}/${cov.total} · ${counts.files} files',
          style: text.bodyMedium?.copyWith(color: t.onSurfaceMuted),
        ),
        const SizedBox(height: AppTokens.space5),
        Section(
          title: 'Next milestone',
          child: next == null
              ? Text('No open milestones.', style: TextStyle(color: t.muted))
              : RowCard(
                  onTap: () => showRecordSheet(context, 'Milestone', next.id),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(next.title, style: text.titleSmall),
                            Text(
                              next.description,
                              style: TextStyle(
                                fontSize: AppTokens.textMeta,
                                color: t.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(child: DueLabel(due: next.due)),
                    ],
                  ),
                ),
        ),
        Section(
          title: 'Phase',
          child: PhaseStepper(
            phases: project.phases,
            currentIndex: project.phaseIndex,
          ),
        ),
        Section(
          title: 'Recent changes',
          action: TextButton(
            onPressed: () => context.setQueryParams({'view': 'history'}),
            child: const Text('All history'),
          ),
          child: recent.isEmpty
              ? Text(
                  'No changes recorded yet.',
                  style: TextStyle(color: t.muted),
                )
              : Column(
                  children: [
                    for (var i = 0; i < recent.length; i++)
                      ChangeEntry(
                        change: recent[i],
                        last: i == recent.length - 1,
                        onTap: () => context.setQueryParams({
                          'view': 'history',
                          'select': recent[i].id,
                        }),
                      ),
                  ],
                ),
        ),
        // Reference details last and quiet.
        Section(
          title: 'About',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.objective,
                style: text.bodyMedium?.copyWith(color: t.onSurfaceMuted),
              ),
              const SizedBox(height: AppTokens.space2),
              Fields(
                items: [
                  (
                    'Dates',
                    Text(
                      '${formatDate(project.start)} – ${formatDate(project.end)}',
                    ),
                  ),
                  ('Category', Text(project.category)),
                  (
                    'Tags',
                    project.tags.isEmpty ? null : Text(project.tags.join(', ')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Work extends StatelessWidget {
  const _Work({
    required this.project,
    required this.data,
    required this.params,
    required this.onSelect,
  });

  final Project project;
  final WorkspaceData data;
  final Map<String, String> params;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final mode = params['mode'] ?? 'groups';
    final milestones = stableSorted(
      data.milestonesIn(project.id),
      (a, b) => a.due.compareTo(b.due),
    );
    final loose = [
      for (final t in data.tasks)
        if (t.projectId == project.id && t.milestoneId == null) t,
    ];
    final select = params['select'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedToggle(
          label: 'Layout',
          value: mode,
          onChanged: (v) =>
              context.setQueryParams({'mode': v == 'groups' ? null : v}),
          options: const [('groups', 'Groups'), ('timeline', 'Timeline')],
        ),
        const SizedBox(height: AppTokens.space4),
        if (milestones.isEmpty && loose.isEmpty)
          const EmptyState(
            title: 'No work yet',
            body: 'Tap + to add a task to this project.',
          )
        else if (mode == 'timeline')
          TimelineList(
            milestones: milestones,
            projectName: (_) => project.name,
            selectedId: select,
            onSelect: onSelect,
          )
        else
          Column(
            spacing: AppTokens.space3,
            children: [
              for (final m in milestones)
                MilestoneGroup(
                  milestone: m,
                  tasks: data.tasksOfMilestone(m.id),
                  selectedId: select,
                  onSelectTask: onSelect,
                  onSelectMilestone: onSelect,
                ),
              if (loose.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No milestone',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTokens.space2),
                    Column(
                      spacing: AppTokens.space2,
                      children: [
                        for (final t in loose)
                          TaskTile(
                            task: t,
                            selected: select == t.id,
                            onTap: () => onSelect(t.id),
                          ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
      ],
    );
  }
}

class _Specs extends StatelessWidget {
  const _Specs({
    required this.project,
    required this.data,
    required this.onSelect,
  });

  final Project project;
  final WorkspaceData data;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final list = data.requirementsIn(project.id);
    if (list.isEmpty) {
      return const EmptyState(
        title: 'No requirements yet',
        body: 'Requirements say what must be true when the project is done.',
        action: PreviewAction(label: 'Add requirement', primary: true),
      );
    }
    return Column(
      spacing: AppTokens.space2,
      children: [
        for (final r in list)
          RequirementRow(requirement: r, onTap: () => onSelect(r.id)),
      ],
    );
  }
}

class _Files extends StatelessWidget {
  const _Files({
    required this.project,
    required this.data,
    required this.onSelect,
  });

  final Project project;
  final WorkspaceData data;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final list = data.filesIn(project.id);
    if (list.isEmpty) {
      return const EmptyState(
        title: 'No files yet',
        body: 'Notes, drafts, and references for this project appear here.',
        action: PreviewAction(label: 'Add file', primary: true),
      );
    }
    return FileGrid(files: list, onSelect: onSelect);
  }
}

/// Two-column grid of file tiles (project Files and Library grid layout).
class FileGrid extends StatelessWidget {
  const FileGrid({
    super.key,
    required this.files,
    required this.onSelect,
    this.selectedId,
  });

  final List<WorkFile> files;
  final ValueChanged<String> onSelect;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final left = <WorkFile>[];
    final right = <WorkFile>[];
    for (var i = 0; i < files.length; i++) {
      (i.isEven ? left : right).add(files[i]);
    }
    Widget column(List<WorkFile> items) => Expanded(
      child: Column(
        spacing: AppTokens.space2,
        children: [
          for (final f in items)
            FileTile(
              file: f,
              selected: selectedId == f.id,
              onTap: () => onSelect(f.id),
            ),
        ],
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppTokens.space2,
      children: [column(left), column(right)],
    );
  }
}

class _History extends StatelessWidget {
  const _History({
    required this.project,
    required this.data,
    required this.params,
    required this.onSelect,
  });

  final Project project;
  final WorkspaceData data;
  final Map<String, String> params;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final rev = params['rev'];
    final compare = params['mode'] == 'compare' && rev != null
        ? data.changeById(rev)
        : null;
    if (compare?.diff != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () =>
                context.setQueryParams({'mode': null, 'rev': null}),
            icon: const Icon(LucideIcons.chevronLeft, size: 16),
            label: const Text('Back to history'),
          ),
          DiffView(change: compare!),
        ],
      );
    }
    final list = stableSorted(
      data.changesIn(project.id),
      (a, b) => b.at.compareTo(a.at),
    );
    if (list.isEmpty) {
      return const EmptyState(
        title: 'No history yet',
        body: 'Changes to records and documents are listed here as you make them.',
      );
    }
    final groups = <(String, List<Change>)>[];
    for (final c in list) {
      final key = dayGroup(c.at);
      if (groups.isNotEmpty && groups.last.$1 == key) {
        groups.last.$2.add(c);
      } else {
        groups.add((key, [c]));
      }
    }
    final select = params['select'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, items) in groups)
          Section(
            title: label,
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  ChangeEntry(
                    change: items[i],
                    selected: select == items[i].id,
                    last: i == items.length - 1,
                    onTap: () => onSelect(items[i].id),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
