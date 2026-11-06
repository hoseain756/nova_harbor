import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/nova_theme.dart';

/// Accessible in-app feedback, using the shared NOVA snackbar theme.
class NoorToast {
  NoorToast._();
  static void show(BuildContext context, String message, {bool error = false}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    // Netflix toast anatomy, explicit: #262626 fill on dark (inverseSurface
    // on light), white 14dp w500 copy, 4dp corners, subtle hairline edge,
    // 14–16dp padding. Floating behaviour comes from the shared theme.
    final fill = dark ? NovaColors.surfaceHigh : scheme.inverseSurface;
    final ink = dark ? NovaColors.white : scheme.onInverseSurface;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      duration: Duration(seconds: error ? 5 : 3),
      backgroundColor: fill,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
              color: dark ? NovaColors.divider : Colors.transparent)),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
      content: Semantics(
          liveRegion: true,
          child: Row(children: [
            Icon(error ? LucideIcons.circleAlert : LucideIcons.circleCheck,
                color: ink, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Text(message,
                    style: TextStyle(
                        color: ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w500))),
          ])),
    ));
  }
}
