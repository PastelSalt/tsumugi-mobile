import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

const _generic =
    'This action is not part of the demo, so nothing was changed and nothing is saved or sent anywhere. '
    'What does work for this session: completing, rescheduling, editing and deleting tasks, adding tasks and '
    'projects, and your Account settings. They reset when you close the app.';

/// What each preview-only action would do in the full product, and what works in the demo instead
/// (docs/PLAN-UX.md, U4: say what is real and what is not, in context).
const _messages = <String, String>{
  'Edit':
      'In the full product you would edit this document here. In the demo documents are read-only. '
      'You can still change the text size and jump between sections.',
  'Add file':
      'In the full product you would choose a file from your phone and attach it to a project. '
      'Files are not part of the demo, so nothing was added.',
  'Edit project':
      'In the full product you would rename the project and change its status here. '
      'In the demo, projects stay as they are. You can add a new project for this session instead '
      'from the + menu.',
  'Add requirement':
      'In the full product you would write a requirement and link it to the work that delivers it. '
      'Requirements are fixed sample data in the demo.',
  'Edit milestone':
      'In the full product you would change a milestone’s title and date here. '
      'Milestones are fixed sample data in the demo.',
  'Mark done':
      'In the full product this would close the milestone. Milestones are fixed sample data in the demo. '
      'To finish a task, tap its circle on Tasks or Home.',
  'Mark met':
      'In the full product you would record that this requirement is met. '
      'Requirements are fixed sample data in the demo.',
  'Mark verified':
      'In the full product you would record that this was checked. '
      'Requirements are fixed sample data in the demo.',
  'Link work':
      'In the full product you would link tasks and files to this requirement so the chain from why to what '
      'stays visible. Links are fixed sample data in the demo.',
  'Download': 'In the full product this would save the file to your phone. The demo does not download or share files.',
  'Mark as final file': 'In the full product this would mark the file as the final version. Files are fixed sample data in the demo.',
  'Unmark final file': 'In the full product this would remove the final mark. Files are fixed sample data in the demo.',
  'Mark reviewed': 'In the full product you would record that you reviewed this change. Changes are fixed sample data in the demo.',
  'Mark not reviewed': 'In the full product you would clear the reviewed mark. Changes are fixed sample data in the demo.',
};

/// The message shown for the action called [label].
String previewMessageFor(String label) => _messages[label] ?? _generic;

/// "Preview only" bottom sheet (website `PreviewDialog`): shown by every action that would write data
/// and is not part of the play-demo. The body says what the action would do and what works instead.
Future<void> showPreviewSheet(
  BuildContext context, {
  String title = 'Preview only',
  String? body,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SingleChildScrollView(
      child: Padding(
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
              body ?? _generic,
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
    ),
  );
}

/// Button that opens the preview sheet with the message for its [label]. [primary] uses the filled
/// style.
class PreviewAction extends StatelessWidget {
  const PreviewAction({
    super.key,
    required this.label,
    this.primary = false,
    this.icon,
    this.body,
    this.quiet = false,
  });

  final String label;
  final bool primary;
  final IconData? icon;

  /// Overrides the message for [label].
  final String? body;

  /// A text button instead of an outlined one, for actions that should not compete with content.
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    void onTap() =>
        showPreviewSheet(context, body: body ?? previewMessageFor(label));
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
    if (quiet) return TextButton(onPressed: onTap, child: child);
    return primary
        ? FilledButton(onPressed: onTap, child: child)
        : OutlinedButton(onPressed: onTap, child: child);
  }
}
