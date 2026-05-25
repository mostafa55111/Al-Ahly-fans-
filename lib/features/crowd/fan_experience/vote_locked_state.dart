import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/identity/club_award_labels.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_visual_tokens.dart';

/// شارة حالة بعد التصويت — بدون تفاعل.
class VoteLockedBadge extends StatelessWidget {
  const VoteLockedBadge({super.key, this.compact = true});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = StadiumVisualTokens.of(null);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.primary.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: compact ? 14 : 16, color: tokens.secondary),
          const SizedBox(width: 4),
          Text(
            ClubAwardLabels.voteRecorded,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// يعطّل التفاعل مع الكروت الأخرى بعد الاختيار.
class VoteLockedInteractionGate extends StatelessWidget {
  const VoteLockedInteractionGate({
    super.key,
    required this.locked,
    required this.isSelected,
    required this.child,
  });

  final bool locked;
  final bool isSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;
    return IgnorePointer(
      ignoring: !isSelected,
      child: Opacity(
        opacity: isSelected ? 1.0 : 0.42,
        child: child,
      ),
    );
  }
}
