// Mechanical checks of the design rules carried over from the website: text is never smaller than
// 12 sp, and the individual workspace never shows team concepts.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> _dartFiles(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

void main() {
  test('no text style is smaller than 12 sp', () {
    final small = <String>[];
    final pattern = RegExp(r'fontSize:\s*(\d+(?:\.\d+)?)\b');
    for (final file in _dartFiles('lib')) {
      for (final m in pattern.allMatches(file.readAsStringSync())) {
        if (double.parse(m.group(1)!) < 12) {
          small.add('${file.path}: fontSize ${m.group(1)}');
        }
      }
    }
    expect(small, isEmpty, reason: small.join('\n'));
  });

  test('no team concepts in the app code or user-facing copy', () {
    final banned = RegExp(
      r'assignee|assigned to|teammate|invite|collaborator|\brole\b',
      caseSensitive: false,
    );
    final offenders = <String>[];
    for (final file in _dartFiles('lib')) {
      final text = file.readAsStringSync();
      for (final line in text.split('\n')) {
        final isComment = line.trimLeft().startsWith('//');
        if (!isComment && banned.hasMatch(line)) {
          offenders.add('${file.path}: ${line.trim()}');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
