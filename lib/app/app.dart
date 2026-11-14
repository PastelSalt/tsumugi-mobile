import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme.dart';
import 'router.dart';

class TsumugiApp extends StatefulWidget {
  const TsumugiApp({super.key, this.initialLocation = '/'});

  /// Where the app opens. The welcome screen by default; tests open a tab directly.
  final String initialLocation;

  @override
  State<TsumugiApp> createState() => _TsumugiAppState();
}

class _TsumugiAppState extends State<TsumugiApp> {
  late final GoRouter _router = buildRouter(
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tsumugi',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: _router,
    );
  }
}
