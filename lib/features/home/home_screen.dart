import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/format.dart';
import '../../core/data/models.dart';
import '../../core/data/selectors.dart';
import '../../core/data/status.dart';
import '../../core/data/workspace_store.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/layout.dart';
import '../../shared/widgets/record_sheets.dart';
import '../../shared/widgets/records.dart';
import '../../shared/widgets/task_tile.dart';
import '../../shared/widgets/states.dart';
import '../projects/new_project_sheet.dart';
import '../quickadd/quick_add_sheet.dart';

/// Home: what to do now, a glance at the numbers, and where to continue
/// (docs/PLAN-MOBILE-UI.md 6.1; website `HomePage`, PLAN-A-04A).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(workspaceDataProvider);
    return RefreshIndicator(
      // Demo: the sample data is local, so a short pause is all a refresh needs.
      onRefresh: () => Future<void>.delayed(const Duration(milliseconds: 450)),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTokens.pageGutter),
        children: [
          const PageHeader(
            title: 'Home',
            description: 'What needs you today, and what is coming next.',
          ),
          StateGate(
            empty: const FirstRun(),
            child: data.projects.isEmpty
                ? const FirstRun()
                : _HomeBody(data: data),
          ),
        ],
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.data});

  final WorkspaceData data;

  @override
  Widget build(BuildContext context) {
    final today = data.todayList();
    final f = data.figures();
    final focus = [...today.overdue, ...today.today, ...today.doing];
    final upcoming = data.upNext(7).take(5).toList();
    final recent = data.recentProjects(4);
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // At a glance: compact chips that open the matching list.
        Semantics(
          label: 'At a glance',
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: AppTokens.space5),
            child: Row(
              spacing: AppTokens.space2,
              children: [
                _GlanceChip(
                  value: '${f.dueToday}',
                  label: 'Due today',
                  onTap: () => context.go('/tasks'),
                ),
                _GlanceChip(
                  value: '${f.overdue}',
                  label: 'Overdue',
                  hint: f.overdue > 0 ? 'Needs a look' : null,
                  warn: f.overdue > 0,
                  onTap: () => context.go('/tasks'),
                ),
                _GlanceChip(
                  value: '${f.doing}',
                  label: 'In progress',
                  onTap: () => context.go('/tasks'),
                ),
                _GlanceChip(
                  value: '',
                  label: 'Insights',
                  icon: LucideIcons.chartNoAxesColumn,
                  onTap: () => context.push('/insights'),
                ),
              ],
            ),
          ),
        ),
        Section(
          title: 'Up now',
          action: TextButton(
            onPressed: () => context.go('/tasks'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    focus.length > 3
                        ? 'All tasks (${focus.length})'
                        : 'All tasks',
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(LucideIcons.arrowRight, size: 14),
              ],
            ),
          ),
          child: focus.isEmpty
              ? EmptyState(
                  title: 'Nothing due today',
                  body: 'Enjoy the quiet, or pull something forward from Up next.',
                  action: OutlinedButton(
                    onPressed: () => showQuickAddSheet(context),
                    child: const Text('Add a task'),
                  ),
                )
              : Column(
                  children: [
                    for (final task in focus.take(3))
                      TaskTile(task: task, showProject: true),
                  ],
                ),
        ),
        if (recent.isNotEmpty)
          Section(
            title: 'Continue',
            child: _ContinueCard(data: data, project: recent.first),
          ),
        Section(
          title: 'Up next',
          child: upcoming.isEmpty
              ? Text(
                  'Nothing due in the next seven days.',
                  style: TextStyle(color: t.muted),
                )
              : Column(
                  spacing: AppTokens.space2,
                  children: [
                    for (final item in upcoming)
                      _UpNextRow(item: item, data: data),
                  ],
                ),
        ),
        Section(
          title: 'Your projects',
          action: TextButton(
            onPressed: () => showNewProjectSheet(context),
            child: const Text('New project'),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppTokens.space2,
                children: [
                  for (final p in recent)
                    SizedBox(
                      width: 240,
                      child: RowCard(
                        onTap: () => context.go('/projects/${p.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            StatusBadge(StatusDomain.project, p.status),
                            const Spacer(),
                            const SizedBox(height: 8),
                            TsProgressBar(
                              value: data.projectProgress(p.id).done,
                              max: data.projectProgress(p.id).total,
                              label: '${p.name} progress',
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Section(
          title: 'Recent',
          child: Column(
            spacing: AppTokens.space2,
            children: [
              for (final item in data.recents(5)) _RecentRow(item: item),
            ],
          ),
        ),
      ],
    );
  }
}

/// A figure on Home that opens the matching list. 48 dp tall.
class _GlanceChip extends StatelessWidget {
  const _GlanceChip({
    required this.value,
    required this.label,
    required this.onTap,
    this.hint,
    this.warn = false,
    this.icon,
  });

  final String value;
  final String label;
  final String? hint;
  final bool warn;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: value.isEmpty ? label : '$label: $value',
      excludeSemantics: true,
      child: Material(
        color: warn ? t.dangerContainer : t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          side: BorderSide(color: warn ? t.danger : t.controlBorder),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 64,
              minWidth: AppTokens.minTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space3,
                vertical: AppTokens.space2,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null)
                    Icon(icon, size: 22)
                  else
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: AppTokens.textMeta,
                      color: t.onSurfaceMuted,
                    ),
                  ),
                  if (hint != null)
                    Text(
                      hint!,
                      style: TextStyle(
                        fontSize: AppTokens.textMeta,
                        color: t.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The most recently opened project with its next milestone and progress.
class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.data, required this.project});

  final WorkspaceData data;
  final Project project;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final next = data.nextMilestone(project.id);
    final progress = data.projectProgress(project.id);
    return RowCard(
      onTap: () => context.go('/projects/${project.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusBadge(StatusDomain.project, project.status),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: 4),
            Text(
              'Next: ${next.title} · ${formatDate(next.due)}',
              style: TextStyle(
                fontSize: AppTokens.textMeta,
                color: t.onSurfaceMuted,
              ),
            ),
          ],
          const SizedBox(height: AppTokens.space2),
          TsProgressBar(
            value: progress.done,
            max: progress.total,
            label: '${project.name} progress',
          ),
        ],
      ),
    );
  }
}

