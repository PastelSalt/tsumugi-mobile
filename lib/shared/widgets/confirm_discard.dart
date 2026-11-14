import 'package:flutter/material.dart';

/// Asks whether to throw away an unsaved draft. Returns true to discard. Used when back is pressed
/// while a sheet holds text the person has typed (docs/PLAN-MOBILE-UI.md, principle 7).
Future<bool> confirmDiscard(BuildContext context, String title) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: const Text('What you typed will be lost.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep writing'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Discard'),
        ),
      ],
    ),
  );
  return result ?? false;
}
