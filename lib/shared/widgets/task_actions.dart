import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/format.dart';
import '../../core/data/models.dart';
import '../../core/data/selectors.dart';
import '../../core/data/status.dart';
import '../../core/data/workspace_store.dart';
import '../../core/feedback/app_feedback.dart';
import '../../core/theme/tokens.dart';
import 'confirm_discard.dart';
import 'record_sheets.dart';
import 'undo_toast.dart';

/// Shows a floating message with **Undo** (see [UndoToast]). Every in-session change goes through
/// here, instead of a confirmation dialog (docs/PLAN-MOBILE-UI.md section 7.3). The latest message
/// replaces the previous one.
void showUndoSnackBar(BuildContext context, WidgetRef ref, String message) {
  // Capture now: the tile that triggered this may move to another group (and unmount) before the
  // person taps Undo, and a disposed widget's `ref` can no longer be read.
  final session = ref.read(sessionProvider.notifier);
  final feedback = ref.read(feedbackProvider);
  UndoToast.show(
    context,
    message: message,
    onUndo: () {
      session.undo();
      feedback.haptic(Haptic.selection);
    },
  );
}

String _quote(String title) =>
    '“${title.length > 32 ? '${title.substring(0, 30)}…' : title}”';

/// Real, in-session task actions with haptics and an undo message. One instance per call site.
/// Nothing is saved: closing the app discards every change.
///
/// Everything the actions need (the session, haptics, the overlay for the Undo message and the root
/// navigator for sheets and dialogs) is captured here, when the instance is made. A task that
/// changes status moves to another group, which unmounts the tile that started the action; nothing
/// below may touch that tile's `context` or `ref` afterwards.
class TaskActions {
  TaskActions(BuildContext context, WidgetRef ref)
    : _session = ref.read(sessionProvider.notifier),
      _feedback = ref.read(feedbackProvider),
      _overlay = Overlay.maybeOf(context, rootOverlay: true),
      _nav = Navigator.of(context, rootNavigator: true).context;

  final SessionNotifier _session;
  final AppFeedback _feedback;
  final OverlayState? _overlay;
  final BuildContext _nav;

  void _undo(String message) {
    final overlay = _overlay;
    if (overlay == null) return;
    UndoToast.showIn(
      overlay,
      message: message,
      onUndo: () {
        _session.undo();
        _feedback.haptic(Haptic.selection);
      },
    );
  }

  /// Completes the task, or reopens it when it is already done.
  void toggleComplete(Task task) {
    final next = _session.toggleComplete(task.id);
    if (next == null) return;
    final done = next == 'Done';
    _feedback.haptic(done ? Haptic.medium : Haptic.selection);
    _undo(
      done
          ? 'Completed ${_quote(task.title)}'
          : 'Reopened ${_quote(task.title)}',
    );
  }

  void setStatus(Task task, String status) {
    if (task.status == status) return;
    _session.setTaskStatus(task.id, status);
    _feedback.haptic(Haptic.selection);
    _undo('${_quote(task.title)} is now $status');
  }

  void moveToTomorrow(Task task) {
    _session.rescheduleTask(task.id, tomorrowIso);
    _feedback.haptic(Haptic.light);
    _undo('Moved ${_quote(task.title)} to tomorrow');
  }

  /// Asks for a date with the system date picker, then moves the task there.
  Future<void> pickDate(Task task) async {
    final initial = task.due == null
        ? parseDay(demoToday)
        : parseDay(task.due!);
    final picked = await showDatePicker(
      context: _nav,
      initialDate: initial,
      firstDate: DateTime(2025),
      lastDate: DateTime(2029, 12, 31),
      helpText:
          'Move “${task.title.length > 24 ? '${task.title.substring(0, 22)}…' : task.title}” to',
    );
    if (picked == null) return;
    final iso = addDays(
      demoToday,
      picked.difference(parseDay(demoToday)).inDays,
    );
    _session.rescheduleTask(task.id, iso);
    _feedback.haptic(Haptic.light);
    _undo('Moved ${_quote(task.title)} to ${formatDate(iso)}');
  }

  void clearDate(Task task) {
    _session.rescheduleTask(task.id, null);
    _feedback.haptic(Haptic.light);
    _undo('Removed the date from ${_quote(task.title)}');
  }

  void toggleHighPriority(Task task) {
    final high = task.priority != 'high';
    _session.setTaskPriority(task.id, high ? 'high' : 'normal');
    _feedback.haptic(Haptic.selection);
    _undo(
      high
          ? '${_quote(task.title)} is high priority'
          : '${_quote(task.title)} is normal priority',
    );
  }

  void toggleBlocked(Task task) {
    _session.setTaskBlocked(task.id, !task.blocked);
    _feedback.haptic(Haptic.selection);
    _undo(
      task.blocked
          ? 'Unblocked ${_quote(task.title)}'
          : 'Blocked ${_quote(task.title)}',
    );
  }

  void toggleSubtask(Task task, int index) {
    _session.toggleSubtask(task.id, index);
    _feedback.haptic(Haptic.selection);
  }

  void delete(Task task) {
    _session.deleteTask(task.id);
    _feedback.haptic(Haptic.medium);
    _undo('Deleted ${_quote(task.title)}');
  }

  Future<void> edit(Task task) => _openEditor(this, _nav, task);

  /// The long-press menu, also reachable from the detail sheet.
  Future<void> showMenu(Task task, {VoidCallback? onOpenDetails}) =>
      _openMenu(this, _nav, task, onOpenDetails: onOpenDetails);
}

