import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/time/app_clock_bootstrap.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/domain/repositories/crowd_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/awards_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/presentation/cubit/hall_of_fame_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/services/voting_session_lifecycle_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_votes_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/crowd_production_bootstrap.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/cold_start_audit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/presentation/cubit/crowd_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/presentation/widgets/crowd_fan_immersive_shell.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/mobile_runtime_survival_bridge.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/runtime/crowd_navigation_runtime_guard.dart';
import 'package:gomhor_alahly_clean_new/features/public_arena/presentation/cubit/squad_cubit.dart';

/// شاشة الجمهور — ملعب ملء الشاشة، تصويت نسر المباراة على الكروت، وعرض النسور.
class CrowdScreen extends StatelessWidget {
  const CrowdScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CrowdCubit(
            repository: getIt<CrowdRepository>(),
            serverTime: getIt<EgyptServerTimeService>(),
            auth: getIt<FirebaseAuth>(),
          )..init(),
        ),
        BlocProvider(
          create: (_) => SquadCubit(FirebaseDatabase.instance)..start(),
        ),
        BlocProvider(
          create: (_) => MatchVotingCubit(
            repository: getIt<MatchVotesRepository>(),
            auth: getIt<FirebaseAuth>(),
            serverTime: getIt<EgyptServerTimeService>(),
            clubTag: FanAppIdentity.registryAppId,
          )..start(),
        ),
        BlocProvider(
          create: (_) => HallOfFameCubit(
            awardsRepository: getIt<AwardsRepository>(),
            lifecycle: getIt<VotingSessionLifecycleService>(),
            clubTag: FanAppIdentity.registryAppId,
          ),
        ),
      ],
      child: _CrowdRouteMountGuard(
        child: _CrowdAwardsLifecycle(
          child: _CrowdLifecycleSessionFeed(
            child: CrowdFanImmersiveShell(
              initialTopTab: initialTabIndex >= 2 ? 1 : 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _CrowdRouteMountGuard extends StatefulWidget {
  const _CrowdRouteMountGuard({required this.child});

  final Widget child;

  @override
  State<_CrowdRouteMountGuard> createState() => _CrowdRouteMountGuardState();
}

class _CrowdRouteMountGuardState extends State<_CrowdRouteMountGuard> {
  final Stopwatch _hydrationSw = Stopwatch();

  @override
  void initState() {
    super.initState();
    _hydrationSw.start();
    CrowdNavigationRuntimeGuard.instance.registerCrowdScreenMount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ColdStartAudit.instance.recordStopwatch(
        'crowd_screen_hydration',
        _hydrationSw,
      );
    });
  }

  @override
  void dispose() {
    CrowdNavigationRuntimeGuard.instance.unregisterCrowdScreenMount();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _CrowdAwardsLifecycle extends StatefulWidget {
  const _CrowdAwardsLifecycle({required this.child});

  final Widget child;

  @override
  State<_CrowdAwardsLifecycle> createState() => _CrowdAwardsLifecycleState();
}

class _CrowdAwardsLifecycleState extends State<_CrowdAwardsLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getIt<VotingSessionLifecycleService>().start();
    unawaited(CrowdProductionBootstrap.initialize());
    if (AppClockBootstrap.isInitialized) {
      unawaited(
        AppClockBootstrap.refreshOnResume(getIt<EgyptServerTimeService>()),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        AppClockBootstrap.refreshOnResume(getIt<EgyptServerTimeService>()),
      );
    }
    MobileRuntimeSurvivalBridge.instance.onLifecycle(
      state,
      context: mounted ? context : null,
      clubTag: FanAppIdentity.registryAppId,
      castVote: getIt.isRegistered<MatchVotesRepository>()
          ? ({
              required String clubTag,
              required String matchId,
              required String playerId,
              required String uid,
            }) =>
              getIt<MatchVotesRepository>().castVoteImmutableTransaction(
                clubTag: clubTag,
                matchId: matchId,
                playerId: playerId,
                uid: uid,
              )
          : null,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    getIt<VotingSessionLifecycleService>().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// يغذي lifecycle من بث الجلسة الوحيد (MatchVotingCubit) — بدون listener مكرر.
class _CrowdLifecycleSessionFeed extends StatelessWidget {
  const _CrowdLifecycleSessionFeed({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<MatchVotingCubit, MatchVotingState>(
      listenWhen: (prev, next) {
        final pm = prev.match;
        final nm = next.match;
        if (pm?.id != nm?.id) return true;
        if (pm?.awardsFinalized != nm?.awardsFinalized) return true;
        if (pm?.effectiveClosesAtServer != nm?.effectiveClosesAtServer) {
          return true;
        }
        if (pm?.votingEnabled != nm?.votingEnabled) return true;
        return false;
      },
      listener: (context, state) {
        getIt<VotingSessionLifecycleService>()
            .notifyActiveSession(state.match);
      },
      child: child,
    );
  }
}
