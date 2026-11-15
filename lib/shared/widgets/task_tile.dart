import 'dart:math' as math;

import 'package:flutter/semantics.dart' show CustomSemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/format.dart';
import '../../core/data/models.dart';
import '../../core/data/selectors.dart';
import '../../core/data/workspace_store.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import 'badges.dart';
import 'task_actions.dart';

/// Task list tile (docs/PLAN-MOBILE-UI.md section 6.2). Two lines, no card border:
///
/// ```
/// ( ) Title of the task                         Today
///     Project Garden · Chapter one review     ↑ High  ◔
/// ```
///
/// - The **status circle** completes (or reopens) the task with one tap; long-press opens the full
///   action menu. Swipe right completes, swipe left moves it to tomorrow; every gesture has a
///   menu or accessibility-action equivalent and an Undo message.
/// - Tapping the tile opens the details.
class TaskTile extends ConsumerWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.onTap,
    this.selected = false,
    this.showProject = false,
    this.divider = true,
  });

  final Task task;

  /// Defaults to opening the task's detail sheet.
  final VoidCallback? onTap;
  final bool selected;
  final bool showProject;

  /// Draw the hairline under the tile (inset to the text).
  final bool divider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(workspaceDataProvider);
    final t = context.tokens;
    final actions = TaskActions(context, ref);
    final done = task.status == 'Done';
    final milestone = task.milestoneId == null
        ? null
        : data.milestoneById(task.milestoneId!);
    final project = showProject ? data.projectById(task.projectId) : null;
    final open = onTap ?? () => openTaskDetails(context, task);
    final subDone = task.subtasks.where((s) => s.done).length;

    final secondary = <Widget>[
      if (project != null) _Meta(project.name),
      if (milestone != null) _Meta(milestone.title),
      if (task.blocked)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.octagonX, size: 13, color: t.danger),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                'Blocked',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppTokens.textMeta,
                  color: t.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      if (task.session) const SessionTag(),
    ];

    final tile = Material(
      color: selected ? t.accentContainer : t.background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusCircle(
            task: task,
            onTap: () => actions.toggleComplete(task),
            onLongPress: () => actions.showMenu(task, onOpenDetails: open),
          ),
          Expanded(
            child: InkWell(
              onTap: open,
              onLongPress: () => actions.showMenu(task, onOpenDetails: open),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 12,
                  bottom: 12,
                  right: AppTokens.pageGutter,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: done ? t.onSurfaceMuted : t.onSurface,
                                  decoration: done
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: t.onSurfaceMuted,
                                ),
                          ),
                          if (secondary.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Wrap(
                              spacing: AppTokens.space2,
                              runSpacing: 2,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: secondary,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTokens.space3),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 124),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          DueText(due: task.due, done: done),
                          if (task.priority == 'high' ||
                              task.subtasks.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Wrap(
                              alignment: WrapAlignment.end,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: AppTokens.space2,
                              children: [
                                if (task.priority == 'high')
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.arrowUp,
                                        size: 13,
                                        color: t.warning,
                                      ),
                                      Text(
                                        'High',
                                        style: TextStyle(
                                          fontSize: AppTokens.textMeta,
                                          color: t.warning,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (task.subtasks.isNotEmpty)
                                  SubtaskRing(
                                    done: subDone,
                                    total: task.subtasks.length,
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final withDivider = divider
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              tile,
              Divider(height: 1, indent: 56, color: t.outline),
            ],
          )
        : tile;

    return Semantics(
      container: true,
      customSemanticsActions: {
        CustomSemanticsAction(label: done ? 'Reopen' : 'Mark done'): () =>
            actions.toggleComplete(task),
        const CustomSemanticsAction(label: 'Move to tomorrow'): () =>
            actions.moveToTomorrow(task),
        CustomSemanticsAction(
          label: task.blocked ? 'Unblock' : 'Mark blocked',
        ): () =>
            actions.toggleBlocked(task),
        const CustomSemanticsAction(label: 'More actions'): () =>
            actions.showMenu(task, onOpenDetails: open),
        const CustomSemanticsAction(label: 'Delete'): () =>
            actions.delete(task),
      },
      child: Dismissible(
        key: ValueKey('task-tile-${task.id}'),
        // The swipe runs the action and the tile snaps back: the task moves group on its own.
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            actions.toggleComplete(task);
          } else {
            actions.moveToTomorrow(task);
          }
          return false;
        },
        background: _SwipeBackground(
          alignment: Alignment.centerLeft,
          color: t.successContainer,
          foreground: t.success,
          icon: done ? LucideIcons.rotateCcw : LucideIcons.check,
          label: done ? 'Reopen' : 'Done',
        ),
        secondaryBackground: _SwipeBackground(
          alignment: Alignment.centerRight,
          color: t.infoContainer,
          foreground: t.info,
          icon: LucideIcons.calendarArrowDown,
          label: 'Tomorrow',
        ),
        child: withDivider,
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: context.tokens.onSurfaceMuted),
  );
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.foreground,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final Color foreground;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    color: color,
    alignment: alignment,
    padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

/// The round status control. One tap completes or reopens; long-press opens the action menu.
/// Shapes differ by status (empty ring, half ring, filled check), so status is never colour alone.
class StatusCircle extends StatelessWidget {
  const StatusCircle({
    super.key,
    required this.task,
    required this.onTap,
    this.onLongPress,
  });

  final Task task;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final done = task.status == 'Done';
    final doing = task.status == 'Doing';
    return Semantics(
      button: true,
      checked: done,
      label: done
          ? 'Done. Double tap to reopen ${task.title}'
          : '${task.status}. Double tap to complete ${task.title}',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        onLongPress: onLongPress,
        radius: 24,
        child: SizedBox(
          width: AppTokens.minTarget,
          height: 52,
          child: Center(
            child: AnimatedContainer(
              duration: motionDuration(
                context,
                const Duration(milliseconds: 220),
              ),
              curve: Curves.easeOutCubic,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? t.green : Colors.transparent,
                border: Border.all(
                  color: done
                      ? t.green
                      : (doing ? t.onSurface : t.controlBorder),
                  width: 2,
                ),
              ),
              child: AnimatedSwitcher(
                duration: motionDuration(
                  context,
                  const Duration(milliseconds: 180),
                ),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: done
                    ? Icon(
                        LucideIcons.check,
                        key: const ValueKey('done'),
                        size: 14,
                        color: t.onAccent,
                      )
                    : doing
                    ? CustomPaint(
                        key: const ValueKey('doing'),
                        painter: _HalfDot(t.onSurface),
                      )
                    : const SizedBox.shrink(key: ValueKey('todo')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HalfDot extends CustomPainter {
  _HalfDot(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - 4,
    );
    canvas.drawArc(rect, math.pi / 2, math.pi, true, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_HalfDot old) => old.color != color;
}

/// Small progress ring for subtasks ("1 of 2").
class SubtaskRing extends StatelessWidget {
  const SubtaskRing({super.key, required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: '$done of $total subtasks done',
      child: ExcludeSemantics(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CustomPaint(
            painter: _Ring(
              fraction: total == 0 ? 0 : done / total,
              track: t.outlineStrong,
              fill: t.green,
            ),
          ),
        ),
      ),
    );
  }
}

class _Ring extends CustomPainter {
  _Ring({required this.fraction, required this.track, required this.fill});

  final double fraction;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 3.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(arc, 0, math.pi * 2, false, base);
    if (fraction > 0) {
      canvas.drawArc(
        arc,
        -math.pi / 2,
        math.pi * 2 * fraction,
        false,
        base
          ..color = fill
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_Ring old) =>
      old.fraction != fraction || old.track != track || old.fill != fill;
}

/// Due date as plain text (no pill): "Today", "3 days overdue", "18 Nov". Overdue and today get a
/// colour *and* wording or an icon, so colour is never the only cue.
class DueText extends StatelessWidget {
  const DueText({super.key, required this.due, this.done = false});

  final String? due;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final info = dueInfo(due, done: done);
    if (info.tone == DueTone.none) return const SizedBox.shrink();
    final (color, weight) = switch (info.tone) {
      DueTone.overdue => (t.danger, FontWeight.w600),
      DueTone.today => (t.warning, FontWeight.w600),
      DueTone.soon => (t.info, FontWeight.w500),
      _ => (t.onSurfaceMuted, FontWeight.w400),
    };
    // One text run with the icon inline, so the icon stays next to the words when they wrap.
    return Text.rich(
      textAlign: TextAlign.end,
      TextSpan(
        style: TextStyle(
          fontSize: AppTokens.textMeta,
          color: color,
          fontWeight: weight,
        ),
        children: [
          if (info.tone == DueTone.overdue)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Icon(LucideIcons.triangleAlert, size: 13, color: color),
              ),
            ),
          TextSpan(text: info.label),
        ],
      ),
    );
  }
}
