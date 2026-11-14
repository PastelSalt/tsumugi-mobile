import 'package:flutter/material.dart';

/// Short fade with a small upward slide for pushed pages. When the device (or the Account setting
/// "Reduce motion") asks for no animation, the page simply appears.
class TsumugiPageTransitionsBuilder extends PageTransitionsBuilder {
  const TsumugiPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// Duration for small decorative animations: zero when animations are disabled.
Duration motionDuration(
  BuildContext context, [
  Duration normal = const Duration(milliseconds: 150),
]) => MediaQuery.disableAnimationsOf(context) ? Duration.zero : normal;
