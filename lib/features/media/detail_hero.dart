import '../../core/theme/nova_theme.dart';
import 'package:nova_mobile/l10n/nova_strings.dart';
import 'package:nova_mobile/shared/widgets/nova_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/media_item.dart';
import '../../shared/widgets/image_decode.dart';
import '../../shared/widgets/nova_brand.dart';
import '../../shared/widgets/shimmer_box.dart';
export '../../shared/widgets/shimmer_box.dart';

class DetailBackPill extends StatelessWidget {
  const DetailBackPill({super.key, required this.english});
  final bool english;
  @override
  Widget build(BuildContext context) {
    final forward = Directionality.of(context) == TextDirection.ltr;
    return Padding(
      padding: EdgeInsetsDirectional.only(
          start: 16, top: MediaQuery.paddingOf(context).top + 12),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: IconButton.filledTonal(
          tooltip: NovaStrings.lookup(english, 'message136'),
          style: IconButton.styleFrom(
            minimumSize: const Size.square(40),
            backgroundColor: Colors.black.withValues(alpha: .40),
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: .15)),
          ),
          icon: Icon(
            forward ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}

/// Uncropped canvas edge: artwork always fills the available width, on phones
/// and tablets. Content is independent of artwork and covers this hero.
class DetailHero extends StatelessWidget {
  const DetailHero(
      {super.key,
      required this.item,
      required this.backdropUrl,
      required this.logoUrl,
      required this.isWide,
      required this.viewportHeight,
      required this.viewportWidth,
      required this.contentVisibility});
  final MediaItem item;
  final String? backdropUrl;
  final String? logoUrl;
  final bool isWide;
  final double viewportHeight;
  final double viewportWidth;
  final ValueListenable<double> contentVisibility;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = Theme.of(context).brightness == Brightness.dark
        ? scheme.onSurface
        : scheme.surface;
    final url = backdropUrl?.isNotEmpty == true ? backdropUrl : item.poster;
    return RepaintBoundary(
        child: Stack(fit: StackFit.expand, children: [
      ColoredBox(color: scheme.surfaceContainerHighest),
      if (url?.isNotEmpty == true)
        NovaNetworkImage(url!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            cacheWidth: imageCacheWidth(context, viewportWidth),
            excludeFromSemantics: true,
            frameBuilder: (context, child, frame, sync) => AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 320),
                child: child),
            errorBuilder: (_, __, ___) => const SizedBox.shrink()),
      DecoratedBox(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [
            0,
            .35,
            .75,
            1
          ],
                  colors: [
            scheme.scrim.withValues(alpha: .30),
            scheme.scrim.withValues(alpha: .05),
            scheme.scrim.withValues(alpha: .65),
            scheme.scrim
          ]))),
      PositionedDirectional(
          start: isWide ? 40 : 24,
          end: isWide ? 40 : 24,
          bottom: 32,
          child: ValueListenableBuilder<double>(
            valueListenable: contentVisibility,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Netflix detail tag: the N symbol followed by the letter-
                // spaced FILM / SERIES type line.
                Row(children: [
                  const NovaBrand(symbolOnly: true, width: 18, onDark: true),
                  const SizedBox(width: 6),
                  Text(
                    item.type == 'movie'
                        ? (Directionality.of(context) == TextDirection.rtl
                            ? 'فيلم'
                            : 'FILM')
                        : (Directionality.of(context) == TextDirection.rtl
                            ? 'مسلسل'
                            : 'SERIES'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .81),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.5,
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                if (logoUrl?.isNotEmpty == true)
                  NovaNetworkImage(logoUrl!,
                      height: isWide ? 112 : 80,
                      width: isWide ? 400 : viewportWidth - 48,
                      fit: BoxFit.contain,
                      alignment: AlignmentDirectional.centerStart
                          .resolve(Directionality.of(context)),
                      cacheWidth: imageCacheWidth(
                          context, isWide ? 400 : viewportWidth - 48),
                      semanticLabel: item.name,
                      errorBuilder: (_, __, ___) => Text(item.name,
                          style: TextStyle(
                              color: foreground,
                              fontSize: isWide ? 48 : 32,
                              fontWeight: FontWeight.w800,
                              height: 1.2)))
                else
                  Text(item.name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: foreground,
                          fontSize: isWide ? 48 : 32,
                          fontWeight: FontWeight.w800,
                          height: 1.2)),
              ],
            ),
            builder: (context, visibility, child) => IgnorePointer(
              key: const ValueKey('detail-hero-content-ignore-pointer'),
              ignoring: visibility <= .05,
              child: Opacity(
                key: const ValueKey('detail-hero-content-opacity'),
                opacity: visibility,
                child: child,
              ),
            ),
          )),
    ]));
  }
}

