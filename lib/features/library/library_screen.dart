import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/query_params.dart';
import '../../app/sheet_selection.dart';
import '../../core/data/selectors.dart';
import '../../core/data/workspace_store.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/filters.dart';
import '../../shared/widgets/layout.dart';
import '../../shared/widgets/preview_sheet.dart';
import '../../shared/widgets/records.dart';
import '../../shared/widgets/states.dart';
import '../project/project_screen.dart';

const _kinds = [
  ('all', 'All types'),
  ('document', 'Documents'),
  ('image', 'Images'),
  ('media', 'Audio and video'),
  ('data', 'Data'),
  ('link', 'Links'),
];

/// Library: notes, documents and files from every project in one place (website `LibraryPage`,
/// PLAN-A-04G). Query: `kind`, `project`, `final`, `mode` (grid|list), `select` (file id).
/// Markdown documents open the reader; other files open their detail sheet.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key, required this.params});

  final Map<String, String> params;

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SheetSelection<LibraryScreen> {
  String _search = '';

  @override
  Map<String, String> get routeParams => widget.params;

  @override
  String sheetTypeFor(String id) => 'File';

  @override
  void initState() {
    super.initState();
    syncSelection();
  }

  @override
  void didUpdateWidget(LibraryScreen old) {
    super.didUpdateWidget(old);
    syncSelection();
  }

  void _open(String id) {
    final file = ref.read(workspaceDataProvider).fileById(id);
    if (file?.body != null) {
      context.go('/library/doc/$id');
    } else {
      select(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(workspaceDataProvider);
    final kind = widget.params['kind'] ?? 'all';
    final project = widget.params['project'] ?? 'all';
    final onlyFinal = widget.params['final'] == '1';
    final mode = widget.params['mode'] ?? 'list';

    final list = [
      for (final f in data.files)
        if ((kind == 'all' || f.kind == kind) &&
            (project == 'all' || f.projectId == project) &&
            (!onlyFinal || isFinalFile(f)) &&
            (_search.isEmpty ||
                '${f.name} ${f.tags.join(' ')}'.toLowerCase().contains(
                  _search.toLowerCase(),
                )))
          f,
    ];
    final filterCount =
        (kind != 'all' ? 1 : 0) +
        (project != 'all' ? 1 : 0) +
        (onlyFinal ? 1 : 0);
    void reset() {
      setState(() => _search = '');
      context.setQueryParams({'kind': null, 'project': null, 'final': null});
    }

    return ListView(
      padding: const EdgeInsets.all(AppTokens.pageGutter),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Library',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const PreviewAction(
              label: 'Add file',
              quiet: true,
              icon: LucideIcons.plus,
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space3),
        StateGate(
          empty: const EmptyState(
            title: 'Your library is empty',
            body: 'Notes and files you add to a project appear here.',
            action: PreviewAction(label: 'Add file', primary: true),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SearchFilterBar(
                hint: 'Search files and notes',
                onSearch: (v) => setState(() => _search = v),
                filterCount: filterCount,
                onFilter: () => showFilterSheet(
                  context,
                  onReset: reset,
                  builder: (context, refresh) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FilterField(
                        label: 'Type',
                        value: kind,
                        options: _kinds,
                        onChanged: (v) {
                          context.setQueryParams({
                            'kind': v == 'all' ? null : v,
                          });
                          refresh();
                        },
                      ),
                      FilterField(
                        label: 'Project',
                        value: project,
                        options: [
                          ('all', 'All projects'),
                          for (final p in data.activeProjects) (p.id, p.name),
                        ],
                        onChanged: (v) {
                          context.setQueryParams({
                            'project': v == 'all' ? null : v,
                          });
                          refresh();
                        },
                      ),
                      FilterToggle(
                        label: 'Final files only',
                        value: onlyFinal,
                        onChanged: (v) {
                          context.setQueryParams({'final': v ? '1' : null});
                          refresh();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.space4),
                child: SegmentedToggle(
                  label: 'Layout',
                  value: mode,
                  onChanged: (v) =>
                      context.setQueryParams({'mode': v == 'list' ? null : v}),
                  options: const [('list', 'List'), ('grid', 'Grid')],
                ),
              ),
              if (list.isEmpty)
                NoResults(onClear: reset)
              else if (mode == 'list')
                Column(
                  spacing: AppTokens.space2,
                  children: [
                    for (final f in list)
                      FileRow(
                        file: f,
                        selected: widget.params['select'] == f.id,
                        onTap: () => _open(f.id),
                      ),
                  ],
                )
              else
                FileGrid(
                  files: list,
                  selectedId: widget.params['select'],
                  onSelect: _open,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
