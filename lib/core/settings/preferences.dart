import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Preferences that take effect at once and last until the app is closed (docs/PLAN-MOBILE-UI.md
/// 6.9). Nothing is saved on the device: a restart returns to the defaults.
class Preferences {
  const Preferences({
    this.themeMode = ThemeMode.system,
    this.textScale = 1.0,
    this.reduceMotion = false,
    this.weekStartsSunday = false,
  });

  /// Follow the device, or force light or dark.
  final ThemeMode themeMode;

  /// Multiplies the device's text size: 0.9 small, 1.0 default, 1.15 large, 1.3 largest.
  final double textScale;

  /// Turns decorative animation off on top of the device setting.
  final bool reduceMotion;

  /// Calendar weeks start on Sunday instead of Monday.
  final bool weekStartsSunday;

  Preferences copyWith({
    ThemeMode? themeMode,
    double? textScale,
    bool? reduceMotion,
    bool? weekStartsSunday,
  }) => Preferences(
    themeMode: themeMode ?? this.themeMode,
    textScale: textScale ?? this.textScale,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    weekStartsSunday: weekStartsSunday ?? this.weekStartsSunday,
  );

  bool get isDefault =>
      themeMode == ThemeMode.system &&
      textScale == 1.0 &&
      !reduceMotion &&
      !weekStartsSunday;
}

const textScaleOptions = [
  (0.9, 'Small'),
  (1.0, 'Default'),
  (1.15, 'Large'),
  (1.3, 'Largest'),
];

class PreferencesNotifier extends Notifier<Preferences> {
  @override
  Preferences build() => const Preferences();

  void setThemeMode(ThemeMode mode) => state = state.copyWith(themeMode: mode);

  void setTextScale(double scale) => state = state.copyWith(textScale: scale);

  void setReduceMotion(bool value) =>
      state = state.copyWith(reduceMotion: value);

  void setWeekStartsSunday(bool value) =>
      state = state.copyWith(weekStartsSunday: value);

  void reset() => state = const Preferences();
}

final preferencesProvider = NotifierProvider<PreferencesNotifier, Preferences>(
  PreferencesNotifier.new,
);

/// Whether the one-time hint about swiping and pressing and holding a task was dismissed this
/// session. Account can bring it back (docs/PLAN-UX.md, U3).
class GestureHintNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void dismiss() => state = true;

  void show() => state = false;
}

final gestureHintDismissedProvider =
    NotifierProvider<GestureHintNotifier, bool>(GestureHintNotifier.new);
