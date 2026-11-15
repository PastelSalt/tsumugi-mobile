import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/query_params.dart';
import '../../app/shell/shell_actions.dart';
import '../../app/sheet_selection.dart';
import '../../core/data/format.dart';
import '../../core/data/models.dart';
import '../../core/data/selectors.dart';
import '../../core/data/status.dart';
import '../../core/data/workspace_store.dart';
import '../../core/settings/preferences.dart';
import '../../core/state/preview_state.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/filters.dart';
import '../../shared/widgets/large_title_scaffold.dart';
import '../../shared/widgets/layout.dart';
import '../../shared/widgets/record_sheets.dart';
import '../../shared/widgets/records.dart';
import '../../shared/widgets/task_tile.dart';
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

    final preview = ref.watch(previewStateProvider);
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageGutter,
        AppTokens.space4,
        AppTokens.pageGutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today is for doing, not searching: the one box on screen is "Add a task". Search and
          // filters live on the other views (and the app bar's Search finds tasks anywhere).
          if (view != 'today')
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
                onChanged: (v) =>
                    context.setQueryParams({'mode': v == 'list' ? null : v}),
                options: const [('list', 'List'), ('board', 'Board')],
              ),
            ),
        ],
      ),
    );

    return LargeTitleScaffold(
      title: 'Tasks',
      restorationId: 'tasks-scroll',
      actions: shellActions(context),
      onRefresh: () async {
        // Demo: the sample data is local, so there is nothing to fetch. A short pause keeps the
        // gesture feeling like a refresh.
        await Future<void>.delayed(const Duration(milliseconds: 450));
      },
      pinnedHeader: ViewTabs(
        tabs: _views,
        value: view,
        margin: EdgeInsets.zero,
        onChanged: (v) => context.setQueryParams({
          'view': v == 'today' ? null : v,
          'select': null,
        }),
      ),
      slivers: switch (preview) {
        PreviewState.loading => [_box(const LoadingState())],
        PreviewState.error => [_box(const ErrorState())],
        PreviewState.empty => [_box(_noTasks)],
        PreviewState.normal =>
          data.tasks.isEmpty
              ? [_box(_noTasks)]
              : [
                  SliverToBoxAdapter(child: header),
                  ..._body(data, view, project, mode, matches),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppTokens.space5),
                  ),
                ],
      },
    );
  }

  static const _noTasks = EmptyState(
    title: 'No tasks yet',
    body: 'Tap + to add your first one.',
  );

  /// One group of tiles with a header that stays pinned under the view tabs while its tiles scroll.
  Widget _group(String title, int count, List<Widget> tiles) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.pageGutter),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _GroupHeaderDelegate(title: title, count: count),
          ),
          SliverList.builder(
            itemCount: tiles.length,
            itemBuilder: (context, i) => tiles[i],
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space3)),
        ],
      ),
    );
  }

  Widget _box(Widget child) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: AppTokens.pageGutter),
    sliver: SliverToBoxAdapter(child: child),
  );

  TaskTile _tile(Task task) => TaskTile(
    key: ValueKey(task.id),
    task: task,
    showProject: true,
    selected: widget.params['select'] == task.id,
    onTap: () => select(task.id),
  );

  List<Widget> _body(
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
        return [
          _box(
            CalendarView(
              data: data,
              month: widget.params['month'],
              day: widget.params['day'],
              matches: matches,
              project: project,
              onMonth: (m) => context.setQueryParams({'month': m, 'day': null}),
              onDay: (d) => context.setQueryParams({'day': d}),
              onSelectTask: select,
              sundayStart: ref.watch(preferencesProvider).weekStartsSunday,
            ),
          ),
        ];
      case 'all':
        return _all(data, mode, matches);
      default:
        return _today(data, project, matches);
    }
  }

  List<Widget> _today(
    WorkspaceData data,
    String project,
    bool Function(Task) matches,
  ) {
    final t = data.todayList(project);
    // Tasks finished during this session leave their group at once; they gather here so a person
    // can see them and Undo remains reachable.
    final session = ref.watch(sessionProvider).taskOverrides;
    final finished = data.tasks
        .where(
          (task) =>
              task.status == 'Done' &&
              session.containsKey(task.id) &&
              matches(task),
        )
        .toList();
    final groups = [
      ('Overdue', t.overdue.where(matches).toList()),
      ('Today', t.today.where(matches).toList()),
      ('In progress', t.doing.where(matches).toList()),
      ('Done this session', finished),
    ].where((g) => g.$2.isNotEmpty).toList();
    return [
      _box(
        Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.space4),
          child: _InlineAdd(projectId: project == 'all' ? null : project),
        ),
      ),
      if (groups.isNotEmpty && !ref.watch(gestureHintDismissedProvider))
        _box(
          _GestureHint(
            onDismiss: () =>
                ref.read(gestureHintDismissedProvider.notifier).dismiss(),
          ),
        ),
      if (groups.isEmpty)
        _box(
          const EmptyState(
            title: 'All clear for today',
            body: 'Add a task above, or look at Upcoming.',
          ),
        )
      else
        for (final (label, list) in groups)
          _group(label, list.length, [for (final task in list) _tile(task)]),
    ];
  }

  List<Widget> _upcoming(
    WorkspaceData data,
    String project,
    bool Function(Task) matches,
  ) {
    final items = data
        .upNext(30, project)
        .where((i) => !i.isTask || matches(i.task!))
        .toList();
    if (items.isEmpty) {
      return [
        _box(
          const EmptyState(
            icon: LucideIcons.calendarDays,
            title: 'Nothing coming up',
            body: 'No tasks or milestones are due in the next 30 days.',
          ),
        ),
      ];
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
    return [
      for (final (key, list) in groups)
        _group(key, list.length, [
          for (final item in list)
            if (item.isTask)
              _tile(item.task!)
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: RowCard(
                  onTap: () => showRecordSheet(context, 'Milestone', item.id),
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
              ),
        ]),
    ];
  }

  List<Widget> _all(
    WorkspaceData data,
    String mode,
    bool Function(Task) matches,
  ) {
    final list = data.tasks.where(matches).toList();
    if (list.isEmpty) {
      return [
        _box(
          NoResults(
            onClear: () {
              setState(() => _search = '');
              context.setQueryParams({'project': null, 'status': null});
            },
          ),
        ),
      ];
    }
    if (mode == 'board') {
      return [
        _box(
          SingleChildScrollView(
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
          ),
        ),
      ];
    }
    final open = stableSorted(list.where(isOpen), (a, b) {
      final o = (isOverdue(b) ? 1 : 0) - (isOverdue(a) ? 1 : 0);
      return o != 0 ? o : (a.due ?? '9').compareTo(b.due ?? '9');
    });
    final done = list.where((t) => !isOpen(t)).toList();
    return [
      if (open.isNotEmpty)
        _group('Open', open.length, [for (final t in open) _tile(t)]),
      if (done.isNotEmpty)
        _group('Done', done.length, [for (final t in done) _tile(t)]),
    ];
  }
}

