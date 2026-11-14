// The demo stores and sends nothing. These checks keep that true: no networking or storage code or
// packages, no INTERNET (or any other) permission in the main Android manifest, and no persistence
// of session data.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> _dartFiles(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

void main() {
  test('no networking or storage code in the app', () {
    final banned = <Pattern>[
      RegExp(r"import 'dart:io'"),
      RegExp(r"import 'dart:html'"),
      RegExp(
        r"package:(http|dio|web_socket_channel|shared_preferences|sqflite|hive|isar|firebase_\w+|path_provider|url_launcher)/",
      ),
      RegExp(r'HttpClient|WebSocket\.connect|Uri\.https?\('),
    ];
    final offenders = <String>[];
    for (final file in _dartFiles('lib')) {
      final text = file.readAsStringSync();
      for (final pattern in banned) {
        if (text.contains(pattern)) offenders.add('${file.path}: $pattern');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('pubspec has no networking, storage or analytics dependencies', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final dependencies = pubspec.split('dev_dependencies:').first;
    for (final name in [
      'http:',
      'dio:',
      'shared_preferences:',
      'sqflite:',
      'hive:',
      'firebase_',
      'url_launcher:',
      'path_provider:',
      'sentry',
      'google_analytics',
    ]) {
      expect(dependencies.contains(name), isFalse, reason: name);
    }
  });

  test('the main Android manifest requests no permissions', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest.contains('uses-permission'), isFalse);
    expect(manifest.contains('android:label="Tsumugi"'), isTrue);
  });

  test('session additions are held in memory only (no persistence APIs used by the store)', () {
    final store = File('lib/core/data/workspace_store.dart').readAsStringSync();
    expect(store.contains('File('), isFalse);
    expect(store.contains('SharedPreferences'), isFalse);
    expect(
      store.contains('loadString('),
      isTrue,
    ); // it only reads the bundled sample data
  });
}
