import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsumugi_mobile/core/data/models.dart';
import 'package:tsumugi_mobile/core/data/selectors.dart';
import 'package:tsumugi_mobile/core/data/workspace_store.dart';

ProviderContainer _container() {
  final fixtures = Fixtures.fromJson(
    jsonDecode(File('assets/data/fixtures.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  return ProviderContainer(
    overrides: [fixturesProvider.overrideWithValue(fixtures)],
  );
}

void main() {
  test(
    'adding a task shows up everywhere, is labelled session-only and counted',
    () {
      final c = _container();
      addTearDown(c.dispose);
      final before = c.read(workspaceDataProvider).figures();

      final id = c
          .read(sessionProvider.notifier)
          .addTask(title: 'Write notes', due: '2026-11-12', priority: 'high');

      final data = c.read(workspaceDataProvider);
      final task = data.taskById(id)!;
      expect(task.session, isTrue);
      expect(task.priority, 'high');
      expect(data.figures().dueToday, before.dueToday + 1);
      expect(data.todayList().today.map((t) => t.id), contains(id));
      expect(c.read(sessionProvider).count, 1);
    },
  );

  test('a template project brings its milestone and starter tasks', () {
    final c = _container();
    addTearDown(c.dispose);
    final t = c.read(templatesProvider).firstWhere((t) => t.kind == 'software');

    final id = c
        .read(sessionProvider.notifier)
        .addProject(
          name: 'My API',
          kind: t.kind,
          category: t.category,
          phases: t.phases,
          milestones: [(title: t.milestone!, due: '2026-12-15')],
          taskTitles: t.tasks,
        );

    final data = c.read(workspaceDataProvider);
    final p = data.projectById(id)!;
    expect((p.session, p.status, p.phaseIndex), (true, 'Planning', 0));
    expect(data.projectCounts(id).tasks, t.tasks.length);
    expect(data.projectCounts(id).milestones, 1);
    expect(data.activeProjects.map((x) => x.id), contains(id));
    expect(data.projectProgress(id).pct, 0);
  });

  test('reset removes every session record and restores the sample data', () {
    final c = _container();
    addTearDown(c.dispose);
    final base = c.read(workspaceDataProvider).tasks.length;
    c.read(sessionProvider.notifier)
      ..addTask(title: 'One')
      ..addTask(title: 'Two');
    expect(c.read(workspaceDataProvider).tasks.length, base + 2);

    c.read(sessionProvider.notifier).reset();
    expect(c.read(workspaceDataProvider).tasks.length, base);
    expect(c.read(sessionProvider).count, 0);
  });

  test('session ids never collide', () {
    final c = _container();
    addTearDown(c.dispose);
    final n = c.read(sessionProvider.notifier);
    final ids = {
      n.addTask(title: 'a'),
      n.addTask(title: 'b'),
      n.addProject(
        name: 'p',
        kind: 'blank',
        category: 'Other',
        phases: ['Plan'],
      ),
    };
    expect(ids.length, 3);
  });
}
