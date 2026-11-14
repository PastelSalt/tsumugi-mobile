import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/query_params.dart';
import '../../core/data/models.dart';
import '../../core/data/selectors.dart';
import '../../core/data/status.dart';
import '../../core/data/workspace_store.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/filters.dart';
import '../../shared/widgets/layout.dart';
import '../../shared/widgets/record_sheets.dart';
import '../../shared/widgets/records.dart';
import '../../shared/widgets/states.dart';

const _definitions = [
  ('Progress', 'Done tasks divided by all tasks in scope.'),
  (
    'Coverage',
    'A requirement is complete when it is met, verified, and has a task and a final file.',
  ),
  ('Overdue', 'Open tasks and milestones with a date before today.'),
];

/// Insights: three honest numbers (website `InsightsPage`, PLAN-A-04J). Query: `project`.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key, required this.params});

  final Map<String, String> params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(workspaceDataProvider);
    final project = params['project'] ?? 'all';
    final tasks = data.tasksIn(project);
    final done = tasks.where((t) => t.status == 'Done').length;
    final cov = data.coverage(project);
    final overdue = data.overdueRecords(project);
    final rows = [
      for (final p in data.activeProjects)
        if (project == 'all' || p.id == project) p,
    ];
    final t = context.tokens;

    return ListView(
      padding: const EdgeInsets.all(AppTokens.pageGutter),
      children: [
        const PageHeader(
          title: 'Insights',
          description: 'Three numbers that tell you where things stand.',
        ),
        StateGate(
          empty: const EmptyState(
            title: 'No data yet',
            body: 'Insights appear once you have projects and tasks.',
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilterField(
                label: 'Project',
                value: project,
                options: [
                  ('all', 'All projects'),
                  for (final p in data.activeProjects) (p.id, p.name),
                ],
                onChanged: (v) =>
                    context.setQueryParams({'project': v == 'all' ? null : v}),
              ),
              _InsightCard(
                title: 'Progress',
                value:
                    '${tasks.isEmpty ? 0 : (done / tasks.length * 100).round()}%',
                bar: TsProgressBar(
                  value: done,
                  max: tasks.length,
                  label: 'Tasks done',
                  showCount: false,
                ),
                note: '$done of ${tasks.length} tasks done',
              ),
              const SizedBox(height: AppTokens.space3),
              _InsightCard(
                title: 'Coverage',
                value: '${cov.complete}/${cov.total}',
                bar: TsProgressBar(
                  value: cov.complete,
                  max: cov.total,
                  label: 'Requirements complete',
                  showCount: false,
                ),
                note:
                    '${cov.withGaps} requirement${cov.withGaps == 1 ? '' : 's'} with gaps',
              ),
              const SizedBox(height: AppTokens.space3),
              _InsightCard(
                title: 'Overdue',
                value: '${overdue.length}',
                note: overdue.isEmpty
                    ? 'Nothing is late.'
                    : 'Open the list below to catch up.',
              ),
              const SizedBox(height: AppTokens.space5),
              if (overdue.isNotEmpty)
                Section(
                  title: 'Overdue items',
                  child: Column(
                    spacing: AppTokens.space2,
                    children: [
                      for (final o in overdue)
                        RowCard(
                          onTap: () => showRecordSheet(context, o.type, o.id),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      o.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      o.type,
                                      style: TextStyle(
                                        fontSize: AppTokens.textMeta,
                                        color: t.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Flexible(child: DueLabel(due: o.due)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              Section(
                title: 'By project',
                child: Column(
                  spacing: AppTokens.space2,
                  children: [
                    for (final p in rows) _ProjectRow(project: p, data: data),
                  ],
                ),
              ),
              Section(
                title: 'How these are counted',
                child: Fields(
                  items: [
                    for (final (term, text) in _definitions) (term, Text(text)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.value,
    required this.note,
    this.bar,
  });

  final String title;
  final String value;
  final String note;
  final Widget? bar;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: '$title: $value. $note',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTokens.space4),
          decoration: BoxDecoration(
            color: t.paper,
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            border: Border.all(color: t.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontSize: 36),
              ),
              if (bar != null) ...[const SizedBox(height: 6), bar!],
              const SizedBox(height: 6),
              Text(
                note,
                style: TextStyle(fontSize: AppTokens.textMeta, color: t.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.project, required this.data});

  final Project project;
  final WorkspaceData data;

  @override
  Widget build(BuildContext context) {
    final progress = data.projectProgress(project.id);
    return RowCard(
      onTap: () => context.go('/projects/${project.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: AppTokens.space2,
            runSpacing: 4,
            children: [
              StatusBadge(StatusDomain.project, project.status),
              if (project.status == 'Active')
                StatusBadge(
                  StatusDomain.health,
                  data.projectHealth(project.id),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TsProgressBar(
            value: progress.done,
            max: progress.total,
            label: '${project.name} tasks done',
          ),
        ],
      ),
    );
  }
}
