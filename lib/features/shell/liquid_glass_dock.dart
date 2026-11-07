/// NOVA's Apple-style "Liquid Glass" floating tab bar — an iOS 26/27
/// bottom bar built on the `liquid_glass_renderer` Flutter GPU pipeline.
///
/// Architecture (mirrors the renderer's canonical bottom-bar recipe and the
/// user mandate):
///  - The dock mounts in the shell's `Stack` ABOVE the background feed; the
///    glass samples everything painted beneath it (real backdrop refraction).
///  - ONE ambient [LiquidGlassLayer] carries the shared material —
///    `LiquidGlassSettings.ios27Regular(brightness:)`, Apple's measured
///    regular-glass rim: 1.2pt glint along the light axis, 0.75pt dark
///    contour outside the silhouette and the inner bevel shadow.
///  - A [LiquidGlassBlendGroup] with `blend: 24` groups the two chrome
///    segments so adjacent glass shapes smooth/liquid-merge into each other:
///      • the tab-bar container capsule —
///        `LiquidGlass.grouped(shape: LiquidRoundedSuperellipse(borderRadius: 28))`,
///      • the trailing search orb — `LiquidGlass.grouped(shape: LiquidOval())`
///        wrapped in [LiquidStretch]. At rest the 12pt gap keeps the segments
///        apart; stretching the orb toward the capsule closes the gap under
///        the blend distance and the two shapes melt into one liquid blob.
///  - The selection platter is glass-on-glass: while the finger scrubs the
///    tabs, a clear lens (`LiquidGlass.withOwnLayer`, Apple-loupe settings —
///    `frost: 0`, `backdropShrink`, negative dispersion) is mounted ABOVE the
///    capsule's interior and refracts the bar glass beneath it. At rest a
///    painted platter keeps the cost at zero.
///  - Wherever full glass is unavailable (tests, web, shader-less Impeller)
///    the renderer falls back to FakeGlass automatically; `reduceTransparency`
///    swaps the whole chrome for an opaque accessibility surface.
///  - Interaction contract is identical to [GlassDock]: the scrub gesture
///    (≥250ms hold or >6px move), fractional pill, flick commit, exactly-one
///    navigation per gesture, haptics, RTL mirroring, tab ValueKeys
///    (`dock-tab-<id>`) and button+selected semantics — so hosts can swap the
///    two docks freely.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:nova_mobile/core/theme/nova_theme.dart';
import 'package:nova_mobile/l10n/nova_strings.dart';

import 'dock_tab.dart';
import 'glass_dock.dart' show NavigationBarStyle, kDockEase;

// ---------------------------------------------------------------------------
// Motion + gesture constants (same feel as GlassDock).
// ---------------------------------------------------------------------------

const Duration _kSlideDuration = Duration(milliseconds: 350);
const Duration _kIconCrossfadeDuration = Duration(milliseconds: 150);
const Duration _kGrowDuration = Duration(milliseconds: 150);
const Duration _kScrubHold = Duration(milliseconds: 250);
const double _kScrubMovePx = 6;
const double _kScrubGrow = 1.08;
const double _kFlickPxPerMs = 0.5;
const int _kFlickSampleWindowMs = 120;
const int _kMaxScrubSamples = 6;

/// `kPrimaryMouseButton`, kept as a literal to stay import-minimal.
const int _leftMouseButton = 1;

/// The capsule silhouette the user mandate pins: a superellipse with a 28dp
/// corner radius (iOS 27 tab-bar geometry — NOT a stadium).
const double _kCapsuleRadius = 28;

/// Blend distance (logical px) at which grouped shapes liquid-merge.
const double _kBlendDistance = 24;

/// Soft ambient shadow under every glass segment.
const List<BoxShadow> _kGlassShadows = [
  BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10)),
];

/// The clear selection lens mounted while scrubbing — Apple's tab-bar loupe:
/// an unfrosted lens that shrinks the bar a little through its
/// [LiquidGlassSettings.backdropShrink] and folds the content only in a
/// narrow band along its rim (negative dispersion, like real glass).
const LiquidGlassSettings _kLensSettings = LiquidGlassSettings(
  refractionHeight: 15,
  refractionAmount: 10,
  refractionFitsShape: false,
  dispersion: -0.3,
  frost: 0,
  contourStrength: 0.3,
  backdropShrink: 0.06,
);

