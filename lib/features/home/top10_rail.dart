import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/media_item.dart';
import '../../shared/widgets/image_decode.dart';
import '../../shared/widgets/media_quick_look.dart';
import '../../shared/widgets/nova_network_image.dart';

/// Netflix's signature ranked rail: a giant translucent numeral tucked
/// behind an end-aligned 140×200 poster, exactly as the Netflix home feed
/// renders its Top 10 rows (white @ 15%, zero-padded, no captions).
class Top10Rail extends StatelessWidget {
  const Top10Rail({
    super.key,
    required this.title,
    required this.items,
    required this.onTap,
  });

  final String title;
  final List<MediaItem> items;
  final ValueChanged<MediaItem> onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final gutter = wide ? 34.0 : 16.0;
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: gutter),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  // Netflix section title: 18pt bold white.
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: Top10Item.itemHeight + (scale - 1) * 32,
          child: ListView.separated(
            padding: EdgeInsetsDirectional.symmetric(horizontal: gutter),
            scrollDirection: Axis.horizontal,
            itemCount: items.length.clamp(0, 10),
            separatorBuilder: (_, __) => const SizedBox(width: 20),
            itemBuilder: (context, index) => Top10Item(
              rank: index + 1,
              item: items[index],
              onTap: () => onTap(items[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class Top10Item extends StatelessWidget {
  const Top10Item({
    super.key,
    required this.rank,
    required this.item,
    required this.onTap,
  });

  final int rank;
  final MediaItem item;
  final VoidCallback onTap;

  // Netflix Top 10 geometry: 140×200 poster (radius 4), the numeral row
  // leaves a 50dp lead for the oversized rank figure that tucks behind it.
  static const double posterWidth = 140;
  static const double posterHeight = 200;
  static const double numeralLead = 50;
  static const double itemHeight = 230; // poster + 30dp numeral overhang.

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tileWidth = numeralLead + posterWidth;

    return SizedBox(
      width: tileWidth,
      height: itemHeight,
      child: InkWell(
        onTap: onTap,
        onLongPress: () =>
            showMediaQuickLook(context, item: item, onOpen: onTap),
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Giant translucent numeral (Netflix: white @ 15%, 200pt).
            PositionedDirectional(
              start: -6,
              bottom: 0,
              child: IgnorePointer(
                child: SizedBox(
                  height: posterHeight + 30,
                  child: Align(
                    alignment: AlignmentDirectional.bottomStart,
                    child: Text(
                      '$rank'.padLeft(2, '0'),
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: rank >= 10 ? 180 : 200,
                        fontWeight: FontWeight.w800,
                        height: 0.78,
                        letterSpacing: -6,
                        fontFamily: 'Tajawal',
                        color: Colors.white.withValues(alpha: .15),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // End-aligned poster card (Netflix: 140×200, radius 4).
            PositionedDirectional(
              end: 0,
              top: 0,
              width: posterWidth,
              height: posterHeight,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: scheme.surfaceContainerHighest,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .45),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: item.poster?.isNotEmpty == true
                    ? NovaNetworkImage(
                        item.poster!,
                        fit: BoxFit.cover,
                        cacheWidth:
                            imageCacheWidth(context, posterWidth),
                        semanticLabel: item.name,
                        errorBuilder: (_, __, ___) => Icon(
                          LucideIcons.film,
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    : Icon(
                        LucideIcons.film,
                        color: scheme.onSurfaceVariant,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compatibility for downstream consumers of the earlier ranking presenter.
class OutlinedRankNumber extends StatelessWidget {
  const OutlinedRankNumber(
      {super.key, required this.rank, required this.fontSize});
  final int rank;
  final double fontSize;
  static const String rankFontFamily = 'Tajawal';
  @override
  Widget build(BuildContext context) => Text('$rank',
      textDirection: TextDirection.ltr,
      style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.secondary));
}
