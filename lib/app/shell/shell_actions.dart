import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../layout_breakpoints.dart';
import 'account_sheet.dart';

/// Search and account buttons shown in the top bar. On tablets the rail already has them, so a
/// screen's own app bar shows none there.
List<Widget> shellActions(BuildContext context) {
  if (isWideLayout(context)) return const [];
  return [
    IconButton(
      tooltip: 'Search or jump to',
      icon: const Icon(LucideIcons.search),
      onPressed: () => context.push('/search'),
    ),
    IconButton(
      tooltip: 'Account menu',
      icon: const Icon(LucideIcons.user),
      onPressed: () => showAccountSheet(context),
    ),
  ];
}