// ---------------------------------------------------------------------------
// Size ladder.
// ---------------------------------------------------------------------------

/// Resolved metrics for one window class.
class LiquidGlassDockSizing {
  const LiquidGlassDockSizing({
    required this.barHeight,
    required this.iconSize,
    required this.orbDiameter,
    required this.orbGap,
    required this.totalWidth,
    required this.bottomOffset,
  });

  /// Capsule height (the superellipse's short side).
  final double barHeight;

  /// Tab glyph size.
  final double iconSize;

  /// The round search orb's diameter.
  final double orbDiameter;

  /// Gap between the capsule and the orb (kept above the blend distance at
  /// rest so the segments stay separate until stretched together).
  final double orbGap;

  /// Whole dock width: capsule + gap + orb.
  final double totalWidth;

  /// Air between the dock and the screen edge.
  final double bottomOffset;

  /// Tab track inset inside the capsule (iOS 27: ~9pt at the ends).
  double get trackInset => 9;

  /// Selection platter height inside the capsule.
  double get platterHeight => barHeight - 12;

  /// Content clearance pages must reserve (capsule + air + safe + 16).
  double contentClearance({required double safeBottom}) =>
      barHeight + bottomOffset + safeBottom + 16;
}

/// Window-class ladder (<360 / 360–599 / 600–839 / ≥840, landscape override,
/// `mini` slimming, zoom multipliers) — resolved like [glassDockSizing].
LiquidGlassDockSizing liquidGlassDockSizing({
  required Size viewport,
  EdgeInsets safePadding = EdgeInsets.zero,
  NavigationBarStyle style = NavigationBarStyle.classic,
  double zoom = 1.0,
  double kidsZoom = 1.0,
}) {
  final w = viewport.width;
  double barH, orb, gap, bottom;
  if (viewport.height <= 480) {
    barH = 54;
    orb = 54;
    gap = 10;
    bottom = 8;
  } else if (w < 360) {
    barH = 58;
    orb = 58;
    gap = 10;
    bottom = 12;
  } else if (w < 600) {
    barH = 64;
    orb = 64;
    gap = 12;
    bottom = 16;
  } else if (w < 840) {
    barH = 64;
    orb = 64;
    gap = 12;
    bottom = 20;
  } else {
    barH = 68;
    orb = 68;
    gap = 14;
    bottom = 24;
  }
  double icon = w < 600 ? 21 : 22;
  final mini = style == NavigationBarStyle.mini;
  if (mini) {
    barH = math.min(barH, 56);
    orb = barH;
    icon = math.min(icon, 20.0);
  }
  final scale = zoom * kidsZoom;
  barH *= scale;
  orb *= scale;
  gap *= scale;
  icon *= scale;
  // Hard width guard: the whole dock never exceeds the viewport minus air.
  final viewportCap = math.max(
    0.0,
    math.min(w - 12, w - safePadding.horizontal),
  );
  final total = math.min(viewportCap, 430 * scale);
  return LiquidGlassDockSizing(
    barHeight: barH,
    iconSize: icon,
    orbDiameter: orb,
    orbGap: gap,
    totalWidth: total,
    bottomOffset: bottom,
  );
}

// ---------------------------------------------------------------------------
// LiquidGlassDock.
// ---------------------------------------------------------------------------

/// The liquid glass dock: floating capsule + search orb on ONE shared glass
/// layer, with a liquid selection lens that flows between tabs.
class LiquidGlassDock extends StatefulWidget {
  const LiquidGlassDock({
    super.key,
    required this.tabs,
    required this.activeId,
    required this.onTabSelected,
    this.languageCode,
    this.hidden = false,
    this.previewMode = false,
    this.style = NavigationBarStyle.classic,
    this.reduceMotion = false,
    this.reduceTransparency = false,
    this.zoom = 1.0,
    this.kidsZoom = 1.0,
    this.onSearch,
    this.searchLabel,
  });

  /// Tabs to render, in display order ([noorDockTabsFor] output).
  final List<DockTab> tabs;

