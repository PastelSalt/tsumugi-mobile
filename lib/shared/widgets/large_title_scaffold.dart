import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Scaffold for top-level screens with a **large title that collapses into the app bar** as the
/// content scrolls (docs/PLAN-MOBILE-UI.md, principle 1). It replaces the website's static page
/// header: the title is big at the top, shrinks to a normal app-bar title when scrolled, and an
/// optional header (view tabs) stays pinned underneath.
///
/// - [slivers] is the scrolling content (use `SliverList`, `SliverPadding`, ...).
/// - [pinnedHeader] stays visible under the bar (height [pinnedHeaderHeight]).
/// - [onRefresh] adds pull-to-refresh.
/// - [restorationId] keeps the scroll position when the app is restored after the system has
///   stopped it (requires `restorationScopeId` on the app, which `TsumugiApp` sets).
class LargeTitleScaffold extends StatefulWidget {
  const LargeTitleScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.actions = const [],
    this.leading,
    this.pinnedHeader,
    this.pinnedHeaderHeight = 49,
    this.onRefresh,
    this.restorationId,
    this.expandedHeight = 120,
  });

  final String title;
  final List<Widget> slivers;
  final List<Widget> actions;

  /// Shown before the title (a back button on pushed pages).
  final Widget? leading;
  final Widget? pinnedHeader;
  final double pinnedHeaderHeight;
  final Future<void> Function()? onRefresh;
  final String? restorationId;
  final double expandedHeight;

  @override
  State<LargeTitleScaffold> createState() => _LargeTitleScaffoldState();
}

class _LargeTitleScaffoldState extends State<LargeTitleScaffold>
    with RestorationMixin {
  final _offset = RestorableDouble(0);
  late final ScrollController _controller = ScrollController()
    ..addListener(_remember);

  @override
  String? get restorationId => widget.restorationId;

  void _remember() {
    if (_controller.hasClients) _offset.value = _controller.offset;
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_offset, 'scroll-offset');
    if (_offset.value > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) {
          _controller.jumpTo(
            _offset.value.clamp(0, _controller.position.maxScrollExtent),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final scroll = CustomScrollView(
      controller: _controller,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: widget.expandedHeight,
          backgroundColor: t.background,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          foregroundColor: t.onSurface,
          titleSpacing: AppTokens.pageGutter,
          leading: widget.leading,
          automaticallyImplyLeading: false,
          actions: [...widget.actions, const SizedBox(width: 4)],
          // The title is drawn once and scaled: 1.6x (32 sp) when expanded, 20 sp when collapsed.
          flexibleSpace: FlexibleSpaceBar(
            expandedTitleScale: 1.6,
            titlePadding: const EdgeInsetsDirectional.only(
              start: AppTokens.pageGutter,
              bottom: 14,
            ),
            title: Semantics(
              header: true,
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        if (widget.pinnedHeader != null)
          SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedHeader(
              child: widget.pinnedHeader!,
              height: widget.pinnedHeaderHeight,
              color: t.background,
              line: t.outline,
            ),
          ),
        ...widget.slivers,
        const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space5)),
      ],
    );
    return Material(
      color: t.background,
      child: widget.onRefresh == null
          ? scroll
          : RefreshIndicator(onRefresh: widget.onRefresh!, child: scroll),
    );
  }
}

class _PinnedHeader extends SliverPersistentHeaderDelegate {
  _PinnedHeader({
    required this.child,
    required this.height,
    required this.color,
    required this.line,
  });

  final Widget child;
  final double height;
  final Color color;
  final Color line;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Container(
    height: height,
    padding: const EdgeInsets.symmetric(horizontal: AppTokens.pageGutter),
    decoration: BoxDecoration(
      color: color,
      border: Border(
        bottom: BorderSide(color: overlapsContent ? line : Colors.transparent),
      ),
    ),
    child: child,
  );

  @override
  bool shouldRebuild(_PinnedHeader old) =>
      old.child != child ||
      old.height != height ||
      old.color != color ||
      old.line != line;
}