class DetailColumnTitle extends StatelessWidget {
  const DetailColumnTitle(
      {super.key,
      required this.logoUrl,
      required this.title,
      required this.isWide,
      required this.viewportWidth});
  final String? logoUrl;
  final String title;
  final bool isWide;
  final double viewportWidth;
  @override
  Widget build(BuildContext context) =>
      Text(title, style: Theme.of(context).textTheme.headlineMedium);
}

class HarborPill extends StatelessWidget {
  const HarborPill({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Netflix meta chip: flat #333 block with 4dp corners.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: NovaColors.raised.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}

class DetailMetaRow extends StatelessWidget {
  const DetailMetaRow({super.key, required this.item, required this.isWide});
  final MediaItem item;
  final bool isWide;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (item.releaseInfo?.isNotEmpty == true)
          HarborPill(
            child: Text(
              item.releaseInfo!,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (double.tryParse(item.rating ?? '') != null)
          HarborPill(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.star, color: scheme.secondary, size: 14),
                const SizedBox(width: 4),
                Text(
                  item.rating!,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        if (item.runtime?.isNotEmpty == true)
          HarborPill(
            child: Text(
              item.runtime!,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (item.certification?.isNotEmpty == true)
          HarborPill(
            child: Text(
              item.certification!,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        for (final genre in item.genres.take(3))
          HarborPill(
            child: Text(
              genre,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12.5,
              ),
            ),
          ),
      ],
    );
  }
}

class DetailSynopsis extends StatelessWidget {
  const DetailSynopsis(
      {super.key,
      required this.description,
      required this.isWide,
      required this.viewportWidth});
  final String description;
  final bool isWide;
  final double viewportWidth;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 880),
      child: SelectableText(description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.7,
              color: Theme.of(context).colorScheme.onSurfaceVariant)));
}

class DetailActionRow extends StatelessWidget {
  const DetailActionRow(
      {super.key,
      required this.english,
      required this.isWide,
      required this.inList,
      required this.showTrackAnime,
      required this.primaryLabel,
      required this.primaryIsResume,
      required this.loading,
      required this.onPrimaryPressed,
      required this.onToggleWatchlist,
      required this.onOpenStreams,
      required this.onTrackAnime,
      required this.onShare,
      required this.onAddToList,
      this.nativeTopActions = false,
      this.onDownload});
  final bool english, isWide, inList, showTrackAnime, primaryIsResume, loading;
  final bool nativeTopActions;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed,
      onToggleWatchlist,
      onOpenStreams,
      onTrackAnime,
      onShare,
      onAddToList;
  final VoidCallback? onDownload;
  @override
  Widget build(BuildContext context) => Wrap(
          spacing: 8,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Netflix detail actions: white 4dp-corner Play plus #333
            // secondary buttons, icon circles for the overflow actions.
            FilledButton.icon(
                onPressed: loading ? null : onPrimaryPressed,
                icon: loading
                    ? SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: NovaColors.ink))
                    : Icon(
                        primaryIsResume
                            ? LucideIcons.rotateCcw
                            : LucideIcons.play,
                        size: 20),
                label: Text(primaryLabel),
                style: FilledButton.styleFrom(
                    backgroundColor: NovaColors.white,
                    foregroundColor: NovaColors.ink,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    elevation: 3,
                    shadowColor: Colors.black.withValues(alpha: .4),
                    minimumSize: const Size(176, 52))),
            FilledButton.icon(
                onPressed: onToggleWatchlist,
                icon: Icon(inList ? LucideIcons.check : LucideIcons.plus,
                    size: 20),
                label: Text(inList
                    ? (NovaStrings.lookup(english, 'message137'))
                    : (NovaStrings.lookup(english, 'netflixMyList'))),
                style: FilledButton.styleFrom(
                    backgroundColor: NovaColors.raised,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    elevation: 0,
                    minimumSize: const Size(112, 52))),
            if (!nativeTopActions)
              IconButton.outlined(
                  onPressed: onShare,
                  tooltip: NovaStrings.lookup(english, 'message139'),
                  icon: const Icon(LucideIcons.share2),
                  style:
                      IconButton.styleFrom(minimumSize: const Size.square(52))),
            if (onDownload != null)
              FilledButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(LucideIcons.download, size: 20),
                  label: Text(NovaStrings.lookup(english, 'downloads')),
                  style: FilledButton.styleFrom(
                      backgroundColor: NovaColors.raised,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      elevation: 0,
                      minimumSize: const Size(112, 52))),
            if (!nativeTopActions)
              PopupMenuButton<String>(
                tooltip: NovaStrings.lookup(english, 'message141'),
                icon: const Icon(LucideIcons.ellipsis),
                constraints: const BoxConstraints(minWidth: 240),
                onSelected: (action) {
                  switch (action) {
                    case 'sources':
                      onOpenStreams();
                    case 'list':
                      onAddToList();
                    case 'track':
                      onTrackAnime();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                      value: 'sources',
                      child: ListTile(
                          leading: const Icon(LucideIcons.layers),
                          title:
                              Text(NovaStrings.lookup(english, 'message142')))),
                  PopupMenuItem(
                      value: 'list',
                      child: ListTile(
                          leading: const Icon(LucideIcons.listPlus),
                          title:
                              Text(NovaStrings.lookup(english, 'message143')))),
                  if (showTrackAnime)
                    PopupMenuItem(
                        value: 'track',
                        child: ListTile(
                            leading: const Icon(LucideIcons.activity),
                            title: Text(
                                NovaStrings.lookup(english, 'message144')))),
                ],
              ),
          ]);
}

