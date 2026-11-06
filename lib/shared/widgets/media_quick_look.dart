import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/models/media_item.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/nova_theme.dart';
import '../../features/anime/anime_tracker_sheet.dart';
import 'nova_network_image.dart';
import 'image_decode.dart';
import 'noor_toast.dart';

/// Compact action sheet; no full-screen blur or oversized poster animation.
Future<void> showMediaQuickLook(BuildContext context,
    {required MediaItem item, required VoidCallback onOpen}) async {
  HapticFeedback.selectionClick();
  final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => _QuickLook(item: item));
  if (!context.mounted) return;
  if (action == 'watch') onOpen();
  if (action == 'track') await showAnimeTrackerSheet(context, item);
}

/// Netflix secondary action: white label on the #323232 fill.
ButtonStyle _quickLookSecondary(BuildContext context) =>
    FilledButton.styleFrom(
      backgroundColor: NovaColors.raised,
      foregroundColor: NovaColors.white,
      disabledBackgroundColor: NovaColors.raised.withValues(alpha: .5),
      disabledForegroundColor: NovaColors.white.withValues(alpha: .5),
    );

class _QuickLook extends StatelessWidget {
  const _QuickLook({required this.item});
  final MediaItem item;
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final inLibrary = app.contains(item);
    final watched = app.history.any((entry) => entry.item.id == item.id);
    final canTrack = item.hasAnimeIds &&
        (app.linkedServices['anilist']?['linked'] == true ||
            app.linkedServices['mal']?['linked'] == true);
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                          width: 96,
                          height: 144,
                          child: item.poster == null
                              ? ColoredBox(
                                  color: scheme.surfaceContainerHigh,
                                  child: const Icon(LucideIcons.film))
                              : NovaNetworkImage(item.poster!,
                                  fit: BoxFit.cover,
                                  cacheWidth: imageCacheWidth(context, 96)))),
                  const SizedBox(width: 20),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(item.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? NovaColors.white
                                        : null)),
                        const SizedBox(height: 8),
                        if (item.releaseInfo != null)
                          Text(item.releaseInfo!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                      color: scheme.onSurfaceVariant)),
                        if (item.description?.isNotEmpty == true) ...[
                          const SizedBox(height: 12),
                          Text(item.description!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant))
                        ],
                      ])),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      tooltip: app.tr('close'),
                      icon: const Icon(LucideIcons.x)),
                ]),
                const SizedBox(height: 24),
                FilledButton.icon(
                    onPressed: () => Navigator.pop(context, 'watch'),
                    icon: const Icon(LucideIcons.play),
                    label: Text(app.tr('message95'))),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                    style: _quickLookSecondary(context),
                    onPressed: () async {
                      await app.toggleWatchlist(item);
                      if (context.mounted) {
                        NoorToast.show(
                            context,
                            inLibrary
                                ? app.tr('message91')
                                : app.tr('message92'));
                        Navigator.pop(context);
                      }
                    },
                    icon: Icon(inLibrary
                        ? LucideIcons.bookmarkCheck
                        : LucideIcons.bookmarkPlus),
                    label: Text(
                        inLibrary ? app.tr('message96') : app.tr('message97'))),
                Divider(
                    height: 1,
                    thickness: 1,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? NovaColors.netflixLine
                        : null),
                FilledButton.tonalIcon(
                    style: _quickLookSecondary(context),
                    onPressed: watched
                        ? null
                        : () async {
                            await app.recordPlayback(item,
                                positionMs: 1, durationMs: 0);
                            if (context.mounted) {
                              NoorToast.show(context, app.tr('message94'));
                              Navigator.pop(context);
                            }
                          },
                    icon: Icon(
                        watched ? LucideIcons.circleCheck : LucideIcons.eye),
                    label: Text(
                        watched ? app.tr('message98') : app.tr('message99'))),
                if (canTrack) ...[
                  Divider(
                      height: 1,
                      thickness: 1,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? NovaColors.netflixLine
                              : null),
                  FilledButton.tonalIcon(
                      style: _quickLookSecondary(context),
                      onPressed: () => Navigator.pop(context, 'track'),
                      icon: const Icon(LucideIcons.listChecks),
                      label: Text(app.tr('message100'))),
                ],
              ]),
        ));
  }
}
