import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/data/workspace_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final fixtures = await loadFixtures();
  runApp(
    ProviderScope(
      overrides: [fixturesProvider.overrideWithValue(fixtures)],
      child: const TsumugiApp(),
    ),
  );
}
