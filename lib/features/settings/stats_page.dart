import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/nova_theme.dart';
import 'widgets/settings_tiles.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final (_, watchedCount, watchedHours, activeAddons, history) =
        context.select((AppState app) => (
              app.english,
              app.watchedCount,
              app.watchedHours,
              app.addons.where((e) => e.enabled).length,
              app.history
            ));
    final app = context.read<AppState>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days =
        List.generate(7, (index) => today.subtract(Duration(days: 6 - index)));
    final counts = days
        .map((day) => history.where((entry) {
              final date = DateTime.fromMillisecondsSinceEpoch(entry.watchedAt);
              return date.year == day.year &&
                  date.month == day.month &&
                  date.day == day.day;
            }).length)
        .toList();
    final peak = counts.fold<int>(1, (a, b) => a > b ? a : b);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final line = dark
        ? NovaColors.netflixLine
        : Theme.of(context).colorScheme.outlineVariant;
    final metrics = <(String, String)>[
      ('$watchedCount', app.tr('message512')),
      (watchedHours.toStringAsFixed(1), app.tr('message513')),
      ('$activeAddons', app.tr('message514')),
    ];
    return Scaffold(
        appBar: AppBar(title: Text(app.tr('message466'))),
        body: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: CustomScrollView(slivers: [
            SliverPadding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 0),
                sliver: SliverToBoxAdapter(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      SettingsPageIntro(
                          title: app.tr('message510'),
                          description: app.tr('message511'),
                          icon: LucideIcons.chartNoAxesCombined),
                      // Netflix stat strip: a flat 2-column grid — big bold
                      // numbers, muted labels, hairline grid lines, no boxes.
                      Table(
                          border: TableBorder(
                              horizontalInside:
                                  BorderSide(width: 1, color: line),
                              verticalInside:
                                  BorderSide(width: 1, color: line)),
                          children: [
                            for (var i = 0; i < metrics.length; i += 2)
                              TableRow(children: [
                                _Metric(
                                    value: metrics[i].$1,
                                    label: metrics[i].$2),
                                i + 1 < metrics.length
                                    ? _Metric(
                                        value: metrics[i + 1].$1,
                                        label: metrics[i + 1].$2)
                                    : const SizedBox(),
                              ]),
                          ]),
                      SettingsSectionTitle(title: app.tr('message515')),
                      Container(
                          padding:
                              const EdgeInsetsDirectional.only(top: 4),
                          child: Column(children: [
                            for (var i = 0; i < days.length; i++)
                              Padding(
                                  padding:
                                      const EdgeInsetsDirectional.symmetric(
                                          vertical: 8),
                                  child: Row(children: [
                                    SizedBox(
                                        width: 80,
                                        child: Text(
                                            MaterialLocalizations.of(context)
                                                .formatShortDate(days[i]),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall)),
                                    Expanded(
                                        child: Semantics(
                                            label: app.tr('message516',
                                                {'p0': counts[i]}),
                                            child: LinearProgressIndicator(
                                                value: counts[i] / peak,
                                                minHeight: 8,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                borderRadius:
                                                    BorderRadius.circular(4)))),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                        width: 24,
                                        child: Text('${counts[i]}',
                                            textAlign: TextAlign.end)),
                                  ])),
                          ])),
                      SettingsSectionTitle(title: app.tr('message517')),
                      if (history.isEmpty)
                        SettingsInfoBanner(
                            icon: LucideIcons.film,
                            message: app.tr('message518')),
                    ]))),
            SliverPadding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
                sliver: SliverList.builder(
                    itemCount: history.length.clamp(0, 50),
                    itemBuilder: (context, index) {
                      final entry = history[index];
                      return ListTile(
                          contentPadding: const EdgeInsetsDirectional.symmetric(
                              vertical: 8),
                          leading: CircleAvatar(
                              backgroundColor: dark
                                  ? NovaColors.raised
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                              child: Icon(LucideIcons.film,
                                  color: dark
                                      ? NovaColors.mist
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                  size: 18)),
                          title: Text(entry.item.name),
                          subtitle: Text(MaterialLocalizations.of(context)
                              .formatMediumDate(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      entry.watchedAt))));
                    })),
            SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverToBoxAdapter(
                    child: history.isEmpty
                        ? const SizedBox.shrink()
                        : OutlinedButton.icon(
                            icon: Icon(LucideIcons.trash2,
                                size: 18,
                                color: Theme.of(context).colorScheme.error),
                            label: Text(app.tr('message519'),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface)),
                            onPressed: () async {
                              final clear = await confirmSettingsAction(context,
                                  title: app.tr('message361'),
                                  message: app.tr('message520'),
                                  confirm: app.tr('message368'),
                                  cancel: app.tr('cancel'));
                              if (clear) await app.clearHistory();
                            },
                          ))),
          ]),
        )));
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
        padding: const EdgeInsetsDirectional.symmetric(
            vertical: 16, horizontal: 16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: dark
                          ? NovaColors.white
                          : Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 4),
              Text(label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: dark
                          ? NovaColors.mist
                          : Theme.of(context).colorScheme.onSurfaceVariant)),
            ]));
  }
}
