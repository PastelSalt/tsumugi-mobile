import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/workspace_store.dart';
import '../../core/net/live_store.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/confirm_discard.dart';

/// New project from a template (website `NewProjectDialog`): pick a starting point, name it, and a
/// session-only project is created with its phases, one starter milestone and starter tasks.
Future<void> showNewProjectSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: const NewProjectSheet(),
    ),
  );
}

class NewProjectSheet extends ConsumerStatefulWidget {
  const NewProjectSheet({super.key});

  @override
  ConsumerState<NewProjectSheet> createState() => _NewProjectSheetState();
}

class _NewProjectSheetState extends ConsumerState<NewProjectSheet> {
  String _kind = 'software';
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool _saving = false;

  Future<void> _create() async {
    final templates = ref.read(templatesProvider);
    final t = templates.firstWhere((x) => x.kind == _kind);
    final title = _name.text.trim().isEmpty
        ? 'Untitled ${t.label.toLowerCase()} project'
        : _name.text.trim();
    if (ref.read(liveProvider) != null) {
      // Signed in: the server creates the project (and the template's starter milestone and tasks).
      setState(() => _saving = true);
      final router = GoRouter.of(context);
      final navigator = Navigator.of(context);
      try {
        final id = await ref
            .read(liveGatewayProvider)
            .createProject(name: title, templateKind: t.kind);
        await ref.read(liveGatewayProvider).refresh();
        navigator.pop();
        router.go('/projects/$id');
      } catch (e) {
        ref.read(liveErrorProvider.notifier).report(e);
        if (mounted) setState(() => _saving = false);
      }
      return;
    }
    final id = ref
        .read(sessionProvider.notifier)
        .addProject(
          name: title,
          kind: t.kind,
          category: t.category,
          phases: t.phases,
          description: '${t.label} project created from a template.',
          milestones: t.milestone == null
              ? const []
              : [(title: t.milestone!, due: '2026-12-15')],
          taskTitles: t.tasks,
        );
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go('/projects/$id');
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(templatesProvider);
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return PopScope(
      canPop: _name.text.trim().isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await confirmDiscard(context, 'Discard this project?');
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
          children: [
            Semantics(
              header: true,
              child: Text('New project', style: text.titleLarge),
            ),
            Text(
              'Choose a template. It adds a few starter steps you can change or delete.',
              style: text.bodyMedium?.copyWith(color: t.muted),
            ),
            const SizedBox(height: AppTokens.space3),
            RadioGroup<String>(
              groupValue: _kind,
              onChanged: (v) => setState(() => _kind = v ?? _kind),
              child: Column(
                children: [
                  for (final tpl in templates)
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      value: tpl.kind,
                      title: Text(
                        tpl.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(tpl.text),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space2),
            TextField(
              controller: _name,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Project name',
                hintText: 'Give it a short name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppTokens.space2),
            Text(
              'Created for this session only. It disappears when you restart the app.',
              style: TextStyle(color: t.muted, fontSize: AppTokens.textMeta),
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
                  onPressed: _saving ? null : _create,
                  child: Text(_saving ? 'Creating…' : 'Create project'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
