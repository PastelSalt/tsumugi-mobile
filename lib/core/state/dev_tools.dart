import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the developer tools are shown (website developer bar). Off by default; turned on from
/// Account. When on, the account menu shows the preview-state picker and the widget gallery.
class DevToolsNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final devToolsProvider = NotifierProvider<DevToolsNotifier, bool>(
  DevToolsNotifier.new,
);
