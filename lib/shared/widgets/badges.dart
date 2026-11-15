import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/format.dart';
import '../../core/data/status.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';

/// Pill with icon and text on a tone colour. Status is never conveyed by colour alone.
class TonePill extends StatelessWidget {
  const TonePill({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
    this.quiet = false,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final colors = context.tokens.tone(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: colors.foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppTokens.textMeta,
                fontWeight: quiet ? FontWeight.w400 : FontWeight.w700,
                color: colors.foreground,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status badge from the shared vocabulary: `StatusBadge(StatusDomain.work, 'Doing')`.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.domain, this.status, {super.key});

  final StatusDomain domain;
  final String status;

  @override
  Widget build(BuildContext context) {
    final style =
        statusStyles[domain]?[status] ??
        const StatusStyle(StatusTone.neutral, LucideIcons.circle);
    return TonePill(label: status, tone: style.tone, icon: style.icon);
  }
}

/// Flag shown next to a status when it applies (Blocked, Verified, Reviewed, Final, High).
class Flag extends StatelessWidget {
  const Flag(this.name, {super.key, this.label});

  final String name;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final style =
        flagStyles[name] ??
        const StatusStyle(StatusTone.neutral, LucideIcons.flag);
    return TonePill(label: label ?? name, tone: style.tone, icon: style.icon);
  }
}

/// Due date with relative wording ("Today", "2 days overdue", "18 Nov").
class DueLabel extends StatelessWidget {
  const DueLabel({super.key, required this.due, this.done = false});

  final String? due;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final info = dueInfo(due, done: done);
    switch (info.tone) {
      case DueTone.overdue:
        return TonePill(
          label: info.label,
          tone: StatusTone.danger,
          icon: LucideIcons.triangleAlert,
        );
      case DueTone.today:
        return TonePill(
          label: info.label,
          tone: StatusTone.warning,
          icon: LucideIcons.calendar,
        );
      case DueTone.soon:
        return TonePill(
          label: info.label,
          tone: StatusTone.info,
          icon: LucideIcons.calendar,
        );
      case DueTone.later:
      case DueTone.done:
      case DueTone.none:
        return Text(
          info.label,
          style: TextStyle(
            fontSize: AppTokens.textMeta,
            color: context.tokens.muted,
          ),
        );
    }
  }
}

/// Small tag for records that exist only until the app restarts.
class SessionTag extends StatelessWidget {
  const SessionTag({super.key});

  @override
  Widget build(BuildContext context) =>
      const TonePill(label: 'Session only', tone: StatusTone.info, quiet: true);
}

/// Thin progress bar with a text-readable value for screen readers.
class TsProgressBar extends StatelessWidget {
  const TsProgressBar({
    super.key,
    required this.value,
    required this.max,
    required this.label,
    this.showCount = true,
  });

  final int value;
  final int max;
  final String label;
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fraction = max == 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Semantics(
      label: label,
      value: max == 0 ? 'No tasks' : '$value of $max',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Stack(
                  children: [
                    Container(height: 8, color: t.line),
                    // Fills from empty on first appearance and moves from the old value to the new one
                    // when the number changes (docs/PLAN-UX.md, M-7).
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: fraction),
                      duration: fadeDuration(context, Motion.number),
                      curve: Motion.standard,
                      builder: (context, f, _) => FractionallySizedBox(
                        widthFactor: f.clamp(0.0, 1.0),
                        child: Container(height: 8, color: t.green),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showCount) ...[
              const SizedBox(width: 8),
              Text(
                max == 0 ? '—' : '$value/$max',
                style: TextStyle(fontSize: AppTokens.textMeta, color: t.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