class DetailCastCrew extends StatelessWidget {
  const DetailCastCrew(
      {super.key,
      required this.english,
      required this.item,
      this.centered = false});
  final MediaItem item;
  final bool english, centered;
  @override
  Widget build(BuildContext context) {
    final people = <MediaPerson>[
      ...item.castMembers,
      if (item.castMembers.isEmpty)
        ...item.cast.map((name) => MediaPerson(
            name: name, role: NovaStrings.lookup(english, 'message145'))),
      ...item.crewMembers,
      if (item.crewMembers.isEmpty)
        ...item.director.map((name) => MediaPerson(
            name: name, role: NovaStrings.lookup(english, 'message146'))),
    ];
    if (people.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        NovaStrings.lookup(english, 'message147'),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
      ),
      const SizedBox(height: 14),
      SizedBox(
        height: 195 + (scale - 1) * 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: people.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final person = people[index];
            final initials = person.name
                .trim()
                .split(RegExp(r'\s+'))
                .take(2)
                .map((part) => part.characters.first)
                .join();
            return SizedBox(
              width: 92,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 92,
                    height: 136,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(HarborRadii.md),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: .5),
                        width: 1,
                      ),
                      color: scheme.surfaceContainerHighest,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: person.photo == null
                        ? Center(
                            child: Text(
                              initials,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          )
                        : NovaNetworkImage(
                            person.photo!,
                            fit: BoxFit.cover,
                            cacheWidth: imageCacheWidth(context, 92),
                            excludeFromSemantics: true,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                initials,
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    person.name,
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (person.role?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      person.role!,
                      textAlign: TextAlign.start,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class DetailProduction extends StatelessWidget {
  const DetailProduction(
      {super.key, required this.item, required this.english});
  final MediaItem item;
  final bool english;
  @override
  Widget build(BuildContext context) {
    if (item.productionCompanies.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
        padding: const EdgeInsetsDirectional.only(top: 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(NovaStrings.lookup(english, 'message148'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SizedBox(
              height:
                  128 + (MediaQuery.textScalerOf(context).scale(14) - 14) * 2.8,
              child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: item.productionCompanies.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 24),
                  itemBuilder: (context, index) {
                    final company = item.productionCompanies[index];
                    return SizedBox(
                        width: 144,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  height: 72,
                                  width: 144,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                      color: scheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: company.logo == null
                                      ? Icon(LucideIcons.clapperboard,
                                          color: scheme.onSurfaceVariant)
                                      : NovaNetworkImage(company.logo!,
                                          fit: BoxFit.contain,
                                          cacheWidth:
                                              imageCacheWidth(context, 112),
                                          semanticLabel: company.name,
                                          errorBuilder: (_, __, ___) => Icon(
                                              LucideIcons.clapperboard,
                                              color: scheme.onSurfaceVariant))),
                              const SizedBox(height: 8),
                              Text(company.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(context).textTheme.labelLarge),
                            ]));
                  })),
        ]));
  }
}

class DetailFactsTable extends StatelessWidget {
  const DetailFactsTable(
      {super.key, required this.item, required this.english});
  final MediaItem item;
  final bool english;
  @override
  Widget build(BuildContext context) {
    final series = item.type == 'series';
    final rows = <(String, String?)>[
      (
        NovaStrings.lookup(english, 'message149'),
        series
            ? (NovaStrings.lookup(english, 'message129'))
            : (NovaStrings.lookup(english, 'message128'))
      ),
      (NovaStrings.lookup(english, 'message150'), item.originalTitle),
      (
        NovaStrings.lookup(english, 'message151'),
        item.releaseDate ?? item.releaseInfo
      ),
      (NovaStrings.lookup(english, 'message152'), item.status),
      if (!series) (NovaStrings.lookup(english, 'message153'), item.runtime),
      if (series && item.seasonCount != null)
        (
          NovaStrings.lookup(english, 'message154'),
          item.seasonCount.toString()
        ),
      if (series && (item.episodeCount != null || item.videos.isNotEmpty))
        (
          NovaStrings.lookup(english, 'message43'),
          (item.episodeCount ?? item.videos.length).toString()
        ),
      (NovaStrings.lookup(english, 'message155'), item.genres.join(' · ')),
      (NovaStrings.lookup(english, 'language'), item.language),
      (NovaStrings.lookup(english, 'message156'), item.originCountry),
      (
        NovaStrings.lookup(english, 'message148'),
        item.productionCompanies.map((company) => company.name).join(' · ')
      ),
      (NovaStrings.lookup(english, 'tmdbNetworks'), item.networks.join(' · ')),
      (NovaStrings.lookup(english, 'tmdbCollection'), item.collectionName),
      (
        NovaStrings.lookup(english, 'message157'),
        item.director.isNotEmpty
            ? item.director.join(' · ')
            : item.crewMembers
                .where((person) =>
                    person.role == 'Creator' || person.role == 'Director')
                .map((person) => person.name)
                .join(' · ')
      ),
      (NovaStrings.lookup(english, 'message158'), item.rating),
      (NovaStrings.lookup(english, 'message159'), item.certification),
    ].where((row) => row.$2?.trim().isNotEmpty == true).toList();
    final scheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(NovaStrings.lookup(english, 'message160'),
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 16),
      Table(
          columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2)},
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder(
              horizontalInside: BorderSide(color: scheme.outlineVariant)),
          children: [
            for (final row in rows)
              TableRow(children: [
                Padding(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(0, 16, 16, 16),
                    child: Text(row.$1,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant))),
                Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 16),
                    child: SelectableText(row.$2!,
                        style: Theme.of(context).textTheme.bodyMedium)),
              ]),
          ]),
      if (item.trailerUrl case final trailer?)
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 16),
          child: TextButton.icon(
            onPressed: () => launchUrl(Uri.parse(trailer),
                mode: LaunchMode.externalApplication),
            icon: const Icon(LucideIcons.play),
            label: Text(NovaStrings.lookup(english, 'tmdbWatchTrailer')),
          ),
        ),
    ]);
  }
}

class DetailLoadingSkeleton extends StatelessWidget {
  const DetailLoadingSkeleton({super.key});
  @override
  Widget build(BuildContext context) => ListView(children: [
        ShimmerBox(
            height: (MediaQuery.sizeOf(context).height * .6).clamp(320, 600),
            borderRadius: BorderRadius.zero),
        const Padding(
            padding: EdgeInsets.all(24),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ShimmerBox(width: 240, height: 24),
              SizedBox(height: 24),
              ShimmerBox(height: 52),
              SizedBox(height: 24),
              ShimmerBox(height: 96)
            ])),
      ]);
}
