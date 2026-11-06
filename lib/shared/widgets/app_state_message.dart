import 'package:flutter/material.dart';
import '../../core/theme/nova_theme.dart';

/// Shared responsive empty/error surface. The caller owns localized copy/actions.
class AppStateMessage extends StatelessWidget {
  const AppStateMessage(
      {super.key,
      required this.icon,
      required this.message,
      this.actionLabel,
      this.onAction,
      this.loading = false,
      this.filledButton = false,
      this.actionIcon,
      this.iconSize = 44,
      this.padding = const EdgeInsets.all(24)});
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool loading, filledButton;
  final IconData? actionIcon;
  final double iconSize;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    // Netflix state pattern: red spinner while loading (dark), muted icon,
    // white w600 headline and an optional red FilledButton retry.
    final muted = dark ? NovaColors.mist : scheme.onSurfaceVariant;
    return Center(
        child: SingleChildScrollView(
            padding: padding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Semantics(
                  liveRegion: true,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    if (loading)
                      SizedBox.square(
                          dimension: 44,
                          child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color:
                                  dark ? NovaColors.red : scheme.primary))
                    else
                      Icon(icon, size: iconSize, color: muted),
                    const SizedBox(height: 24),
                    Text(message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: dark ? NovaColors.white : null)),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 24),
                      if (filledButton)
                        FilledButton.icon(
                            onPressed: onAction,
                            icon: actionIcon == null
                                ? const SizedBox.shrink()
                                : Icon(actionIcon),
                            label: Text(actionLabel!))
                      else
                        OutlinedButton.icon(
                            onPressed: onAction,
                            icon: actionIcon == null
                                ? const SizedBox.shrink()
                                : Icon(actionIcon),
                            label: Text(actionLabel!)),
                    ],
                  ])),
            )));
  }
}
