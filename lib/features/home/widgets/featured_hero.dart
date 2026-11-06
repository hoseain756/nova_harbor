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
const _heroSlideAnimation = Duration(milliseconds: 620);

/// The hero carousel starts far from both ends so the feed can keep sliding
/// FORWARD forever (Netflix loops its hero without ever sliding backwards).
const _kHeroPageBase = 6000;

/// The featured hero carousel (home's top slot): a full-bleed, edge-to-edge
/// PageView whose artwork + title art + actions SLIDE together — exactly the
/// Netflix home hero. It auto-advances every [_heroSlideDuration], pauses
/// while touched, and shows the Netflix-style segmented progress bars.
/// TMDB-enriched logo / portrait / landscape picks and the bottom scrim
/// ladder are preserved.
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
  final PageController _pageController =
      PageController(initialPage: _kHeroPageBase);
  Timer? _autoplayTimer;
  Timer? _touchResumeTimer;
  int _activeIndex = 0;
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
      // Reset to the base page so the new feed starts from its first slide
      // and keeps looping forward from there.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        _pageController.jumpToPage(_kHeroPageBase);
      });
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
    _pageController.dispose();
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

  int get _currentPage => _pageController.hasClients
      ? _pageController.page!.round()
      : _kHeroPageBase;

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
      final target = _currentPage + 1;
      if (_reducedMotion) {
        _pageController.jumpToPage(target);
      } else {
        _pageController.animateToPage(
          target,
          duration: _heroSlideAnimation,
          curve: Curves.easeInOutCubic,
        );
      }
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

  void _onSlideChanged(int page) {
    if (widget.items.isEmpty) return;
    final realIndex = page % widget.items.length;
    if (realIndex == _activeIndex) return;
    setState(() => _activeIndex = realIndex);
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

  @override
  Widget build(BuildContext context) {
    final heroHeight = featuredHeroHeight(context);
    if (widget.items.isEmpty) {
      return SizedBox(height: heroHeight, child: const SizedBox.expand());
    }
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final count = widget.items.length;

    return SizedBox(
      height: heroHeight,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _pauseForTouch(),
        onPointerUp: (_) => _resumeAfterTouch(),
        onPointerCancel: (_) => _resumeAfterTouch(),
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: _onSlideChanged,
          // Physical, page-by-page sliding — the Netflix hero motion.
          physics: const PageScrollPhysics(),
          allowImplicitScrolling: false,
          itemBuilder: (context, absolutePage) {
            final item = widget.items[absolutePage % count];
            final artwork = _artwork[item.id];
            return _FeaturedSlide(
              item: item,
              artwork: artwork,
              slideTick: absolutePage,
              wide: wide,
              contentVisibility: widget.contentVisibility,
              onTap: () => widget.onTap(item),
            );
          },
        ),
      ),
    );
  }
}

/// One full-bleed hero page: artwork + scrim + title art + actions slide
/// together as one unit (Netflix home hero behavior).
class _FeaturedSlide extends StatelessWidget {
  const _FeaturedSlide({
    required this.item,
    required this.artwork,
    required this.slideTick,
    required this.wide,
    required this.contentVisibility,
    required this.onTap,
  });

  final MediaItem item;
  final FeaturedArtwork? artwork;
  final int slideTick;
  final bool wide;
  final ValueListenable<double> contentVisibility;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _FeaturedArtwork(item: item, artwork: artwork),
        const Positioned.fill(child: _FeaturedScrim()),
        Positioned.fill(
          child: ValueListenableBuilder<double>(
            valueListenable: contentVisibility,
            child: _FeaturedOverlay(
              item: item,
              artwork: artwork,
              slideTick: slideTick,
              wide: wide,
              onTap: onTap,
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
    );
  }
}

class _FeaturedArtwork extends StatelessWidget {
  const _FeaturedArtwork({required this.item, required this.artwork});
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
          : NovaNetworkImage(
              url,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              cacheWidth: imageCacheWidth(context, size.width),
              alignment: Alignment.topCenter,
              excludeFromSemantics: true,
              frameBuilder: (context, child, frame, sync) => AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 320),
                child: child,
              ),
              errorBuilder: (_, __, ___) =>
                  ColoredBox(color: scheme.surfaceContainerHighest),
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
      // Netflix hero: a light top guard for the status icons plus the
      // signature bottom scrim (transparent → black @ 82%).
      colors: [
        Colors.black.withValues(alpha: .40),
        Colors.transparent,
        Colors.transparent,
        Colors.black.withValues(alpha: .82),
      ],
      stops: const [0, .30, .55, 1],
    )));
  }
}

