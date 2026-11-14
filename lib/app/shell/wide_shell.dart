import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/selectors.dart';
import '../../core/data/workspace_store.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../features/quickadd/quick_add_sheet.dart';
import '../../shared/widgets/brand_mark.dart';
import '../../shared/widgets/record_sheets.dart';
import '../layout_breakpoints.dart';
import '../query_params.dart';
import 'account_sheet.dart';

/// Tablet layout (width from [wideBreakpoint]): a side rail with the five destinations (the website
/// rail), Quick add, search and the account menu; the page beside it; and, when a record is selected
/// on Tasks, Projects, a project or Library, its details docked on the right instead of in a sheet.
class WideShell extends ConsumerWidget {
  const WideShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    ('Home', LucideIcons.house),
    ('Projects', LucideIcons.folderKanban),
    ('Tasks', LucideIcons.listChecks),
    ('Library', LucideIcons.library),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final uri = GoRouterState.of(context).uri;
    final selectedId = uri.queryParameters['select'];
    final data = ref.watch(workspaceDataProvider);
    final type = selectedId == null ? null : data.recordTypeOf(selectedId);
    final docked =
        selectedId != null && type != null && navigationShell.currentIndex != 0;

    Widget tab(int i) => _RailItem(
      label: _tabs[i].$1,
      icon: _tabs[i].$2,
      selected: navigationShell.currentIndex == i,
      onTap: () => navigationShell.goBranch(
        i,
        initialLocation: i == navigationShell.currentIndex,
      ),
    );

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 104,
            child: Material(
              color: t.paper,
              child: SafeArea(
                right: false,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppTokens.space4),
                      child: BrandMark(size: 36),
                    ),
                    Semantics(
                      button: true,
                      label: 'Quick add',
                      child: Material(
                        color: t.pink,
                        shape: CircleBorder(
                          side: BorderSide(color: t.ink, width: 2),
                        ),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => showQuickAddSheet(context),
                          child: SizedBox(
                            width: 52,
                            height: 52,
                            child: Icon(
                              LucideIcons.plus,
                              color: t.onAccent,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTokens.space3),
                    tab(0),
                    tab(1),
                    tab(2),
                    tab(3),
                    _RailItem(
                      label: 'Insights',
                      icon: LucideIcons.chartColumn,
                      selected: false,
                      onTap: () => context.push('/insights'),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Search or jump to',
                      icon: const Icon(LucideIcons.search),
                      onPressed: () => context.push('/search'),
                    ),
                    IconButton(
                      tooltip: 'Account menu',
                      icon: const Icon(LucideIcons.user),
                      onPressed: () => showAccountSheet(context),
                    ),
                    const SizedBox(height: AppTokens.space3),
                  ],
                ),
              ),
            ),
          ),
          VerticalDivider(width: 1, color: t.line),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: docked ? 760 : 900),
                child: navigationShell,
              ),
            ),
          ),
          if (docked)
            _DetailDock(
              key: ValueKey('dock-$selectedId'),
              onClose: () => context.setQueryParams({'select': null}),
              child: recordPanel(type, selectedId),
            ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72, minWidth: 104),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: motionDuration(context),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: selected ? t.pinkSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? t.ink : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Icon(icon, size: 20, color: selected ? t.ink : t.muted),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textScaler: MediaQuery.textScalerOf(context)
                    .clamp(maxScaleFactor: 1.3),
                style: TextStyle(
                  fontSize: AppTokens.textMeta,
                  fontWeight: FontWeight.w700,
                  color: selected ? t.ink : t.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Record details docked on the right (the website's detail panel), with a close button.
class _DetailDock extends StatelessWidget {
  const _DetailDock({super.key, required this.child, required this.onClose});

  final Widget child;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: dockWidth,
      decoration: BoxDecoration(
        color: t.paper,
        border: Border(left: BorderSide(color: t.line)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          left: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Close details',
                  icon: const Icon(LucideIcons.x),
                  onPressed: onClose,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.space5,
                    0,
                    AppTokens.space5,
                    AppTokens.space6,
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
