import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../shared/widgets/record_sheets.dart';
import 'layout_breakpoints.dart';
import 'query_params.dart';

/// Opens the record named by the route's `select` query value as a detail sheet, and clears the
/// value when the sheet closes. Lets any screen deep-link to a record (`?select=t1`) and lets rows
/// select a record by only changing the URL.
///
/// On wide screens (see [isWideLayout]) no sheet is opened: the app shell docks the same panel
/// beside the list, so the screens themselves do not change.
mixin SheetSelection<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  String? _openSelect;

  /// Current route query parameters of the screen.
  Map<String, String> get routeParams;

  /// Record type ("Task", "Milestone", "Requirement", "File", "Change") for [id].
  String sheetTypeFor(String id);

  /// Call from `initState` and `didUpdateWidget`.
  void syncSelection() {
    final id = routeParams['select'];
    if (id == null || id == _openSelect) return;
    _openSelect = id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (isWideLayout(context)) {
        _openSelect = null; // the docked panel shows it
        return;
      }
      showRecordSheet(context, sheetTypeFor(id), id).whenComplete(() async {
        _openSelect = null;
        // The sheet future completes the moment the sheet is popped, which can be in the same
        // breath as a navigation started from inside the sheet (e.g. "Open comparison"). Give the
        // router a moment to apply that navigation before deciding whether to clear the selection.
        await Future<void>.delayed(const Duration(milliseconds: 60));
        if (!mounted) return;
        // Skip when the router has moved on: another page opened on top (e.g. "Open" in a file
        // sheet) or a new location without this selection. Replacing the location then would undo it.
        final now = GoRouter.of(context).state.uri;
        final samePage = now.path == GoRouterState.of(context).uri.path;
        if (samePage && now.queryParameters['select'] == id) {
          context.setQueryParams({'select': null});
        }
      });
    });
  }

  void select(String id) => context.setQueryParams({'select': id});
}
