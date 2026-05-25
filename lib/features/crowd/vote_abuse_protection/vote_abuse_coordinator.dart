import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/runtime_health_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_abuse_protection/session_anomaly_detector.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_abuse_protection/vote_cooldown_policy.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_abuse_protection/vote_velocity_guard.dart';

/// واجهة موحّدة لحماية التصويت على العميل.
class VoteAbuseCoordinator {
  VoteAbuseCoordinator({
    required EgyptServerTimeService serverTime,
    VoteVelocityGuard? velocity,
    VoteCooldownPolicy? cooldown,
    SessionAnomalyDetector? anomalies,
  })  : _serverTime = serverTime,
        _velocity = velocity ?? VoteVelocityGuard(),
        _cooldown = cooldown ?? VoteCooldownPolicy(),
        _anomalies = anomalies ?? SessionAnomalyDetector();

  final EgyptServerTimeService _serverTime;
  final VoteVelocityGuard _velocity;
  final VoteCooldownPolicy _cooldown;
  final SessionAnomalyDetector _anomalies;

  void assertCanAttemptCast() {
    final now = _serverTime.serverNowMs;
    if (!_cooldown.canCastNow(now)) {
      RuntimeHealthReport.instance.recordAbuseBlock('cooldown');
      throw StateError('انتظر لحظة قبل المحاولة مرة أخرى');
    }
    if (!_velocity.allowAttempt(now)) {
      _anomalies.flagVoteFlood(votesInWindow: 99);
      RuntimeHealthReport.instance.recordAbuseBlock('velocity');
      throw StateError('محاولات سريعة جداً — حاول بعد ثوانٍ');
    }
  }

  void onVoteConfirmed() {
    _cooldown.markVoteConfirmed(_serverTime.serverNowMs);
  }

  void onDuplicateRejected() {
    _anomalies.flagReplayPattern(duplicateAttempts: 3);
    RuntimeHealthReport.instance.recordAbuseBlock('duplicate');
  }

  SessionAnomalyDetector get anomalies => _anomalies;
}
