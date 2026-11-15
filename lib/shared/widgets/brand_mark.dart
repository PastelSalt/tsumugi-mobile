import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// The Tsumugi "ts" badge, rebuilt from the website (`.brand__mark` in base.css):
/// pink badge, corner radii 50% 50% 50% 8px, rotated -8 degrees, white Fredoka 700 "ts".
/// All measurements scale from the website's 31 px badge.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 31,
    this.color,
    this.rotate = true,
    this.textScale = 1,
  });

  final double size;
  final Color? color;
  final bool rotate;

  /// Enlarges the "ts" inside the badge (1 = the website's proportion). The launcher icon uses a
  /// larger value so the letters read at small sizes.
  final double textScale;

  static const double _webSize = 31;

  @override
  Widget build(BuildContext context) {
    final scale = size / _webSize;
    final badge = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color ?? context.tokens.pink,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(size / 2),
          topRight: Radius.circular(size / 2),
          bottomRight: Radius.circular(size / 2),
          bottomLeft: Radius.circular(8 * scale),
        ),
      ),
      child: Text(
        'ts',
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w700,
          fontSize: 12 * scale * textScale,
          letterSpacing: -0.08 * 12 * scale * textScale,
          height: 1,
          color: Colors.white,
        ),
      ),
    );
    final mark = rotate
        ? Transform.rotate(angle: -8 * math.pi / 180, child: badge)
        : badge;
    return Semantics(
      label: 'Tsumugi',
      image: true,
      child: ExcludeSemantics(child: mark),
    );
  }
}

/// Badge plus the lowercase "tsumugi" wordmark (Fredoka 700, 18 px, -0.04em), as in the website header.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.markSize = 31, this.showWordmark = true});

  final double markSize;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final fontSize = 18 * markSize / 31;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: markSize),
        if (showWordmark) ...[
          const SizedBox(width: 9),
          Text(
            'tsumugi',
            // The wordmark is a logo, not body text, so it keeps its size at any text scale.
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
              letterSpacing: -0.04 * fontSize,
              color: context.tokens.ink,
            ),
          ),
        ],
      ],
    );
  }
}
