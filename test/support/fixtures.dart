import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/misc.dart';
import 'package:tsumugi_mobile/core/data/models.dart';
import 'package:tsumugi_mobile/core/data/workspace_store.dart';

/// The website sample data, loaded from the bundled JSON for tests.
Fixtures testFixtures() => Fixtures.fromJson(
  jsonDecode(File('assets/data/fixtures.json').readAsStringSync())
      as Map<String, dynamic>,
);

List<Override> fixtureOverrides() => [
  fixturesProvider.overrideWithValue(testFixtures()),
];
