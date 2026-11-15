import 'package:flutter/material.dart';

/// Motion tokens: every duration and curve the app uses (docs/PLAN-UX.md, section 9.1). Our own
/// working values, not Material's table. Most are 80 to 300 ms; nothing is over 400 ms except page
/// travel and a loading loop.
class Motion {
  Motion._();

  /// Press feedback: starts within 100 ms so an action feels caused by the person.
  static const press = Duration(milliseconds: 80);

  /// Chips, switches, selected states.
  static const fast = Duration(milliseconds: 120);

  /// Tiles entering or leaving, toasts, tip collapse, tab underline.
  static const short = Duration(milliseconds: 200);

  /// Tab fade-through and a screen section appearing.
  static const tab = Duration(milliseconds: 240);

  /// Page travel.
  static const page = Duration(milliseconds: 300);

  /// Numbers and bars moving to a new value.
  static const number = Duration(milliseconds: 400);

  /// Delay between sections on a screen's first appearance.
  static const stagger = Duration(milliseconds: 40);

  /// What movement becomes when motion is reduced: a plain fade.
  static const reducedFade = Duration(milliseconds: 100);

  /// A loading skeleton's shimmer loop.
  static const shimmer = Duration(milliseconds: 1200);

  /// Things moving within the screen.
  static const Curve standard = Curves.easeOutCubic;

  /// Things entering.
  static const Curve enter = Cubic(0.05, 0.7, 0.1, 1);

  /// Things leaving.
  static const Curve exit = Curves.easeInCubic;
}

/// Whether the person (or the device) has asked for less motion. True when the system disables
/// animations or the Account "Reduce motion" switch is on (the app builder merges both).
bool motionReduced(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

/// Duration for small state changes (a colour, a border): zero when motion is reduced, because the
/// end state is all that matters there.
Duration motionDuration(
  BuildContext context, [
  Duration normal = const Duration(milliseconds: 150),
]) => motionReduced(context) ? Duration.zero : normal;

/// Duration for a change that carries meaning (a screen or list changing): when motion is reduced
/// it does not vanish, it becomes a short fade, so the person still sees that something changed.
Duration fadeDuration(BuildContext context, [Duration normal = Motion.short]) =>
    motionReduced(context) ? Motion.reducedFade : normal;

/// Shared-axis page transition: the new page enters 30 dp from the right while fading in, and the
/// page under it drifts left a little; back reverses it. With reduced motion it is a short fade.
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
    final reduced = MediaQuery.disableAnimationsOf(context);
    final fadeIn = CurvedAnimation(
      parent: animation,
      curve: reduced ? const Interval(0, 0.34) : Motion.enter,
      reverseCurve: reduced ? const Interval(0.66, 1) : Motion.exit,
    );
    if (reduced) return FadeTransition(opacity: fadeIn, child: child);
    final fadeOut = Tween<double>(begin: 1, end: 0.6).animate(
      CurvedAnimation(parent: secondaryAnimation, curve: Motion.standard),
    );
    final slideIn = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Motion.enter));
    final slideOut =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-0.04, 0)).animate(
          CurvedAnimation(parent: secondaryAnimation, curve: Motion.standard),
        );
    return SlideTransition(
      position: slideOut,
      child: FadeTransition(
        opacity: fadeOut,
        child: FadeTransition(
          opacity: fadeIn,
          child: SlideTransition(position: slideIn, child: child),
        ),
      ),
    );
  }
}
