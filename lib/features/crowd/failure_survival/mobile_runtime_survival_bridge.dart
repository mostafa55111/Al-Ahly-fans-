import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/durable_vote_intent_queue.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/failure_survival_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/infrastructure_degradation_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_votes_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/network_resilience/lazy_vote_subscription_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/background_runtime_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef VoteCastExecutor = Future<void> Function({
  required String clubTag,
  required String matchId,
  required String playerId,
  required String uid,
});

/// جسر بقاء التشغيل على الجوال — lifecycle بدون عاصفة reconnect.
class MobileRuntimeSurvivalBridge {
  MobileRuntimeSurvivalBridge._();

  static final MobileRuntimeSurvivalBridge instance =
      MobileRuntimeSurvivalBridge._();

  bool _restoreInFlight = false;

  void onLifecycle(
    AppLifecycleState state, {
    required BuildContext? context,
    required String clubTag,
    VoteCastExecutor? castVote,
  }) {
    final lazy = LazyVoteSubscriptionController.instance;
    final degradation = InfrastructureDegradationResolver.instance;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        BackgroundRuntimePolicy.instance.onAppBackgrounded();
        degradation.resolve(
          degradation.collectLiveSignals(
            recoveryQueueDepth: _queueDepth(),
          ),
        );
        break;
      case AppLifecycleState.detached:
        BackgroundRuntimePolicy.instance.onAppBackgrounded();
        lazy.cancelRestore();
        unawaited(_flushPendingIntents(clubTag: clubTag, castVote: castVote));
        break;
      case AppLifecycleState.resumed:
        BackgroundRuntimePolicy.instance.onAppForegrounded();
        degradation.resolve(degradation.collectLiveSignals());
        if (context != null && context.mounted && !_restoreInFlight) {
          _restoreInFlight = true;
          unawaited(
            _phasedResume(
              context: context,
              clubTag: clubTag,
              castVote: castVote,
            ).whenComplete(() => _restoreInFlight = false),
          );
        }
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _phasedResume({
    required BuildContext context,
    required String clubTag,
    VoteCastExecutor? castVote,
  }) async {
    final lazy = LazyVoteSubscriptionController.instance;
    final degradation = InfrastructureDegradationResolver.instance;
    if (degradation.allowPhasedRestoreOnly) {
      degradation.recordReconnectSuppression();
    }
    await lazy.schedulePhasedRestore(
      appResumed: true,
      restoreLight: () async {
        if (context.mounted) {
          context.read<MatchVotingCubit>().start(phasedRestore: true);
        }
      },
      restoreHeavy: () async {},
    );
    await _replayVoteIntents(clubTag: clubTag, castVote: castVote);
  }

  Future<void> _flushPendingIntents({
    required String clubTag,
    VoteCastExecutor? castVote,
  }) async {
    if (!getIt.isRegistered<SharedPreferences>()) return;
    final queue = DurableVoteIntentQueue(getIt<SharedPreferences>());
    FailureSurvivalRuntimeReport.instance.recordQueueDepth(queue.load().length);
    if (castVote == null) return;
    await _replayVoteIntents(clubTag: clubTag, castVote: castVote, queue: queue);
  }

  Future<void> _replayVoteIntents({
    required String clubTag,
    VoteCastExecutor? castVote,
    DurableVoteIntentQueue? queue,
  }) async {
    if (castVote == null) return;
    if (!getIt.isRegistered<SharedPreferences>() ||
        !getIt.isRegistered<MatchVotesRepository>() ||
        !getIt.isRegistered<EgyptServerTimeService>()) {
      return;
    }
    final q = queue ?? DurableVoteIntentQueue(getIt<SharedPreferences>());
    final votes = getIt<MatchVotesRepository>();
    final serverTime = getIt<EgyptServerTimeService>();
    final sw = Stopwatch()..start();
    try {
      await serverTime.refreshOffset();
      final bundle = await votes.getBundle(clubTag);
      final session = bundle.match;
      final now = serverTime.serverNowMs;
      final due = q.dueForReplay(
        serverNowMs: now,
        session: session,
        userAlreadyVoted: (intent) => false,
      );
      for (final intent in due) {
        if (intent.clubTag.trim().toLowerCase() != clubTag.trim().toLowerCase()) {
          continue;
        }
        try {
          await castVote(
            clubTag: intent.clubTag,
            matchId: intent.matchId,
            playerId: intent.playerId,
            uid: intent.uid,
          );
          await q.remove(intent.operationId);
          FailureSurvivalRuntimeReport.instance.recordRecoveredVoteIntent();
        } catch (_) {
          await q.enqueue(intent.bumpRetry());
        }
      }
    } finally {
      sw.stop();
      FailureSurvivalRuntimeReport.instance
          .recordReplayRecoveryMs(sw.elapsedMilliseconds);
    }
  }

  int _queueDepth() {
    if (!getIt.isRegistered<SharedPreferences>()) return 0;
    return DurableVoteIntentQueue(getIt<SharedPreferences>()).load().length;
  }
}
