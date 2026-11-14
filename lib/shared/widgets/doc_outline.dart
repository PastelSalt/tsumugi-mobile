import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Collapsible "On this page" list that jumps to a section (replaces the website's anchor lists).
/// [keys] are attached to the section widgets by the screen; tapping an item scrolls to its key.
class DocOutline extends StatelessWidget {
  const DocOutline({
    super.key,
    required this.headings,
    required this.keys,
    this.title = 'On this page',
    this.initiallyExpanded = false,
  });

  final List<String> headings;
  final List<GlobalKey> keys;
  final String title;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        side: BorderSide(color: t.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppTokens.space2,
            0,
            AppTokens.space2,
            AppTokens.space2,
          ),
          children: [
            for (var i = 0; i < headings.length; i++)
              ListTile(
                dense: true,
                minTileHeight: AppTokens.minTarget,
                title: Text(headings[i]),
                onTap: () {
                  final ctx = keys[i].currentContext;
                  if (ctx != null) {
                    Scrollable.ensureVisible(
                      ctx,
                      duration: const Duration(milliseconds: 250),
                      alignment: 0.05,
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
