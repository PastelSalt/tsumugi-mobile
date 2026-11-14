import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/format.dart';
import '../../core/data/kinds.dart';
import '../../core/data/selectors.dart';
import '../../core/data/status.dart';
import '../../core/data/workspace_store.dart';
import '../../core/theme/tokens.dart';
import 'badges.dart';
import 'layout.dart';
import 'preview_sheet.dart';
import 'records.dart';
import 'states.dart';

/// Opens a record from anywhere (relation chips, search, links between records).
/// A project opens its page; every other record opens its detail sheet over the current screen.
void openRecord(BuildContext context, String type, String id) {
  if (type == 'Project') {
    GoRouter.of(context).go('/projects/$id');
  } else {
    showRecordSheet(context, type, id);
  }
}

/// The detail panel for one record. Shown in a draggable sheet on phones and docked beside the
/// list on wide screens.
Widget recordPanel(String type, String id) {
  switch (type) {
    case 'Task':
      return TaskPanel(taskId: id);
    case 'Milestone':
      return MilestonePanel(milestoneId: id);
    case 'Requirement':
      return RequirementPanel(requirementId: id);
    case 'File':
      return FilePanel(fileId: id);
    case 'Change':
      return ChangePanel(changeId: id);
  }
  return const _NotFoundPanel();
}

/// Draggable detail sheet (replaces the website's side panel) for one record.
Future<void> showRecordSheet(BuildContext context, String type, String id) {
  return showDetailSheet(context, (context) => recordPanel(type, id));
}

/// Generic draggable sheet: starts at 60% height and can be pulled up to nearly full screen.
Future<void> showDetailSheet(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space5,
          0,
          AppTokens.space5,
          AppTokens.space6,
        ),
        child: builder(sheetContext),
      ),
    ),
  );
}

/// Header (kicker and title), action buttons, then the body, for one record sheet.
class DetailPanel extends StatelessWidget {
  const DetailPanel({
    super.key,
    required this.title,
    required this.kicker,
    this.actions = const [],
    required this.children,
  });

  final String title;
  final String kicker;
  final List<Widget> actions;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kicker,
          style: TextStyle(
            fontSize: AppTokens.textMeta,
            color: t.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Semantics(header: true, child: Text(title, style: text.titleLarge)),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: AppTokens.space3),
          Wrap(
            spacing: AppTokens.space2,
            runSpacing: AppTokens.space2,
            children: actions,
          ),
        ],
        const SizedBox(height: AppTokens.space4),
        for (final child in children) ...[
          child,
          const SizedBox(height: AppTokens.space4),
        ],
      ],
    );
  }
}

class _NotFoundPanel extends StatelessWidget {
  const _NotFoundPanel();

  @override
  Widget build(BuildContext context) => const DetailPanel(
    title: 'Record not found',
    kicker: 'Not found',
    children: [Text('It may have been removed, or the link is wrong.')],
  );
}

Widget _chips(List<Widget> items) => Wrap(
  spacing: AppTokens.space2,
  runSpacing: AppTokens.space2,
  children: items,
);

class TaskPanel extends ConsumerWidget {
  const TaskPanel({super.key, required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(workspaceDataProvider);
    final task = data.taskById(taskId);
    if (task == null) return const _NotFoundPanel();
    final milestone = task.milestoneId == null
        ? null
        : data.milestoneById(task.milestoneId!);
    final project = data.projectById(task.projectId);
    final t = context.tokens;
    return DetailPanel(
      title: task.title,
      kicker: 'Task · ${project?.name ?? ''}',
      actions: [
        const PreviewAction(label: 'Edit task', primary: true),
        const PreviewAction(label: 'Change status'),
        PreviewAction(label: task.blocked ? 'Unblock' : 'Mark blocked'),
      ],
      children: [
        _chips([
          StatusBadge(StatusDomain.work, task.status),
          if (task.blocked) const Flag('Blocked'),
          if (task.priority == 'high')
            const Flag('High', label: 'High priority'),
        ]),
        if (task.notes.isNotEmpty) Text(task.notes),
        Fields(
          items: [
            ('Due', DueLabel(due: task.due, done: task.status == 'Done')),
            ('Milestone', Text(milestone?.title ?? 'None')),
          ],
        ),
        if (task.subtasks.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Subtasks', style: Theme.of(context).textTheme.titleMedium),
              for (final s in task.subtasks)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        s.done ? LucideIcons.check : LucideIcons.circle,
                        size: 16,
                        semanticLabel: s.done ? 'Done' : 'Not done',
                        color: s.done ? t.green : t.muted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(s.text)),
                    ],
                  ),
                ),
            ],
          ),
        LensBlock(
          why: [
            RelationChip(type: 'Project', id: task.projectId),
            if (milestone != null)
              RelationChip(type: 'Milestone', id: milestone.id),
            for (final id in task.requirementIds)
              RelationChip(type: 'Requirement', id: id, label: id),
          ],
          becomes: [
            for (final id in task.fileIds) RelationChip(type: 'File', id: id),
            for (final id in task.changeIds)
              RelationChip(type: 'Change', id: id),
          ],
          emptyWhy: 'Not linked to a requirement yet.',
          emptyBecomes: 'No files or changes yet.',
        ),
        if (task.session)
          const _Note(
            'Added for this session only. It disappears when you restart the app.',
          ),
      ],
    );
  }
}

