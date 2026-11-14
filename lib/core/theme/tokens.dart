import 'package:flutter/material.dart';

/// Design tokens, extracted from the website (`client/src/styles/base.css`, `workspace.css`) and
/// extended for mobile. Two layers:
///
/// 1. **Palette** fields (paper, canvas, ink, pink, ...) hold the actual colours for one theme.
///    [AppTokens.new] is the light palette, [AppTokens.dark] the dark one.
/// 2. **Roles** (`background`, `surface`, `onSurface`, `accent`, `danger`, ...) name what a colour is
///    *for*. New code should use roles, so a widget never needs to know which theme it is in.
///
/// No widget should contain a literal `Color(0x...)`; `test/design_rules_test.dart` enforces it.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    this.paper = const Color(0xFFFFFDFD),
    this.canvas = const Color(0xFFF8F6FB),
    this.ink = const Color(0xFF2F2938),
    this.muted = const Color(0xFF655F70),
    this.pink = const Color(0xFFC73579),
    this.pinkSoft = const Color(0xFFFFE8F5),
    this.blueSoft = const Color(0xFFE5F4FF),
    this.lilac = const Color(0xFFEAD9F8),
    this.green = const Color(0xFF5C8A6B),
    this.greenSoft = const Color(0xFFE8EFE9),
    this.butter = const Color(0xFFF8D95A),
    this.butterSoft = const Color(0xFFFFF2CF),
    this.line = const Color(0xFFE9E3ED),
    this.lineStrong = const Color(0xFFD8D0E0),
    this.onAccent = const Color(0xFFFFFFFF),
    this.neutralSoft = const Color(0xFFF1EEF5),
    this.neutralText = const Color(0xFF4A4455),
    this.infoText = const Color(0xFF1D5F80),
    this.progressSoft = const Color(0xFFECE6FB),
    this.progressText = const Color(0xFF5A45A8),
    this.warningText = const Color(0xFF7A5600),
    this.dangerText = const Color(0xFFA3205C),
    this.successText = const Color(0xFF2F6A42),
    this.brightness = Brightness.light,
  });

  /// Dark palette. Every colour below has a dark value, so a widget that only uses tokens works in
  /// both themes. The app still ships the light theme until the dark-mode phase (M5).
  static const dark = AppTokens(
    paper: Color(0xFF1F1B26),
    canvas: Color(0xFF17141C),
    ink: Color(0xFFF3EEF8),
    muted: Color(0xFFB9B2C4),
    pink: Color(0xFFF08CBB),
    pinkSoft: Color(0xFF3B2233),
    blueSoft: Color(0xFF1E2E3A),
    lilac: Color(0xFF2F2540),
    green: Color(0xFF8FC2A0),
    greenSoft: Color(0xFF22302A),
    butter: Color(0xFFF8D95A),
    butterSoft: Color(0xFF3A3320),
    line: Color(0xFF332D3C),
    lineStrong: Color(0xFF453E50),
    onAccent: Color(0xFF17141C),
    neutralSoft: Color(0xFF2C2733),
    neutralText: Color(0xFFD9D2E3),
    infoText: Color(0xFF8FCBEA),
    progressSoft: Color(0xFF2F2540),
    progressText: Color(0xFFC9B9F5),
    warningText: Color(0xFFF2CE6B),
    dangerText: Color(0xFFFF9DC4),
    successText: Color(0xFFA9D8B8),
    brightness: Brightness.dark,
  );

  // Palette.
  final Color paper;
  final Color canvas;
  final Color ink;
  final Color muted;
  final Color pink;
  final Color pinkSoft;
  final Color blueSoft;
  final Color lilac;
  final Color green;
  final Color greenSoft;
  final Color butter;
  final Color butterSoft;
  final Color line;
  final Color lineStrong;

  /// Text or icon colour on top of [pink] (and on solid [green]).
  final Color onAccent;
  final Color neutralSoft;
  final Color neutralText;
  final Color infoText;
  final Color progressSoft;
  final Color progressText;
  final Color warningText;
  final Color dangerText;
  final Color successText;
  final Brightness brightness;

  bool get isDark => brightness == Brightness.dark;

  // Roles (what a colour is for).
  Color get background => canvas;
  Color get surface => paper;
  Color get onSurface => ink;
  Color get onSurfaceMuted => muted;
  Color get accent => pink;
  Color get accentContainer => pinkSoft;
  Color get outline => line;
  Color get outlineStrong => lineStrong;
  Color get danger => dangerText;
  Color get dangerContainer => pinkSoft;
  Color get warning => warningText;
  Color get warningContainer => butterSoft;
  Color get success => successText;
  Color get successContainer => greenSoft;
  Color get info => infoText;
  Color get infoContainer => blueSoft;

  /// Background and foreground of a status pill for this theme.
  ToneColors tone(StatusTone tone) => switch (tone) {
    StatusTone.neutral => ToneColors(neutralSoft, neutralText),
    StatusTone.info => ToneColors(blueSoft, infoText),
    StatusTone.progress => ToneColors(progressSoft, progressText),
    StatusTone.warning => ToneColors(butterSoft, warningText),
    StatusTone.danger => ToneColors(pinkSoft, dangerText),
    StatusTone.success => ToneColors(greenSoft, successText),
  };

  // Spacing scale (--space-1 .. --space-6) and page gutter.
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 24;
  static const double space6 = 32;
  static const double pageGutter = 16;

  // Radii (--radius-sm/md/lg).
  static const double radiusSm = 8;
  static const double radiusMd = 14;
  static const double radiusLg = 20;

  // Type sizes. 12 is the minimum text size. The full mobile scale lives in `theme.dart`.
  static const double textMeta = 12;
  static const double textBody = 14;
  static const double textTitle = 20;
  static const double textDisplay = 32;

  /// Minimum touch target on mobile (the website allows 24 px; phones need more).
  static const double minTarget = 48;

  @override
  AppTokens copyWith() => this;

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) => this;
}

/// Kinds of status pill (`.badge--*` in the website's workspace.css). Colours come from
/// [AppTokens.tone] so they follow the theme.
enum StatusTone { neutral, info, progress, warning, danger, success }

@immutable
class ToneColors {
  const ToneColors(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? const AppTokens();
}
