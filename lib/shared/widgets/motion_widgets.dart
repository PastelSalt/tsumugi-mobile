import 'package:flutter/material.dart';

import '../../core/theme/motion.dart';

/// A section's first appearance: it fades in and rises 12 dp, a little after the one before it, so
/// the eye is led down the screen. Plays **once per launch** for each [id] (scrolling back or
/// returning to the screen does not replay it). With reduced motion it is a short fade without the
/// rise (docs/PLAN-UX.md, M-8).
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.id,
    required this.child,
    this.index = 0,
  });

  /// Names this section, for example `home/up-now`.
  final String id;

  /// Position in the order of appearance; later ones start a little later (at most six steps).
  final int index;
  final Widget child;

  static final Set<String> _played = {};

  /// Forgets what has played, so the entrances run again (tests).
  static void reset() => _played.clear();

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _animated = false;

  @override
  void initState() {
    super.initState();
    _animated = Entrance._played.add(widget.id);
    final step = widget.index.clamp(0, 6);
    final total = Motion.short + Motion.stagger * step;
    _controller = AnimationController(
      vsync: this,
      duration: total,
      value: _animated ? 0 : 1,
    );
    _delayFraction = step == 0
        ? 0
        : (Motion.stagger * step).inMilliseconds / total.inMilliseconds;
  }

  late final double _delayFraction;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_animated && !_started) {
      _started = true;
      if (motionReduced(context)) {
        _controller.duration = Motion.reducedFade;
      }
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = motionReduced(context);
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(reduced ? 0 : _delayFraction, 1, curve: Motion.enter),
    );
    return AnimatedBuilder(
      animation: curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: curve.value,
        child: reduced
            ? child
            : Transform.translate(
                offset: Offset(0, 12 * (1 - curve.value)),
                child: child,
              ),
      ),
    );
  }
}

/// Swaps its child with a short fade and a small rise when [switchKey] changes: a count or a
/// headline that changes value, rather than a hard swap. Reduced motion: a plain short fade.
class FadeSwitch extends StatelessWidget {
  const FadeSwitch({super.key, required this.switchKey, required this.child});

  final Object switchKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = motionReduced(context);
    return AnimatedSwitcher(
      duration: fadeDuration(context),
      switchInCurve: Motion.enter,
      switchOutCurve: Motion.exit,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerLeft,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: reduced
            ? child
            : SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
      ),
      child: KeyedSubtree(key: ValueKey(switchKey), child: child),
    );
  }
}