class _FeaturedOverlay extends StatelessWidget {
  const _FeaturedOverlay({
    required this.item,
    required this.artwork,
    required this.slideTick,
    required this.wide,
    required this.onTap,
  });

  final MediaItem item;
  final FeaturedArtwork? artwork;
  final int slideTick;
  final bool wide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final english = app.english;
    final size = MediaQuery.sizeOf(context);
    const foreground = Colors.white;
    final logo = artwork?.logo ?? item.logo;
    final displayTitle = artwork?.title ?? item.name;
    final genres = [
      if ((artwork?.genre ?? item.genres.firstOrNull)?.isNotEmpty == true)
        artwork?.genre ?? item.genres.firstOrNull!,
    ];
    final inMyList = app.contains(item);
    // The hero state owns the rotation: this slide's own position and the
    // currently-featured index drive the segmented progress bars.
    final hero = context.findAncestorStateOfType<_FeaturedCardState>();
    final heroItems = hero?.widget.items ?? const <MediaItem>[];
    final slideCount = heroItems.length;
    final ownIndex = slideCount == 0
        ? 0
        : heroItems.indexOf(item).clamp(0, slideCount - 1);
    final activeIndex = hero?._activeIndex ?? 0;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
          wide ? 32 : 20, 16, wide ? 32 : 20, 18),
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
              const SizedBox(height: 14),
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
              const SizedBox(height: 14),
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
                          onTap: () => unawaited(app.toggleWatchlist(item)),
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
              // Netflix-style segmented progress: one thin bar per slide;
              // watched slides fill solid, the active one fills over the
              // slide duration, upcoming ones stay faint.
              if (slideCount > 1) ...[
                const SizedBox(height: 14),
                _HeroProgressSegments(
                  count: slideCount,
                  activeIndex: activeIndex,
                  ownIndex: ownIndex,
                  slideTick: slideTick,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroTitle(String title,
          {required bool wide, required Color color}) =>
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

/// Netflix-style segmented hero progress: each slide owns one 20×3 bar.
class _HeroProgressSegments extends StatelessWidget {
  const _HeroProgressSegments({
    required this.count,
    required this.activeIndex,
    required this.ownIndex,
    required this.slideTick,
  });

  final int count;
  final int activeIndex;

  /// This slide's own position — only the featured slide animates its bar.
  final int ownIndex;
  final int slideTick;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count && i < 8; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.5),
            child: _HeroSegment(
              state: i == activeIndex && ownIndex == activeIndex
                  ? _HeroSegmentState.active
                  : i < activeIndex
                      ? _HeroSegmentState.done
                      : _HeroSegmentState.upcoming,
              animate: i == activeIndex &&
                  ownIndex == activeIndex &&
                  !reducedMotion,
              tick: slideTick,
            ),
          ),
      ],
    );
  }
}

enum _HeroSegmentState { active, done, upcoming }

class _HeroSegment extends StatelessWidget {
  const _HeroSegment({
    required this.state,
    required this.animate,
    required this.tick,
  });

  final _HeroSegmentState state;
  final bool animate;

  /// Changes every slide so the active segment's fill restarts cleanly.
  final int tick;

  @override
  Widget build(BuildContext context) {
    const track = Colors.white24;
    const fill = Colors.white;
    return switch (state) {
      _HeroSegmentState.done => Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: fill.withValues(alpha: .9),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      _HeroSegmentState.upcoming => Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: track,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      _HeroSegmentState.active => Container(
          width: 20,
          height: 3,
          alignment: AlignmentDirectional.centerStart,
          decoration: BoxDecoration(
            color: track,
            borderRadius: BorderRadius.circular(2),
          ),
          child: animate
              ? TweenAnimationBuilder<double>(
                  key: ValueKey('hero-segment-$tick'),
                  tween: Tween(begin: 0, end: 1),
                  duration: _heroSlideDuration,
                  curve: Curves.linear,
                  builder: (context, value, _) => FractionallySizedBox(
                    widthFactor: value.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
        ),
    };
  }
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
