import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/session_operational_timeline.dart';

/// خط زمني للجلسة — للمالك فقط، قراءة فقط.
class SessionStatusTimelineWidget extends StatelessWidget {
  const SessionStatusTimelineWidget({super.key, required this.match});

  final MatchActiveSession? match;

  @override
  Widget build(BuildContext context) {
    final steps = SessionOperationalTimeline.buildSteps(
      session: match,
      serverTime: getIt<EgyptServerTimeService>(),
    );
    return Card(
      color: const Color(0xFF151515),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'مسار الجلسة (تلقائي)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in steps)
                  _PhaseChip(
                    label: s.labelAr,
                    reached: s.reached,
                    active: s.active,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'بعد النشر: الإغلاق والتصنيف والجوائف تلقائياً — لا حاجة لإجراء يدوي.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseChip extends StatelessWidget {
  const _PhaseChip({
    required this.label,
    required this.reached,
    required this.active,
  });

  final String label;
  final bool reached;
  final bool active;

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFF2A2A2A);
    Color fg = Colors.white38;
    if (reached) {
      bg = active ? Colors.green.shade900 : const Color(0xFF1E3A1E);
      fg = active ? Colors.greenAccent : Colors.white70;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: active ? Border.all(color: Colors.greenAccent) : null,
      ),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11)),
    );
  }
}
