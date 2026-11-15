// Renders the Tsumugi launcher icon PNGs from the BrandMark widget (real Fredoka font).
// Run: flutter test tool/render_launcher_icons_test.dart
// Then: dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsumugi_mobile/shared/widgets/brand_mark.dart';

Future<void> _render(
  WidgetTester tester,
  String path, {
  required Color? background,
  required double mark,
  double side = 1024,
  double textScale = 1,
}) async {
  final key = GlobalKey();
  tester.view.physicalSize = Size(side, side);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: Container(
          width: side,
          height: side,
          color: background ?? Colors.transparent,
          alignment: Alignment.center,
          child: BrandMark(
            size: mark,
            color: const Color(0xFFC73579),
            textScale: textScale,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    File(path).writeAsBytesSync(bytes.buffer.asUint8List());
  });
}

void main() {
  testWidgets('render launcher icons', (tester) async {
    // Flutter tests draw with a placeholder font unless the real one is loaded explicitly.
    final loader = FontLoader('Fredoka')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            Uint8List.fromList(
              File('assets/fonts/Fredoka-Bold.ttf').readAsBytesSync(),
            ),
          ),
        ),
      );
    await loader.load();
    await _render(
      tester,
      'assets/brand/launcher_icon.png',
      background: const Color(0xFFFFE8F5),
      mark: 860,
      textScale: 1.9,
    );
    await _render(
      tester,
      'assets/brand/launcher_foreground.png',
      background: null,
      mark: 650,
      textScale: 1.9,
    );
    // Android launch screen mark (shown on the canvas colour while the app starts).
    await _render(
      tester,
      'android/app/src/main/res/drawable/splash_mark.png',
      background: null,
      mark: 96,
      side: 192,
    );
  });
}
