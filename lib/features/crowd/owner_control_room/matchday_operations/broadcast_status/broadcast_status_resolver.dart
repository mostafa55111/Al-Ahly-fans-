import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/matchday_timeline/matchday_timeline_resolver.dart';

/// حالة شريط البث التشغيلي.
enum BroadcastOperationalStatus {
  readyToStart,
  liveNow,
  closingSoon,
  finalizing,
  sessionClosed,
  recoveryActive,
  completed,
}

abstract final class BroadcastStatusResolver {
  static BroadcastOperationalStatus resolve({
    required MatchdayTimelinePhase phase,
    required bool recoverySuggested,
  }) {
    if (recoverySuggested && phase == MatchdayTimelinePhase.finalizing) {
      return BroadcastOperationalStatus.recoveryActive;
    }
    return switch (phase) {
      MatchdayTimelinePhase.idle => BroadcastOperationalStatus.readyToStart,
      MatchdayTimelinePhase.preparing => BroadcastOperationalStatus.readyToStart,
      MatchdayTimelinePhase.live => BroadcastOperationalStatus.liveNow,
      MatchdayTimelinePhase.closing => BroadcastOperationalStatus.closingSoon,
      MatchdayTimelinePhase.finalizing => BroadcastOperationalStatus.finalizing,
      MatchdayTimelinePhase.completed => BroadcastOperationalStatus.completed,
    };
  }

  static String labelAr(BroadcastOperationalStatus status) => switch (status) {
        BroadcastOperationalStatus.readyToStart => 'جاهز للبدء',
        BroadcastOperationalStatus.liveNow => 'بث مباشر',
        BroadcastOperationalStatus.closingSoon => 'إغلاق قريب',
        BroadcastOperationalStatus.finalizing => 'جاري الإنهاء',
        BroadcastOperationalStatus.sessionClosed => 'الجلسة مغلقة',
        BroadcastOperationalStatus.recoveryActive => 'استرداد نشط',
        BroadcastOperationalStatus.completed => 'مكتمل',
      };
}
