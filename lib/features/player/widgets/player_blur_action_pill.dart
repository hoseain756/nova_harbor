import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/nova_theme.dart';

/// Compact player prompt with separate dismiss and action targets.
///
/// Netflix treatment: a solid translucent-black pill floating over the video
/// (no live backdrop blur), 4dp control geometry, white content — matching
/// the rest of the player's over-video control language.
class PlayerBlurActionPill extends StatelessWidget {
  const PlayerBlurActionPill({
    super.key,
    required this.label,
    required this.onAction,
    required this.onDismiss,
    this.dismissTooltip,
  });

  final String label;
  final VoidCallback onAction;
  final VoidCallback onDismiss;
  final String? dismissTooltip;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, maxWidth: 300),
        child: Material(
          color: Colors.black.withValues(alpha: .55),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onDismiss,
                tooltip: dismissTooltip ??
                    MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(LucideIcons.x, size: 18),
                color: NovaColors.white,
                constraints:
                    const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
              Flexible(
                child: TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: NovaColors.white,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: NovaColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
