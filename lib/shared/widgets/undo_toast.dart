import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';

/// A floating message with an **Undo** action, drawn in the app's root overlay so it appears above
/// bottom sheets and dialogs as well as pages (a `SnackBar` hides behind a sheet). One toast at a
/// time: a new one replaces the previous. It disappears after [duration] or when Undo is tapped.
class UndoToast {
  UndoToast._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 5),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    showIn(overlay, message: message, onUndo: onUndo, duration: duration);
  }

  /// Like [show], for a caller that captured the overlay earlier (its own context may be gone).
  static void showIn(
    OverlayState overlay, {
    required String message,
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 5),
  }) {
    if (!overlay.mounted) return;
    hide();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastView(
        message: message,
        onUndo: () {
          hide();
          onUndo();
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(duration, hide);
  }

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({required this.message, required this.onUndo});

  final String message;
  final VoidCallback onUndo;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final media = MediaQuery.of(context);
    final animate = motionDuration(context) != Duration.zero;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    // Sits above the bottom navigation bar (about 72 dp) and the system gesture area.
    final bottom = media.viewPadding.bottom + 88;
    Widget toast = Material(
      color: t.onSurface,
      elevation: 3,
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppTokens.minTarget),
        child: Padding(
          padding: const EdgeInsets.only(left: AppTokens.space4),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    widget.message,
                    style: TextStyle(color: t.surface, fontSize: 14),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: widget.onUndo,
                style: TextButton.styleFrom(
                  foregroundColor: t.butter,
                  minimumSize: const Size(
                    AppTokens.minTarget,
                    AppTokens.minTarget,
                  ),
                ),
                icon: const Icon(LucideIcons.undo2, size: 16),
                label: const Text(
                  'Undo',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (animate) {
      toast = FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.4),
            end: Offset.zero,
          ).animate(curved),
          child: toast,
        ),
      );
    }
    return Positioned(
      left: AppTokens.pageGutter,
      right: AppTokens.pageGutter,
      bottom: bottom,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Semantics(liveRegion: true, child: toast),
        ),
      ),
    );
  }
}
