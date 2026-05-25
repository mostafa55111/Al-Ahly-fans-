import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_animation_budget.dart';

/// نموذج رمز عائم لحظي — يُنشأ من خارج الطبقة.
@immutable
class CrowdFloatingReaction {
  const CrowdFloatingReaction({
    required this.id,
    required this.emoji,
    required this.dx,
    required this.dy,
    required this.createdMs,
  });

  final int id;
  final String emoji;
  final double dx;
  final double dy;
  final int createdMs;
}

/// طبقة ردود عائمة خفيفة — تتبع [CrowdAnimationBudget] (minimal = ثابت فقط).
class CrowdReactionStreamLayer extends StatelessWidget {
  const CrowdReactionStreamLayer({
    super.key,
    required this.reactions,
    required this.budget,
  });

  final List<CrowdFloatingReaction> reactions;
  final CrowdAnimationBudget budget;

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    final minimal = budget == CrowdAnimationBudget.minimal;
    final reduced = budget == CrowdAnimationBudget.reduced;

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final r in reactions)
            Positioned(
              left: r.dx * w - 14,
              top: r.dy * h - 18,
              child: minimal
                  ? Text(
                      r.emoji,
                      style: const TextStyle(
                        fontSize: 20,
                        shadows: [
                          Shadow(blurRadius: 6, color: Colors.black45),
                        ],
                      ),
                    )
                  : Text(
                      r.emoji,
                      style: TextStyle(
                        fontSize: reduced ? 23 : 26,
                        shadows: const [
                          Shadow(blurRadius: 8, color: Colors.black54),
                        ],
                      ),
                    )
                        .animate(key: ValueKey(r.id))
                        .fadeIn(duration: reduced ? 100.ms : 160.ms)
                        .scale(
                          begin: reduced ? const Offset(0.88, 0.88) : const Offset(0.72, 0.72),
                          end: const Offset(1, 1),
                          duration: reduced ? 140.ms : 220.ms,
                        )
                        .moveY(
                          begin: reduced ? 10 : 22,
                          end: reduced ? -18 : -36,
                          duration: reduced ? 650.ms : 1100.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .fadeOut(
                          delay: reduced ? 280.ms : 520.ms,
                          duration: reduced ? 260.ms : 420.ms,
                        ),
            ),
        ],
      ),
    );
  }
}
