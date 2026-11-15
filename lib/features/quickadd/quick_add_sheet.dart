import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/format.dart';
import '../../core/data/models.dart';
import '../../core/data/selectors.dart';
import '../../core/data/workspace_store.dart';
import '../../core/feedback/app_feedback.dart';
import '../../core/quickadd/parse.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/confirm_discard.dart';
import '../../shared/widgets/preview_sheet.dart';
import '../projects/new_project_sheet.dart';

/// The project used last in Quick add this session; the next sheet starts there.
class LastProjectNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

final lastProjectProvider = NotifierProvider<LastProjectNotifier, String?>(
  LastProjectNotifier.new,
);

/// Whether the one-time typed-syntax tip was dismissed this session.
class QuickAddTipNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void dismiss() => state = true;

  void show() => state = false;
}

final quickAddTipDismissedProvider =
    NotifierProvider<QuickAddTipNotifier, bool>(QuickAddTipNotifier.new);

/// Long-press menu on the + button: New task, New project, New note (a preview).
Future<void> showCreateMenu(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (icon, label, run) in <(IconData, String, VoidCallback)>[
            (
              LucideIcons.listPlus,
              'New task',
              () => showQuickAddSheet(context),
            ),
            (
              LucideIcons.folderPlus,
              'New project',
              () => showNewProjectSheet(context),
            ),
            (
              LucideIcons.stickyNote,
              'New note',
              () => showPreviewSheet(
                context,
                body: 'In the full product you would write a quick note here. Notes are not part of the demo, so nothing was added.',
              ),
            ),
          ])
            ListTile(
              minTileHeight: AppTokens.minTarget,
              leading: Icon(icon, size: 20),
              title: Text(label),
              onTap: () {
                Navigator.of(sheetContext).pop();
                run();
              },
            ),
        ],
      ),
    ),
  );
}

/// Quick add (website `QuickAdd`): one line is enough. Details are picked up as you type
/// (`#project`, a day word, `!`) and every detail is also a chip you can tap to change.
/// Added tasks are session-only and the sheet stays open for rapid entry.
Future<void> showQuickAddSheet(BuildContext context, {String? projectId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: QuickAddSheet(projectId: projectId),
    ),
  );
}