/// Bottom sheet listing every action for a task (the long-press menu). Thumb-friendly, 48 dp rows.
Future<void> showTaskActionSheet(
  BuildContext context,
  WidgetRef ref,
  Task task, {
  VoidCallback? onOpenDetails,
}) => _openMenu(
  TaskActions(context, ref),
  context,
  task,
  onOpenDetails: onOpenDetails,
);

Future<void> _openMenu(
  TaskActions actions,
  BuildContext context,
  Task task, {
  VoidCallback? onOpenDetails,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Consumer(
      builder: (_, sheetRef, _) {
        // Read the live task so the menu reflects changes made while it is open.
        final live =
            sheetRef.watch(workspaceDataProvider).taskById(task.id) ?? task;
        Widget item(
          IconData icon,
          String label,
          VoidCallback run, {
          bool danger = false,
        }) => ListTile(
          minTileHeight: AppTokens.minTarget,
          leading: Icon(
            icon,
            size: 20,
            color: danger ? sheetContext.tokens.danger : null,
          ),
          title: Text(
            label,
            style: danger ? TextStyle(color: sheetContext.tokens.danger) : null,
          ),
          onTap: () {
            Navigator.of(sheetContext).pop();
            run();
          },
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppTokens.space5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space5,
                  0,
                  AppTokens.space5,
                  AppTokens.space2,
                ),
                child: Text(
                  live.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space5,
                ),
                child: Wrap(
                  spacing: AppTokens.space2,
                  children: [
                    for (final s in workStatuses)
                      ChoiceChip(
                        label: Text(s),
                        selected: live.status == s,
                        onSelected: (_) {
                          Navigator.of(sheetContext).pop();
                          actions.setStatus(live, s);
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.space2),
              item(
                live.status == 'Done'
                    ? LucideIcons.rotateCcw
                    : LucideIcons.circleCheckBig,
                live.status == 'Done' ? 'Reopen' : 'Mark done',
                () => actions.toggleComplete(live),
              ),
              item(
                LucideIcons.calendarArrowDown,
                'Move to tomorrow',
                () => actions.moveToTomorrow(live),
              ),
              item(
                LucideIcons.calendarDays,
                'Pick a date…',
                () => actions.pickDate(live),
              ),
              if (live.due != null)
                item(
                  LucideIcons.calendarX,
                  'Remove the date',
                  () => actions.clearDate(live),
                ),
              item(
                LucideIcons.arrowUp,
                live.priority == 'high'
                    ? 'Make normal priority'
                    : 'Make high priority',
                () => actions.toggleHighPriority(live),
              ),
              item(
                LucideIcons.octagonX,
                live.blocked ? 'Unblock' : 'Mark blocked',
                () => actions.toggleBlocked(live),
              ),
              item(
                LucideIcons.pencil,
                'Edit title and notes',
                () => actions.edit(live),
              ),
              if (onOpenDetails != null)
                item(
                  LucideIcons.panelBottomOpen,
                  'Open details',
                  onOpenDetails,
                ),
              item(
                LucideIcons.trash2,
                'Delete',
                () => actions.delete(live),
                danger: true,
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// Edit a task's title and notes. Back asks before discarding changes.
Future<void> showTaskEditor(BuildContext context, WidgetRef ref, Task task) =>
    _openEditor(TaskActions(context, ref), context, task);

Future<void> _openEditor(TaskActions actions, BuildContext context, Task task) {
  final session = actions._session;
  final feedback = actions._feedback;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _TaskEditor(
        task: task,
        onSaved: () => actions._undo('Saved changes to ${_quote(task.title)}'),
        session: session,
        feedback: feedback,
      ),
    ),
  );
}

class _TaskEditor extends StatefulWidget {
  const _TaskEditor({
    required this.task,
    required this.onSaved,
    required this.session,
    required this.feedback,
  });

  final Task task;
  final VoidCallback onSaved;

  /// Captured when the editor opens: the tile that opened it may be gone by the time Save is
  /// tapped (a task that changes status moves to another group).
  final SessionNotifier session;
  final AppFeedback feedback;

  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  late final _title = TextEditingController(text: widget.task.title);
  late final _notes = TextEditingController(text: widget.task.notes);

  bool get _changed =>
      _title.text.trim() != widget.task.title ||
      _notes.text.trim() != widget.task.notes.trim();
  bool get _valid => _title.text.trim().isNotEmpty;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    if (!_valid) return;
    widget.session.editTask(
      widget.task.id,
      title: _title.text.trim(),
      notes: _notes.text.trim(),
    );
    widget.feedback.haptic(Haptic.light);
    Navigator.of(context).pop();
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PopScope(
      canPop: !_changed,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await confirmDiscard(context, 'Discard your changes?');
        if (discard && context.mounted) Navigator.of(context).pop();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space5,
          0,
          AppTokens.space5,
          AppTokens.space5,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text('Edit task', style: text.titleLarge),
            ),
            const SizedBox(height: AppTokens.space3),
            TextField(
              controller: _title,
              autofocus: true,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Title',
                errorText: _valid ? null : 'A task needs a title',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppTokens.space3),
            TextField(
              controller: _notes,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Notes',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppTokens.space2),
            Text(
              'Changes last until you close the app.',
              style: TextStyle(
                fontSize: AppTokens.textMeta,
                color: context.tokens.muted,
              ),
            ),
            const SizedBox(height: AppTokens.space4),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppTokens.space2,
              runSpacing: AppTokens.space2,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: _valid && _changed ? _save : null,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens a task's detail sheet (shared by tiles and menus).
void openTaskDetails(BuildContext context, Task task) =>
    showRecordSheet(context, 'Task', task.id);
