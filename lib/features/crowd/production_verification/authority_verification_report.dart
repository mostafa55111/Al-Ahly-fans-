import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/finalize_session_response.dart';

class AuthorityFinalizeSample {
  const AuthorityFinalizeSample({
    required this.matchId,
    required this.source,
    required this.response,
    required this.durationMs,
    this.coldStart = false,
  });

  final String matchId;
  final String source;
  final FinalizeSessionResponse response;
  final int durationMs;
  final bool coldStart;
}

class AuthorityVerificationReport {
  AuthorityVerificationReport._();

  static final AuthorityVerificationReport instance =
      AuthorityVerificationReport._();

  int remoteAttempts = 0;
  int remoteSuccess = 0;
  int localFallbacks = 0;
  int hybridMismatches = 0;
  int hybridComparisons = 0;
  int timeouts = 0;
  int coldStarts = 0;
  Duration totalRemoteDuration = Duration.zero;
  Duration totalLocalDuration = Duration.zero;
  final List<AuthorityFinalizeSample> _samples = [];

  void recordRemoteAttempt({
    required String matchId,
    required FinalizeSessionResponse response,
    required Duration duration,
    bool coldStart = false,
  }) {
    if (!kDebugMode) return;
    remoteAttempts++;
    if (response.success) remoteSuccess++;
    if (coldStart) coldStarts++;
    totalRemoteDuration += duration;
    _samples.add(
      AuthorityFinalizeSample(
        matchId: matchId,
        source: 'remote',
        response: response,
        durationMs: duration.inMilliseconds,
        coldStart: coldStart,
      ),
    );
    _trim();
  }

  void recordLocalFinalize({
    required String matchId,
    required FinalizeSessionResponse response,
    required Duration duration,
  }) {
    if (!kDebugMode) return;
    totalLocalDuration += duration;
    _samples.add(
      AuthorityFinalizeSample(
        matchId: matchId,
        source: 'local',
        response: response,
        durationMs: duration.inMilliseconds,
      ),
    );
    _trim();
  }

  void recordLocalFallback(String matchId) {
    if (!kDebugMode) return;
    localFallbacks++;
    debugPrint('[AuthorityVerify] fallback match=$matchId');
  }

  void recordTimeout(String matchId) {
    if (!kDebugMode) return;
    timeouts++;
    debugPrint('[AuthorityVerify] timeout match=$matchId');
  }

  void compareHybrid({
    required String matchId,
    required FinalizeSessionResponse local,
    required FinalizeSessionResponse shadow,
  }) {
    if (!kDebugMode) return;
    hybridComparisons++;
    final match = local.success == shadow.success &&
        local.alreadyFinalized == shadow.alreadyFinalized &&
        local.snapshotWritten == shadow.snapshotWritten;
    if (!match) {
      hybridMismatches++;
      debugPrint(
        '[AuthorityVerify] CRITICAL hybrid mismatch match=$matchId '
        'local=${local.toJson()} shadow=${shadow.toJson()}',
      );
    }
  }

  double get remoteSuccessRate =>
      remoteAttempts <= 0 ? 0 : remoteSuccess / remoteAttempts;

  double get averageRemoteMs =>
      remoteAttempts <= 0
          ? 0
          : totalRemoteDuration.inMilliseconds / remoteAttempts;

  Map<String, dynamic> snapshot() {
    if (!kDebugMode) return const {};
    return {
      'remoteAttempts': remoteAttempts,
      'remoteSuccessRate': remoteSuccessRate,
      'localFallbacks': localFallbacks,
      'hybridComparisons': hybridComparisons,
      'hybridMismatches': hybridMismatches,
      'timeouts': timeouts,
      'coldStarts': coldStarts,
      'averageRemoteMs': averageRemoteMs,
      'recentSamples': _samples.length,
    };
  }

  void _trim() {
    if (_samples.length > 80) _samples.removeRange(0, _samples.length - 80);
  }

  @visibleForTesting
  void reset() {
    remoteAttempts = 0;
    remoteSuccess = 0;
    localFallbacks = 0;
    hybridMismatches = 0;
    hybridComparisons = 0;
    timeouts = 0;
    coldStarts = 0;
    totalRemoteDuration = Duration.zero;
    totalLocalDuration = Duration.zero;
    _samples.clear();
  }
}
