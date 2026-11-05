import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/media_item.dart';
import '../../core/theme/nova_theme.dart';
import '../../shared/widgets/image_decode.dart';
import '../../shared/widgets/media_quick_look.dart';
import '../../shared/widgets/nova_network_image.dart';

/// Harbor\'s signature ranked rail: giant stroked numeral overlapping the
/// end-aligned poster, followed by an offset title caption.
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
    final gutter = wide ? 34.0 : 20.0;
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: Top10Item.itemHeight + (scale - 1) * 32,
          child: ListView.separated(
            padding: EdgeInsetsDirectional.symmetric(horizontal: gutter),
            scrollDirection: Axis.horizontal,
            itemCount: items.length.clamp(0, 10),
            separatorBuilder: (_, __) => const SizedBox(width: 14),
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

  static const double itemHeight = 210;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const tileWidth = 152.0;
    const tileHeight = 176.0;
    const posterWidth = tileWidth * 0.62; // ~94dp
    const posterHeight = posterWidth / 0.68; // ~138dp

    return SizedBox(
      width: tileWidth,
      child: InkWell(
        onTap: onTap,
        onLongPress: () =>
            showMediaQuickLook(context, item: item, onOpen: onTap),
        borderRadius: BorderRadius.circular(HarborRadii.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: tileWidth,
              height: tileHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Giant outlined numeral behind the poster (Harbor signature)
                  PositionedDirectional(
                    start: -6,
                    top: -2,
                    child: IgnorePointer(
                      child: Text(
                        '$rank',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: rank >= 10 ? 116 : 152,
                          fontWeight: FontWeight.w800,
                          height: 0.82,
                          letterSpacing: -4,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 2.4
                            ..color = scheme.onSurfaceVariant.withValues(alpha: .5),
                        ),
                      ),
                    ),
                  ),
                  // Overlapping poster card on the end side
                  PositionedDirectional(
                    end: 0,
                    top: 0,
                    width: posterWidth,
                    height: posterHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(HarborRadii.md),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: .6),
                          width: 1,
                        ),
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
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: tileWidth * 0.38),
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
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
