import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// One filter: a label and a set of options shown as choice chips (replaces the website's select).
/// The selected chip gets an ink outline. [value] is the option id; options are (id, label).
class FilterField extends StatelessWidget {
  const FilterField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<(String id, String label)> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: AppTokens.space2),
          Wrap(
            spacing: AppTokens.space2,
            runSpacing: AppTokens.space2,
            children: [
              for (final (id, text) in options)
                Semantics(
                  button: true,
                  selected: id == value,
                  label: text,
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => onChanged(id),
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: AppTokens.minTarget,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.space4,
                        vertical: 8,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: id == value ? t.pinkSoft : t.paper,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: id == value ? t.ink : t.lineStrong,
                          width: id == value ? 2 : 1,
                        ),
                      ),
                      child: ExcludeSemantics(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontWeight: id == value
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A labelled on/off filter (e.g. "Show archived", "Final files only").
class FilterToggle extends StatelessWidget {
  const FilterToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppTokens.space2),
    child: CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(label),
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      minTileHeight: AppTokens.minTarget,
    ),
  );
}

/// Filter bottom sheet. [builder] draws the fields; call the supplied `refresh` after changing a
/// value so the sheet redraws. [onReset] clears every filter.
Future<void> showFilterSheet(
  BuildContext context, {
  required Widget Function(BuildContext context, VoidCallback refresh) builder,
  VoidCallback? onReset,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space5,
          0,
          AppTokens.space5,
          AppTokens.space5,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Filters',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: AppTokens.space4),
            builder(context, () => setState(() {})),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onReset != null)
                  TextButton(
                    onPressed: () {
                      onReset();
                      setState(() {});
                    },
                    child: const Text('Reset'),
                  ),
                const SizedBox(width: AppTokens.space2),
                FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
