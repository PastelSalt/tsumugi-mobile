import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/query_params.dart';
import '../../app/sheet_selection.dart';
import '../../core/data/format.dart';
import '../../core/data/models.dart';
import '../../core/data/selectors.dart';
import '../../core/data/status.dart';
import '../../core/data/workspace_store.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/filters.dart';
import '../../shared/widgets/layout.dart';
import '../../shared/widgets/record_sheets.dart';
import '../../shared/widgets/records.dart';
import '../../shared/widgets/states.dart';
import 'calendar_view.dart';

const _views = [
  TabItem('today', 'Today', icon: LucideIcons.sun),
  TabItem('upcoming', 'Upcoming', icon: LucideIcons.calendarClock),
  TabItem('calendar', 'Calendar', icon: LucideIcons.calendarRange),
  TabItem('all', 'All', icon: LucideIcons.layoutList),
];

/// Tasks: Today, Upcoming, Calendar and All (website `TasksPage`, PLAN-A-04E).
/// View, filters, calendar month/day and the selected task live in the route query
/// (`view`, `project`, `status`, `mode`, `month`, `day`, `select`).
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key, required this.params});

  final Map<String, String> params;

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SheetSelection<TasksScreen> {
  String _search = '';

  @override
  Map<String, String> get routeParams => widget.params;

  @override
  String sheetTypeFor(String id) => 'Task';

  String _p(String key, String fallback) => widget.params[key] ?? fallback;

  @override
  void initState() {
    super.initState();
    syncSelection();
  }

  @override
  void didUpdateWidget(TasksScreen old) {
    super.didUpdateWidget(old);
    syncSelection();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(workspaceDataProvider);
    final view = _p('view', 'today');
    final project = _p('project', 'all');
    final status = _p('status', 'all');
    final mode = _p('mode', 'list');

    bool matches(Task t) =>
        (project == 'all' || t.projectId == project) &&
        (status == 'all' || t.status == status) &&
        (_search.isEmpty ||
            t.title.toLowerCase().contains(_search.toLowerCase()));
    final filterCount =
        (project != 'all' ? 1 : 0) + (view == 'all' && status != 'all' ? 1 : 0);

    return ListView(
      padding: const EdgeInsets.all(AppTokens.pageGutter),
      children: [
        const PageHeader(
          title: 'Tasks',
          description: 'Everything you have to do, across all projects.',
        ),
        ViewTabs(
          tabs: _views,
          value: view,
          onChanged: (v) => context.setQueryParams({
            'view': v == 'today' ? null : v,
            'select': null,
          }),
        ),
        StateGate(
          empty: const EmptyState(
            title: 'No tasks yet',
            body: 'Tap + to add your first one.',
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SearchFilterBar(
                hint: 'Search tasks',
                onSearch: (v) => setState(() => _search = v),
                filterCount: filterCount,
                onFilter: () => showFilterSheet(
                  context,
                  onReset: () =>
                      context.setQueryParams({'project': null, 'status': null}),
                  builder: (context, refresh) => _Filters(
                    view: view,
                    project: project,
                    status: status,
                    projects: data.activeProjects,
                    onChanged: (changes) {
                      context.setQueryParams(changes);
                      refresh();
                    },
                  ),
                ),
              ),
              if (view == 'all')
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.space4),
                  child: SegmentedToggle(
                    label: 'Layout',
                    value: mode,
                    onChanged: (v) => context.setQueryParams({
                      'mode': v == 'list' ? null : v,
                    }),
                    options: const [('list', 'List'), ('board', 'Board')],
                  ),
                ),
              _body(data, view, project, mode, matches),
            ],
          ),
        ),
      ],
    );
  }

  Widget _body(
    WorkspaceData data,
    String view,
    String project,
    String mode,
    bool Function(Task) matches,
  ) {
    switch (view) {
      case 'upcoming':
        return _upcoming(data, project, matches);
      case 'calendar':
        return CalendarView(
          data: data,
          month: widget.params['month'],
          day: widget.params['day'],
          matches: matches,
          project: project,
          onMonth: (m) => context.setQueryParams({'month': m, 'day': null}),
          onDay: (d) => context.setQueryParams({'day': d}),
          onSelectTask: select,
        );
      case 'all':
        return _all(data, mode, matches);
      default:
        return _today(data, project, matches);
    }
  }

  Widget _today(
    WorkspaceData data,
    String project,
    bool Function(Task) matches,
  ) {
    final t = data.todayList(project);
    final groups = [
      ('Overdue', t.overdue.where(matches).toList()),
      ('Today', t.today.where(matches).toList()),
      ('In progress', t.doing.where(matches).toList()),
    ].where((g) => g.$2.isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InlineAdd(projectId: project == 'all' ? null : project),
        const SizedBox(height: AppTokens.space4),
        if (groups.isEmpty)
          const EmptyState(
            title: 'All clear for today',
            body: 'Add a task above, or look at Upcoming.',
          )
        else
          for (final (label, list) in groups)
            Section(
              title: label,
              child: Column(
                spacing: AppTokens.space2,
                children: [
                  for (final task in list)
                    TaskRow(
                      task: task,
                      showProject: true,
                      selected: widget.params['select'] == task.id,
                      onTap: () => select(task.id),
                    ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _upcoming(
    WorkspaceData data,
    String project,
    bool Function(Task) matches,
  ) {
    final items = data
        .upNext(30, project)
        .where((i) => !i.isTask || matches(i.task!))
        .toList();
    if (items.isEmpty) {
      return const EmptyState(
        icon: LucideIcons.calendarDays,
        title: 'Nothing coming up',
        body: 'No tasks or milestones are due in the next 30 days.',
      );
    }
    String label(String due) =>
        daysFromToday(due) == 1 ? 'Tomorrow' : formatDate(due);
    final groups = <(String, List<UpNextItem>)>[];
    for (final item in items) {
      final key = label(item.due);
      if (groups.isNotEmpty && groups.last.$1 == key) {
        groups.last.$2.add(item);
      } else {
        groups.add((key, [item]));
      }
    }
    final muted = TextStyle(
      fontSize: AppTokens.textMeta,
      color: context.tokens.muted,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (key, list) in groups)
          Section(
            title: key,
            child: Column(
              spacing: AppTokens.space2,
              children: [
                for (final item in list)
                  if (item.isTask)
                    TaskRow(
                      task: item.task!,
                      showProject: true,
                      selected: widget.params['select'] == item.task!.id,
                      onTap: () => select(item.id),
                    )
                  else
                    RowCard(
                      onTap: () =>
                          showRecordSheet(context, 'Milestone', item.id),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.flag, size: 18),
                          const SizedBox(width: AppTokens.space2),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Milestone · ${data.projectById(item.projectId)?.name ?? ''}',
                                  style: muted,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _all(WorkspaceData data, String mode, bool Function(Task) matches) {
    final list = data.tasks.where(matches).toList();
    if (list.isEmpty) {
      return NoResults(
        onClear: () {
          setState(() => _search = '');
          context.setQueryParams({'project': null, 'status': null});
        },
      );
    }
    if (mode == 'board') {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final status in workStatuses)
              Container(
                width: 300,
                margin: const EdgeInsets.only(right: AppTokens.space3),
                child: _BoardColumn(
                  status: status,
                  tasks: list.where((t) => t.status == status).toList(),
                  onSelect: select,
                ),
              ),
          ],
        ),
      );
    }
    final open = stableSorted(list.where(isOpen), (a, b) {
      final o = (isOverdue(b) ? 1 : 0) - (isOverdue(a) ? 1 : 0);
      return o != 0 ? o : (a.due ?? '9').compareTo(b.due ?? '9');
    });
    final done = list.where((t) => !isOpen(t)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          spacing: AppTokens.space2,
          children: [
            for (final t in open)
              TaskRow(
                task: t,
                showProject: true,
                selected: widget.params['select'] == t.id,
                onTap: () => select(t.id),
              ),
          ],
        ),
        if (done.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppTokens.space3),
            child: Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Done (${done.length})',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                children: [
                  Column(
                    spacing: AppTokens.space2,
                    children: [
                      for (final t in done)
                        TaskRow(
                          task: t,
                          showProject: true,
                          selected: widget.params['select'] == t.id,
                          onTap: () => select(t.id),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.view,
    required this.project,
    required this.status,
    required this.projects,
    required this.onChanged,
  });

  final String view;
  final String project;
  final String status;
  final List<Project> projects;
  final ValueChanged<Map<String, String?>> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FilterField(
        label: 'Project',
        value: project,
        options: [
          ('all', 'All projects'),
          for (final p in projects) (p.id, p.name),
        ],
        onChanged: (v) => onChanged({'project': v == 'all' ? null : v}),
      ),
      if (view == 'all')
        FilterField(
          label: 'Status',
          value: status,
          options: [
            ('all', 'Any status'),
            for (final s in workStatuses) (s, s),
          ],
          onChanged: (v) => onChanged({'status': v == 'all' ? null : v}),
        ),
    ],
  );
}

class _BoardColumn extends StatelessWidget {
  const _BoardColumn({
    required this.status,
    required this.tasks,
    required this.onSelect,
  });

  final String status;
  final List<Task> tasks;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: '$status, ${tasks.length} tasks',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: status,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextSpan(
                  text: '  ${tasks.length}',
                  style: TextStyle(color: t.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space2),
          if (tasks.isEmpty)
            Text(
              'Nothing here',
              style: TextStyle(color: t.muted, fontSize: AppTokens.textMeta),
            )
          else
            Column(
              spacing: AppTokens.space2,
              children: [
                for (final task in tasks)
                  TaskRow(
                    task: task,
                    showProject: true,
                    onTap: () => onSelect(task.id),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// "Add a task for today" field at the top of Today. Session-only.
class _InlineAdd extends ConsumerStatefulWidget {
  const _InlineAdd({this.projectId});

  final String? projectId;

  @override
  ConsumerState<_InlineAdd> createState() => _InlineAddState();
}

class _InlineAddState extends ConsumerState<_InlineAdd> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final title = value.trim();
    if (title.isEmpty) return;
    final data = ref.read(workspaceDataProvider);
    ref
        .read(sessionProvider.notifier)
        .addTask(
          title: title,
          due: demoToday,
          projectId:
              widget.projectId ??
              (data.activeProjects.isEmpty
                  ? 'project-garden'
                  : data.activeProjects.first.id),
        );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.done,
      onSubmitted: _submit,
      decoration: InputDecoration(
        hintText: 'Add a task for today',
        hintMaxLines: 2,
        helperText: 'Press the keyboard\x27s done key to add. Session only.',
        helperMaxLines: 2,
        prefixIcon: const Icon(LucideIcons.plus, size: 18),
        filled: true,
        fillColor: t.paper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: BorderSide(color: t.lineStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: BorderSide(color: t.lineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: BorderSide(color: t.ink, width: 2),
        ),
      ),
    );
  }
}
