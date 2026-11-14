import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/brand_mark.dart';
import '../../features/quickadd/quick_add_sheet.dart';
import '../layout_breakpoints.dart';
import 'account_sheet.dart';
import 'wide_shell.dart';

/// Level-1 destinations (website `nav.js`): the mobile bar shows four of the five,
/// with Quick add in the middle. Insights lives in the account menu.
class _Destination {
  const _Destination(this.label, this.icon);
  final String label;
  final IconData icon;
}

const _destinations = [
  _Destination('Home', LucideIcons.house),
  _Destination('Projects', LucideIcons.folderKanban),
  _Destination('Tasks', LucideIcons.listChecks),
  _Destination('Library', LucideIcons.library),
];

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    if (isWideLayout(context)) {
      return WideShell(navigationShell: navigationShell);
    }
    final index = navigationShell.currentIndex;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppTokens.pageGutter,
        title: const Align(alignment: Alignment.centerLeft, child: BrandLogo()),
        actions: [
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
          const SizedBox(width: 4),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: _BottomBar(
        currentIndex: index,
        onSelect: (i) =>
            navigationShell.goBranch(i, initialLocation: i == index),
        onQuickAdd: () => showQuickAddSheet(context),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentIndex,
    required this.onSelect,
    required this.onQuickAdd,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onQuickAdd;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget item(int i) {
      final d = _destinations[i];
      final active = i == currentIndex;
      return Expanded(
        child: Semantics(
          button: true,
          selected: active,
          label: d.label,
          child: InkWell(
            onTap: () => onSelect(i),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
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
                      color: active ? t.pinkSoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: active ? t.ink : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      d.icon,
                      size: 20,
                      color: active ? t.ink : t.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    d.label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    // Navigation labels stop growing at 130% so the bar stays compact at large text sizes.
                    textScaler: MediaQuery.textScalerOf(context)
                        .clamp(maxScaleFactor: 1.3),
                    style: TextStyle(
                      fontSize: AppTokens.textMeta,
                      fontWeight: FontWeight.w700,
                      color: active ? t.ink : t.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: t.paper,
      child: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: t.line)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  item(0),
                  item(1),
                  Expanded(
                    child: Center(
                      child: Semantics(
                        button: true,
                        label: 'Quick add',
                        child: Material(
                          color: t.pink,
                          shape: CircleBorder(
                            side: BorderSide(color: t.ink, width: 2),
                          ),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onQuickAdd,
                            child: const SizedBox(
                              width: 52,
                              height: 52,
                              child: Icon(
                                LucideIcons.plus,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  item(2),
                  item(3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
