import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// "Preview only" bottom sheet (website `PreviewDialog`): shown by every action that would write data.
Future<void> showPreviewSheet(
  BuildContext context, {
  String title = 'Preview only',
  String? body,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => Padding(
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
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppTokens.space2),
          Text(
            body ?? 'This is a demo. Nothing is saved or sent anywhere.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: context.tokens.muted),
          ),
          const SizedBox(height: AppTokens.space4),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Button that opens the preview sheet. [primary] uses the filled style.
class PreviewAction extends StatelessWidget {
  const PreviewAction({
    super.key,
    required this.label,
    this.primary = false,
    this.icon,
  });

  final String label;
  final bool primary;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    void onTap() => showPreviewSheet(context);
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
        Text(label),
      ],
    );
    return primary
        ? FilledButton(onPressed: onTap, child: child)
        : OutlinedButton(onPressed: onTap, child: child);
  }
}