class _UpNextRow extends StatelessWidget {
  const _UpNextRow({required this.item, required this.data});

  final UpNextItem item;
  final WorkspaceData data;

  @override
  Widget build(BuildContext context) {
    final project = data.projectById(item.projectId);
    final muted = TextStyle(
      fontSize: AppTokens.textMeta,
      color: context.tokens.muted,
    );
    return RowCard(
      onTap: () =>
          showRecordSheet(context, item.isTask ? 'Task' : 'Milestone', item.id),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Wrap(
                  spacing: AppTokens.space2,
                  children: [
                    Text(item.isTask ? 'Task' : 'Milestone', style: muted),
                    Text(project?.name ?? '', style: muted),
                  ],
                ),
              ],
            ),
          ),
          Flexible(child: DueLabel(due: item.due)),
        ],
      ),
    );
  }
}

class _RecentRow extends ConsumerWidget {
  const _RecentRow({required this.item});

  final RecentItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = TextStyle(
      fontSize: AppTokens.textMeta,
      color: context.tokens.muted,
    );
    return RowCard(
      onTap: () => openRecord(context, item.type, item.id),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(item.type, style: muted),
              ],
            ),
          ),
          Text(timeAgo(item.at), style: muted),
        ],
      ),
    );
  }
}

/// First run: no projects yet. Three small steps, any of which can be skipped.
class FirstRun extends StatefulWidget {
  const FirstRun({super.key});

  @override
  State<FirstRun> createState() => _FirstRunState();
}

class _FirstRunState extends State<FirstRun> {
  final _done = <int>{};

  static const _steps = [
    (
      'Create a project',
      'Start from a template so the first steps are filled in.',
    ),
    ('Add a task', 'Tap the + button anywhere. One line is enough.'),
    ('Open the Library', 'Keep notes and files next to the work.'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final actions = <VoidCallback>[
      () => showNewProjectSheet(context),
      () => showQuickAddSheet(context),
      () => context.go('/library'),
    ];
    return Column(
      children: [
        EmptyState(
          title: 'Welcome. Nothing here yet.',
          body: 'Three small steps get you started. Skip any of them.',
          action: FilledButton(
            onPressed: () => showNewProjectSheet(context),
            child: const Text('New project'),
          ),
        ),
        const SizedBox(height: AppTokens.space3),
        for (var i = 0; i < _steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space2),
            child: RowCard(
              child: Row(
                children: [
                  Semantics(
                    label: 'Mark "${_steps[i].$1}" done',
                    checked: _done.contains(i),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(
                        () =>
                            _done.contains(i) ? _done.remove(i) : _done.add(i),
                      ),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _done.contains(i) ? t.green : t.paper,
                            shape: BoxShape.circle,
                            border: Border.all(color: t.ink, width: 2),
                          ),
                          child: _done.contains(i)
                              ? Icon(
                                  LucideIcons.check,
                                  size: 14,
                                  color: t.onAccent,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _steps[i].$1,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          _steps[i].$2,
                          style: TextStyle(
                            fontSize: AppTokens.textMeta,
                            color: t.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: actions[i],
                    child: Text(i == 2 ? 'Open' : 'Do it'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