class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key, this.projectId});

  final String? projectId;

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  final _controller = TextEditingController();
  String _message = '';

  // Picked by tapping a chip; these win over what the typed line says.
  String? _project;
  String? _due;
  bool _dueSet = false;
  bool? _high;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _fallback(WorkspaceData data) =>
      widget.projectId ??
      ref.read(lastProjectProvider) ??
      (data.activeProjects.isEmpty ? null : data.activeProjects.first.id);

  /// What the typed line says, with anything picked by tapping on top.
  QuickAddResult _effective(WorkspaceData data) {
    final typed = parseQuickAdd(_controller.text, _fallback(data), data);
    return QuickAddResult(
      title: typed.title,
      priority: (_high ?? typed.priority == 'high') ? 'high' : 'normal',
      due: _dueSet ? _due : typed.due,
      projectId: _project ?? typed.projectId,
    );
  }

  void _submit() {
    final data = ref.read(workspaceDataProvider);
    final parsed = _effective(data);
    if (parsed.title.isEmpty) return;
    ref
        .read(sessionProvider.notifier)
        .addTask(
          title: parsed.title,
          priority: parsed.priority,
          due: parsed.due,
          projectId: parsed.projectId ?? 'project-garden',
        );
    ref.read(lastProjectProvider.notifier).set(parsed.projectId);
    ref.read(feedbackProvider).haptic(Haptic.light);
    final project = data.projectById(parsed.projectId ?? '');
    setState(() {
      _message =
          'Added “${parsed.title}” to ${project?.name ?? 'your project'} for this session.';
      _controller.clear();
      _due = null;
      _dueSet = false;
      _high = null;
      _project = parsed.projectId; // the project carries over to the next task
    });
  }

  Future<void> _pickProject(WorkspaceData data, String? current) async {
    final id = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetTitle('Project', sheetContext),
              for (final p in data.activeProjects)
                ListTile(
                  minTileHeight: AppTokens.minTarget,
                  title: Text(p.name),
                  trailing: p.id == current
                      ? const Icon(LucideIcons.check, size: 18)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(p.id),
                ),
            ],
          ),
        ),
      ),
    );
    if (id != null && mounted) setState(() => _project = id);
  }

  Future<void> _pickDate(String? current) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetTitle('Due date', sheetContext),
            for (final (label, value) in <(String, String)>[
              ('Today', 'today'),
              ('Tomorrow', 'tomorrow'),
              ('Next week', 'week'),
              ('Pick a date…', 'pick'),
              ('No date', 'none'),
            ])
              ListTile(
                minTileHeight: AppTokens.minTarget,
                title: Text(label),
                onTap: () => Navigator.of(sheetContext).pop(value),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    String? due;
    switch (choice) {
      case 'today':
        due = demoToday;
      case 'tomorrow':
        due = tomorrowIso;
      case 'week':
        due = addDays(demoToday, 7);
      case 'none':
        due = null;
      default:
        final picked = await showDatePicker(
          context: context,
          initialDate: parseDay(current ?? demoToday),
          firstDate: DateTime(2025),
          lastDate: DateTime(2029, 12, 31),
        );
        if (picked == null || !mounted) return;
        due = addDays(demoToday, picked.difference(parseDay(demoToday)).inDays);
    }
    setState(() {
      _due = due;
      _dueSet = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(workspaceDataProvider);
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final parsed = _effective(data);
    final project = data.projectById(parsed.projectId ?? '');
    final tipDismissed = ref.watch(quickAddTipDismissedProvider);
    return PopScope(
      // A typed line is a draft: back asks before throwing it away.
      canPop: _controller.text.trim().isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await confirmDiscard(context, 'Discard this task?');
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text('Quick add a task', style: text.titleLarge),
            ),
            Text(
              'One line is enough. Tap a chip to change a detail.',
              style: text.bodyMedium?.copyWith(color: t.muted),
            ),
            const SizedBox(height: AppTokens.space3),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() => _message = ''),
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Write the task, e.g. Proof chapter one',
                prefixIcon: const Icon(LucideIcons.plus, size: 18),
                filled: true,
                fillColor: t.paper,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  borderSide: BorderSide(color: t.controlBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  borderSide: BorderSide(color: t.controlBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  borderSide: BorderSide(color: t.ink, width: 2),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.space3),
            Semantics(
              label: 'Details. Tap a chip to change it.',
              child: Wrap(
                spacing: AppTokens.space2,
                runSpacing: AppTokens.space2,
                children: [
                  _Chip(
                    project?.name ?? 'No project',
                    icon: LucideIcons.folder,
                    onTap: () => _pickProject(data, parsed.projectId),
                  ),
                  _Chip(
                    parsed.due == null ? 'No date' : formatDate(parsed.due!),
                    icon: LucideIcons.calendar,
                    onTap: () => _pickDate(parsed.due),
                  ),
                  _Chip(
                    parsed.priority == 'high'
                        ? 'High priority'
                        : 'Normal priority',
                    icon: LucideIcons.arrowUp,
                    selected: parsed.priority == 'high',
                    onTap: () =>
                        setState(() => _high = parsed.priority != 'high'),
                  ),
                ],
              ),
            ),
            if (!tipDismissed)
              Padding(
                padding: const EdgeInsets.only(top: AppTokens.space2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tip: you can also type #project, a day word (today, tomorrow, fri) and ! for high priority.',
                        style: TextStyle(
                          fontSize: AppTokens.textMeta,
                          color: t.muted,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(quickAddTipDismissedProvider.notifier)
                          .dismiss(),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              ),
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
                child: Text(
                  _message,
                  style: TextStyle(color: t.green, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Close'),
                ),
                const SizedBox(width: AppTokens.space2),
                FilledButton(
                  onPressed: parsed.title.isEmpty ? null : _submit,
                  child: const Text('Add task'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.title, this.sheetContext);

  final String title;
  final BuildContext sheetContext;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppTokens.space5,
      0,
      AppTokens.space5,
      AppTokens.space2,
    ),
    child: Semantics(
      header: true,
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip(
    this.label, {
    required this.icon,
    this.onTap,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? t.accentContainer : t.paper,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? t.ink : t.controlBorder),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppTokens.minTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
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
    );
  }
}
