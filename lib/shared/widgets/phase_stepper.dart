import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/tokens.dart';

/// Project phases as a stepper: done steps are checked, the current step is outlined in ink.
class PhaseStepper extends StatelessWidget {
  const PhaseStepper({
    super.key,
    required this.phases,
    required this.currentIndex,
  });

  final List<String> phases;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: 'Project phases',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < phases.length; i++) ...[
              if (i > 0)
                Container(
                  width: 20,
                  height: 2,
                  color: i <= currentIndex ? t.green : t.line,
                ),
              Semantics(
                label:
                    '${phases[i]}, ${i < currentIndex
                        ? 'done'
                        : i == currentIndex
                        ? 'current phase'
                        : 'next'}',
                excludeSemantics: true,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
                  decoration: BoxDecoration(
                    color: i == currentIndex ? t.pinkSoft : t.paper,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: i == currentIndex ? t.ink : t.line,
                      width: i == currentIndex ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i < currentIndex
                              ? t.green
                              : (i == currentIndex ? t.pink : t.line),
                          shape: BoxShape.circle,
                        ),
                        child: i < currentIndex
                            ? const Icon(
                                LucideIcons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: AppTokens.textMeta,
                                  fontWeight: FontWeight.w700,
                                  color: i == currentIndex
                                      ? Colors.white
                                      : t.muted,
                                ),
                              ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        phases[i],
                        style: TextStyle(
                          fontWeight: i == currentIndex
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: i > currentIndex ? t.muted : t.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
