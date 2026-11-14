import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsumugi_mobile/core/theme/tokens.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  const t = AppTokens();
  const aa = 4.5;

  test('status tone pairs meet WCAG AA for small text in both themes', () {
    for (final tokens in [const AppTokens(), AppTokens.dark]) {
      for (final tone in StatusTone.values) {
        final c = tokens.tone(tone);
        expect(
          _ratio(c.background, c.foreground),
          greaterThanOrEqualTo(aa),
          reason: '${tone.name} pill (${tokens.brightness.name})',
        );
      }
    }
  });

  test('body and secondary text meet AA on paper and canvas', () {
    for (final bg in [t.paper, t.canvas]) {
      expect(_ratio(t.ink, bg), greaterThanOrEqualTo(aa));
      expect(_ratio(t.muted, bg), greaterThanOrEqualTo(aa));
    }
  });

  test('white text on the pink accent meets AA', () {
    expect(_ratio(const Color(0xFFFFFFFF), t.pink), greaterThanOrEqualTo(aa));
  });

  test('pink hint text meets AA on paper', () {
    expect(_ratio(t.pink, t.paper), greaterThanOrEqualTo(aa));
  });
}
