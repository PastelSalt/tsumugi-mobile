import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/state/dev_tools.dart';
import '../../core/state/preview_state.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/layout.dart';

/// Account menu (website `AccountMenu`): workspace, Insights, Account, Help, legal links and the
/// developer tools. Legal and developer entries are early versions; Phase 6 completes the screens.
Future<void> showAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => const _AccountSheet(),
  );
}

const _legal = [
  ('privacy-policy', 'Privacy Policy'),
  ('terms-of-service', 'Terms of Service'),
  ('cookie-and-local-storage-policy', 'Cookie & Local Storage Policy'),
];

class _AccountSheet extends ConsumerWidget {
  const _AccountSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(previewStateProvider);
    final dev = ref.watch(devToolsProvider);
    final text = Theme.of(context).textTheme;
    final t = context.tokens;

    Widget item(IconData icon, String label, String route) => ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: AppTokens.minTarget,
      leading: Icon(icon, size: 20),
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop();
        context.push(route);
      },
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space5,
        0,
        AppTokens.space5,
        AppTokens.space5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Demo workspace', style: text.titleLarge),
          Text(
            'Individual · sample data, nothing is saved',
            style: text.bodyMedium?.copyWith(color: t.muted),
          ),
          const SizedBox(height: AppTokens.space3),
          item(LucideIcons.chartColumn, 'Insights', '/insights'),
          item(LucideIcons.settings, 'Account and preferences', '/account'),
          item(LucideIcons.circleQuestionMark, 'Help', '/help'),
          const SizedBox(height: AppTokens.space2),
          Row(
            children: [
              Icon(LucideIcons.scale, size: 14, color: t.muted),
              const SizedBox(width: 6),
              Text(
                'Legal',
                style: TextStyle(
                  fontSize: AppTokens.textMeta,
                  color: t.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          for (final (slug, label) in _legal)
            ListTile(
              contentPadding: EdgeInsets.zero,
              minTileHeight: AppTokens.minTarget,
              title: Text(label),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/legal/$slug');
              },
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            minTileHeight: AppTokens.minTarget,
            leading: const Icon(LucideIcons.house, size: 20),
            title: const Text('Back to welcome'),
            onTap: () {
              Navigator.of(context).pop();
              context.go('/');
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            minTileHeight: AppTokens.minTarget,
            leading: const Icon(LucideIcons.logOut, size: 20),
            title: const Text('Leave demo'),
            onTap: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Developer tools'),
            value: dev,
            onChanged: (v) => ref.read(devToolsProvider.notifier).set(v),
          ),
          if (dev) ...[
            const SizedBox(height: AppTokens.space3),
            Text('Developer: preview state', style: text.titleMedium),
            const SizedBox(height: AppTokens.space2),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedToggle(
                label: 'Preview state',
                value: state.name,
                onChanged: (v) => ref
                    .read(previewStateProvider.notifier)
                    .set(PreviewState.values.byName(v)),
                options: [
                  for (final s in PreviewState.values) (s.name, _label(s)),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space2),
            item(LucideIcons.layoutGrid, 'Widget gallery', '/gallery'),
          ],
        ],
      ),
    );
  }

  static String _label(PreviewState s) => switch (s) {
    PreviewState.normal => 'Normal',
    PreviewState.loading => 'Loading',
    PreviewState.empty => 'Empty',
    PreviewState.error => 'Error',
  };
}
