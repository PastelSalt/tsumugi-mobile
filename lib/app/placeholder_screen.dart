import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../shared/widgets/layout.dart';

/// Temporary page used until each screen is built in its own phase.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.description,
    this.details = const [],
  });

  final String title;
  final String description;

  /// Extra lines (query parameters, ids) so route and state wiring can be checked on screen.
  final List<String> details;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppTokens.pageGutter),
      children: [
        PageHeader(title: title, description: description),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This screen is built in a later phase.',
                  style: text.bodyMedium,
                ),
                for (final d in details)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: AppTokens.textMeta,
                        color: context.tokens.muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A pushed page outside the bottom-bar tabs, with a back button (Insights, Account, Help, Search, Legal).
class SubPageScaffold extends StatelessWidget {
  const SubPageScaffold({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: child,
  );
}
