import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/format.dart';
import '../../core/data/models.dart';
import '../../core/data/selectors.dart';
import '../../core/data/status.dart';
import '../../core/data/workspace_store.dart';
import '../../core/theme/tokens.dart';
import 'badges.dart';
import 'record_sheets.dart';
import 'task_tile.dart';

/// Shared card shell for list rows: paper card, thin border, ink outline when selected.
class RowCard extends StatelessWidget {
  const RowCard({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.padding,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: onTap != null,
      selected: selected,
      child: Material(
        color: t.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          side: BorderSide(
            color: selected ? t.ink : t.line,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppTokens.minTarget),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(AppTokens.space3),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _meta(BuildContext context, String text) => Text(
  text,
  style: TextStyle(fontSize: AppTokens.textMeta, color: context.tokens.muted),
);

/// A milestone with its tasks underneath (project Work tab).
class MilestoneGroup extends ConsumerWidget {
  const MilestoneGroup({
    super.key,
    required this.milestone,
    required this.tasks,
    this.selectedId,
    this.onSelectTask,
    this.onSelectMilestone,
    this.initiallyExpanded = true,
  });

  final Milestone milestone;
  final List<Task> tasks;
  final String? selectedId;
  final ValueChanged<String>? onSelectTask;

  /// Called with the milestone id when its details button is tapped (default: opens its sheet).
  final ValueChanged<String>? onSelectMilestone;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(workspaceDataProvider);
    final state = milestoneState(milestone);
    final progress = data.milestoneProgress(milestone.id);
    final after = milestone.afterId == null
        ? null
        : data.milestoneById(milestone.afterId!);
    final t = context.tokens;
    return Material(
      color: t.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        side: BorderSide(color: t.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: AppTokens.space3),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppTokens.space2,
            0,
            AppTokens.space2,
            AppTokens.space2,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  milestone.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Milestone details',
                icon: const Icon(LucideIcons.info, size: 18),
                onPressed: () => onSelectMilestone != null
                    ? onSelectMilestone!(milestone.id)
                    : showRecordSheet(context, 'Milestone', milestone.id),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppTokens.space2,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(StatusDomain.derived, state),
                    if (milestone.blocked) const Flag('Blocked'),
                    DueLabel(due: milestone.due, done: state == 'Done'),
                    if (after != null) _meta(context, 'after ${after.title}'),
                  ],
                ),
                const SizedBox(height: 6),
                TsProgressBar(
                  value: progress.done,
                  max: progress.total,
                  label: '${milestone.title} tasks done',
                ),
              ],
            ),
          ),
          children: [
            if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppTokens.space3),
                child: _meta(context, 'No tasks yet'),
              )
            else
              for (final task in tasks)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.space2),
                  child: TaskTile(
                    task: task,
                    selected: selectedId == task.id,
                    onTap: onSelectTask == null
                        ? null
                        : () => onSelectTask!(task.id),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Requirement row (website `RequirementRow`).
class RequirementRow extends ConsumerWidget {
  const RequirementRow({
    super.key,
    required this.requirement,
    this.onTap,
    this.selected = false,
  });

  final Requirement requirement;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(workspaceDataProvider);
    final criteria = criteriaProgress(requirement);
    final links = data.requirementLinks(requirement);
    final t = context.tokens;
    return RowCard(
      selected: selected,
      onTap:
          onTap ??
          () => showRecordSheet(context, 'Requirement', requirement.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${requirement.label}  ',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: AppTokens.textMeta,
                    color: t.muted,
                  ),
                ),
                TextSpan(
                  text: requirement.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: AppTokens.space2,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _meta(
                context,
                criteria.total == 0
                    ? 'No criteria'
                    : '${criteria.met}/${criteria.total} criteria',
              ),
              _meta(
                context,
                '${plural(links.tasks.length, 'task')} · ${plural(links.files.length, 'file')}',
              ),
              if (links.gapTask)
                const TonePill(
                  label: 'No work yet',
                  tone: StatusTone.warning,
                  quiet: true,
                ),
              StatusBadge(StatusDomain.requirement, requirement.status),
              if (requirement.verified) const Flag('Verified'),
            ],
          ),
        ],
      ),
    );
  }
}

const _kindIcons = <String, IconData>{
  'document': LucideIcons.fileText,
  'image': LucideIcons.image,
  'media': LucideIcons.music,
  'data': LucideIcons.table,
  'link': LucideIcons.link2,
};

Color _kindColor(BuildContext context, String kind) {
  final t = context.tokens;
  return switch (kind) {
    'image' => t.blueSoft,
    'document' => t.butterSoft,
    'media' => t.lilac,
    'data' => t.greenSoft,
    'link' => t.pinkSoft,
    _ => t.line,
  };
}

/// Coloured thumbnail with the kind icon and extension (website `FileThumb`).
class FileThumb extends StatelessWidget {
  const FileThumb({super.key, required this.file, this.large = false});