class _GroupHeaderDelegate extends SliverPersistentHeaderDelegate {
  _GroupHeaderDelegate({required this.title, required this.count});

  final String title;
  final int count;

  static const _height = 40.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox(
    height: _height,
    child: Align(
      alignment: Alignment.centerLeft,
      child: _GroupHeader(title: title, count: count),
    ),
  );

  @override
  bool shouldRebuild(_GroupHeaderDelegate old) =>
      old.title != title || old.count != count;
}

/// Header of a task group: the label and a count, on the page background so tiles slide under it.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      header: true,
      label: '$title, $count',
      child: ExcludeSemantics(
        child: Container(
          color: t.background,
          padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextSpan(
                  text: '  $count',
                  style: TextStyle(
                    color: t.onSurfaceMuted,
                    fontSize: AppTokens.textMeta,
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
                  TaskTile(
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

/// One-time hint for the gestures on a task tile. Shown once, dismissible, and Account can show it
/// again. It is a hint, not a tour (docs/PLAN-UX.md, 3.6).
class _GestureHint extends StatelessWidget {
  const _GestureHint({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.space3),
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space3,
        AppTokens.space2,
        AppTokens.space1,
        AppTokens.space2,
      ),
      decoration: BoxDecoration(
        color: t.blueSoft,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.hand, size: 18, color: t.info),
          const SizedBox(width: AppTokens.space2),
          Expanded(
            child: Text(
              'Tip: swipe a task right to complete it and left to move it to tomorrow. Press and hold for more.',
              style: TextStyle(
                fontSize: AppTokens.textMeta,
                color: t.onSurface,
              ),
            ),
          ),
          TextButton(
            onPressed: onDismiss,
            style: TextButton.styleFrom(foregroundColor: t.onSurface),
            child: const Text('Got it'),
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
        prefixIcon: const Icon(LucideIcons.plus, size: 18),
        filled: true,
        fillColor: t.paper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: BorderSide(color: t.controlBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: BorderSide(color: t.controlBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: BorderSide(color: t.ink, width: 2),
        ),
      ),
    );
  }
}
