import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/tokens.dart';

/// Page title block: title, optional description and trailing actions.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.description,
    this.actions = const [],
  });

  final String title;
  final String? description;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: text.headlineMedium),
          ),
          if (description != null) ...[
            const SizedBox(height: AppTokens.space1),
            Text(
              description!,
              style: text.bodyMedium?.copyWith(color: context.tokens.muted),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppTokens.space3),
            Wrap(
              spacing: AppTokens.space2,
              runSpacing: AppTokens.space2,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

/// Titled section with an optional trailing link-style action.
class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.title,
    required this.child,
    this.action,
  });

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: AppTokens.space2),
          child,
        ],
      ),
    );
  }
}

class Stat {
  const Stat(this.label, this.value, {this.hint});
  final String label;
  final String value;
  final String? hint;
}

/// Row of headline numbers (Home and project Overview).
class StatStrip extends StatelessWidget {
  const StatStrip({super.key, required this.stats});

  final List<Stat> stats;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space5),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0) const SizedBox(width: AppTokens.space2),
              Expanded(
                child: Semantics(
                  label: '${stats[i].label}: ${stats[i].value}',
                  child: ExcludeSemantics(
                    child: Container(
                      padding: const EdgeInsets.all(AppTokens.space3),
                      decoration: BoxDecoration(
                        color: t.paper,
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        border: Border.all(color: t.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stats[i].value,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(
                            stats[i].label,
                            style: TextStyle(
                              fontSize: AppTokens.textMeta,
                              color: t.muted,
                            ),
                          ),
                          if (stats[i].hint != null)
                            Text(
                              stats[i].hint!,
                              style: TextStyle(
                                fontSize: AppTokens.textMeta,
                                color: t.pink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TabItem {
  const TabItem(this.id, this.label, {this.icon, this.count});
  final String id;
  final String label;
  final IconData? icon;
  final int? count;
}

/// Scrollable view tabs (website `ViewTabs`): selected tab has an ink underline and bold text.
class ViewTabs extends StatelessWidget {
  const ViewTabs({
    super.key,
    required this.tabs,
    required this.value,
    required this.onChanged,
  });

  final List<TabItem> tabs;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.space4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tab in tabs)
              Semantics(
                button: true,
                selected: tab.id == value,
                label: tab.count == null
                    ? tab.label
                    : '${tab.label}, ${tab.count}',
                child: InkWell(
                  onTap: () => onChanged(tab.id),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: AppTokens.minTarget,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space3,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: tab.id == value ? t.ink : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: ExcludeSemantics(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (tab.icon != null) ...[
                            Icon(
                              tab.icon,
                              size: 16,
                              color: tab.id == value ? t.ink : t.muted,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontWeight: tab.id == value
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: tab.id == value ? t.ink : t.muted,
                            ),
                          ),
                          if (tab.count != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${tab.count}',
                              style: TextStyle(
                                fontSize: AppTokens.textMeta,
                                color: t.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Two- or three-way toggle (List/Board, Grid/List, Groups/Timeline). Selected segment gets an ink outline.
class SegmentedToggle extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
  });

  final List<(String id, String label)> options;
  final String value;
  final ValueChanged<String> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      container: true,
      label: label,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: t.line,
          borderRadius: BorderRadius.circular(999),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (id, text) in options)
                Semantics(
                  button: true,
                  selected: id == value,
                  label: text,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(id),
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: AppTokens.minTarget,
                        minWidth: 64,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.space4,
                      ),
                      decoration: BoxDecoration(
                        color: id == value ? t.paper : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: id == value ? t.ink : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ExcludeSemantics(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: AppTokens.textBody,
                            color: t.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Definition list of label/value rows (website `Fields`). A null value is skipped.
class Fields extends StatelessWidget {
  const Fields({super.key, required this.items});

  final List<(String label, Widget? value)> items;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      children: [
        for (final (label, value) in items)
          if (value != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 104,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: AppTokens.textMeta,
                        color: t.muted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(alignment: Alignment.centerLeft, child: value),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

/// Search field with an optional filter button and count badge. The filter sheet content is
/// supplied by the screen.
class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    required this.hint,
    required this.onSearch,
    this.filterCount = 0,
    this.onFilter,
  });

  final String hint;
  final ValueChanged<String> onSearch;
  final int filterCount;
  final VoidCallback? onFilter;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: color, width: width),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                filled: true,
                fillColor: t.paper,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: border(t.lineStrong),
                enabledBorder: border(t.lineStrong),
                focusedBorder: border(t.ink, 2),
              ),
            ),
          ),
          if (onFilter != null) ...[
            const SizedBox(width: AppTokens.space2),
            Badge(
              isLabelVisible: filterCount > 0,
              label: Text('$filterCount'),
              child: IconButton.outlined(
                tooltip: filterCount > 0
                    ? 'Filters, $filterCount active'
                    : 'Filters',
                onPressed: onFilter,
                icon: const Icon(LucideIcons.listFilter, size: 18),
                style: IconButton.styleFrom(
                  minimumSize: const Size(
                    AppTokens.minTarget,
                    AppTokens.minTarget,
                  ),
                  side: BorderSide(color: t.ink, width: 2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
