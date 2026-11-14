import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/state/preview_state.dart';
import '../../core/theme/tokens.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.body,
    this.action,
    this.icon = LucideIcons.inbox,
  });

  final String title;
  final String? body;
  final Widget? action;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.space5),
      decoration: BoxDecoration(
        color: t.paper,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: t.lineStrong),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: t.muted),
          const SizedBox(height: AppTokens.space2),
          Text(title, style: text.titleMedium, textAlign: TextAlign.center),
          if (body != null) ...[
            const SizedBox(height: AppTokens.space1),
            Text(
              body!,
              style: text.bodyMedium?.copyWith(color: t.muted),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppTokens.space4),
            action!,
          ],
        ],
      ),
    );
  }
}

class NoResults extends StatelessWidget {
  const NoResults({super.key, required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: LucideIcons.searchX,
    title: 'Nothing matches',
    body: 'Try a different search or clear the filters.',
    action: OutlinedButton(
      onPressed: onClear,
      child: const Text('Clear filters'),
    ),
  );
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: LucideIcons.triangleAlert,
    title: 'Something went wrong',
    body: 'This is a designed error state. Nothing is lost.',
    action: onRetry == null
        ? null
        : OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
  );
}

/// Skeleton rows shown while loading.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.rows = 4});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: 'Loading',
      liveRegion: true,
      child: ExcludeSemantics(
        child: Column(
          children: [
            for (var i = 0; i < rows; i++)
              Container(
                margin: const EdgeInsets.only(bottom: AppTokens.space2),
                height: 64,
                decoration: BoxDecoration(
                  color: t.line.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Wraps a screen body and swaps in the loading / empty / error layout when the developer
/// preview state asks for it (website `StateGate`). [empty] is the layout shown for "empty".
class StateGate extends ConsumerWidget {
  const StateGate({
    super.key,
    required this.child,
    required this.empty,
    this.onRetry,
  });

  final Widget child;
  final Widget empty;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (ref.watch(previewStateProvider)) {
      case PreviewState.loading:
        return const LoadingState();
      case PreviewState.empty:
        return empty;
      case PreviewState.error:
        return ErrorState(onRetry: onRetry);
      case PreviewState.normal:
        return child;
    }
  }
}
