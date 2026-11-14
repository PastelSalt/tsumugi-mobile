import 'package:flutter/material.dart';

/// Design tokens extracted from the website (`client/src/styles/base.css` and `workspace.css`).
/// One place for colours, radii, spacing and status tones so screens never hard-code values.
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
    this.line = const Color(0xFFE9E3ED),
    this.lineStrong = const Color(0xFFD8D0E0),
  });

  /// Dark palette. A scaffold only: the app ships the light theme (like the website). Widgets that use
  /// fixed colours (status pills, a few banners) are not yet adapted, so dark mode stays off.
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
    line: Color(0xFF332D3C),
    lineStrong: Color(0xFF453E50),
  );

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
  final Color line;
  final Color lineStrong;

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

  // Type scale (--text-meta/body/title/display). 12 is the minimum text size.
  static const double textMeta = 12;
  static const double textBody = 14;
  static const double textTitle = 20;
  static const double textDisplay = 28;

  /// Minimum touch target on mobile (the website allows 24 px; phones need more).
  static const double minTarget = 48;

  @override
  AppTokens copyWith() => this;

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) => this;
}

/// Status pill colours (`.badge--*` in workspace.css): background and foreground.
enum StatusTone {
  neutral(Color(0xFFF1EEF5), Color(0xFF4A4455)),
  info(Color(0xFFE5F4FF), Color(0xFF1D5F80)),
  progress(Color(0xFFECE6FB), Color(0xFF5A45A8)),
  warning(Color(0xFFFFF2CF), Color(0xFF7A5600)),
  danger(Color(0xFFFFE8F5), Color(0xFFA3205C)),
  success(Color(0xFFE8EFE9), Color(0xFF2F6A42));

  const StatusTone(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? const AppTokens();
}
