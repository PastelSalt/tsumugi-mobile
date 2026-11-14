import 'package:flutter_test/flutter_test.dart';
import 'package:tsumugi_mobile/core/data/format.dart';

void main() {
  group('dueInfo (demo today is 2026-11-12)', () {
    test('overdue', () {
      final i = dueInfo('2026-11-09');
      expect(i.label, '3 days overdue');
      expect(i.tone, DueTone.overdue);
      expect(dueInfo('2026-11-11').label, '1 day overdue');
    });
    test('today, tomorrow, within a week, later', () {
      expect(dueInfo('2026-11-12').label, 'Today');
      expect(dueInfo('2026-11-13').label, 'Tomorrow');
      expect(dueInfo('2026-11-18').label, 'In 6 days');
      expect(dueInfo('2026-11-19').label, 'In 7 days');
      expect(dueInfo('2026-11-20').label, '20 Nov');
      expect(dueInfo('2026-11-20').tone, DueTone.later);
    });
    test('done and none', () {
      expect(dueInfo('2026-11-05', done: true).tone, DueTone.done);
      expect(dueInfo(null).label, 'No date');
    });
  });

  test('formatDate and formatMonth', () {
    expect(formatDate('2026-11-12'), '12 Nov');
    expect(formatMonth('2026-11-12'), 'Nov 2026');
  });

  test('timeAgo and dayGroup', () {
    expect(timeAgo('2026-11-12T10:42:00'), '1 h ago');
    expect(timeAgo('2026-11-11T16:30:00'), '20 h ago');
    expect(timeAgo('2026-11-10T14:20:00'), '2 days ago');
    expect(dayGroup('2026-11-12T09:00:00'), 'Today');
    expect(dayGroup('2026-11-11T09:00:00'), 'Yesterday');
    expect(dayGroup('2026-11-09T09:00:00'), '9 Nov');
  });

  test('formatBytes', () {
    expect(formatBytes(0), '—');
    expect(formatBytes(18400), '18 KB');
    expect(formatBytes(2480000), '2.4 MB');
  });
}