class MilestonePanel extends ConsumerWidget {
  const MilestonePanel({super.key, required this.milestoneId});
  final String milestoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(workspaceDataProvider);
    final m = data.milestoneById(milestoneId);
    if (m == null) return const _NotFoundPanel();
    final state = milestoneState(m);
    final tasks = data.tasksOfMilestone(m.id);
    final after = m.afterId == null ? null : data.milestoneById(m.afterId!);
    return DetailPanel(
      title: m.title,
      kicker: 'Milestone · ${data.projectById(m.projectId)?.name ?? ''}',
      actions: const [
        PreviewAction(label: 'Edit milestone', primary: true),
        PreviewAction(label: 'Mark done'),
      ],
      children: [
        _chips([
          StatusBadge(StatusDomain.derived, state),
          if (m.blocked) const Flag('Blocked'),
        ]),
        Text(m.description),
        Fields(
          items: [
            ('Starts', Text(formatDate(m.start))),
            ('Due', DueLabel(due: m.due, done: state == 'Done')),
            ('After', after == null ? null : Text(after.title)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tasks', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            if (tasks.isEmpty)
              Text(
                'No tasks yet.',
                style: TextStyle(color: context.tokens.muted),
              )
            else
              _chips([
                for (final t in tasks) RelationChip(type: 'Task', id: t.id),
              ]),
          ],
        ),
      ],
    );
  }
}

class RequirementPanel extends ConsumerWidget {
  const RequirementPanel({super.key, required this.requirementId});
  final String requirementId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(workspaceDataProvider);
    final r = data.requirementById(requirementId);
    if (r == null) return const _NotFoundPanel();
    final links = data.requirementLinks(r);
    final t = context.tokens;
    return DetailPanel(
      title: r.title,
      kicker: '${r.id} · ${data.projectById(r.projectId)?.name ?? ''}',
      actions: const [
        PreviewAction(label: 'Mark met', primary: true),
        PreviewAction(label: 'Mark verified'),
        PreviewAction(label: 'Link work'),
      ],
      children: [
        _chips([
          StatusBadge(StatusDomain.requirement, r.status),
          if (r.verified) const Flag('Verified'),
          TonePill(label: r.type, tone: StatusTone.neutral, quiet: true),
        ]),
        Text(r.description),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acceptance criteria',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (r.acceptance.isEmpty)
              const Text(
                'No acceptance criteria defined. Add at least one before this can be marked met.',
              )
            else
              for (final c in r.acceptance)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        c.met ? LucideIcons.check : LucideIcons.circle,
                        size: 16,
                        semanticLabel: c.met ? 'Met' : 'Not met',
                        color: c.met ? t.green : t.muted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c.text)),
                    ],
                  ),
                ),
          ],
        ),
        LensBlock(
          why: [
            RelationChip(type: 'Project', id: r.projectId),
            if (links.milestone != null)
              RelationChip(type: 'Milestone', id: links.milestone!.id),
          ],
          becomes: [
            for (final task in links.tasks)
              RelationChip(type: 'Task', id: task.id),
            for (final f in links.files) RelationChip(type: 'File', id: f.id),
          ],
          emptyWhy: 'Linked to the project objective.',
          emptyBecomes: 'No work or files yet.',
        ),
        if (links.gapTask || links.gapFile)
          _chips([
            if (links.gapTask)
              const TonePill(
                label: 'No task yet',
                tone: StatusTone.warning,
                quiet: true,
              ),
            if (links.gapFile)
              const TonePill(
                label: 'No final file yet',
                tone: StatusTone.warning,
                quiet: true,
              ),
          ]),
      ],
    );
  }
}

class FilePanel extends ConsumerWidget {
  const FilePanel({super.key, required this.fileId});
  final String fileId;

