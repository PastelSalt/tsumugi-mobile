import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/data/workspace_store.dart';
import 'core/net/auth_state.dart';
import 'core/theme/system_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  enableEdgeToEdge();
  final fixtures = await loadFixtures();
  final container = ProviderContainer(
    overrides: [fixturesProvider.overrideWithValue(fixtures)],
  );
  // If a session was saved, check it and load the workspace in the background. The demo needs none of this.
  container.read(authProvider.notifier).bootstrap();
  runApp(UncontrolledProviderScope(container: container, child: const TsumugiApp()));
}
