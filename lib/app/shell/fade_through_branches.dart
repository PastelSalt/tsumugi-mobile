import 'package:flutter/material.dart';

import '../../core/theme/motion.dart';

/// The bottom bar's tab contents with a fade-through: the tab you switch to fades in and rises 6 dp
/// over the one you left. All tabs stay alive (scroll position and state are kept) like an indexed
/// stack. With reduced motion it is a 100 ms fade, without the rise (docs/PLAN-UX.md, M-3).
class FadeThroughBranches extends StatefulWidget {
  const FadeThroughBranches({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<FadeThroughBranches> createState() => _FadeThroughBranchesState();
}

class _FadeThroughBranchesState extends State<FadeThroughBranches>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.tab,
    value: 1,
  );

  @override
  void didUpdateWidget(FadeThroughBranches old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _controller.duration = fadeDuration(context, Motion.tab);
      _controller.forward(from: 0);
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
    final curve = CurvedAnimation(parent: _controller, curve: Motion.enter);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          // The same wrappers for every tab, so switching never rebuilds a tab's state.
          Offstage(
            offstage: i != widget.currentIndex,
            child: TickerMode(
              enabled: i == widget.currentIndex,
              child: AnimatedBuilder(
                animation: curve,
                child: widget.children[i],
                builder: (context, child) {
                  final active = i == widget.currentIndex;
                  final t = active ? curve.value : 1.0;
                  return Opacity(
                    key: ValueKey('tab-fade-$i'),
                    opacity: t,
                    child: reduced || !active
                        ? child
                        : Transform.translate(
                            offset: Offset(0, 6 * (1 - t)),
                            child: child,
                          ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
