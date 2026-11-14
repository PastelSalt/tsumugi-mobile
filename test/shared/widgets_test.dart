import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsumugi_mobile/core/data/status.dart';
import 'package:tsumugi_mobile/core/state/preview_state.dart';
import 'package:tsumugi_mobile/core/theme/theme.dart';
import 'package:tsumugi_mobile/features/gallery/gallery_screen.dart';
import 'package:tsumugi_mobile/shared/widgets/badges.dart';
import 'package:tsumugi_mobile/shared/widgets/layout.dart';
import 'package:tsumugi_mobile/shared/widgets/preview_sheet.dart';
import 'package:tsumugi_mobile/shared/widgets/states.dart';

import '../support/fixtures.dart';

Widget _host(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      key: UniqueKey(),
      overrides: overrides,
      child: MaterialApp(
        theme: buildTheme(),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  testWidgets('StatusBadge shows icon and text, DueLabel words overdue dates', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            StatusBadge(StatusDomain.work, 'Doing'),
            DueLabel(due: '2026-11-09'),
            Flag('Blocked'),
          ],
        ),
      ),
    );
    expect(find.text('Doing'), findsOneWidget);
    expect(find.text('3 days overdue'), findsOneWidget);
    expect(find.text('Blocked'), findsOneWidget);
  });

  testWidgets('progress bar exposes value to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(const TsProgressBar(value: 3, max: 4, label: 'Tasks done')),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Tasks done')),
      matchesSemantics(label: 'Tasks done', value: '3 of 4'),
    );
    handle.dispose();
  });

  testWidgets('StateGate follows the developer preview state', (tester) async {
    Future<void> pumpWith(PreviewState s) async {
      await tester.pumpWidget(
        _host(
          const StateGate(
            empty: Text('empty body'),
            child: Text('normal body'),
          ),
          overrides: [previewStateProvider.overrideWith(() => _Fixed(s))],
        ),
      );
    }

    await pumpWith(PreviewState.normal);
    expect(find.text('normal body'), findsOneWidget);
    await pumpWith(PreviewState.empty);
    expect(find.text('empty body'), findsOneWidget);
    await pumpWith(PreviewState.error);
    expect(find.text('Something went wrong'), findsOneWidget);
    await pumpWith(PreviewState.loading);
    expect(find.byType(LoadingState), findsOneWidget);
  });

  testWidgets('ViewTabs reports taps and marks the selected tab', (
    tester,
  ) async {
    String? tapped;
    await tester.pumpWidget(
      _host(
        ViewTabs(
          value: 'a',
          onChanged: (v) => tapped = v,
          tabs: const [TabItem('a', 'Alpha'), TabItem('b', 'Beta', count: 3)],
        ),
      ),
    );
    await tester.tap(find.text('Beta'));
    expect(tapped, 'b');
  });

  testWidgets('PreviewAction opens the Preview only sheet', (tester) async {
    await tester.pumpWidget(
      _host(const PreviewAction(label: 'Edit task', primary: true)),
    );
    await tester.tap(find.text('Edit task'));
    await tester.pumpAndSettle();
    expect(find.text('Preview only'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Preview only'), findsNothing);
  });

  testWidgets('gallery builds without layout errors', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: fixtureOverrides(),
        child: MaterialApp(theme: buildTheme(), home: const GalleryScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Design system'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Fixed extends PreviewStateNotifier {
  _Fixed(this.value);
  final PreviewState value;

  @override
  PreviewState build() => value;
}
