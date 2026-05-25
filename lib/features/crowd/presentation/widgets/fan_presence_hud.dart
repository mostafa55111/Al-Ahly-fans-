import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/fan_presence/fan_presence_controller.dart';

/// شريط حضور صغير — مستمع منفصل عن AnimatedBuilder الملعب.
class FanPresenceHud extends StatelessWidget {
  const FanPresenceHud({
    super.key,
    required this.controller,
    required this.topPadding,
  });

  final FanPresenceController controller;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isActive) return const SizedBox.shrink();
        final p = controller.profile!;
        return Positioned(
          left: 8,
          top: topPadding + 4,
          child: AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 420),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.rankTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'مستوى ${p.crowdLevel} · streak ${p.voteStreak}',
                      style: const TextStyle(color: Colors.white60, fontSize: 9),
                    ),
                    if (p.legacyMoments.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'تأثيرك: ${p.legacyMoments.length} لحظة',
                          style: const TextStyle(color: Colors.white38, fontSize: 8),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
