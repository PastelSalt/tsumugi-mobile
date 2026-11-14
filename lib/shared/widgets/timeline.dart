import 'package:flutter/material.dart';

import '../../core/data/format.dart';
import '../../core/data/models.dart';
import '../../core/data/selectors.dart';
import '../../core/data/status.dart';
import '../../core/theme/tokens.dart';
import 'badges.dart';
import 'records.dart';

/// Milestones on a shared date axis with a Today marker, as a vertical list (the website's own
/// narrow-screen layout) with a small span bar under each row. Every row is a real list item, so
/// the dates are also written out as text.
class TimelineList extends StatelessWidget {
  const TimelineList({
    super.key,
    required this.milestones,
    required this.projectName,
    required this.onSelect,
    this.selectedId,
    this.showProject = false,
  });

  final List<Milestone> milestones;

  /// Resolves a project id to its name (used when [showProject] is true).
  final String Function(String projectId) projectName;
  final ValueChanged<String> onSelect;
  final String? selectedId;
  final bool showProject;

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) return const SizedBox.shrink();
    final t = context.tokens;
    final sorted = stableSorted(
      milestones,
      (a, b) => a.start.compareTo(b.start),
    );
    final min = sorted.fold<String>(
      demoToday,
      (m, x) => x.start.compareTo(m) < 0 ? x.start : m,
    );
    final max = sorted.fold<String>(
      demoToday,
      (m, x) => x.due.compareTo(m) > 0 ? x.due : m,
    );
    final span = daysBetween(min, max).clamp(1, 100000);
    double frac(String day) => (daysBetween(min, day) / span).clamp(0.0, 1.0);
    final todayAt = frac(demoToday);

    var todayPlaced = false;
    final children = <Widget>[];
    Widget todayMarker() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: t.pink, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            'Today · ${formatDate(demoToday)}',
            style: TextStyle(
              color: t.pink,
              fontWeight: FontWeight.w700,
              fontSize: AppTokens.textMeta,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 2, color: t.pink)),
        ],
      ),
    );

    for (final m in sorted) {
      if (!todayPlaced && m.start.compareTo(demoToday) > 0) {
        children.add(todayMarker());
        todayPlaced = true;
      }
      final state = milestoneState(m);
      final style = statusStyles[StatusDomain.derived]![state]!;
      final left = frac(m.start);
      final width = (frac(m.due) - left).clamp(0.04, 1.0 - left);
      final selected = selectedId == m.id;
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.space2),
          child: RowCard(
            selected: selected,
            onTap: () => onSelect(m.id),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        m.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    StatusBadge(StatusDomain.derived, state),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${showProject ? '${projectName(m.projectId)} · ' : ''}${formatDate(m.start)} – ${formatDate(m.due)}',
                  style: TextStyle(
                    fontSize: AppTokens.textMeta,
                    color: t.muted,
                  ),
                ),
                const SizedBox(height: AppTokens.space2),
                ExcludeSemantics(
                  child: LayoutBuilder(
                    builder: (context, box) => SizedBox(
                      height: 10,
                      width: box.maxWidth,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: t.line,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          Positioned(
                            left: box.maxWidth * left,
                            width: box.maxWidth * width,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: t
                                    .tone(style.tone)
                                    .foreground
                                    .withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          Positioned(
                            left: box.maxWidth * todayAt - 1,
                            top: -2,
                            bottom: -2,
                            child: Container(width: 2, color: t.pink),
                          ),
                        ],
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
    if (!todayPlaced) children.add(todayMarker());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
