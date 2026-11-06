import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nova_mobile/l10n/nova_strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/nova_theme.dart';
import '../../core/models/media_item.dart';
import 'poster_card.dart';

class MediaRail extends StatelessWidget {
  const MediaRail({
    super.key,
    required this.title,
    required this.items,
    required this.onTap,
    this.subtitle,
    this.onOpenSection,
  });

  final String title;

  /// Optional source line under the rail title (the add-on name on the web
  /// AddonRail).
  final String? subtitle;
  final List<MediaItem> items;
  final ValueChanged<MediaItem> onTap;

  /// When provided, the header gains the "greater-than" mark that opens the
  /// full catalog section this rail belongs to.
  final VoidCallback? onOpenSection;

  static double sectionSpacing(BuildContext context) =>
      (MediaQuery.sizeOf(context).width * .045).clamp(14.0, 24.0).toDouble();

  static double headerSpacing(BuildContext context) =>
      (MediaQuery.sizeOf(context).width * .03).clamp(8.0, 14.0).toDouble();

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final wide = viewportWidth >= 700;
    // Task 122-b (F5): the rail used to `watch` AppState (rebuilding the
    // whole rail on any notification) for a single setting — select exactly
    // that field instead (identical value, identical UI).
    final showTitle = context.select<AppState, bool>(
      (app) => app.webSettings['hidePosterTitles'] != true,
    );
    final showRelease =
        showTitle && items.any((item) => item.releaseInfo != null);
    // Netflix rails: 120dp posters at the exact 2:3 card ratio.
    final posterWidth = wide ? 138.0 : 120.0;
    final posterHeight = posterWidth * 3 / 2;
    final titleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.3,
        );
    final releaseStyle = Theme.of(context).textTheme.bodySmall;
    final cardTextHeight = showTitle
        ? 8 +
            _lineBoxHeight(
              context,
              titleStyle,
              posterWidth,
              lines: 2,
            ) +
            (showRelease
                ? 3 +
                    _lineBoxHeight(
                      context,
                      releaseStyle,
                      posterWidth,
                      lines: 1,
                    )
                : 0)
        : 0.0;
    final railHeight = posterHeight + cardTextHeight;
    // Netflix rail geometry: 16dp phone gutter (34 on wide canvases, matching
    // the Top 10 rail); the vertical rhythm stays owned by the callers via
    // sectionSpacing (24dp max between sections).
    final gutter = wide ? 34.0 : 16.0;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: Row(
            children: [
              Expanded(
                child: subtitle == null
                    ? Text(
                        title,
                        // Netflix section title: 18pt bold white.
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color:
                                    dark ? NovaColors.white : null),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: dark
                                        ? NovaColors.white
                                        : null),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: NovaTheme.of(context).muted),
                          ),
                        ],
                      ),
              ),
              if (onOpenSection != null) _SectionChevron(onTap: onOpenSection!),
            ],
          ),
        ),
        SizedBox(height: headerSpacing(context)),
        SizedBox(
          height: railHeight,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(
              width: (viewportWidth * .035).clamp(10.0, 14.0).toDouble(),
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return PosterCard(
                item: item,
                width: posterWidth,
                onTap: () => onTap(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

double _lineBoxHeight(
  BuildContext context,
  TextStyle? style,
  double width, {
  required int lines,
}) {
  const sample = 'Ag أج';
  final painter = TextPainter(
    text: TextSpan(text: List.filled(lines, sample).join('\n'), style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.maybeLocaleOf(context),
    maxLines: lines,
  )..layout(maxWidth: width);
  // RenderFlex constraints are exact; round fractional font metrics upward so
  // rasterization can never need a fraction more than the rail reserves.
  final height = painter.height.ceilToDouble();
  painter.dispose();
  return height;
}

/// The header "greater-than" mark that opens the rail's full section.
/// A chevron glyph (not a shafted arrow), pointing forward in both locales.
class _SectionChevron extends StatelessWidget {
  const _SectionChevron({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final english = context.read<AppState>().english;
    final forward = Directionality.of(context) == TextDirection.ltr;
    final label = NovaStrings.lookup(english, 'message101');
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Icon(
                forward ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
                size: 20,
                // Netflix rail link mark: white on the dark canvas.
                color: Theme.of(context).brightness == Brightness.dark
                    ? NovaColors.white
                    : NovaTheme.of(context).ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
