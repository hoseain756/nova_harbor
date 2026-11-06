import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/data/catalog_repository.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/nova_theme.dart';
import '../../../l10n/nova_strings.dart';
import '../../../shared/widgets/nova_network_image.dart';
import 'player_sheets.dart' show SheetScaffold;

/// Season and episode picker shared by the legacy and Core player routes.
/// Episode rows keep the supplied playback metadata and can enrich artwork.
class PlayerEpisodesSheet extends StatefulWidget {
  const PlayerEpisodesSheet({
    super.key,
    required this.english,
    required this.episodes,
    required this.currentVideoId,
    required this.onPick,
    this.fallbackArtwork,
    this.titleId,
    this.loading = false,
  });

  final bool english;
  final List<Map<String, dynamic>> episodes;
  final String currentVideoId;
  final ValueChanged<Map<String, dynamic>> onPick;
  final String? fallbackArtwork;
  final String? titleId;
  final bool loading;

  @override
  State<PlayerEpisodesSheet> createState() => _PlayerEpisodesSheetState();
}

class _PlayerEpisodesSheetState extends State<PlayerEpisodesSheet> {
  int? _selectedSeason;
  final Map<int, SeasonEpisodeArtwork> _seasonArtwork = {};
  final Set<int> _requestedSeasons = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _activeSeason != null) {
        unawaited(_loadSeasonArtwork(_activeSeason!));
      }
    });
  }

  Future<void> _loadSeasonArtwork(int season) async {
    final titleId = widget.titleId;
    if (titleId == null || !_requestedSeasons.add(season)) return;
    final app = context.read<AppState>();
    if (app.webSettings['tmdbEnabled'] == false) return;
    final art = await app.catalogs
        .seasonEpisodeArtwork(titleId, season, language: app.contentTmdbLocale);
    if (mounted) setState(() => _seasonArtwork[season] = art);
  }

  int _seasonOf(Map<String, dynamic> episode) =>
      (episode['season'] as num?)?.toInt() ?? 0;

  int _episodeOf(Map<String, dynamic> episode) =>
      (episode['episode'] as num?)?.toInt() ?? 0;

  List<int> get _seasons {
    final values = widget.episodes.map(_seasonOf).where((value) => value > 0);
    return values.toSet().toList()..sort();
  }

  int? get _activeSeason {
    final seasons = _seasons;
    if (seasons.isEmpty) return null;
    if (_selectedSeason != null && seasons.contains(_selectedSeason)) {
      return _selectedSeason;
    }
    for (final episode in widget.episodes) {
      if ((episode['id'] ?? '').toString() == widget.currentVideoId) {
        final current = _seasonOf(episode);
        if (seasons.contains(current)) return current;
      }
    }
    return seasons.first;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final season = _activeSeason;
    final visible = widget.episodes
        .where((episode) => _seasonOf(episode) == season)
        .toList()
      ..sort((a, b) => _episodeOf(a).compareTo(_episodeOf(b)));
    return SheetScaffold(
      title: NovaStrings.lookup(widget.english, 'message43'),
      expanded: true,
      child: Column(
        children: [
          if (_seasons.isNotEmpty)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: DropdownButton<int>(
                value: season,
                isDense: true,
                borderRadius: BorderRadius.circular(4),
                icon: const Icon(LucideIcons.chevronDown, size: 18),
                items: [
                  for (final value in _seasons)
                    DropdownMenuItem(
                      value: value,
                      child: Text(NovaStrings.lookup(
                          widget.english, 'message45', {'p0': value})),
                    ),
                ],
                onChanged: (value) {
                  setState(() => _selectedSeason = value);
                  if (value != null) unawaited(_loadSeasonArtwork(value));
                },
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.loading
                ? Center(
                    child: CircularProgressIndicator(
                        color: dark ? NovaColors.red : scheme.primary,
                        strokeWidth: 2.5))
                : visible.isEmpty
                    ? Center(
                        child: Text(
                          NovaStrings.lookup(
                              widget.english, 'playerNoEpisodes'),
                          style: TextStyle(
                              color: dark
                                  ? NovaColors.mist
                                  : scheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        itemCount: visible.length,
                        // Netflix episode browser: hairline #222222
                        // separators instead of card gaps.
                        separatorBuilder: (_, __) => const Divider(
                            color: NovaColors.netflixLine, height: 1),
                        itemBuilder: (context, index) => _EpisodeRow(
                          english: widget.english,
                          episode: visible[index],
                          currentVideoId: widget.currentVideoId,
                          fallbackArtwork: widget.fallbackArtwork,
                          seasonStill: _seasonArtwork[season]
                              ?.stills[_episodeOf(visible[index])],
                          seasonPoster: _seasonArtwork[season]?.poster,
                          onPick: widget.onPick,
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({
    required this.english,
    required this.episode,
    required this.currentVideoId,
    required this.fallbackArtwork,
    required this.seasonStill,
    required this.seasonPoster,
    required this.onPick,
  });

  final bool english;
  final Map<String, dynamic> episode;
  final String currentVideoId;
  final String? fallbackArtwork;
  final String? seasonStill;
  final String? seasonPoster;
  final ValueChanged<Map<String, dynamic>> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final season = (episode['season'] as num?)?.toInt() ?? 0;
    final number = (episode['episode'] as num?)?.toInt() ?? 0;
    final tag =
        'S${season.toString().padLeft(2, '0')}E${number.toString().padLeft(2, '0')}';
    final title = (episode['name'] ?? episode['title'] ?? '').toString().trim();
    final ratingRaw = episode['rating'] ?? episode['imdbRating'];
    final rating = ratingRaw is num
        ? ratingRaw.toDouble()
        : double.tryParse(ratingRaw?.toString() ?? '');
    final existing =
        (episode['thumbnail'] ?? episode['thumb'] ?? '').toString();
    final artwork = ((season > 1 || existing.isEmpty)
            ? (seasonStill ?? seasonPoster)
            : null) ??
        (existing.isNotEmpty ? existing : fallbackArtwork) ??
        '';
    final current = (episode['id'] ?? '').toString() == currentVideoId;
    final imageWidth = MediaQuery.sizeOf(context).width < 420 ? 112.0 : 140.0;
    final titleText = title.isEmpty
        ? NovaStrings.lookup(english, 'message44', {'p0': number})
        : title;

    // Netflix episode browser row: flat (transparent on the sheet surface),
    // no card Material box, 8dp vertical padding, hairline separators handled
    // by the ListView.separated builder.
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: imageWidth,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      artwork.isEmpty
                          ? ColoredBox(
                              color: dark
                                  ? NovaColors.surfaceHigh
                                  : scheme.surfaceContainerHighest)
                          : NovaNetworkImage(artwork,
                              fit: BoxFit.cover,
                              cacheWidth: 320,
                              excludeFromSemantics: true),
                      PositionedDirectional(
                        start: 5,
                        bottom: 5,
                        child: _ImageBadge(label: tag),
                      ),
                      if (rating != null && rating > 0)
                        PositionedDirectional(
                          end: 5,
                          top: 5,
                          child: _ImageBadge(
                              label: rating.toStringAsFixed(1),
                              icon: LucideIcons.star),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current episode: white w700 title + small red badgeCheck.
                  if (current)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            titleText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  dark ? NovaColors.white : scheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.badgeCheck,
                            size: 14, color: NovaColors.red),
                      ],
                    )
                  else
                    Text(
                      titleText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: dark ? NovaColors.white : scheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 5),
                  if (current)
                    // 'Now playing' affordance: red filled circular play
                    // button + the existing localized string (kept verbatim).
                    Semantics(
                      button: true,
                      enabled: false,
                      label: NovaStrings.lookup(
                          english, 'playerCurrentEpisode'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: NovaColors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.play,
                                size: 16, color: NovaColors.white),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              NovaStrings.lookup(
                                  english, 'playerCurrentEpisode'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: NovaColors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onPick(episode);
                      },
                      icon: const Icon(LucideIcons.play, size: 15),
                      label: Text(
                          NovaStrings.lookup(english, 'playerEpisodePlay')),
                      style: FilledButton.styleFrom(
                        backgroundColor: NovaColors.raised,
                        foregroundColor: NovaColors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        minimumSize: const Size(80, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}

class _ImageBadge extends StatelessWidget {
  const _ImageBadge({required this.label, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          // Netflix thumbnail badge: black @70% fill, white 10dp w700 text.
          color: Colors.black.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 10, color: NovaColors.white),
                  const SizedBox(width: 2),
                ],
                Text(label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: NovaColors.white,
                    )),
              ],
            ),
          ),
        ),
      );
}
