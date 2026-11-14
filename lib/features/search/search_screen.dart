import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/selectors.dart';
import '../../core/data/workspace_store.dart';
import '../../core/theme/tokens.dart';
import '../projects/new_project_sheet.dart';
import '../quickadd/quick_add_sheet.dart';

class _Item {
  const _Item(this.id, this.group, this.label, this.run);

  final String id;
  final String group;
  final String label;
  final VoidCallback run;
}

/// Search or jump to (the mobile version of the website's command palette, `CommandPalette.jsx`):
/// actions, pages, projects and files. With nothing typed it shows recent items, then actions and pages.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _query = '';

  List<_Item> _items(BuildContext context) {
    final data = ref.read(workspaceDataProvider);
    // Tabs are switched with go; other pages are opened over the search page it replaces.
    void tab(String route) => context.go(route);
    void page(String route) => context.pushReplacement(route);

    final base = [
      _Item(
        'a-quick',
        'Actions',
        'Quick add a task',
        () => showQuickAddSheet(context),
      ),
      _Item(
        'a-project',
        'Actions',
        'New project',
        () => showNewProjectSheet(context),
      ),
      _Item('g-/home', 'Go to', 'Home', () => tab('/home')),
      _Item('g-/projects', 'Go to', 'Projects', () => tab('/projects')),
      _Item('g-/tasks', 'Go to', 'Tasks', () => tab('/tasks')),
      _Item('g-/library', 'Go to', 'Library', () => tab('/library')),
      _Item('g-/insights', 'Go to', 'Insights', () => page('/insights')),
      _Item('g-account', 'Go to', 'Account', () => page('/account')),
      _Item(
        'g-calendar',
        'Go to',
        'Calendar',
        () => tab('/tasks?view=calendar'),
      ),
      _Item('g-help', 'Go to', 'Help', () => page('/help')),
      for (final p in data.activeProjects)
        _Item(p.id, 'Projects', p.name, () => tab('/projects/${p.id}')),
      for (final f in data.files)
        _Item(
          f.id,
          'Library',
          f.name,
          () => f.body != null
              ? page('/library/doc/${f.id}')
              : tab('/library?select=${f.id}'),
        ),
    ];
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) {
      final recentIds = {for (final r in data.recents(4)) r.id};
      return [
        for (final i in base)
          if (recentIds.contains(i.id)) _Item(i.id, 'Recent', i.label, i.run),
        for (final i in base)
          if (i.group == 'Actions' || i.group == 'Go to') i,
      ];
    }
    return base
        .where((i) => i.label.toLowerCase().contains(q))
        .take(12)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final items = _items(context);
    final rows = <Widget>[];
    String? last;
    for (final item in items) {
      if (item.group != last) {
        last = item.group;
        rows.add(
          Padding(
            padding: const EdgeInsets.only(top: AppTokens.space3, bottom: 4),
            child: Semantics(
              header: true,
              child: Text(
                item.group,
                style: TextStyle(
                  fontSize: AppTokens.textMeta,
                  color: t.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }
      rows.add(
        ListTile(
          contentPadding: EdgeInsets.zero,
          minTileHeight: AppTokens.minTarget,
          title: Text(item.label),
          onTap: item.run,
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Search or jump to')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTokens.pageGutter),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search projects, files, or type a command',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                filled: true,
                fillColor: t.paper,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: t.lineStrong),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: t.lineStrong),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: t.ink, width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppTokens.pageGutter),
                    child: Text(
                      'No matches for “$_query”.',
                      style: TextStyle(color: t.muted),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.pageGutter,
                    ),
                    children: rows,
                  ),
          ),
        ],
      ),
    );
  }
}
