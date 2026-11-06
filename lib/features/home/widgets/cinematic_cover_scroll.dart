import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef CinematicHeroBuilder = Widget Function(
    ValueListenable<double> contentVisibility);

/// Netflix page anatomy (user mandate — "الهيرو يتحرك ضمن الصفحة"): the
/// featured hero is the FIRST child of the scroll view itself, so it glides
/// away with the feed exactly like the Netflix app — no stationary backdrop
/// and no surface sheet sliding over it.
///
/// [contentVisibility] still reports the hero's on-screen share (1 at the
/// top → 0 once it has fully scrolled past), so hero content keeps its
/// gentle fade-out while leaving — now driven by the hero's own position
/// inside the page instead of a cover layer.
class CinematicCoverScroll extends StatefulWidget {
  const CinematicCoverScroll(
      {super.key,
      required this.heroBuilder,
      required this.heroHeight,
      required this.slivers,
      this.storageKey});

  final CinematicHeroBuilder heroBuilder;

  /// The hero's laid-out height inside the scroll flow (used to map scroll
  /// offset → visibility).
  final double heroHeight;
  final List<Widget> slivers;
  final PageStorageKey<String>? storageKey;

  @override
  State<CinematicCoverScroll> createState() => _CinematicCoverScrollState();
}

class _CinematicCoverScrollState extends State<CinematicCoverScroll> {
  final _scroll = ScrollController();
  late final ValueNotifier<double> _contentVisibility;

  @override
  void initState() {
    super.initState();
    // The controller attaches during the first build; start at full
    // visibility (the hero's natural state at scroll offset zero) and let
    // the listener refine it from there.
    _contentVisibility = ValueNotifier(1);
    _scroll.addListener(_updateContentVisibility);
  }

  @override
  void didUpdateWidget(covariant CinematicCoverScroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.heroHeight != widget.heroHeight) {
      _updateContentVisibility();
    }
  }

  double _visibilityFor(double offset) => widget.heroHeight <= 0
      ? 0.0
      : (1 - offset / widget.heroHeight).clamp(0.0, 1.0);

  void _updateContentVisibility() {
    final visibility = _visibilityFor(
        _scroll.hasClients ? _scroll.offset : 0.0);
    if ((_contentVisibility.value - visibility).abs() > .001) {
      _contentVisibility.value = visibility;
    }
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_updateContentVisibility)
      ..dispose();
    _contentVisibility.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: widget.storageKey,
      controller: _scroll,
      slivers: [
        // The hero lives INSIDE the page — it scrolls away with the feed,
        // exactly like the Netflix home / detail pages. The height slot
        // gives hero widgets (which fill their parent) a bounded box.
        SliverToBoxAdapter(
          child: SizedBox(
            height: widget.heroHeight,
            child: RepaintBoundary(
              child: widget.heroBuilder(_contentVisibility),
            ),
          ),
        ),
        // The feed follows directly on the page canvas (pure black under
        // the Netflix theme) — no rounded sheet edge, like the Netflix app.
        SliverMainAxisGroup(slivers: widget.slivers),
      ],
    );
  }
}
