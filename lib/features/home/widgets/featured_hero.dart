import 'package:nova_mobile/l10n/nova_strings.dart';
import 'package:nova_mobile/shared/widgets/nova_network_image.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/featured_artwork.dart';
import '../../../core/models/media_item.dart';
import '../../../core/state/app_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../shared/widgets/image_decode.dart';

const _heroSlideDuration = Duration(seconds: 6);

/// The featured hero carousel (home's top slot): full-bleed autoplaying
/// artwork with TMDB-enriched logo / portrait / landscape picks, the bottom
/// scrim ladder, metadata row, "View details" pill and page dots — plus the
/// geometry-matched [FeaturedSkeleton] loading state. Moved verbatim from
/// home_page.dart (Task 121-c); visuals, keys and ordering are unchanged.
class FeaturedHero extends StatefulWidget {
  const FeaturedHero({
    super.key,
    required this.items,
    required this.autoplayActive,
    required this.onTap,
    required this.contentVisibility,
  });

  final List<MediaItem> items;
  final bool autoplayActive;
  final ValueChanged<MediaItem> onTap;
  final ValueListenable<double> contentVisibility;

  @override
  State<FeaturedHero> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<FeaturedHero>
    with WidgetsBindingObserver {
  Timer? _autoplayTimer;
  Timer? _touchResumeTimer;
  int _activeIndex = 0;
  double _dragDistance = 0;
  bool _reducedMotion = false;
  bool _appActive = true;
  bool _touching = false;
  String? _artworkSignature;
  final Map<String, FeaturedArtwork> _artwork = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion != _reducedMotion) {
      _reducedMotion = reduceMotion;
    }
    _enrichSlides();
    _startAutoplay();
  }

  @override
  void didUpdateWidget(covariant FeaturedHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_itemsSignature(oldWidget.items) != _itemsSignature(widget.items)) {
      _activeIndex = 0;
      _artworkSignature = null;
      _startAutoplay();
    }
    if (oldWidget.autoplayActive != widget.autoplayActive) _startAutoplay();
    _enrichSlides();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoplayTimer?.cancel();
    _touchResumeTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    if (_appActive) {
      _startAutoplay();
    } else {
      _autoplayTimer?.cancel();
    }
  }

  String _itemsSignature(List<MediaItem> items) =>
      items.map((item) => item.id).join('|');

  void _enrichSlides() {
    if (widget.items.isEmpty) return;
    final app = context.read<AppState>();
    // Task 122-d: hero artwork, logo and overview language follow the
    // CONTENT language (app.contentTmdbLocale — the same basis home_page
    // reloads on) instead of the legacy UI-less TMDB-locale fallback plus
    // the UI language. The repository normalizes uiLanguage to its primary
    // subtag for the include_image_language list and logo pick (the
    // '<subtag>,en,null' fallback chain is unchanged), so the full locale
    // is safe to pass through.
    final language = app.contentTmdbLocale;
    final region = app.webSettings['region']?.toString() ?? 'US';
    final uiLanguage = language.split(RegExp('[-_]')).first.toLowerCase();
    final signature =
        '${_itemsSignature(widget.items)}:$language:$region:$uiLanguage:'
        '${app.webSettings['tmdbEnabled']}:'
        '${app.webSettings['tmdbUseArtwork']}:'
        '${app.webSettings['tmdbUseBasicInfo']}:'
        '${app.api.hasUserTmdbKey ? 'user' : 'default'}';
    if (signature == _artworkSignature) return;
    _artworkSignature = signature;
    _artwork.clear();
    if (app.webSettings['tmdbEnabled'] == false) return;
    unawaited(_loadFeaturedArtwork(
      app,
      signature: signature,
      language: language,
      region: region,
      uiLanguage: uiLanguage,
    ));
  }

  Future<void> _loadFeaturedArtwork(
    AppState app, {
    required String signature,
    required String language,
    required String region,
    required String uiLanguage,
  }) async {
    for (final item in widget.items) {
      if (!mounted || signature != _artworkSignature) return;
      final result = await app.catalogs.featuredArtwork(
        item,
        language: language,
        region: region,
        uiLanguage: uiLanguage,
      );
      if (!mounted || signature != _artworkSignature) return;
      setState(() => _artwork[item.id] = result);
      _precacheNext();
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  }

  void _startAutoplay() {
    _autoplayTimer?.cancel();
    if (_reducedMotion ||
        !_appActive ||
        _touching ||
        !_destinationVisible ||
        widget.items.length < 2) {
      return;
    }
    _autoplayTimer = Timer.periodic(_heroSlideDuration, (_) {
      if (!mounted || _touching || !_destinationVisible) return;
      _setActiveSlide((_activeIndex + 1) % widget.items.length);
    });
  }

  // A selected Home tab remains mounted beneath detail/player routes. Timers
  // are not muted by TickerMode, so explicitly stop their work while covered.
  bool get _destinationVisible =>
      mounted &&
      widget.autoplayActive &&
      TickerMode.valuesOf(context).enabled &&
      (ModalRoute.of(context)?.isCurrent ?? true);

  void _pauseForTouch() {
    _touchResumeTimer?.cancel();
    _autoplayTimer?.cancel();
    _touching = true;
  }

  void _resumeAfterTouch() {
    _touchResumeTimer?.cancel();
    _touchResumeTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      _touching = false;
      _startAutoplay();
    });
  }

  void _setActiveSlide(int targetIndex) {
    if (!mounted || widget.items.length < 2) return;
    final count = widget.items.length;
    final target = ((targetIndex % count) + count) % count;
    if (target == _activeIndex) return;
    setState(() => _activeIndex = target);
    _precacheNext();
  }

  void _precacheNext() {
    if (!_destinationVisible || !_appActive || widget.items.isEmpty) return;
    final next = widget.items[(_activeIndex + 1) % widget.items.length];
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final art = _artwork[next.id];
    final url = wide
        ? (art?.landscape ?? next.background ?? next.poster)
        : (art?.portrait ?? next.poster ?? next.background);
    if (url != null) {
      unawaited(precacheImage(
          ResizeImage.resizeIfNeeded(
              imageCacheWidth(context, MediaQuery.sizeOf(context).width),
              null,
              NetworkImage(url)),
          context));
    }
  }

  void _handleSwipeEnd() {
    if (_dragDistance.abs() < 36 || widget.items.length < 2) return;
    final forward = Directionality.of(context) == TextDirection.rtl
        ? _dragDistance > 0
        : _dragDistance < 0;
    _setActiveSlide((_activeIndex + (forward ? 1 : -1)) % widget.items.length);
    _dragDistance = 0;
  }

  @override
  Widget build(BuildContext context) {
    final heroHeight = featuredHeroHeight(context);
    final activeItem = widget.items[_activeIndex];
    final wide = MediaQuery.sizeOf(context).width >= 700;
    // Netflix reserves a band above the hero card for the floating brand
    // header (title row + search), exactly like its home feed.
    final topPadding = MediaQuery.paddingOf(context).top + 56;
    final cardPadding = EdgeInsets.fromLTRB(
      wide ? 32 : 20,
      topPadding,
      wide ? 32 : 20,
      12,
    );

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Netflix page backdrop: the deep indigo-to-black ladder that sits
          // behind the featured card (#202036 → #11111d → #07070c).
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF202036), Color(0xFF11111D), Color(0xFF07070C)],
                stops: [0, .4, .8],
              ),
            ),
          ),
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _pauseForTouch(),
            onPointerUp: (_) => _resumeAfterTouch(),
            onPointerCancel: (_) => _resumeAfterTouch(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) => _dragDistance = 0,
              onHorizontalDragUpdate: (details) =>
                  _dragDistance += details.delta.dx,
              onHorizontalDragEnd: (_) => _handleSwipeEnd(),
              child: Padding(
                padding: cardPadding,
                child: Container(
                  decoration: BoxDecoration(
                    // Netflix featured card: 8dp corners + hairline white ring.
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .20),
                      width: .5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedSwitcher(
                        duration: _reducedMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 380),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeOutCubic,
                        child: _FeaturedArtwork(
                          key: ValueKey(activeItem.id),
                          item: activeItem,
                          artwork: _artwork[activeItem.id],
                        ),
                      ),
                      const Positioned.fill(child: _FeaturedScrim()),
                      Positioned.fill(
                        child: ValueListenableBuilder<double>(
                          valueListenable: widget.contentVisibility,
                          child: _FeaturedOverlay(
                            item: activeItem,
                            artwork: _artwork[activeItem.id],
                            onTap: () => widget.onTap(activeItem),
                          ),
                          builder: (context, visibility, child) => IgnorePointer(
                            key: const ValueKey('home-hero-content-ignore-pointer'),
                            ignoring: visibility <= .05,
                            child: Opacity(
                              key: const ValueKey('home-hero-content-opacity'),
                              opacity: visibility,
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _FeaturedArtwork extends StatelessWidget {
  const _FeaturedArtwork(
      {super.key, required this.item, required this.artwork});
  final MediaItem item;
  final FeaturedArtwork? artwork;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 700 || size.width > size.height;
    final url = wide
        ? (artwork?.landscape ?? item.background ?? item.poster)
        : (artwork?.portrait ?? item.poster ?? item.background);
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.expand(
      child: url == null
          ? ColoredBox(color: scheme.surfaceContainerHighest)
          : ClipRect(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 1,
                  end: MediaQuery.disableAnimationsOf(context) ? 1 : 1.05,
                ),
                duration: _heroSlideDuration,
                curve: Curves.linear,
                builder: (context, scale, child) => Transform.scale(
                  scale: scale,
                  child: child,
                ),
                child: NovaNetworkImage(
                  url,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  cacheWidth: imageCacheWidth(context, size.width),
                  alignment: Alignment.topCenter,
                  excludeFromSemantics: true,
                  frameBuilder: (context, child, frame, sync) =>
                      AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 320),
                    child: child,
                  ),
                  errorBuilder: (_, __, ___) =>
                      ColoredBox(color: scheme.surfaceContainerHighest),
                ),
              ),
            ),
    );
  }
}