  final WorkFile file;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final size = large ? 160.0 : 56.0;
    return ExcludeSemantics(
      child: Container(
        width: large ? double.infinity : size,
        height: size,
        decoration: BoxDecoration(
          color: _kindColor(context, file.kind),
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _kindIcons[file.kind] ?? LucideIcons.file,
              size: large ? 40 : 22,
              color: t.ink,
            ),
            Text(
              file.ext == 'link' ? 'link' : '.${file.ext}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textScaler: large ? null : TextScaler.noScaling,
              style: TextStyle(
                height: 1.2,
                fontSize: AppTokens.textMeta,
                color: t.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Library grid tile or project Files tile.
class FileTile extends ConsumerWidget {
  const FileTile({
    super.key,
    required this.file,
    this.onTap,
    this.selected = false,
  });

  final WorkFile file;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref
        .watch(workspaceDataProvider)
        .projectById(file.projectId);
    final size = file.progress != null
        ? '${file.progress}% uploaded'
        : file.kind == 'link'
        ? (file.host ?? 'Link')
        : formatBytes(file.bytes);
    return RowCard(
      selected: selected,
      onTap: onTap ?? () => showRecordSheet(context, 'File', file.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FileThumb(file: file, large: true),
          const SizedBox(height: AppTokens.space2),
          Text(
            file.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (project != null) _meta(context, project.name),
          const SizedBox(height: 4),
          Wrap(
            spacing: AppTokens.space2,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _meta(context, size),
              if (file.body != null && file.status != null)
                StatusBadge(StatusDomain.document, file.status!),
              if (file.body == null && isFinalFile(file))
                const Flag('Final', label: 'Final file'),
            ],
          ),
          if (file.progress != null) ...[
            const SizedBox(height: 6),
            TsProgressBar(
              value: file.progress!,
              max: 100,
              label: '${file.name} upload',
              showCount: false,
            ),
          ],
        ],
      ),
    );
  }
}

/// List-mode file row (Library list layout).
class FileRow extends ConsumerWidget {
  const FileRow({
    super.key,
    required this.file,
    this.onTap,
    this.selected = false,
  });

  final WorkFile file;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref
        .watch(workspaceDataProvider)
        .projectById(file.projectId);
    return RowCard(
      selected: selected,
      onTap: onTap ?? () => showRecordSheet(context, 'File', file.id),
      child: Row(
        children: [
          FileThumb(file: file),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Wrap(
                  spacing: AppTokens.space2,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (project != null) _meta(context, project.name),
                    _meta(
                      context,
                      file.bytes > 0
                          ? formatBytes(file.bytes)
                          : (file.host ?? ''),
                    ),
                    if (file.body != null && file.status != null)
                      StatusBadge(StatusDomain.document, file.status!),
                    if (file.body == null && isFinalFile(file))
                      const Flag('Final', label: 'Final file'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One entry of the History feed: a timeline dot and a card (website `ChangeEntry`).
class ChangeEntry extends ConsumerWidget {
  const ChangeEntry({
    super.key,
    required this.change,
    this.onTap,
    this.selected = false,
    this.last = false,
  });

  final Change change;
  final VoidCallback? onTap;
  final bool selected;
  final bool last;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(workspaceDataProvider);
    final t = context.tokens;
    final record = data.recordTitle(change.recordType, change.recordId);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 18),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: t.pink,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!last) Expanded(child: Container(width: 2, color: t.line)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.space2),
              child: RowCard(
                selected: selected,
                onTap:
                    onTap ??
                    () => showRecordSheet(context, 'Change', change.id),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      change.summary,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: AppTokens.space2,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _meta(context, '${change.recordType}: $record'),
                        if (change.toVersion != null)
                          _meta(
                            context,
                            'v${change.fromVersion} → v${change.toVersion}',
                          ),
                        _meta(context, timeAgo(change.at)),
                        if (change.reviewed) const Flag('Reviewed'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Where a relation chip leads: its icon.
const _typeIcons = <String, IconData>{
  'Project': LucideIcons.folderKanban,
  'Milestone': LucideIcons.flag,
  'Task': LucideIcons.listChecks,
  'Requirement': LucideIcons.clipboardList,
  'File': LucideIcons.fileText,
  'Change': LucideIcons.history,
};

/// Chip linking to another record. Tapping opens that record (a project opens its page, anything
/// else opens its detail sheet over the current screen).
class RelationChip extends ConsumerWidget {
  const RelationChip({
    super.key,
    required this.type,
    required this.id,
    this.label,
  });

  final String type;
  final String id;
  final String? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(workspaceDataProvider);
    final t = context.tokens;
    final text = label ?? data.recordTitle(type, id);
    return Semantics(
      button: true,
      label: '$type: $text',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => openRecord(context, type, id),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppTokens.minTarget),
          child: Align(
            widthFactor: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: t.paper,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: t.lineStrong),
              ),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _typeIcons[type] ?? LucideIcons.link,
                      size: 14,
                      color: t.muted,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: AppTokens.textMeta,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Why it exists" / "What it becomes" block shown on every record (the traceability idea).
class LensBlock extends StatelessWidget {
  const LensBlock({
    super.key,
    this.why = const [],
    this.becomes = const [],
    this.emptyWhy = '',
    this.emptyBecomes = '',
  });

  final List<Widget> why;
  final List<Widget> becomes;
  final String emptyWhy;
  final String emptyBecomes;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget group(String title, List<Widget> chips, String empty) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 4),
        if (chips.isNotEmpty)
          Wrap(spacing: AppTokens.space2, children: chips)
        else if (empty.isNotEmpty)
          Text(
            empty,
            style: TextStyle(color: t.muted, fontSize: AppTokens.textBody),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        group('Why it exists', why, emptyWhy),
        const SizedBox(height: AppTokens.space3),
        group('What it becomes', becomes, emptyBecomes),
      ],
    );
  }
}
