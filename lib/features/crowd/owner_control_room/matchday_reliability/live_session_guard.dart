import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/matchday_timeline/matchday_timeline_resolver.dart';

/// نتيجة فحص حارس الجلسة الحية.
class LiveSessionGuardVerdict {
  const LiveSessionGuardVerdict({required this.allowed, this.reason});

  final bool allowed;
  final String? reason;

  static const ok = LiveSessionGuardVerdict(allowed: true);
}

/// قواعد حتمية — منع ازدواجية التشغيل يوم المباراة.
abstract final class LiveSessionGuard {
  static LiveSessionGuardVerdict canStartSession({
    required MatchActiveSession? existing,
    required MatchdayTimelinePhase phase,
    required bool finalizeInFlight,
  }) {
    if (finalizeInFlight) {
      return const LiveSessionGuardVerdict(
        allowed: false,
        reason: 'إنهاء الجلسة قيد التنفيذ — انتظر',
      );
    }
    if (existing != null &&
        existing.id.isNotEmpty &&
        existing.votingEnabled &&
        !existing.awardsFinalized) {
      return const LiveSessionGuardVerdict(
        allowed: false,
        reason: 'يوجد جلسة نشطة — أغلقها أولاً',
      );
    }
    if (phase == MatchdayTimelinePhase.finalizing) {
      return const LiveSessionGuardVerdict(
        allowed: false,
        reason: 'لا يمكن بدء جلسة أثناء الإنهاء',
      );
    }
    return LiveSessionGuardVerdict.ok;
  }

  static LiveSessionGuardVerdict canFinalize({
    required MatchActiveSession? session,
    required MatchdayTimelinePhase phase,
    required bool finalizeInFlight,
  }) {
    if (session == null || session.id.isEmpty) {
      return const LiveSessionGuardVerdict(
        allowed: false,
        reason: 'لا جلسة للإنهاء',
      );
    }
    if (session.awardsFinalized) {
      return LiveSessionGuardVerdict.ok;
    }
    if (finalizeInFlight) {
      return const LiveSessionGuardVerdict(
        allowed: false,
        reason: 'Finalize قيد التنفيذ',
      );
    }
    if (phase == MatchdayTimelinePhase.preparing) {
      return const LiveSessionGuardVerdict(
        allowed: false,
        reason: 'لا finalize أثناء التحضير',
      );
    }
    if (phase == MatchdayTimelinePhase.idle) {
      return const LiveSessionGuardVerdict(
        allowed: false,
        reason: 'لا جلسة نشطة',
      );
    }
    return LiveSessionGuardVerdict.ok;
  }

  static LiveSessionGuardVerdict canEmergencyClose({
    required MatchActiveSession? session,
    required bool finalizeInFlight,
  }) {
    if (session == null || session.id.isEmpty) {
      return const LiveSessionGuardVerdict(
        allowed: false,
        reason: 'لا جلسة',
      );
    }
    if (finalizeInFlight) {
      return const LiveSessionGuardVerdict(
        allowed: false,
        reason: 'لا إغلاق طوارئ أثناء finalize',
      );
    }
    if (!session.votingEnabled) {
      return const LiveSessionGuardVerdict(
        allowed: false,
        reason: 'التصويت مغلق بالفعل',
      );
    }
    return LiveSessionGuardVerdict.ok;
  }

  static LiveSessionGuardVerdict validateRuntimeState({
    required MatchActiveSession? session,
    required MatchdayTimelinePhase phase,
    required bool finalizeInFlight,
  }) {
    if (session == null || session.id.isEmpty) {
      return phase == MatchdayTimelinePhase.idle
          ? LiveSessionGuardVerdict.ok
          : const LiveSessionGuardVerdict(
              allowed: false,
              reason: 'تعارض: مرحلة بدون جلسة',
            );
    }
    if (session.awardsFinalized) {
      return phase == MatchdayTimelinePhase.completed
          ? LiveSessionGuardVerdict.ok
          : const LiveSessionGuardVerdict(
              allowed: false,
              reason: 'الجلسة مكتملة — أعد فتح غرفة التحكم',
            );
    }
    if (finalizeInFlight && phase != MatchdayTimelinePhase.finalizing) {
      return const LiveSessionGuardVerdict(
        allowed: false,
        reason: 'finalize نشط لكن المرحلة غير متزامنة',
      );
    }
    return LiveSessionGuardVerdict.ok;
  }

  static LiveSessionGuardVerdict canPublish({
    required MatchActiveSession? existing,
    required MatchdayTimelinePhase phase,
    required bool finalizeInFlight,
  }) {
    final start = canStartSession(
      existing: existing,
      phase: phase,
      finalizeInFlight: finalizeInFlight,
    );
    if (!start.allowed && existing?.votingEnabled == true) {
      return start;
    }
    if (existing != null &&
        existing.awardsFinalized &&
        existing.id.isNotEmpty) {
      return const LiveSessionGuardVerdict(
        allowed: false,
        reason: 'الجلسة مكتملة — أنشئ جلسة جديدة',
      );
    }
    return LiveSessionGuardVerdict.ok;
  }
}
