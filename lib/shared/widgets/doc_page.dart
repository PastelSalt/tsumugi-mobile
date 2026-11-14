import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/docs/doc_source.dart';
import '../../core/docs/markdown_doc.dart';
import '../../core/theme/tokens.dart';
import 'doc_outline.dart';
import 'markdown_view.dart';
import 'states.dart';

/// Loads a bundled Markdown document and hands the parsed result to [builder]. Shows a loading
/// skeleton and an error state in the meantime.
class DocLoader extends ConsumerWidget {
  const DocLoader({super.key, required this.name, required this.builder});

  final String name;
  final Widget Function(BuildContext context, MarkdownDoc doc) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(docSourceProvider(name))
        .when(
          data: (source) => builder(context, parseDocument(source)),
          loading: () => const LoadingState(),
          error: (_, _) => const ErrorState(),
        );
  }
}

/// One numbered section of a document: a small number chip, the heading and the Markdown body.
class NumberedSection extends StatelessWidget {
  const NumberedSection({super.key, required this.section});

  final MarkdownSection section;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final number = section.number;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (number != null)
                  Container(
                    margin: const EdgeInsets.only(right: 10, top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: t.pinkSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: ExcludeSemantics(
                      child: Text(
                        number,
                        style: TextStyle(
                          fontSize: AppTokens.textMeta,
                          fontWeight: FontWeight.w700,
                          color: t.pink,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    section.plainHeading,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space2),
          MarkdownView(section.body),
        ],
      ),
    );
  }
}

/// Outline plus numbered sections for a document, with section keys managed by the caller's state.
class DocSections extends StatefulWidget {
  const DocSections({
    super.key,
    required this.doc,
    this.extraHeading,
    this.extra,
  });

  final MarkdownDoc doc;

  /// Optional extra section appended after the document's own (e.g. the storage inventory).
  final String? extraHeading;
  final Widget? extra;

  @override
  State<DocSections> createState() => _DocSectionsState();
}

class _DocSectionsState extends State<DocSections> {
  late List<GlobalKey> _keys;

  int get _count => widget.doc.sections.length + (widget.extra == null ? 0 : 1);

  @override
  void initState() {
    super.initState();
    _keys = List.generate(_count, (_) => GlobalKey());
  }

  @override
  Widget build(BuildContext context) {
    final sections = widget.doc.sections;
    if (_keys.length != _count) {
      _keys = List.generate(_count, (_) => GlobalKey());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DocOutline(
          headings: [
            for (final s in sections) s.plainHeading,
            if (widget.extra != null) widget.extraHeading ?? 'More',
          ],
          keys: _keys,
        ),
        const SizedBox(height: AppTokens.space5),
        for (var i = 0; i < sections.length; i++)
          KeyedSubtree(
            key: _keys[i],
            child: NumberedSection(section: sections[i]),
          ),
        if (widget.extra != null)
          KeyedSubtree(key: _keys[sections.length], child: widget.extra!),
      ],
    );
  }
}
