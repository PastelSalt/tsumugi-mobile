import '../data/format.dart';
import '../data/models.dart';
import '../data/selectors.dart';

class QuickAddResult {
  const QuickAddResult({
    required this.title,
    required this.priority,
    required this.due,
    required this.projectId,
  });

  final String title;

  /// "normal" or "high".
  final String priority;
  final String? due;
  final String? projectId;
}

const _days = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];

String _addDays(int n) {
  final d = parseDay(demoToday).add(Duration(days: n));
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

String _squash(String s) => s.replaceAll(RegExp(r'\W+'), '');

/// Reads "#project", "!" / "!high", and a due word (today, tomorrow, weekday) out of one line.
/// Port of the website `quickadd/parse.js`: a weekday means its next occurrence, never today.
QuickAddResult parseQuickAdd(
  String text,
  String? fallbackProject,
  WorkspaceData data,
) {
  var title = text;
  var priority = 'normal';
  String? due;
  var projectId = fallbackProject;

  final tag = RegExp(r'#([\w-]+)').firstMatch(title);
  if (tag != null) {
    final key = tag.group(1)!.toLowerCase();
    final found = data.activeProjects.where(
      (p) =>
          p.id.contains(key) ||
          _squash(p.name.toLowerCase()).contains(_squash(key)),
    );
    if (found.isNotEmpty) {
      projectId = found.first.id;
      title = title.replaceFirst(tag.group(0)!, '');
    }
  }

  if (RegExp(r'(^|\s)!(high)?(\s|$)', caseSensitive: false).hasMatch(title)) {
    priority = 'high';
    title = title.replaceFirst(
      RegExp(r'(^|\s)!(high)?(?=\s|$)', caseSensitive: false),
      ' ',
    );
  }

  final word = RegExp(
    r'\b(today|tomorrow|mon|tue|wed|thu|fri|sat|sun)\b',
    caseSensitive: false,
  ).firstMatch(title);
  if (word != null) {
    final w = word.group(1)!.toLowerCase();
    if (w == 'today') {
      due = demoToday;
    } else if (w == 'tomorrow') {
      due = _addDays(1);
    } else {
      final today =
          parseDay(demoToday).weekday %
          7; // Dart: Monday=1..Sunday=7; website: Sunday=0
      final offset = (_days.indexOf(w) - today + 7) % 7;
      due = _addDays(offset == 0 ? 7 : offset);
    }
    title = title.replaceFirst(word.group(0)!, '');
  }

  return QuickAddResult(
    title: title.replaceAll(RegExp(r'\s+'), ' ').trim(),
    priority: priority,
    due: due,
    projectId: projectId,
  );
}
