import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/docs/legal_meta.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/doc_page.dart';
import '../../shared/widgets/layout.dart';
import '../../shared/widgets/states.dart';

String _clean(String v) => v
    .replaceAll(RegExp(r'`?\[[^\]]+\]`?'), 'To be confirmed')
    .replaceAll('`', '');

/// One of the three draft legal policies, rendered from the bundled Markdown (website
/// `PolicyPage`, PLAN-A-02): draft banner, details, contents list and numbered sections.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final info = legalDocuments[slug];
    final t = context.tokens;
    if (info == null) {
      return ListView(
        padding: const EdgeInsets.all(AppTokens.pageGutter),
        children: const [
          PageHeader(title: 'Policy not found'),
          EmptyState(title: 'We couldn’t find that policy'),
        ],
      );
    }
    return DocLoader(
      name: slug,
      builder: (context, doc) {
        final statusLine = doc.meta
            .where(
              (m) =>
                  RegExp('draft status', caseSensitive: false).hasMatch(m.$1),
            )
            .map((m) => m.$2)
            .firstOrNull;
        final details = [
          for (final m in doc.meta)
            if (!RegExp(
              r'draft status|^service$',
              caseSensitive: false,
            ).hasMatch(m.$1))
              m,
        ];
        final inventory = slug == 'cookie-and-local-storage-policy';
        return ListView(
          padding: const EdgeInsets.all(AppTokens.pageGutter),
          children: [
            if (legalIsDraft)
              Container(
                margin: const EdgeInsets.only(bottom: AppTokens.space4),
                padding: const EdgeInsets.all(AppTokens.space3),
                decoration: BoxDecoration(
                  color: t.warningContainer,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.triangleAlert, size: 20, color: t.warning),
                    const SizedBox(width: AppTokens.space2),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${statusLine ?? 'Planning draft'}. ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(
                              text: 'This is not legal advice and not a binding agreement. Details still to be decided are marked “To be confirmed”.',
                            ),
                          ],
                        ),
                        style: TextStyle(color: t.warning),
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              'Moeko Works · Tsumugi · ${info.label}',
              style: TextStyle(
                fontSize: AppTokens.textMeta,
                color: t.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Semantics(
              header: true,
              child: Text(
                info.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: AppTokens.space2),
            Text(info.description, style: TextStyle(color: t.muted)),
            const SizedBox(height: AppTokens.space3),
            Fields(
              items: [
                ('Version', Text(info.version)),
                for (final (key, value) in details)
                  (key.replaceFirst('Proposed ', ''), Text(_clean(value))),
              ],
            ),
            const SizedBox(height: AppTokens.space4),
            DocSections(
              doc: doc,
              extraHeading: inventory ? 'Storage inventory' : null,
              extra: inventory ? const _StorageInventory() : null,
            ),
            const Divider(),
            const SizedBox(height: AppTokens.space2),
            Text(
              'Other policies',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final (otherSlug, label) in legalLinks)
              if (otherSlug != slug)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  minTileHeight: AppTokens.minTarget,
                  title: Text(label),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () => context.pushReplacement('/legal/$otherSlug'),
                ),
          ],
        );
      },
    );
  }
}

class _StorageInventory extends StatelessWidget {
  const _StorageInventory();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Storage inventory',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: AppTokens.space2),
        const Text(
          'This list shows everything the Tsumugi app stores on your device. It is kept in step with the application.',
        ),
        const SizedBox(height: AppTokens.space2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTokens.space3),
          decoration: BoxDecoration(
            color: t.paper,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            border: Border.all(color: t.line),
          ),
          child: Text(
            storageInventory.isEmpty
                ? 'None. This version of Tsumugi does not set cookies or use local or session storage.'
                : storageInventory.join(', '),
          ),
        ),
      ],
    );
  }
}
