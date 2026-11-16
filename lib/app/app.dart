import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/net/auth_state.dart';
import '../core/net/live_store.dart';
import '../core/settings/preferences.dart';
import '../core/theme/system_ui.dart';
import '../core/theme/theme.dart';
import '../core/theme/tokens.dart';
import 'router.dart';

class TsumugiApp extends ConsumerStatefulWidget {
  const TsumugiApp({super.key, this.initialLocation = '/'});

  /// Where the app opens. The welcome screen by default; tests open a tab directly.
  final String initialLocation;

  @override
  ConsumerState<TsumugiApp> createState() => _TsumugiAppState();
}

class _TsumugiAppState extends ConsumerState<TsumugiApp> {
  late final GoRouter _router = buildRouter(
    initialLocation: widget.initialLocation,
  );
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);
    // A save that failed (offline, rejected): say so, in plain words.
    ref.listen(liveErrorProvider, (_, message) {
      if (message == null) return;
      _messenger.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      ref.read(liveErrorProvider.notifier).clear();
    });
    // The session ended somewhere else (another device, a password change): back to sign-in.
    ref.listen(authProvider, (previous, next) {
      if (previous?.isSignedIn == true && next.status == AuthStatus.signedOut) {
        _router.go('/sign-in');
      }
    });
    return MaterialApp.router(
      scaffoldMessengerKey: _messenger,
      title: 'Tsumugi',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: prefs.themeMode,
      restorationScopeId: 'tsumugi',
      routerConfig: _router,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          // The app's text size and motion preferences sit on top of the device's.
          data: media.copyWith(
            textScaler: prefs.textScale == 1.0
                ? media.textScaler
                : _Scaled(media.textScaler, prefs.textScale),
            disableAnimations: media.disableAnimations || prefs.reduceMotion,
          ),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: systemOverlayStyle(context.tokens),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

/// The device's text scaler multiplied by the app's own text-size preference.
class _Scaled extends TextScaler {
  const _Scaled(this.base, this.factor);

  final TextScaler base;
  final double factor;

  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;

  @override
  double get textScaleFactor => base.scale(1) * factor;

  @override
  TextScaler clamp({
    double minScaleFactor = 0,
    double maxScaleFactor = double.infinity,
  }) => TextScaler.linear(
    (base.scale(1) * factor).clamp(minScaleFactor, maxScaleFactor),
  );

  @override
  bool operator ==(Object other) =>
      other is _Scaled && other.factor == factor && other.base == base;

  @override
  int get hashCode => Object.hash(base, factor);
}
