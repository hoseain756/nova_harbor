import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_mobile/core/models/media_item.dart';
import 'package:nova_mobile/features/home/widgets/cinematic_cover_scroll.dart';
import 'package:nova_mobile/features/media/detail_hero.dart';

void main() {
  const item = MediaItem(
    id: 'nova-test',
    type: 'series',
    name: 'A story across two languages',
    originalTitle: 'حكاية طويلة بين لغتين',
    releaseInfo: '2026',
    description:
        'A detailed synopsis that remains fully readable when text is enlarged.',
    genres: ['Drama', 'Adventure'],
    certification: 'PG',
    seasonCount: 2,
    episodeCount: 16,
    cast: ['One Person', 'شخص آخر'],
    director: ['A Director'],
    productionCompanies: [MediaCompany(name: 'A production company')],
  );

  for (final width in [320.0, 800.0]) {
    for (final direction in TextDirection.values) {
      for (final brightness in Brightness.values) {
        testWidgets('cinematic layout $width $direction $brightness at 200%',
            (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final english = direction == TextDirection.ltr;
          await tester.pumpWidget(MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: MediaQuery(
                data: MediaQueryData(
                    size: Size(width, 900),
                    textScaler: const TextScaler.linear(2),
                    disableAnimations: true),
                child: Directionality(
                    textDirection: direction,
                    child: Scaffold(
                        body: ListView(children: [
                      SizedBox(
                          height: 400,
                          child: DetailHero(
                              item: item,
                              backdropUrl: null,
                              logoUrl: null,
                              isWide: width >= 700,
                              viewportHeight: 900,
                              viewportWidth: width,
                              contentVisibility: ValueNotifier<double>(1))),
                      Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DetailMetaRow(item: item, isWide: width >= 700),
                                DetailActionRow(
                                    english: english,
                                    isWide: width >= 700,
                                    inList: false,
                                    showTrackAnime: true,
                                    primaryLabel:
                                        english ? 'Watch now' : 'شاهد الآن',
                                    primaryIsResume: false,
                                    loading: false,
                                    onPrimaryPressed: () {},
                                    onToggleWatchlist: () {},
                                    onOpenStreams: () {},
                                    onTrackAnime: () {},
                                    onShare: () {},
                                    onAddToList: () {},
                                    onDownload: () {}),
                                DetailSynopsis(
                                    description: item.description!,
                                    isWide: width >= 700,
                                    viewportWidth: width),
                                DetailCastCrew(item: item, english: english),
                                DetailProduction(item: item, english: english),
                                DetailFactsTable(item: item, english: english),
                              ])),
                    ])))),
          ));
          await tester.pump();
          expect(tester.takeException(), isNull);
          await tester.drag(find.byType(ListView).first, const Offset(0, -500));
          await tester.pump();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('hero scrolls away with the page (in-page hero)', (tester) async {
    const marker = Key('hero-marker');
    const heroInfo = Key('hero-info');
    var heroTaps = 0;
    var contentTaps = 0;
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
            colorScheme: const ColorScheme.dark().copyWith(
          surface: Colors.blue,
        )),
        home: MediaQuery(
          data: const MediaQueryData(
              size: Size(320, 800), disableAnimations: true),
          child: Scaffold(
            body: CinematicCoverScroll(
              heroHeight: 400,
              heroBuilder: (visibility) => ColoredBox(
                color: Colors.red,
                child: Stack(fit: StackFit.expand, children: [
                  const Center(
                      child: SizedBox(key: marker, width: 20, height: 20)),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ValueListenableBuilder<double>(
                      valueListenable: visibility,
                      child: GestureDetector(
                        key: heroInfo,
                        onTap: () => heroTaps++,
                        child: const SizedBox(
                          height: 120,
                          child: Center(child: Text('Hero info')),
                        ),
                      ),
                      builder: (context, value, child) => IgnorePointer(
                        ignoring: value <= .05,
                        child: Opacity(opacity: value, child: child),
                      ),
                    ),
                  ),
                ]),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: GestureDetector(
                    onTap: () => contentTaps++,
                    child: const SizedBox(
                      height: 1200,
                      child: ColoredBox(color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Hero controls remain usable at scroll top.
    final beforeHero = tester.getTopLeft(find.byKey(marker));
    await tester.tapAt(const Offset(160, 340));
    expect(heroTaps, 1);

    // THE MANDATE: the hero is part of the page — dragging scrolls it away.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -160));
    await tester.pump();
    final offset = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .pixels;
    expect(offset, greaterThan(100));
    expect(tester.getTopLeft(find.byKey(marker)).dy, lessThan(beforeHero.dy));

    // Once the hero has fully scrolled past, it leaves the viewport and the
    // content underneath receives taps.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.byKey(marker), findsNothing);
    await tester.tapAt(const Offset(160, 100));
    expect(contentTaps, 1);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 900.0]) {
    for (final direction in TextDirection.values) {
      for (final brightness in Brightness.values) {
        testWidgets('cover scroll $width $direction $brightness',
            (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Directionality(
              textDirection: direction,
              child: Scaffold(
                body: CinematicCoverScroll(
                  heroHeight: 400,
                  heroBuilder: (visibility) => Builder(
                    builder: (context) => ColoredBox(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Align(
                        alignment: AlignmentDirectional.bottomStart,
                        child: Text(direction == TextDirection.rtl
                            ? 'عنوان عربي و NOVA 2026'
                            : 'NOVA in two languages 2026'),
                      ),
                    ),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 1200,
                        child: Builder(
                          builder: (context) => ColoredBox(
                              color: Theme.of(context).colorScheme.surface,
                              child: Center(
                                  child: Text(direction == TextDirection.rtl
                                      ? 'محتوى تجريبي'
                                      : 'Sample content'))),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ));
          await tester.pump();
          await tester.drag(
              find.byType(CustomScrollView), const Offset(0, -180));
          await tester.pump();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
