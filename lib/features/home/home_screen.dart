import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/format.dart';
import '../../core/data/models.dart';
import '../../core/data/selectors.dart';
import '../../core/data/workspace_store.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/record_sheets.dart';
import '../../shared/widgets/records.dart';
import '../../shared/widgets/task_tile.dart';
import '../../shared/widgets/states.dart';
import '../projects/new_project_sheet.dart';
import '../quickadd/quick_add_sheet.dart';

/// Home: one headline, one list of what to do now, then a place to continue
/// (docs/PLAN-UX.md, visual hierarchy: a single focal point, quiet everything else).
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
        padding: const EdgeInsets.fromLTRB(
          AppTokens.pageGutter,
          AppTokens.space4,
          AppTokens.pageGutter,
          AppTokens.pageGutter,
        ),
        children: [
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

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.data});

  final WorkspaceData data;

  @override
  Widget build(BuildContext context) {
    final today = data.todayList();
    final f = data.figures();
    final focus = [...today.overdue, ...today.today, ...today.doing];
    final upcoming = data.upNext(7).take(3).toList();
    final recent = data.recentProjects(1);
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    // The headline is the one thing to read first: how things stand, in a sentence.
    final headline = f.overdue > 0
        ? (f.overdue == 1 ? '1 task needs you' : '${f.overdue} tasks need you')
        : (f.dueToday > 0
              ? (f.dueToday == 1
                    ? '1 task is due today'
                    : '${f.dueToday} tasks are due today')
              : 'You are all caught up');
    final facts = [
      if (f.overdue > 0) '${f.overdue} overdue',
      '${f.dueToday} due today',
      '${f.doing} in progress',
    ].join(' · ');
    final day = parseDay(demoToday);
    final dateLine =
        '${_weekdayNames[day.weekday - 1]} ${formatDate(demoToday)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: '$headline. $facts. Opens Tasks.',
          excludeSemantics: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            onTap: () => context.go('/tasks'),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.space2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateLine,
                    style: text.bodySmall?.copyWith(
                      color: t.onSurfaceMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    headline,
                    style: text.headlineMedium?.copyWith(
                      color: f.overdue > 0 ? t.danger : t.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    facts,
                    style: text.bodyMedium?.copyWith(color: t.onSurfaceMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTokens.space5),
        _SectionLabel(
          'Up now',
          action: TextButton(
            onPressed: () => context.go('/tasks'),
            child: Text(
              focus.length > 3 ? 'All tasks (${focus.length})' : 'All tasks',
            ),
          ),
        ),
        if (focus.isEmpty)
          EmptyState(
            title: 'Nothing due today',
            body: 'Enjoy the quiet, or pull something forward from Up next.',
            action: OutlinedButton(
              onPressed: () => showQuickAddSheet(context),
              child: const Text('Add a task'),
            ),
          )
        else
          Column(
            children: [
              for (final task in focus.take(3))
                TaskTile(task: task, showProject: true),
            ],
          ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: AppTokens.space6),
          _SectionLabel(
            'Continue',
            action: TextButton(
              onPressed: () => context.go('/projects'),
              child: const Text('All projects'),
            ),
          ),
          _ContinueCard(data: data, project: recent.first),
        ],
        if (upcoming.isNotEmpty) ...[
          const SizedBox(height: AppTokens.space6),
          const _SectionLabel('Up next'),
          for (final item in upcoming) _UpNextRow(item: item, data: data),
        ],
        const SizedBox(height: AppTokens.space4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.push('/insights'),
            icon: const Icon(LucideIcons.chartNoAxesColumn, size: 16),
            label: const Text('See insights'),
          ),
        ),
      ],
    );
  }
}

/// A section label: small and quiet, so the content under it is what draws the eye. The optional
/// action sits at the end of the same line.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title, {this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space1),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: t.onSurface),
              ),
            ),
          ),
          if (action != null)
            Flexible(
              child: Align(alignment: Alignment.centerRight, child: action),
            ),
        ],
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
          Text(project.name, style: Theme.of(context).textTheme.titleMedium),
          if (next != null) ...[
            const SizedBox(height: 2),
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

/// A quiet row: no card, just the title and when it is due.
class _UpNextRow extends StatelessWidget {
  const _UpNextRow({required this.item, required this.data});

  final UpNextItem item;
  final WorkspaceData data;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final project = data.projectById(item.projectId);
    final kind = item.isTask ? '' : 'Milestone · ';
    return InkWell(
      onTap: () =>
          showRecordSheet(context, item.isTask ? 'Task' : 'Milestone', item.id),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppTokens.minTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      // Quieter than the tiles above: the next thing, not this thing.
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: t.onSurface,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      '$kind${project?.name ?? ''}',
                      style: TextStyle(
                        fontSize: AppTokens.textMeta,
                        color: t.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.space3),
              DueText(due: item.due),
            ],
          ),
        ),
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
