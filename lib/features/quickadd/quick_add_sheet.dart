import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/format.dart';
import '../../core/data/models.dart';
import '../../core/data/selectors.dart';
import '../../core/data/workspace_store.dart';
import '../../core/quickadd/parse.dart';
import '../../core/theme/tokens.dart';

/// Quick add (website `QuickAdd`): one line is enough. Details are picked up as you type:
/// `#project`, a day word (today, tomorrow, fri) and `!` for high priority.
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final data = ref.read(workspaceDataProvider);
    final parsed = parseQuickAdd(_controller.text, _fallback(data), data);
    if (parsed.title.isEmpty) return;
    ref
        .read(sessionProvider.notifier)
        .addTask(
          title: parsed.title,
          priority: parsed.priority,
          due: parsed.due,
          projectId: parsed.projectId ?? 'project-garden',
        );
    final project = data.projectById(parsed.projectId ?? '');
    setState(() {
      _message =
          'Added “${parsed.title}” to ${project?.name ?? 'your project'} for this session.';
      _controller.clear();
    });
  }

  String? _fallback(WorkspaceData data) =>
      widget.projectId ??
      (data.activeProjects.isEmpty ? null : data.activeProjects.first.id);

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(workspaceDataProvider);
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final parsed = parseQuickAdd(_controller.text, _fallback(data), data);
    final project = data.projectById(parsed.projectId ?? '');
    return Padding(
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
            'One line is enough. Details are picked up as you type.',
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
              hintText:
                  'Write the task, e.g. Proof chapter one #garden tomorrow !',
              prefixIcon: const Icon(LucideIcons.plus, size: 18),
              filled: true,
              fillColor: t.paper,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                borderSide: BorderSide(color: t.lineStrong),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                borderSide: BorderSide(color: t.lineStrong),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                borderSide: BorderSide(color: t.ink, width: 2),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space3),
          Semantics(
            label: 'Detected details',
            child: Wrap(
              spacing: AppTokens.space2,
              runSpacing: AppTokens.space2,
              children: [
                _Chip(project?.name ?? 'No project'),
                _Chip(parsed.due == null ? 'No date' : formatDate(parsed.due!)),
                if (parsed.priority == 'high') const _Chip('High priority'),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space2),
          Text(
            'Use #project, a day word (today, tomorrow, fri), and ! for high priority.',
            style: TextStyle(fontSize: AppTokens.textMeta, color: t.muted),
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
                onPressed: () => Navigator.of(context).pop(),
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
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: t.paper,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: t.lineStrong),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: AppTokens.textMeta,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
