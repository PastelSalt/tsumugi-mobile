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
import '../../shared/widgets/states.dart';
import '../projects/new_project_sheet.dart';
import '../quickadd/quick_add_sheet.dart';

/// Home: what needs you today, and what is coming next (website `HomePage`, PLAN-A-04A).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(workspaceDataProvider);
    return ListView(
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
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatStrip(
          stats: [
            Stat('Due today', '${f.dueToday}'),
            Stat(
              'Overdue',
              '${f.overdue}',
              hint: f.overdue > 0 ? 'Needs a look' : null,
            ),
            Stat('In progress', '${f.doing}'),
          ],
        ),
        Section(
          title: 'Today',
          action: TextButton(
            onPressed: () => context.go('/tasks'),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('All tasks'),
                SizedBox(width: 4),
                Icon(LucideIcons.arrowRight, size: 14),
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
                  spacing: AppTokens.space2,
                  children: [
                    for (final task in focus.take(6))
                      TaskRow(task: task, showProject: true),
                  ],
                ),
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
          child: Column(
            spacing: AppTokens.space2,
            children: [
              for (final p in data.recentProjects(4))
                RowCard(
                  onTap: () => context.go('/projects/${p.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          StatusBadge(StatusDomain.project, p.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TsProgressBar(
                        value: data.projectProgress(p.id).done,
                        max: data.projectProgress(p.id).total,
                        label: '${p.name} progress',
                      ),
                    ],
                  ),
                ),
            ],
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
          DueLabel(due: item.due),
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
                              ? const Icon(
                                  LucideIcons.check,
                                  size: 14,
                                  color: Colors.white,
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
