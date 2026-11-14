import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// View, filter and selection state lives in the route's query parameters, as it does in the
/// website URL (`?view=`, `?select=`, `?project=` ...). That keeps screens deep-linkable.
extension QueryParams on BuildContext {
  /// Current value of [key], or null when it is absent.
  String? queryParam(String key) =>
      GoRouterState.of(this).uri.queryParameters[key];

  /// Updates query parameters on the current location. A null (or empty) value removes the key;
  /// other keys are kept. Replaces the current entry so view changes do not pile up in back history.
  void setQueryParams(Map<String, String?> changes) {
    // The router's own current location: a screen's page state can be one frame behind a navigation
    // that was just started (for example from inside a sheet).
    final uri = GoRouter.of(this).state.uri;
    final next = Map<String, String>.from(uri.queryParameters);
    changes.forEach((key, value) {
      if (value == null || value.isEmpty) {
        next.remove(key);
      } else {
        next[key] = value;
      }
    });
    final query = next.isEmpty ? '' : '?${Uri(queryParameters: next).query}';
    replace('${uri.path}$query');
  }
}
