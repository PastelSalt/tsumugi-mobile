import 'package:flutter/material.dart';

import 'motion.dart';
import 'tokens.dart';

/// Builds the app theme: Fredoka, warm paper canvas, flat colour (no gradients or elevation),
/// ink outlines for selected elements. Mirrors the website's look.
ThemeData buildTheme({
  AppTokens tokens = const AppTokens(),
  Brightness brightness = Brightness.light,
}) {
  final t = tokens;
  final scheme = ColorScheme.fromSeed(seedColor: t.pink, brightness: brightness)
      .copyWith(
        primary: t.pink,
        onPrimary: t.onAccent,
        primaryContainer: t.pinkSoft,
        onPrimaryContainer: t.ink,
        secondary: t.green,
        secondaryContainer: t.greenSoft,
        surface: t.paper,
        onSurface: t.ink,
        onSurfaceVariant: t.muted,
        outline: t.lineStrong,
        outlineVariant: t.line,
        surfaceTint: Colors.transparent,
      );

  const fontFamily = 'Fredoka';
  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    fontFamily: fontFamily,
  );
  // Apply the family last so the size/weight overrides below keep Fredoka too.
  // Mobile type scale (docs/PLAN-MOBILE-UI.md section 4.2). Display collapses into Title in the
  // large-title app bar; Row title is lighter than Title so lists read calmly.
  final text = base.textTheme
      .copyWith(
        // Display: large page title.
        headlineMedium: const TextStyle(
          fontSize: AppTokens.textDisplay,
          fontWeight: FontWeight.w700,
          height: 1.15,
          letterSpacing: -0.6,
        ),
        headlineSmall: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: -0.4,
        ),
        // Title: sheet and section titles, collapsed app bar title.
        titleLarge: const TextStyle(
          fontSize: AppTokens.textTitle,
          fontWeight: FontWeight.w600,
          height: 1.25,
          letterSpacing: -0.3,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        // Row title: list rows.
        titleSmall: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
        bodyLarge: const TextStyle(fontSize: 16, height: 1.5),
        bodyMedium: const TextStyle(fontSize: 15, height: 1.45),
        // Meta: secondary lines.
        bodySmall: const TextStyle(fontSize: 13, height: 1.4),
        labelLarge: const TextStyle(
          fontSize: AppTokens.textBody,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        labelSmall: const TextStyle(
          fontSize: AppTokens.textMeta,
          fontWeight: FontWeight.w600,
        ),
      )
      .apply(bodyColor: t.ink, displayColor: t.ink, fontFamily: fontFamily);

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: t.canvas,
    textTheme: text,
    extensions: [tokens],
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: TsumugiPageTransitionsBuilder(),
        TargetPlatform.iOS: TsumugiPageTransitionsBuilder(),
        TargetPlatform.windows: TsumugiPageTransitionsBuilder(),
        TargetPlatform.linux: TsumugiPageTransitionsBuilder(),
        TargetPlatform.macOS: TsumugiPageTransitionsBuilder(),
      },
    ),
    dividerTheme: DividerThemeData(color: t.line, space: 1, thickness: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: t.canvas,
      foregroundColor: t.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: text.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: t.paper,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        side: BorderSide(color: t.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: t.pink,
        foregroundColor: t.onAccent,
        minimumSize: const Size(AppTokens.minTarget, AppTokens.minTarget),
        shape: StadiumBorder(side: BorderSide(color: t.ink, width: 2)),
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: t.ink,
        minimumSize: const Size(AppTokens.minTarget, AppTokens.minTarget),
        shape: StadiumBorder(side: BorderSide(color: t.ink, width: 2)),
        side: BorderSide(color: t.ink, width: 2),
        textStyle: text.labelLarge,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.paper,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.radiusLg),
        ),
      ),
    ),
  );
}

/// Dark theme scaffold (not used by the app yet; see [AppTokens.dark]).
ThemeData buildDarkTheme() =>
    buildTheme(tokens: AppTokens.dark, brightness: Brightness.dark);
