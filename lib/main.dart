import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/data/workspace_store.dart';
import 'core/theme/system_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  enableEdgeToEdge();
  final fixtures = await loadFixtures();
  runApp(
    ProviderScope(
      overrides: [fixturesProvider.overrideWithValue(fixtures)],
      child: const TsumugiApp(),
    ),
  );
}
