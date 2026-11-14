import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../shared/widgets/doc_page.dart';
import '../../shared/widgets/markdown_view.dart';

/// Help: the individual workspace guide, rendered from the bundled Markdown with a contents list
/// (website `HelpPage`, which renders the same file).
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DocLoader(
      name: 'individual-workspace-guide',
      builder: (context, doc) => ListView(
        padding: const EdgeInsets.all(AppTokens.pageGutter),
        children: [
          Semantics(
            header: true,
            child: Text(
              doc.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: AppTokens.space2),
          Text(
            [for (final m in doc.meta) '${m.$1}: ${m.$2}'].join('\n'),
            style: TextStyle(color: t.muted),
          ),
          if (doc.notice.isNotEmpty) ...[
            const SizedBox(height: AppTokens.space3),
            MarkdownView('> ${doc.notice}'),
          ],
          const SizedBox(height: AppTokens.space4),
          DocSections(doc: doc),
        ],
      ),
    );
  }
}