class _FeaturedScrim extends StatelessWidget {
  const _FeaturedScrim();
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
        decoration: BoxDecoration(
            gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      // Netflix featured card: a light top guard for the status icons plus
      // the signature bottom scrim (transparent → black @ 80%).
      colors: [
        Colors.black.withValues(alpha: .35),
        Colors.transparent,
        Colors.transparent,
        Colors.black.withValues(alpha: .80),
      ],
      stops: const [0, .28, .58, 1],
    )));
  }
}

class _FeaturedOverlay extends StatelessWidget {
  const _FeaturedOverlay({
    required this.item,
    required this.artwork,
    required this.onTap,
  });

  final MediaItem item;
  final FeaturedArtwork? artwork;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final english = app.english;
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 700;
    const foreground = Colors.white;
    final logo = artwork?.logo ?? item.logo;
    final displayTitle = artwork?.title ?? item.name;
    final genres = [
      if ((artwork?.genre ?? item.genres.firstOrNull)?.isNotEmpty == true)
        artwork?.genre ?? item.genres.firstOrNull!,
    ];
    final inMyList = app.contains(item);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Netflix title art: the TMDB logo centered above the meta line
              // (250×80 box, exactly like the featured card), with the plain
              // title as the fallback so slides always carry a label.
              GestureDetector(
                onTap: onTap,
                child: logo != null
                    ? NovaNetworkImage(
                        logo,
                        width: math.min(size.width * .7, 250),
                        height: wide ? 88 : 72,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        cacheWidth: imageCacheWidth(context, 250),
                        semanticLabel: displayTitle,
                        errorBuilder: (_, __, ___) => _heroTitle(
                          displayTitle,
                          wide: wide,
                          color: foreground,
                        ),
                      )
                    : _heroTitle(displayTitle, wide: wide, color: foreground),
              ),
              const SizedBox(height: 16),
              // Netflix category line: genres joined with the "•" separator.
              if (genres.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    genres.join(' \u2022 '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foreground.withValues(alpha: .98),
                      fontSize: 14,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Netflix action row: white Play + #333 My List, both flexed.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        child: InkWell(
                          onTap: onTap,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.play,
                                    size: 22, color: Colors.black),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    NovaStrings.lookup(english, 'message131'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Material(
                        color: const Color(0xFF333333).withValues(alpha: .9),
                        borderRadius: BorderRadius.circular(4),
                        child: InkWell(
                          onTap: () =>
                              unawaited(app.toggleWatchlist(item)),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  inMyList
                                      ? LucideIcons.check
                                      : LucideIcons.plus,
                                  size: 22,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    inMyList
                                        ? NovaStrings.lookup(
                                            english, 'message132')
                                        : NovaStrings.lookup(
                                            english, 'netflixMyList'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroTitle(String title, {required bool wide, required Color color}) =>
      Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: wide ? 36 : 28,
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
      );
}


class FeaturedSkeleton extends StatelessWidget {
  const FeaturedSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
        height: featuredHeroHeight(context),
        child: ColoredBox(
            color: scheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 40),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final width in [120.0, 240.0, 160.0]) ...[
                      Container(
                          width: width,
                          height: 20,
                          decoration: BoxDecoration(
                              color: scheme.onSurface.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(8))),
                      const SizedBox(height: 16),
                    ],
                    Container(
                        width: 168,
                        height: 52,
                        decoration: BoxDecoration(
                            color: scheme.onSurface.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(16))),
                  ]),
            )));
  }
}

double featuredHeroHeight(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
  final base = size.height * .68;
  return base + (scale - 1).clamp(0.0, 2.0) * 200;
}