  /// Id of the active tab (same fallback contract as [GlassDock.activeId]:
  /// unknown ids rest the platter on slot 0 with nothing selected).
  final String activeId;

  /// Exactly-one navigation commit per tap/scrub-release.
  final ValueChanged<DockTab> onTabSelected;

  /// Language code for labels/semantics; null defers to ambient direction.
  final String? languageCode;

  /// Effective hidden state (slide below screen + fade + ignore pointers).
  final bool hidden;

  /// Non-interactive settings preview (activation off, semantics excluded).
  final bool previewMode;

  final NavigationBarStyle style;
  final bool reduceMotion;
  final bool reduceTransparency;
  final double zoom;
  final double kidsZoom;

  /// Trailing orb action (search). Null hides the orb (Kids Mode).
  final VoidCallback? onSearch;

  /// Orb tooltip/semantics label.
  final String? searchLabel;

  @override
  State<LiquidGlassDock> createState() => _LiquidGlassDockState();
}

class _LiquidGlassDockState extends State<LiquidGlassDock>
    with TickerProviderStateMixin {

  // -- platter motion (same ONE-fraction model as GlassDock) -----------------
  late final AnimationController _motion;
  late final CurvedAnimation _motionEase;
  double _motionFracFrom = 0;
  double _motionFracTo = 0;
  double _motionScaleFrom = 1;
  double _motionScaleTo = 1;

  /// Scrub grow: 1 → 1.08 over 150ms, composed into the platter transform.
  late final AnimationController _grow;
  late final CurvedAnimation _growEase;

  double _frac = 0;
  double _scale = 1;
  bool _measured = false;

  bool _scrubbing = false;
  int? _litIndex;
  int? _pressedIndex;

  bool _reduceMotion = false;
  bool _isRtl = false;
  int _dirSign = 1;
  double _inset = 9;
  double _trackW = 0;
  double _slotW = 0;

  // Scrub bookkeeping (web ScrubGesture).
  _PendingGesture? _pending;
  Timer? _holdTimer;
  final List<({double x, int t})> _samples = [];
  Stopwatch? _scrubClock;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(vsync: this, duration: _kSlideDuration);
    _motionEase = CurvedAnimation(parent: _motion, curve: kDockEase);
    _motionEase.addListener(_onMotionTick);
    _grow = AnimationController(vsync: this, duration: _kGrowDuration);
    _growEase = CurvedAnimation(parent: _grow, curve: Curves.easeOutQuad);
    _growEase.addListener(_onGrowTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion =
        widget.reduceMotion || MediaQuery.disableAnimationsOf(context);
  }

  @override
  void didUpdateWidget(covariant LiquidGlassDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reduceMotion =
        widget.reduceMotion || MediaQuery.disableAnimationsOf(context);
    final idsChanged = !_sameTabIds(oldWidget.tabs, widget.tabs);
    if (idsChanged && _scrubbing) {
      _holdTimer?.cancel();
      _holdTimer = null;
      _pending = null;
      _scrubClock = null;
      _samples.clear();
      _scrubbing = false;
      _litIndex = null;
      _pressedIndex = null;
    }
    if (!_scrubbing && (idsChanged || oldWidget.activeId != widget.activeId)) {
      _startMotion(toFrac: _resolvedActiveSlot.toDouble(), toScale: 1);
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _motionEase.dispose();
    _motion.dispose();
    _growEase.dispose();
    _grow.dispose();
    super.dispose();
  }

  // -- platter motion --------------------------------------------------------

  int get _resolvedActiveSlot {
    final i = widget.tabs.indexWhere((tab) => tab.id == widget.activeId);
    return i >= 0 ? i : 0;
  }

  void _startMotion({required double toFrac, required double toScale}) {
    if (_motion.isAnimating &&
        _motionFracTo == toFrac &&
        _motionScaleTo == toScale) {
      return;
    }
    _motion.stop();
    _grow.stop();
    _motionFracFrom = _frac;
    _motionFracTo = toFrac;
    _motionScaleFrom = _scale;
    _motionScaleTo = toScale;
    _motion.duration = _reduceMotion ? Duration.zero : _kSlideDuration;
    _motion.forward(from: 0);
  }

  void _onMotionTick() {
    final t = _motionEase.value;
    setState(() {
      _frac = _lerp(_motionFracFrom, _motionFracTo, t);
      _scale = _lerp(_motionScaleFrom, _motionScaleTo, t);
    });
  }

  void _onGrowTick() {
    setState(() => _scale = 1 + (_kScrubGrow - 1) * _growEase.value);
  }

  // -- scrub gesture (ported 1:1 from the web dock) ---------------------------

  void _onPointerDown(PointerDownEvent event) {
    if (widget.hidden || widget.previewMode) return;
    if (_pending != null) return;
    if (event.kind == PointerDeviceKind.mouse &&
        event.buttons != _leftMouseButton) {
      return;
    }
    _pending = _PendingGesture(
      pointer: event.pointer,
      startX: event.localPosition.dx,
      startY: event.localPosition.dy,
    );
    setState(() => _pressedIndex = _slotForLocalX(event.localPosition.dx));
    _holdTimer = Timer(_kScrubHold, () {
      final pending = _pending;
      if (pending != null && !_scrubbing) {
        _enterScrub(pending.startX, pending.pointer);
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    final pending = _pending;
    if (pending == null || event.pointer != pending.pointer) return;
    if (!_scrubbing) {
      final distance =
          (event.localPosition - Offset(pending.startX, pending.startY))
              .distance;
      if (distance > _kScrubMovePx) {
        _holdTimer?.cancel();
        _holdTimer = null;
        _enterScrub(event.localPosition.dx, event.pointer);
      }
      return;
    }
    _updateScrub(event.localPosition.dx);
  }

  void _onPointerUp(PointerUpEvent event) {
    final pending = _pending;
    if (pending == null || event.pointer != pending.pointer) return;
    _holdTimer?.cancel();
    _holdTimer = null;
    _pending = null;
    if (!_scrubbing) {
      setState(() => _pressedIndex = null);
      if (widget.tabs.isNotEmpty) {
        widget
            .onTabSelected(widget.tabs[_slotForLocalX(event.localPosition.dx)]);
      }
      return;
    }
    _commitScrub();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    final pending = _pending;
    if (pending == null || event.pointer != pending.pointer) return;
    _holdTimer?.cancel();
    _holdTimer = null;
    _pending = null;
    if (!_scrubbing) {
      setState(() => _pressedIndex = null);
      return;
    }
    _samples.clear();
    _scrubClock = null;
    setState(() {
      _scrubbing = false;
      _litIndex = null;
      _pressedIndex = null;
    });
    _startMotion(toFrac: _resolvedActiveSlot.toDouble(), toScale: 1);
  }

  void _enterScrub(double localX, int pointer) {
    final pending = _pending;
    if (_scrubbing ||
        pending == null ||
        pending.pointer != pointer ||
        widget.tabs.length < 2) {
      return;
    }
    _motion.stop();
    _grow.duration = _reduceMotion ? Duration.zero : _kGrowDuration;
    _grow.forward(from: 0);
    _scrubClock = Stopwatch()..start();
    _samples.clear();
    setState(() {
      _scrubbing = true;
      _pressedIndex = null;
    });
    _updateScrub(localX);
    HapticFeedback.lightImpact();
  }

  void _updateScrub(double localX) {
    final count = widget.tabs.length;
    if (count < 2 || _scrubClock == null) return;
    final frac = _fracForLocalX(localX);
    _samples.add((x: localX, t: _scrubClock!.elapsedMilliseconds));
    if (_samples.length > _kMaxScrubSamples) _samples.removeAt(0);
    setState(() {
      _frac = frac;
      _litIndex = _clampSlot(frac.round(), count);
    });
  }

  void _commitScrub() {
    final count = widget.tabs.length;
    if (count == 0) return;
    var target = _clampSlot(_frac.round(), count);
    final now = _scrubClock?.elapsedMilliseconds ?? 0;
    final recent = _samples
        .where((sample) => now - sample.t <= _kFlickSampleWindowMs)
        .toList(growable: false);
    if (recent.length >= 2) {
      final dt = recent.last.t - recent.first.t;
      if (dt > 0) {
        final velocity = (recent.last.x - recent.first.x) / dt;
        if (velocity.abs() > _kFlickPxPerMs) {
          target =
              _clampSlot(target + (velocity > 0 ? 1 : -1) * _dirSign, count);
        }
      }
    }
    _samples.clear();
    _scrubClock = null;
    setState(() {
      _scrubbing = false;
      _litIndex = null;
      _pressedIndex = null;
    });
    _startMotion(toFrac: target.toDouble(), toScale: 1);
    final tab = widget.tabs[target];
    if (tab.id != widget.activeId) {
      widget.onTabSelected(tab);
    }
  }

  // -- geometry helpers ------------------------------------------------------

  double _inlinePos(double localX) {
    final x = _clampD(localX - _inset, 0, _trackW);
    return _isRtl ? _trackW - x : x;
  }

  double _fracForLocalX(double localX) {
    final count = widget.tabs.length;
    if (count == 0 || _slotW <= 0) return 0;
    return _clampD(_inlinePos(localX) / _slotW - 0.5, 0, count - 1);
  }

  int _slotForLocalX(double localX) {
    final count = widget.tabs.length;
    if (count == 0 || _slotW <= 0) return 0;
    return _clampSlot((_inlinePos(localX) / _slotW).floor(), count);
  }

  // -- build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    _isRtl = rtl;
    _dirSign = rtl ? -1 : 1;

    final arabic = widget.languageCode != null
        ? dockIsArabicLanguage(widget.languageCode)
        : rtl;
    final navLabel = NovaStrings.lookup(!arabic, 'primaryNavigation');
    final activeIndex = widget.tabs.indexWhere((tab) => tab.id == widget.activeId);
    final hasActive = activeIndex >= 0;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      excludeSemantics: widget.previewMode,
      label: navLabel,
      child: ExcludeSemantics(
        excluding: widget.hidden || widget.previewMode,
        child: IgnorePointer(
          ignoring: widget.hidden || widget.previewMode,
          child: AnimatedSlide(
            offset: widget.hidden ? const Offset(0, 1) : Offset.zero,
            duration: _reduceMotion ? Duration.zero : _kSlideDuration,
            curve: kDockEase,
            child: AnimatedOpacity(
              opacity: widget.hidden ? 0 : 1,
              duration: _reduceMotion ? Duration.zero : _kSlideDuration,
              curve: kDockEase,
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  bottom: MediaQuery.paddingOf(context).bottom,
                ),
                child: Center(
                  child: _buildDock(media, activeIndex, hasActive, arabic),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDock(
    MediaQueryData media,
    int activeIndex,
    bool hasActive,
    bool arabic,
  ) {
    final sizing = liquidGlassDockSizing(
      viewport: media.size,
      safePadding: media.padding,
      style: widget.style,
      zoom: widget.zoom,
      kidsZoom: widget.kidsZoom,
    );
    final brightness = Theme.of(context).brightness;
    final showLabels = widget.style != NavigationBarStyle.mini;
    final showOrb = widget.onSearch != null;

    Widget chrome(Widget segments) => Padding(
          padding: EdgeInsetsDirectional.only(bottom: sizing.bottomOffset),
          child: SizedBox(
            width: sizing.totalWidth,
            height: sizing.barHeight,
            child: segments,
          ),
        );

    // The two glass segments share ONE blend group on ONE ambient layer.
    Widget glassSegments() {
      return LiquidGlassLayer(
        // iOS 27 regular glass for the current brightness — Apple's measured
        // rim lighting, backdrop frost and dark contour.
        settings: LiquidGlassSettings.ios27Regular(brightness: brightness),
        child: LiquidGlassBlendGroup(
          blend: _kBlendDistance,
          child: Row(
            children: [
              Expanded(
                child: LiquidGlass.grouped(
                  shape: const LiquidRoundedSuperellipse(
                    borderRadius: _kCapsuleRadius,
                  ),
                  shadows: _kGlassShadows,
                  child: _TabTrack(
                    state: this,
                    sizing: sizing,
                    arabic: arabic,
                    showLabels: showLabels,
                  ),
                ),
              ),
              if (showOrb) ...[
                SizedBox(width: sizing.orbGap),
                _SearchOrb(
                  diameter: sizing.orbDiameter,
                  tooltip: widget.searchLabel ?? '',
                  onPressed: widget.onSearch!,
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Accessibility surface: identical layout, zero transparency.
    Widget solidSegments() {
      final scheme = Theme.of(context).colorScheme;
      return Row(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(_kCapsuleRadius),
                border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: .65)),
                boxShadow: _kGlassShadows,
              ),
              child: _TabTrack(
                state: this,
                sizing: sizing,
                arabic: arabic,
                showLabels: showLabels,
                solid: true,
              ),
            ),
          ),
          if (showOrb) ...[
            SizedBox(width: sizing.orbGap),
            GestureDetector(
              onTap: widget.onSearch,
              child: Tooltip(
                message: widget.searchLabel ?? '',
                child: SizedBox.square(
                  dimension: sizing.orbDiameter,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: .65)),
                      boxShadow: _kGlassShadows,
                    ),
                    child: Icon(
                      LucideIcons.search,
                      size: sizing.iconSize + 2,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    return chrome(
      widget.reduceTransparency ? solidSegments() : glassSegments(),
    );
  }

  bool _sameTabIds(List<DockTab> a, List<DockTab> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
}

// ---------------------------------------------------------------------------
// Tab track: the capsule's interior — platter + gesture + tab buttons.
// ---------------------------------------------------------------------------

class _TabTrack extends StatelessWidget {
  const _TabTrack({
    required this.state,
    required this.sizing,
    required this.arabic,
    required this.showLabels,
    this.solid = false,
  });

  final _LiquidGlassDockState state;
  final LiquidGlassDockSizing sizing;
  final bool arabic;
  final bool showLabels;

  /// True inside the opaque accessibility chrome (painted platter only).
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final state = this.state;
    final tabs = state.widget.tabs;
    final brightness = Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;

    return LayoutBuilder(builder: (context, constraints) {
      final inset = sizing.trackInset;
      final trackW = _clampD(
        constraints.maxWidth - 2 * inset,
        0,
        constraints.maxWidth,
      );
      final slotW = tabs.isEmpty ? 0.0 : trackW / tabs.length;
      final platterH = math.min(
        sizing.platterHeight,
        math.max(0.0, constraints.maxHeight - 12),
      );
      if (!state._measured && slotW > 0 && tabs.isNotEmpty) {
        state._measured = true;
        state._frac = state._resolvedActiveSlot.toDouble();
        state._scale = 1;
      }
      state
        .._inset = inset
        .._trackW = trackW
        .._slotW = slotW;

      final activeIndex = tabs.indexWhere((tab) => tab.id == state.widget.activeId);
      final hasActive = activeIndex >= 0;
      final showLens = state._scrubbing && !solid && slotW > 0;

      Widget platter() {
        if (slotW <= 0) return const SizedBox.shrink();
        final platter = SizedBox(
          width: math.max(0.0, slotW - 8),
          height: platterH,
          child: showLens
              // Glass-on-glass: the clear loupe mounted ONLY while the finger
              // scrubs — it refracts the capsule glass beneath it.
              ? LiquidGlass.withOwnLayer(
                  shape: const LiquidRoundedSuperellipse(borderRadius: 24),
                  settings: _kLensSettings,
                  child: const SizedBox.expand(),
                )
              : DecoratedBox(
                  // Resting platter (iOS 27): dark glass darkens under the
                  // selection; light glass takes a faint charcoal tint.
                  decoration: BoxDecoration(
                    color: dark
                        ? Colors.black.withValues(alpha: .32)
                        : Colors.black.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
        );
        return ExcludeSemantics(
          child: AnimatedOpacity(
            opacity: state._measured ? 1 : 0,
            duration:
                state._reduceMotion ? Duration.zero : _kIconCrossfadeDuration,
            child: Transform(
              alignment: Alignment.center,
              transformHitTests: false,
              // Slide + grow composed in ONE matrix around the platter center.
              transform: Matrix4.identity()
                ..translateByDouble(
                  state._frac * slotW * state._dirSign,
                  0,
                  0,
                  1,
                )
                ..scaleByDouble(state._scale, state._scale, 1, 1),
              child: platter,
            ),
          ),
        );
      }

      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: state._onPointerDown,
        onPointerMove: state._onPointerMove,
        onPointerUp: state._onPointerUp,
        onPointerCancel: state._onPointerCancel,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: inset),
            child: SizedBox(
              width: trackW > 0 ? trackW : null,
              height: platterH,
              child: Stack(
                children: [
                  if (slotW > 0)
                    PositionedDirectional(
                      start: 0,
                      top: 0,
                      width: slotW,
                      height: platterH,
                      // The platter is centered inside its slot so the slide
                      // lands every selection exactly on its tab.
                      child: Align(
                        alignment: AlignmentDirectional.center,
                        child: platter(),
                      ),
                    ),
                  Row(
                    children: [
                      for (var i = 0; i < tabs.length; i++)
                        Expanded(
                          child: _LiquidTabButton(
                            key: ValueKey('dock-tab-${tabs[i].id}'),
                            tab: tabs[i],
                            highlighted: state._scrubbing
                                ? state._litIndex == i
                                : i == activeIndex,
                            selected: hasActive && i == activeIndex,
                            pressed: state._pressedIndex == i,
                            arabic: arabic,
                            iconSize: sizing.iconSize,
                            showLabel: showLabels,
                            reduceMotion: state._reduceMotion,
                            onActivate: () =>
                                state.widget.onTabSelected(tabs[i]),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Tab button: icon cross-fade, press scale, hover, semantics.
// ---------------------------------------------------------------------------

class _LiquidTabButton extends StatelessWidget {
  const _LiquidTabButton({
    super.key,
    required this.tab,
    required this.highlighted,
    required this.selected,
    required this.pressed,
    required this.arabic,
    required this.iconSize,
    required this.showLabel,
    required this.reduceMotion,
    required this.onActivate,
  });

  final DockTab tab;
  final bool highlighted;
  final bool selected;
  final bool pressed;
  final bool arabic;
  final double iconSize;
  final bool showLabel;
  final bool reduceMotion;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final duration = reduceMotion ? Duration.zero : _kIconCrossfadeDuration;
    final label = dockTabLabel(tab, arabic: arabic);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final idleColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final activeColor = dark ? NovaColors.white : NovaColors.ink;

    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          onActivate();
          return null;
        }),
      },
      child: Semantics(
        excludeSemantics: true,
        button: true,
        selected: selected,
        label: label,
        onTap: onActivate,
        child: AnimatedScale(
          scale: pressed ? 0.94 : 1,
          duration: duration,
          curve: kDockEase,
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                tab.iconOutline,
                size: iconSize,
                color: highlighted ? activeColor : idleColor,
              ),
              if (showLabel) ...[
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight:
                              highlighted ? FontWeight.w700 : FontWeight.w500,
                          color: highlighted ? activeColor : idleColor,
                        ),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search orb: a LiquidOval glass segment in the SAME blend group — stretching
// it toward the capsule closes the gap below the blend distance and the two
// shapes liquid-merge (the fluid grouped-pill moment).
// ---------------------------------------------------------------------------

class _SearchOrb extends StatelessWidget {
  const _SearchOrb({
    required this.diameter,
    required this.tooltip,
    required this.onPressed,
  });

  final double diameter;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final glyph = dark ? NovaColors.white : NovaColors.ink;
    return GestureDetector(
      onTap: onPressed,
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 650),
        child: LiquidStretch(
          interactionScale: 1.06,
          child: LiquidGlass.grouped(
            shape: const LiquidOval(),
            shadows: _kGlassShadows,
            child: SizedBox.square(
              dimension: diameter,
              child: Center(
                child: Icon(
                  LucideIcons.search,
                  size: diameter * 0.42,
                  color: glyph.withValues(alpha: .92),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The pressed pointer's identity — only that pointer may drive the gesture.
class _PendingGesture {
  const _PendingGesture({
    required this.pointer,
    required this.startX,
    required this.startY,
  });

  final int pointer;
  final double startX;
  final double startY;
}

// -- tiny clamping helpers (num.clamp returns `num`; keep types exact) ------

double _lerp(double a, double b, double t) => a + (b - a) * t;

double _clampD(double value, double min, double max) =>
    value < min ? min : (value > max ? max : value);

int _clampSlot(int value, int count) {
  if (count <= 0) return 0;
  if (value < 0) return 0;
  if (value > count - 1) return count - 1;
  return value;
}
