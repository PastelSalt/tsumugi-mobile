import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/status.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/filters.dart';
import '../../shared/widgets/records.dart';
import '../../shared/widgets/task_tile.dart';
import '../../core/data/selectors.dart';
import '../../core/data/workspace_store.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/brand_mark.dart';
import '../../shared/widgets/layout.dart';
import '../../shared/widgets/preview_sheet.dart';
import '../../shared/widgets/states.dart';

/// Developer-only review page: every shared widget in every state, for checking against the website.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  String _tab = 'today';
  String _layout = 'list';

  Widget _wrap(List<Widget> children) => Wrap(
    spacing: AppTokens.space2,
    runSpacing: AppTokens.space2,
    children: children,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Widget gallery')),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.pageGutter),
        children: [
          const PageHeader(
            title: 'Design system',
            description:
                'Developer review page. Mirrors the website components.',
          ),
          const Section(
            title: 'Brand',
            child: Row(
              children: [BrandMark(size: 48), SizedBox(width: 16), BrandLogo()],
            ),
          ),
          Section(
            title: 'Status badges',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final domain in StatusDomain.values) ...[
                  Text(
                    domain.name,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  _wrap([
                    for (final s in statusStyles[domain]!.keys)
                      StatusBadge(domain, s),
                  ]),
                  const SizedBox(height: AppTokens.space3),
                ],
              ],
            ),
          ),
          Section(
            title: 'Flags',
            child: _wrap([
              const Flag('Blocked'),
              const Flag('Verified'),
              const Flag('Reviewed'),
              const Flag('Final', label: 'Final file'),
              const Flag('High', label: 'High priority'),
              const SessionTag(),
            ]),
          ),
          Section(
            title: 'Due labels (demo today is 12 Nov)',
            child: _wrap([
              const DueLabel(due: '2026-11-09'),
              const DueLabel(due: '2026-11-12'),
              const DueLabel(due: '2026-11-13'),
              const DueLabel(due: '2026-11-18'),
              const DueLabel(due: '2026-12-15'),
              const DueLabel(due: '2026-11-05', done: true),
              const DueLabel(due: null),
            ]),
          ),
          const Section(
            title: 'Progress',
            child: Column(
              spacing: AppTokens.space2,
              children: [
                TsProgressBar(value: 3, max: 4, label: 'Sample'),
                TsProgressBar(value: 0, max: 5, label: 'Empty'),
                TsProgressBar(value: 0, max: 0, label: 'No tasks'),
              ],
            ),
          ),
          const StatStrip(
            stats: [
              Stat('Due today', '2'),
              Stat('Overdue', '3', hint: 'Needs a look'),
              Stat('In progress', '5'),
            ],
          ),
          Section(
            title: 'Tabs and toggles',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ViewTabs(
                  value: _tab,
                  onChanged: (v) => setState(() => _tab = v),
                  tabs: const [
                    TabItem('today', 'Today', icon: LucideIcons.sun),
                    TabItem(
                      'upcoming',
                      'Upcoming',
                      icon: LucideIcons.calendarClock,
                    ),
                    TabItem(
                      'calendar',
                      'Calendar',
                      icon: LucideIcons.calendarRange,
                    ),
                    TabItem(
                      'all',
                      'All',
                      icon: LucideIcons.layoutList,
                      count: 15,
                    ),
                  ],
                ),
                SegmentedToggle(
                  label: 'Layout',
                  value: _layout,
                  onChanged: (v) => setState(() => _layout = v),
                  options: const [('list', 'List'), ('board', 'Board')],
                ),
              ],
            ),
          ),
          Section(
            title: 'Search and fields',
            child: Column(
              children: [
                SearchFilterBar(
                  hint: 'Search tasks',
                  onSearch: (_) {},
                  filterCount: 2,
                  onFilter: () {},
                ),
                const Fields(
                  items: [
                    ('Due', DueLabel(due: '2026-11-13')),
                    ('Milestone', Text('Chapter one review')),
                    ('Skipped', null),
                  ],
                ),
              ],
            ),
          ),
          Section(
            title: 'States',
            child: Column(
              spacing: AppTokens.space3,
              children: [
                const EmptyState(
                  title: 'Nothing due today',
                  body: 'Enjoy the quiet, or pull something forward.',
                ),
                NoResults(onClear: () {}),
                ErrorState(onRetry: () {}),
                const LoadingState(rows: 2),
              ],
            ),
          ),
          const Section(
            title: 'Preview sheet',
            child: PreviewAction(
              label: 'Edit project',
              primary: true,
              icon: LucideIcons.pencil,
            ),
          ),
          const _RecordsGallery(),
        ],
      ),
    );
  }
}

/// Record widgets drawn from the real sample data (tap a row or chip to open its detail sheet).
class _RecordsGallery extends ConsumerStatefulWidget {
  const _RecordsGallery();

  @override
  ConsumerState<_RecordsGallery> createState() => _RecordsGalleryState();
}

class _RecordsGalleryState extends ConsumerState<_RecordsGallery> {
  String _project = 'all';
  bool _final = false;

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(workspaceDataProvider);
    Widget gap() => const SizedBox(height: AppTokens.space2);
    return Section(
      title: 'Records (sample data)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TaskTile(task: d.taskById('t1')!, showProject: true),
          gap(),
          TaskTile(task: d.taskById('t3')!),
          gap(),
          TaskTile(task: d.taskById('t7')!),
          gap(),
          MilestoneGroup(
            milestone: d.milestoneById('m1')!,
            tasks: d.tasksOfMilestone('m1'),
          ),
          gap(),
          RequirementRow(requirement: d.requirementById('REQ-001')!),
          gap(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: FileTile(file: d.fileById('a-cover')!)),
              const SizedBox(width: AppTokens.space2),
              Expanded(child: FileTile(file: d.fileById('a-upload')!)),
            ],
          ),
          gap(),
          FileRow(file: d.fileById('d-brief')!),
          gap(),
          ChangeEntry(change: d.changeById('r1')!),
          ChangeEntry(change: d.changeById('r2')!, last: true),
          const SizedBox(height: AppTokens.space3),
          const LensBlock(
            why: [
              RelationChip(
                type: 'Requirement',
                id: 'REQ-001',
                label: 'REQ-001',
              ),
              RelationChip(type: 'Milestone', id: 'm1'),
            ],
            becomes: [
              RelationChip(type: 'File', id: 'a-notes'),
              RelationChip(type: 'Change', id: 'r3'),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          OutlinedButton(
            onPressed: () => showFilterSheet(
              context,
              onReset: () => setState(() {
                _project = 'all';
                _final = false;
              }),
              builder: (context, refresh) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilterField(
                    label: 'Project',
                    value: _project,
                    options: [
                      ('all', 'All projects'),
                      for (final p in d.activeProjects) (p.id, p.name),
                    ],
                    onChanged: (v) {
                      setState(() => _project = v);
                      refresh();
                    },
                  ),
                  FilterToggle(
                    label: 'Final files only',
                    value: _final,
                    onChanged: (v) {
                      setState(() => _final = v);
                      refresh();
                    },
                  ),
                ],
              ),
            ),
            child: const Text('Open filter sheet'),
          ),
        ],
      ),
    );
  }
}
