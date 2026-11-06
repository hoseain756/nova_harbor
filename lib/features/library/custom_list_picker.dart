import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/custom_list.dart';
import '../../core/models/media_item.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/nova_theme.dart';
import '../../l10n/nova_strings.dart';
import 'custom_lists_page.dart';
import '../shared_collections/shared_collection_picker.dart';

Future<void> showCustomListPicker(BuildContext context, MediaItem item) async {
  final app = context.read<AppState>();
  final selection = await showModalBottomSheet<Object>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 720),
    builder: (sheetContext) {
      final dark = Theme.of(sheetContext).brightness == Brightness.dark;
      return SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * .72,
        child: SafeArea(
            top: false,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(app.tr('message631'),
                                style: Theme.of(sheetContext)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color:
                                            dark ? NovaColors.white : null)),
                            const SizedBox(height: 8),
                            Text(item.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    Theme.of(sheetContext).textTheme.bodyLarge),
                          ])),
                  Expanded(
                      child: app.customLists.isEmpty
                          ? Center(
                              child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.library,
                                            size: 44,
                                            color: dark
                                                ? NovaColors.mist
                                                : Theme.of(sheetContext)
                                                    .colorScheme
                                                    .onSurfaceVariant),
                                        const SizedBox(height: 16),
                                        Text(app.tr('message632'),
                                            style: Theme.of(sheetContext)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                    color: dark
                                                        ? NovaColors.white
                                                        : null),
                                            textAlign: TextAlign.center),
                                        const SizedBox(height: 8),
                                        Text(app.tr('message633'),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: dark
                                                    ? NovaColors.mist
                                                    : Theme.of(sheetContext)
                                                        .colorScheme
                                                        .onSurfaceVariant)),
                                      ])))
                          : ListView.separated(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  24, 0, 24, 24),
                              itemCount: app.customLists.length,
                              separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: dark
                                      ? NovaColors.netflixLine
                                      : null),
                              itemBuilder: (_, index) {
                                final list = app.customLists[index];
                                final exists = list.items
                                    .any((entry) => entry.id == item.id);
                                return ListTile(
                                        minTileHeight: 80,
                                        leading: Icon(
                                            exists
                                                ? LucideIcons.circleCheck
                                                : LucideIcons.library,
                                            color: exists
                                                ? NovaColors.red
                                                : dark
                                                    ? NovaColors.mist
                                                    : Theme.of(sheetContext)
                                                        .colorScheme
                                                        .onSurfaceVariant),
                                        title: Text(list.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                        subtitle: Text(exists
                                            ? app.tr('message634')
                                            : '${list.items.length} ${app.tr('message607')}'),
                                        trailing: exists
                                            ? null
                                            : const Icon(LucideIcons.plus),
                                        onTap: exists
                                            ? null
                                            : () => Navigator.pop(
                                                sheetContext, list));
                              })),
                  const Divider(height: 1),
                  Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                                onPressed: () =>
                                    Navigator.pop(sheetContext, 'create'),
                                icon: const Icon(LucideIcons.plus),
                                label: Text(app.tr('message605')))),
                        if (Supabase.instance.isInitialized &&
                            Supabase.instance.client.auth.currentUser !=
                                null) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                              width: double.infinity,
                              child: FilledButton.tonalIcon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: NovaColors.raised,
                                    foregroundColor: NovaColors.white,
                                  ),
                                  onPressed: () =>
                                      Navigator.pop(sheetContext, 'shared'),
                                  icon: const Icon(LucideIcons.usersRound),
                                  label: Text(NovaStrings.of(sheetContext)
                                      .text('sharedAddToCollection')))),
                        ],
                      ])),
                ])));
      });
  if (selection == null || !context.mounted) return;
  if (selection == 'shared') {
    await showSharedCollectionPicker(context, item);
    return;
  }
  if (selection == 'create') {
    await createNovaCollection(context);
    if (context.mounted && app.customLists.isNotEmpty) {
      await showCustomListPicker(context, item);
    }
    return;
  }
  final list = selection as CustomMediaList;
  final added = await app.addToCustomList(list.id, item);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(added ? app.tr('message635') : app.tr('message634'))));
}
