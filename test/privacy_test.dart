// The demo stores and sends nothing, and the networking is confined to one place so that stays checkable.
//
// Decision of 2026-11-16 (owner; website repo docs/PLAN-C-01.md, C1-27): the original "play-demo" rule (no network,
// no storage, no permissions anywhere in the app) is narrowed. Signed-in use may talk to the Tsumugi server and keep
// one session token; the demo stays offline, permanently. These checks enforce the narrowed rule:
//   1. networking, storage and timezone packages are imported only from `lib/core/net/`;
//   2. no analytics, crash reporting, Firebase, or general storage packages are dependencies;
//   3. the release manifest asks for INTERNET and nothing else, and never allows plain-http traffic;
//   4. the demo data code and Welcome never import the API client (and `test/core/net/live_data_test.dart` proves the
//      demo makes zero requests).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> _dartFiles(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

bool _inNet(File f) => f.path.replaceAll('\\', '/').contains('lib/core/net/');

void main() {
  test('networking and storage code lives in lib/core/net only', () {
    final banned = <Pattern>[
      RegExp(r"import 'dart:io'"),
      RegExp(r"import 'dart:html'"),
      RegExp(
        r"package:(http|dio|flutter_secure_storage|flutter_timezone|web_socket_channel|shared_preferences|sqflite|hive|isar|firebase_\w+|path_provider|url_launcher)/",
      ),
      RegExp(r'HttpClient|WebSocket\.connect|Uri\.https?\('),
    ];
    final offenders = <String>[];
    for (final file in _dartFiles('lib').where((f) => !_inNet(f))) {
      final text = file.readAsStringSync();
      for (final pattern in banned) {
        if (text.contains(pattern)) offenders.add('${file.path}: $pattern');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('no tracking, analytics, crash reporting or general storage dependencies', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final dependencies = pubspec.split('dev_dependencies:').first;
    for (final name in [
      'http:',
      'shared_preferences:',
      'sqflite:',
      'hive:',
      'isar:',
      'firebase_',
      'url_launcher:',
      'path_provider:',
      'sentry',
      'google_analytics',
      'crashlytics',
      'mixpanel',
      'amplitude',
    ]) {
      expect(dependencies.contains(name), isFalse, reason: name);
    }
  });

  test('the release manifest asks for INTERNET only, and never allows plain http', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final permissions = RegExp(r'<uses-permission[^>]*android:name="([^"]+)"')
        .allMatches(manifest)
        .map((m) => m.group(1))
        .toList();
    expect(permissions, ['android.permission.INTERNET']);
    expect(manifest.contains('usesCleartextTraffic'), isFalse, reason: 'release builds must use https');
    expect(manifest.contains('android:label="Tsumugi"'), isTrue);
    final debug = File('android/app/src/debug/AndroidManifest.xml').readAsStringSync();
    expect(debug.contains('usesCleartextTraffic'), isTrue, reason: 'debug builds reach the local server over http');
  });

  test('the sample-data store keeps session additions in memory and reads only the bundled data', () {
    final store = File('lib/core/data/workspace_store.dart').readAsStringSync();
    expect(store.contains('File('), isFalse);
    expect(store.contains('SharedPreferences'), isFalse);
    expect(store.contains('loadString('), isTrue); // bundled sample data only
  });

  test('the demo data code and Welcome never import the API client', () {
    for (final path in [
      'lib/core/data/format.dart',
      'lib/core/data/selectors.dart',
      'lib/core/data/models.dart',
      'lib/core/quickadd/parse.dart',
      'lib/features/welcome/welcome_screen.dart',
    ]) {
      final text = File(path).readAsStringSync();
      expect(text.contains('api_client.dart'), isFalse, reason: path);
      expect(text.contains('package:dio'), isFalse, reason: path);
    }
  });
}
