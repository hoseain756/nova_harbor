import 'package:flutter/material.dart';

import '../../../l10n/nova_strings.dart';
import '../../../core/theme/nova_theme.dart';
import '../segments/skip_segment.dart';

String skipSegmentLabelKey(SkipSegmentType type) =>
    type == SkipSegmentType.outro || type == SkipSegmentType.credits
        ? 'message25'
        : 'message24';

String skipSegmentDoneKey(SkipSegmentType type) => switch (type) {
      SkipSegmentType.recap => 'playerRecapSkipped',
      SkipSegmentType.intro => 'message12',
      SkipSegmentType.opening => 'playerOpeningSkipped',
      SkipSegmentType.outro => 'message13',
      SkipSegmentType.credits => 'playerCreditsSkipped',
    };

/// Netflix skip pill (Task: Netflix player UI/UX): the exact "Skip Intro"
/// treatment — a solid white rectangle with bold black text and the tiniest
/// corner radius. Tapping jumps past the segment; it also stays dismissible
/// for users who want the pill gone for this session segment.
class PlayerSkipSegmentPill extends StatelessWidget {
  const PlayerSkipSegmentPill({
    super.key,
    required this.segment,
    required this.english,
    required this.onTap,
    required this.onDismiss,
  });

  final SkipSegment segment;
  final bool english;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: NovaColors.white,
          foregroundColor: NovaColors.ink,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: .2,
          ),
        ),
        child: Text(
          NovaStrings.lookup(english, skipSegmentLabelKey(segment.type)),
        ),
      );
}