  static const _previewable = {'png', 'jpg', 'md', 'pdf'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(workspaceDataProvider);
    final f = data.fileById(fileId);
    if (f == null) return const _NotFoundPanel();
    final t = context.tokens;
    final Widget preview;
    if (f.kind == 'link') {
      preview = _Unsupported(
        'Opens an external site (${f.host}). Tsumugi does not store this file.',
      );
    } else if (f.progress != null) {
      preview = _Unsupported(
        'Upload is ${f.progress}% complete (sample progress).',
      );
    } else if (_previewable.contains(f.ext)) {
      preview = Column(
        children: [
          FileThumb(file: f, large: true),
          const SizedBox(height: 4),
          Text(
            'Preview area — sample illustration',
            style: TextStyle(fontSize: AppTokens.textMeta, color: t.muted),
          ),
        ],
      );
    } else {
      preview = _Unsupported(
        '.${f.ext} files can’t be previewed here. Download it to open it in another app.',
      );
    }
    return DetailPanel(
      title: f.name,
      kicker:
          '${kindLabel(f.kind)} · ${data.projectById(f.projectId)?.name ?? ''}',
      actions: [
        if (f.body != null)
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              GoRouter.of(context).go('/library/doc/${f.id}');
            },
            child: const Text('Open'),
          )
        else
          const PreviewAction(label: 'Download', primary: true),
        PreviewAction(
          label: isFinalFile(f) ? 'Unmark final file' : 'Mark as final file',
        ),
      ],
      children: [
        preview,
        Text(f.description),
        Fields(
          items: [
            ('Type', Text('${kindLabel(f.kind)} (.${f.ext})')),
            ('Size', f.bytes > 0 ? Text(formatBytes(f.bytes)) : null),
            ('Updated', Text(formatDate(f.updatedAt))),
            ('Final file', Text(isFinalFile(f) ? 'Yes' : 'No')),
          ],
        ),
        _chips([
          for (final tag in f.tags)
            TonePill(label: '#$tag', tone: StatusTone.neutral, quiet: true),
        ]),
        LensBlock(
          why: [
            for (final id in f.requirementIds)
              RelationChip(type: 'Requirement', id: id, label: id),
          ],
          becomes: [
            for (final id in f.taskIds) RelationChip(type: 'Task', id: id),
          ],
          emptyWhy: 'Not linked to a requirement.',
          emptyBecomes: 'Not linked to a task.',
        ),
        const _Note(
          'Only metadata is shown here. Files themselves belong in object storage, not in the app.',
        ),
      ],
    );
  }
}

class ChangePanel extends ConsumerWidget {
  const ChangePanel({super.key, required this.changeId});
  final String changeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(workspaceDataProvider);
    final c = data.changeById(changeId);
    if (c == null) return const _NotFoundPanel();
    return DetailPanel(
      title: c.summary,
      kicker: 'Change · ${data.projectById(c.projectId)?.name ?? ''}',
      actions: [
        PreviewAction(
          label: c.reviewed ? 'Mark not reviewed' : 'Mark reviewed',
          primary: true,
        ),
      ],
      children: [
        _chips([
          c.reviewed
              ? const Flag('Reviewed')
              : const StatusBadge(StatusDomain.change, 'Recorded'),
        ]),
        Fields(
          items: [
            ('When', Text(c.at.replaceFirst('T', ' ').substring(0, 16))),
            ('Affected', Text('${c.recordType} ${c.recordId}')),
            (
              'Versions',
              c.toVersion == null
                  ? null
                  : Text('v${c.fromVersion} → v${c.toVersion}'),
            ),
          ],
        ),
        LensBlock(
          why: [
            for (final id in c.taskIds) RelationChip(type: 'Task', id: id),
            for (final id in c.requirementIds)
              RelationChip(type: 'Requirement', id: id, label: id),
          ],
          becomes: [RelationChip(type: c.recordType, id: c.recordId)],
          emptyWhy: 'No linked work.',
        ),
        if (c.diff != null)
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              GoRouter.of(context).go(
                '/projects/${c.projectId}?view=history&mode=compare&rev=${c.id}',
              );
            },
            child: const Text('Open comparison'),
          ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(AppTokens.space3),
      decoration: BoxDecoration(
        color: t.blueSoft,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppTokens.textMeta,
          color: const Color(0xFF1D5F80),
        ),
      ),
    );
  }
}

class _Unsupported extends StatelessWidget {
  const _Unsupported(this.reason);
  final String reason;

  @override
  Widget build(BuildContext context) => EmptyState(
    title: 'No preview available',
    body: reason,
    icon: LucideIcons.eyeOff,
  );
}
