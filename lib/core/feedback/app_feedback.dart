import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kinds of haptic feedback the app uses (docs/PLAN-MOBILE-UI.md section 7.2).
enum Haptic {
  /// Selecting, toggling, undoing.
  selection,

  /// Small confirmations.
  light,

  /// Completing a task.
  medium,

  /// Something good finished (for example the last overdue task).
  success,

  /// Invalid input or a refused action.
  error,
}

/// Haptics behind an interface so tests can record them and a switch can turn them off.
abstract class AppFeedback {
  void haptic(Haptic kind);
}

class SystemFeedback implements AppFeedback {
  const SystemFeedback({this.enabled = true});

  final bool enabled;

  @override
  void haptic(Haptic kind) {
    if (!enabled) return;
    try {
      switch (kind) {
        case Haptic.selection:
          HapticFeedback.selectionClick();
        case Haptic.light:
          HapticFeedback.lightImpact();
        case Haptic.medium:
          HapticFeedback.mediumImpact();
        case Haptic.success:
          HapticFeedback.mediumImpact();
          Future<void>.delayed(
            const Duration(milliseconds: 90),
            HapticFeedback.lightImpact,
          );
        case Haptic.error:
          HapticFeedback.heavyImpact();
      }
    } catch (_) {
      // No vibrator or no platform channel (tests, some desktops): feedback is optional.
    }
  }
}

/// Whether haptic feedback is on. Default on; the Account settings screen controls it (M6).
class HapticsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool value) => state = value;
}

final hapticsEnabledProvider = NotifierProvider<HapticsEnabledNotifier, bool>(
  HapticsEnabledNotifier.new,
);

final feedbackProvider = Provider<AppFeedback>(
  (ref) => SystemFeedback(enabled: ref.watch(hapticsEnabledProvider)),
);
