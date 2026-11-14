import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/format.dart';
import '../../core/data/models.dart';
import '../../core/data/selectors.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/record_sheets.dart';
import '../../shared/widgets/records.dart';

String _pad(int n) => n.toString().padLeft(2, '0');
String _iso(DateTime d) => '${d.year}-${_pad(d.month)}-${_pad(d.day)}';
DateTime _monthStart(String key) => DateTime.parse('$key-01T00:00:00');
String _shiftMonth(String key, int by) {
  final d = _monthStart(key);
  final n = DateTime(d.year, d.month + by);
  return '${n.year}-${_pad(n.month)}';
}

const double _cellHeight = 55; // 52 high plus the 1.5 margins

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Month grid starting on Monday, always whole weeks so the layout never jumps between months.
List<String> buildMonthGrid(String key) {
  final first = _monthStart(key);
  final offset = (first.weekday + 6) % 7; // Monday = 0
  final start = first.subtract(Duration(days: offset));
  final last = DateTime(first.year, first.month + 1, 0);
  final weeks = ((offset + last.day) / 7).ceil();
  return [
    for (var i = 0; i < weeks * 7; i++) _iso(start.add(Duration(days: i))),
  ];
}

/// Calendar of task and milestone due dates (website `CalendarView`). On a phone each day shows a
/// count and up to three dots; selecting a day lists it in the agenda underneath, where status is
/// written out (the dots are never the only cue).
class CalendarView extends StatelessWidget {
  const CalendarView({
    super.key,
    required this.data,
    required this.month,
    required this.day,
    required this.matches,
    required this.project,
    required this.onMonth,
    required this.onDay,
    this.onSelectTask,
  });

  final WorkspaceData data;
  final String? month;
  final String? day;
  final bool Function(Task) matches;
  final String project;
  final ValueChanged<String?> onMonth;
  final ValueChanged<String> onDay;
  final ValueChanged<String>? onSelectTask;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final key = month ?? demoToday.substring(0, 7);
    final cells = buildMonthGrid(key);
    final tasks = [
      for (final task in data.tasks)
        if (task.due != null && matches(task)) task,
    ];
    final milestones = data.milestonesIn(project);
    ({List<Task> tasks, List<Milestone> milestones}) byDay(String date) => (
      tasks: [
        for (final task in tasks)
          if (task.due == date) task,
      ],
      milestones: [
        for (final m in milestones)
          if (m.due == date) m,
      ],
    );

    final d = _monthStart(key);
    final title = '${_monthNames[d.month - 1]} ${d.year}';
    final selectedDay = day != null && cells.contains(day)
        ? day!
        : (demoToday.startsWith(key) ? demoToday : '$key-01');
    final agenda = byDay(selectedDay);
    final isCurrent = key == demoToday.substring(0, 7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          liveRegion: true,
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Previous month',
              onPressed: () => onMonth(_shiftMonth(key, -1)),
              icon: const Icon(LucideIcons.chevronLeft),
            ),
            OutlinedButton(
              onPressed: isCurrent ? null : () => onMonth(null),
              child: const Text('Today'),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: () => onMonth(_shiftMonth(key, 1)),
              icon: const Icon(LucideIcons.chevronRight),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space2),
        ExcludeSemantics(
          child: Row(
            children: [
              for (final w in _weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: TextStyle(
                        fontSize: AppTokens.textMeta,
                        color: t.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // The grid bleeds into the page gutters: seven columns of at least 48 dp each.
        LayoutBuilder(
          builder: (context, box) => SizedBox(
            width: box.maxWidth,
            height: (cells.length ~/ 7) * _cellHeight,
            child: OverflowBox(
              maxWidth: box.maxWidth + 2 * AppTokens.pageGutter,
              child: Column(
                children: [
                  for (var row = 0; row < cells.length ~/ 7; row++)
                    Row(
                      children: [
                        for (final date in cells.sublist(row * 7, row * 7 + 7))
                          Expanded(
                            child: _DayCell(
                              date: date,
                              monthKey: key,
                              selected: date == selectedDay,
                              items: byDay(date),
                              onTap: () => onDay(date),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTokens.space4),
        Semantics(
          header: true,
          child: Text(
            selectedDay == demoToday
                ? 'Today, ${formatDate(selectedDay)}'
                : formatDate(selectedDay),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: AppTokens.space2),
        if (agenda.tasks.isEmpty && agenda.milestones.isEmpty)
          Text('Nothing is due on this day.', style: TextStyle(color: t.muted))
        else
          Column(
            spacing: AppTokens.space2,
            children: [
              for (final m in agenda.milestones)
                RowCard(
                  onTap: () => showRecordSheet(context, 'Milestone', m.id),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.flag, size: 18),
                      const SizedBox(width: AppTokens.space2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Milestone · ${data.projectById(m.projectId)?.name ?? ''}',
                              style: TextStyle(
                                fontSize: AppTokens.textMeta,
                                color: t.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              for (final task in agenda.tasks)
                TaskRow(
                  task: task,
                  showProject: true,
                  onTap: onSelectTask == null
                      ? null
                      : () => onSelectTask!(task.id),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.monthKey,
    required this.selected,
    required this.items,
    required this.onTap,
  });

  final String date;
  final String monthKey;
  final bool selected;
  final ({List<Task> tasks, List<Milestone> milestones}) items;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final count = items.tasks.length + items.milestones.length;
    final inMonth = date.startsWith(monthKey);
    final isToday = date == demoToday;
    final label =
        '${formatDate(date)}${isToday ? ', today' : ''}, $count ${count == 1 ? 'item' : 'items'}';
    final dots = <Color>[
      for (final _ in items.milestones) t.ink,
      for (final task in items.tasks)
        task.status == 'Done'
            ? t.green
            : (task.due!.compareTo(demoToday) < 0
                  ? const Color(0xFFA3205C)
                  : t.pink),
    ];
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 52,
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: selected
                ? t.pinkSoft
                : (inMonth ? t.paper : Colors.transparent),
            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            border: Border.all(
              color: selected ? t.ink : (isToday ? t.pink : t.line),
              width: selected || isToday ? 2 : 1,
            ),
          ),
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${int.parse(date.substring(8))}',
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                      color: inMonth ? t.ink : t.muted.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  height: 8,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final c in dots.take(3))
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (dots.length > 3)
                          Icon(LucideIcons.plus, size: 8, color: t.muted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
