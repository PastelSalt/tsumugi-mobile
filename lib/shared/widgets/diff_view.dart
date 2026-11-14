import 'package:flutter/material.dart';

import '../../core/data/models.dart';
import '../../core/theme/tokens.dart';

/// Before / after lines of a change. Added and removed lines are marked with + and - and announced
/// as "Added:" / "Removed:" to screen readers; colour is never the only cue.
class DiffView extends StatelessWidget {
  const DiffView({super.key, required this.change});

  final Change change;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final lines = change.diff ?? const <DiffLine>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            change.summary,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (change.toVersion != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'v${change.fromVersion} → v${change.toVersion}',
              style: TextStyle(fontSize: AppTokens.textMeta, color: t.muted),
            ),
          ),
        const SizedBox(height: AppTokens.space3),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: t.paper,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            border: Border.all(color: t.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final line in lines)
                Semantics(
                  label:
                      '${line.mark == '+'
                          ? 'Added: '
                          : line.mark == '-'
                          ? 'Removed: '
                          : ''}${line.text}',
                  excludeSemantics: true,
                  child: Container(
                    width: double.infinity,
                    color: line.mark == '+'
                        ? t.greenSoft
                        : line.mark == '-'
                        ? t.pinkSoft
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space3,
                      vertical: 6,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 18,
                          child: Text(
                            line.mark == '=' ? ' ' : line.mark,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: line.mark == '+'
                                  ? const Color(0xFF2F6A42)
                                  : const Color(0xFFA3205C),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            line.text,
                            style: TextStyle(
                              decoration: line.mark == '-'
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: line.mark == '=' ? t.muted : t.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
