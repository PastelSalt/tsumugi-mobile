import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/format.dart';
import '../../core/data/models.dart';
import '../../core/data/selectors.dart';
import '../../core/data/status.dart';
import '../../core/data/workspace_store.dart';
import '../../core/docs/markdown_doc.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/doc_outline.dart';
import '../../shared/widgets/layout.dart';
import '../../shared/widgets/markdown_view.dart';
import '../../shared/widgets/preview_sheet.dart';
import '../../shared/widgets/records.dart';
import '../../shared/widgets/states.dart';

/// Reads one Markdown document: outline, Preview or Source, and what it is linked to
/// (website `DocReader`, PLAN-A-04I).
class DocReaderScreen extends ConsumerStatefulWidget {
  const DocReaderScreen({super.key, required this.fileId});

  final String fileId;

  @override
  ConsumerState<DocReaderScreen> createState() => _DocReaderScreenState();
}

class _DocReaderScreenState extends ConsumerState<DocReaderScreen> {
  String _mode = 'preview';
  List<GlobalKey> _keys = [];

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(workspaceDataProvider);
    final doc = data.fileById(widget.fileId);
    final back = Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () =>
            context.canPop() ? context.pop() : context.go('/library'),
        icon: const Icon(LucideIcons.chevronLeft, size: 16),
        label: const Text('Back to Library'),
      ),
    );
    if (doc == null || doc.body == null) {
      return ListView(
        padding: const EdgeInsets.all(AppTokens.pageGutter),
        children: [
          back,
          const PageHeader(title: 'Document not found'),
          EmptyState(
            title: 'We couldn’t find that document',
            body: 'It may have been removed, or the link is wrong.',
            action: OutlinedButton(
              onPressed: () => context.go('/library'),
              child: const Text('Back to Library'),
            ),
          ),
        ],
      );
    }
    final parsed = parseDocument(doc.body!);
    if (_keys.length != parsed.sections.length) {
      _keys = List.generate(parsed.sections.length, (_) => GlobalKey());
    }
    return _Reader(
      back: back,
      doc: doc,
      parsed: parsed,
      project: data.projectById(doc.projectId)?.name ?? '',
      mode: _mode,
      onMode: (m) => setState(() => _mode = m),
      keys: _keys,
    );
  }
}

class _Reader extends StatelessWidget {
  const _Reader({
    required this.back,
    required this.doc,
    required this.parsed,
    required this.project,
    required this.mode,
    required this.onMode,
    required this.keys,
  });

  final Widget back;
  final WorkFile doc;
  final MarkdownDoc parsed;
  final String project;
  final String mode;
  final ValueChanged<String> onMode;
  final List<GlobalKey> keys;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ListView(
      padding: const EdgeInsets.all(AppTokens.pageGutter),
      children: [
        back,
        Text(
          '$project · v${doc.version}',
          style: TextStyle(
            fontSize: AppTokens.textMeta,
            color: t.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Semantics(
          header: true,
          child: Text(
            parsed.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: AppTokens.space2),
        Wrap(
          spacing: AppTokens.space2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (doc.status != null)
              StatusBadge(StatusDomain.document, doc.status!),
            Text(
              'Updated ${formatDate(doc.updatedAt)}',
              style: TextStyle(color: t.muted, fontSize: AppTokens.textMeta),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space3),
        Wrap(
          spacing: AppTokens.space2,
          runSpacing: AppTokens.space2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedToggle(
              label: 'Document mode',
              value: mode,
              onChanged: onMode,
              options: const [('preview', 'Preview'), ('source', 'Source')],
            ),
            const PreviewAction(label: 'Edit', primary: true),
          ],
        ),
        const SizedBox(height: AppTokens.space4),
        if (parsed.sections.length > 1 && mode == 'preview')
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space4),
            child: DocOutline(
              headings: [for (final s in parsed.sections) s.heading],
              keys: keys,
            ),
          ),
        if (mode == 'source')
          Container(
            padding: const EdgeInsets.all(AppTokens.space3),
            decoration: BoxDecoration(
              color: t.line,
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            ),
            child: SelectableText(
              doc.body!,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
              ),
            ),
          )
        else if (parsed.sections.isEmpty)
          Text(
            'This document has no sections yet.',
            style: TextStyle(color: t.muted),
          )
        else
          for (var i = 0; i < parsed.sections.length; i++)
            Padding(
              key: keys[i],
              padding: const EdgeInsets.only(bottom: AppTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      parsed.sections[i].heading,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space2),
                  MarkdownView(parsed.sections[i].body),
                ],
              ),
            ),
        const SizedBox(height: AppTokens.space3),
        LensBlock(
          why: [
            for (final id in doc.requirementIds)
              RelationChip(type: 'Requirement', id: id, label: id),
          ],
          becomes: [
            for (final id in doc.taskIds) RelationChip(type: 'Task', id: id),
          ],
          emptyWhy: 'Not linked to a requirement.',
          emptyBecomes: 'Not linked to a task.',
        ),
      ],
    );
  }
}
