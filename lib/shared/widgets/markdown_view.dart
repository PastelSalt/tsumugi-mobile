import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../core/theme/tokens.dart';

/// Renders Markdown with the Tsumugi look. Raw HTML is not rendered (as in the website's small
/// parser) and links are shown but not followed: the app has no network access.
class MarkdownView extends StatelessWidget {
  const MarkdownView(this.data, {super.key});

  final String data;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final body = text.bodyMedium!.copyWith(
      fontSize: 15,
      height: 1.55,
      color: t.ink,
    );
    return MarkdownBody(
      data: data,
      selectable: false,
      styleSheet: MarkdownStyleSheet(
        p: body,
        a: body.copyWith(color: t.pink, decoration: TextDecoration.underline),
        strong: body.copyWith(fontWeight: FontWeight.w700),
        em: body.copyWith(fontStyle: FontStyle.italic),
        h1: text.headlineMedium,
        h2: text.titleLarge,
        h3: text.titleMedium,
        h4: text.titleMedium,
        listBullet: body,
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          backgroundColor: t.line,
          color: t.ink,
        ),
        codeblockDecoration: BoxDecoration(
          color: t.line,
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
        blockquote: body.copyWith(color: t.muted),
        blockquoteDecoration: BoxDecoration(
          color: t.blueSoft,
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          border: Border(left: BorderSide(color: t.ink, width: 3)),
        ),
        blockquotePadding: const EdgeInsets.all(AppTokens.space3),
        blockSpacing: AppTokens.space3,
        tableBorder: TableBorder.all(color: t.lineStrong),
        tableHead: body.copyWith(fontWeight: FontWeight.w700),
        tableBody: body,
        tableCellsPadding: const EdgeInsets.all(AppTokens.space2),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: t.line)),
        ),
      ),
    );
  }
}
