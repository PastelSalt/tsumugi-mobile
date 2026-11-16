// "Today" for relative dates and overdue checks. The demo uses a fixed day (website `data/format.js`) so it is
// deterministic. Signed in, the server's "today" (decided in the account's time zone) replaces it with [setClock],
// and [resetClock] puts the fixed day back for the demo and for tests.
const _demoToday = '2026-11-12';
final _demoNow = DateTime(2026, 11, 12, 12);
String _today = _demoToday;
DateTime _now = _demoNow;

String get demoToday => _today;
DateTime get demoNow => _now;

/// Uses the server's `today` (YYYY-MM-DD) with the device's current time of day, so "2 h ago" counts from now.
void setClock(String today, [DateTime? deviceNow]) {
  final d = deviceNow ?? DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  _today = today;
  _now = DateTime.parse('${today}T${two(d.hour)}:${two(d.minute)}:${two(d.second)}');
}

void resetClock() {
  _today = _demoToday;
  _now = _demoNow;
}

DateTime parseDay(String iso) =>
    DateTime.parse('${iso.substring(0, 10)}T00:00:00');

int daysBetween(String from, String to) =>
    parseDay(to).difference(parseDay(from)).inDays;

int daysFromToday(String iso) => daysBetween(demoToday, iso);

/// The day [days] after [iso] (or before, when negative), as "yyyy-MM-dd".
String addDays(String iso, int days) {
  final d = parseDay(iso).add(Duration(days: days));
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

/// Tomorrow, relative to the fixed demo date.
String get tomorrowIso => addDays(demoToday, 1);

// English month abbreviations; avoids needing intl locale data for a fixed en-GB format.
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "12 Nov"
String formatDate(String iso) {
  final d = parseDay(iso);
  return '${d.day} ${_months[d.month - 1]}';
}

/// "Nov 2026"
String formatMonth(String iso) {
  final d = parseDay(iso);
  return '${_months[d.month - 1]} ${d.year}';
}

String plural(int count, String word) => '$count $word${count == 1 ? '' : 's'}';

enum DueTone { none, done, overdue, today, soon, later }

class DueInfo {
  const DueInfo(this.label, this.tone, this.days);
  final String label;
  final DueTone tone;
  final int? days;
}

/// Describes a due date relative to the demo day. [tone] drives the visual treatment.
DueInfo dueInfo(String? due, {bool done = false}) {
  if (due == null) return const DueInfo('No date', DueTone.none, null);
  final days = daysFromToday(due);
  if (done) return DueInfo(formatDate(due), DueTone.done, days);
  if (days < 0) {
    final n = -days;
    return DueInfo('$n day${n == 1 ? '' : 's'} overdue', DueTone.overdue, days);
  }
  if (days == 0) return DueInfo('Today', DueTone.today, days);
  if (days == 1) return DueInfo('Tomorrow', DueTone.soon, days);
  if (days <= 7) return DueInfo('In $days days', DueTone.soon, days);
  return DueInfo(formatDate(due), DueTone.later, days);
}

String timeAgo(String iso) {
  final minutes = demoNow.difference(DateTime.parse(iso)).inMinutes;
  if (minutes < 60) return '${minutes < 1 ? 1 : minutes} min ago';
  final hours = (minutes / 60).round();
  if (hours < 24) return '$hours h ago';
  final days = (hours / 24).round();
  return days == 1 ? 'Yesterday' : '$days days ago';
}

/// Group heading for feeds: Today / Yesterday / "12 Nov".
String dayGroup(String iso) {
  final days = daysBetween(iso, demoToday);
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  return formatDate(iso);
}

String formatBytes(int bytes) {
  if (bytes == 0) return '—';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).round().clamp(1, 1 << 30)} KB';
  }
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}
