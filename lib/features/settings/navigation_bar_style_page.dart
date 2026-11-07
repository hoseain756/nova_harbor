import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/nova_theme.dart';
import '../shell/dock_tab.dart';
import '../shell/glass_dock.dart';
import '../shell/liquid_glass_dock.dart';
import '../shell/noor_dock_tabs.dart';
import 'widgets/settings_tiles.dart';

/// Appearance sub-page for the phone/tablet-width horizontal glass dock.
class NavigationBarStylePage extends StatelessWidget {
  const NavigationBarStylePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final style = NavigationBarStyle.fromSetting(
      app.webSettings['navigationBarStyle'],
    );
    final reduceTransparency = app.webSettings['reduceTransparency'] == true;

    return Scaffold(
      appBar: AppBar(title: Text(app.tr('navigationBarStyle'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 48),
            children: [
              SettingsPageIntro(
                title: app.tr('navigationBarStyle'),
                description: app.tr('navigationBarStyleDescription'),
                icon: LucideIcons.layoutGrid,
              ),
              SettingsContentSection(
                title: app.tr('navigationBarPreview'),
                children: [
                  Padding(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 12),
                    child: SizedBox(
                      height: 132,
                      child: RepaintBoundary(
                        child: style == NavigationBarStyle.liquid
                            ? LiquidGlassDock(
                                key: const ValueKey(
                                    'navigation-style-preview-bar'),
                                tabs: noorDockTabsFor(rtl: !app.english),
                                activeId: DockTab.animeId,
                                onTabSelected: (_) {},
                                languageCode: app.english ? 'en' : 'ar',
                                style: style,
                                previewMode: true,
                                reduceMotion: true,
                                reduceTransparency: reduceTransparency,
                                onSearch: () {},
                                searchLabel: '',
                              )
                            : GlassDock(
                                key: const ValueKey(
                                    'navigation-style-preview-bar'),
                                tabs: noorDockTabsFor(rtl: !app.english),
                                activeId: DockTab.animeId,
                                onTabSelected: (_) {},
                                languageCode: app.english ? 'en' : 'ar',
                                style: style,
                                previewMode: true,
                                reduceMotion: true,
                                reduceTransparency: reduceTransparency,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              SettingsContentSection(
                title: app.tr('navigationBarOptions'),
                children: [
                  for (final option in NavigationBarStyle.values)
                    _NavigationBarStyleOption(
                      key: ValueKey('navigation-style-option-${option.name}'),
                      style: option,
                      title: app.tr(_titleKey(option)),
                      description: app.tr(_descriptionKey(option)),
                      selected: style == option,
                      onTap: () => unawaited(
                          app.setSetting('navigationBarStyle', option.name)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _titleKey(NavigationBarStyle style) => switch (style) {
        NavigationBarStyle.classic => 'navigationBarClassic',
        NavigationBarStyle.compact => 'navigationBarCompact',
        NavigationBarStyle.mini => 'navigationBarMini',
        NavigationBarStyle.liquid => 'navigationBarLiquid',
      };

  String _descriptionKey(NavigationBarStyle style) => switch (style) {
        NavigationBarStyle.classic => 'navigationBarClassicDescription',
        NavigationBarStyle.compact => 'navigationBarCompactDescription',
        NavigationBarStyle.mini => 'navigationBarMiniDescription',
        NavigationBarStyle.liquid => 'navigationBarLiquidDescription',
      };
}

class _NavigationBarStyleOption extends StatelessWidget {
  const _NavigationBarStyleOption({
    super.key,
    required this.style,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final NavigationBarStyle style;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (style) {
        NavigationBarStyle.classic => LucideIcons.list,
        NavigationBarStyle.compact => LucideIcons.layoutGrid,
        NavigationBarStyle.mini => LucideIcons.minus,
        NavigationBarStyle.liquid => LucideIcons.droplets,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : NovaMotion.state,
          curve: NovaMotion.curve,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsetsDirectional.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: dark
                        ? NovaColors.netflixTile
                        : theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: dark
                            ? NovaColors.divider
                            : theme.colorScheme.outlineVariant),
                  ),
                  child: Icon(
                    _icon,
                    size: 20,
                    color: dark
                        ? NovaColors.white
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w500,
                            color: dark ? NovaColors.white : null)),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (selected)
                Icon(
                  LucideIcons.check,
                  size: 20,
                  color: theme.colorScheme.primary,
                )
              else
                const SizedBox(width: 20),
            ],
          ),
        ),
      ),
    );
  }
}
