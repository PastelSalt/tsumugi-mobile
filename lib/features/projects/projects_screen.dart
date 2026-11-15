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
import '../../shared/widgets/filters.dart';
import '../../shared/widgets/layout.dart';
import '../../shared/widgets/states.dart';
import '../../shared/widgets/timeline.dart';
import 'new_project_sheet.dart';

const _categories = ['Software', 'Creative', 'Research', 'Multimedia', 'Other'];

/// Pastel tint for a project card (`tone` in the sample data).
Color projectTint(BuildContext context, String tone) {
  final t = context.tokens;
  return switch (tone) {
    'pink' => t.pinkSoft,
    'blue' => t.blueSoft,
    'lilac' => t.lilac,
    'yellow' => t.butterSoft,
    'green' => t.greenSoft,
    _ => t.paper,
  };
}

/// Projects: card list and cross-project timeline (website `ProjectsPage`, PLAN-A-04B).
/// Query: `view` (list|timeline), `status`, `category`, `archived`, `select` (milestone).
class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key, required this.params});

  final Map<String, String> params;

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen>
    with SheetSelection<ProjectsScreen> {
  String _search = '';

  @override
  Map<String, String> get routeParams => widget.params;

  @override
  String sheetTypeFor(String id) => 'Milestone';

  @override
  void initState() {
    super.initState();
    syncSelection();
  }

  @override
  void didUpdateWidget(ProjectsScreen old) {
    super.didUpdateWidget(old);
    syncSelection();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(workspaceDataProvider);
    final view = widget.params['view'] ?? 'list';
    final status = widget.params['status'] ?? 'all';
    final category = widget.params['category'] ?? 'all';
    final archived = widget.params['archived'] == '1';

    final list = [
      for (final p in data.projects)
        if ((archived || !p.archived) &&
            (status == 'all' || p.status == status) &&
            (category == 'all' || p.category == category) &&
            (_search.isEmpty ||
                p.name.toLowerCase().contains(_search.toLowerCase())))
          p,
    ];
    final filterCount =
        (status != 'all' ? 1 : 0) +
        (category != 'all' ? 1 : 0) +
        (archived ? 1 : 0);
    void reset() {
      setState(() => _search = '');
      context.setQueryParams({
        'status': null,
        'category': null,
        'archived': null,
      });
    }

    return ListView(
      padding: const EdgeInsets.all(AppTokens.pageGutter),
      children: [
        // Title and a small action on one line; the big call-to-action button is gone so the first
        // project is what the eye finds (docs/PLAN-UX.md, 5.5).
        // Wraps onto two lines at very large text instead of overflowing.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Projects',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () => showNewProjectSheet(context),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('New project'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space3),
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedToggle(
            label: 'View',
            value: view,
            onChanged: (v) => context.setQueryParams({
              'view': v == 'list' ? null : v,
              'select': null,
            }),
            options: const [('list', 'Projects'), ('timeline', 'Timeline')],
          ),
        ),
        const SizedBox(height: AppTokens.space4),
        StateGate(
          empty: EmptyState(
            title: 'No projects yet',
            body: 'Start from a template and the first steps are filled in.',
            action: FilledButton(
              onPressed: () => showNewProjectSheet(context),
              child: const Text('New project'),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SearchFilterBar(
                hint: 'Search projects',
                onSearch: (v) => setState(() => _search = v),
                filterCount: filterCount,
                onFilter: () => showFilterSheet(
                  context,
                  onReset: reset,
                  builder: (context, refresh) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FilterField(
                        label: 'Status',
                        value: status,
                        options: [
                          ('all', 'Any status'),
                          for (final s in projectStatuses) (s, s),
                        ],
                        onChanged: (v) {
                          context.setQueryParams({
                            'status': v == 'all' ? null : v,
                          });
                          refresh();
                        },
                      ),
                      FilterField(
                        label: 'Category',
                        value: category,
                        options: [
                          ('all', 'Any category'),
                          for (final c in _categories) (c, c),
                        ],
                        onChanged: (v) {
                          context.setQueryParams({
                            'category': v == 'all' ? null : v,
                          });
                          refresh();
                        },
                      ),
                      FilterToggle(
                        label: 'Show archived',
                        value: archived,
                        onChanged: (v) {
                          context.setQueryParams({'archived': v ? '1' : null});
                          refresh();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (list.isEmpty)
                NoResults(onClear: reset)
              else if (view == 'timeline')
                TimelineList(
                  milestones: [
                    for (final m in data.milestones)
                      if (list.any((p) => p.id == m.projectId)) m,
                  ],
                  projectName: (id) => data.projectById(id)?.name ?? '',
                  showProject: true,
                  selectedId: widget.params['select'],
                  onSelect: select,
                )
              else
                Column(
                  spacing: AppTokens.space3,
                  children: [
                    for (final p in list) ProjectCard(project: p, data: data),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Project card: tint, category, name, description, status, progress and the next milestone.
class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.project, required this.data});

  final Project project;
  final WorkspaceData data;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final progress = data.projectProgress(project.id);
    final next = data.nextMilestone(project.id);
    final health = data.projectHealth(project.id);
    return Semantics(
      button: true,
      label: project.name,
      child: Material(
        color: t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          side: BorderSide(color: t.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/projects/${project.id}'),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (project.session) const SessionTag(),
                  ],
                ),
                Text(
                  project.category,
                  style: TextStyle(
                    fontSize: AppTokens.textMeta,
                    color: t.muted,
                  ),
                ),
                const SizedBox(height: AppTokens.space2),
                Wrap(
                  spacing: AppTokens.space2,
                  runSpacing: 4,
                  children: [
                    StatusBadge(
                      StatusDomain.project,
                      project.archived ? 'Archived' : project.status,
                    ),
                    if (project.status == 'Active' && health == 'At risk')
                      const Flag('Blocked', label: 'At risk'),
                  ],
                ),
                const SizedBox(height: AppTokens.space3),
                TsProgressBar(
                  value: progress.done,
                  max: progress.total,
                  label: '${project.name} progress',
                ),
                const SizedBox(height: 6),
                Text(
                  next == null
                      ? 'No upcoming milestone'
                      : 'Next: ${next.title}, ${formatDate(next.due)}',
                  style: TextStyle(
                    fontSize: AppTokens.textMeta,
                    color: t.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
