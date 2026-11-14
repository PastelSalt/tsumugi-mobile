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
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/badges.dart';
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

class _Reader extends StatefulWidget {
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
  State<_Reader> createState() => _ReaderState();
}

class _ReaderState extends State<_Reader> {
  static const _sizes = [0.9, 1.0, 1.15, 1.3, 1.5];
  final _controller = ScrollController();
  int _size = 1; // index into _sizes: 1.0 = the app's own size

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _progress {
    if (!_controller.hasClients) return 0;
    final max = _controller.position.maxScrollExtent;
    if (max <= 0) return 0;
    return (_controller.offset / max).clamp(0, 1);
  }

  void _openOutline() {
    final headings = [for (final s in widget.parsed.sections) s.heading];
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space5,
                  0,
                  AppTokens.space5,
                  AppTokens.space2,
                ),
                child: Semantics(
                  header: true,
                  child: Text(
                    'On this page',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                ),
              ),
              for (var i = 0; i < headings.length; i++)
                ListTile(
                  minTileHeight: AppTokens.minTarget,
                  title: Text(headings[i]),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    final ctx = widget.keys[i].currentContext;
                    if (ctx != null) {
                      Scrollable.ensureVisible(
                        ctx,
                        duration: motionDuration(
                          context,
                          const Duration(milliseconds: 250),
                        ),
                        alignment: 0.05,
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final doc = widget.doc;
    final parsed = widget.parsed;
    final mode = widget.mode;
    final media = MediaQuery.of(context);
    final factor = _sizes[_size];
    final hasOutline = parsed.sections.length > 1 && mode == 'preview';
    final content = ListView(
      controller: _controller,
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageGutter,
        AppTokens.pageGutter,
        AppTokens.pageGutter,
        96, // room for the Outline button
      ),
      children: [
        widget.back,
        Text(
          '${widget.project} · v${doc.version}',
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
              onChanged: widget.onMode,
              options: const [('preview', 'Preview'), ('source', 'Source')],
            ),
            IconButton.outlined(
              tooltip: 'Smaller text',
              onPressed: _size == 0 ? null : () => setState(() => _size--),
              icon: const Icon(LucideIcons.aArrowDown),
            ),
            IconButton.outlined(
              tooltip: 'Larger text',
              onPressed: _size == _sizes.length - 1
                  ? null
                  : () => setState(() => _size++),
              icon: const Icon(LucideIcons.aArrowUp),
            ),
            const PreviewAction(label: 'Edit', primary: true),
          ],
        ),
        const SizedBox(height: AppTokens.space4),
        // The text-size buttons scale the document itself, on top of the app's text size.
        MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(media.textScaler.scale(1) * factor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mode == 'source')
                _SourceView(body: doc.body!)
              else if (parsed.sections.isEmpty)
                Text(
                  'This document has no sections yet.',
                  style: TextStyle(color: t.muted),
                )
              else
                for (var i = 0; i < parsed.sections.length; i++)
                  Padding(
                    key: widget.keys[i],
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
    return Stack(
      children: [
        Column(
          children: [
            Semantics(
              label: 'Reading progress',
              value: '${(_progress * 100).round()} percent',
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 3,
                backgroundColor: t.line,
              ),
            ),
            Expanded(child: content),
          ],
        ),
        if (hasOutline)
          Positioned(
            right: AppTokens.pageGutter,
            bottom: AppTokens.pageGutter,
            child: FloatingActionButton.extended(
              onPressed: _openOutline,
              icon: const Icon(LucideIcons.listTree),
              label: const Text('Outline'),
            ),
          ),
      ],
    );
  }
}

/// Source mode: the raw Markdown in a monospace face with line numbers; long lines scroll sideways.
class _SourceView extends StatelessWidget {
  const _SourceView({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final lines = body.split('\n');
    const style = TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5);
    return Container(
      padding: const EdgeInsets.all(AppTokens.space3),
      decoration: BoxDecoration(
        color: t.line,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Text(
                [for (var i = 1; i <= lines.length; i++) '$i'].join('\n'),
                textAlign: TextAlign.end,
                style: style.copyWith(color: t.onSurfaceMuted),
              ),
            ),
            const SizedBox(width: AppTokens.space3),
            SelectableText(body, style: style),
          ],
        ),
      ),
    );
  }
}
