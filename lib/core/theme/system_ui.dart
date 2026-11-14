import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// Edge-to-edge system bars: transparent status and navigation bars drawn behind the app, with
/// icon colours that match the theme. Call [enableEdgeToEdge] once at start-up and wrap the app in
/// an `AnnotatedRegion` with [systemOverlayStyle].
void enableEdgeToEdge() =>
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

SystemUiOverlayStyle systemOverlayStyle(AppTokens tokens) {
  final icons = tokens.isDark ? Brightness.light : Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: icons,
    statusBarBrightness: tokens.isDark
        ? Brightness.dark
        : Brightness.light, // iOS naming
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: icons,
    systemNavigationBarContrastEnforced: false,
  );
}
