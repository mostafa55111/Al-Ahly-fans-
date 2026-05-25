import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/match_night_atmosphere.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_state.dart';

/// يمرّر طور ليلة المباراة للأبناء عبر الـ tree — بدون اشتراكات إضافية.
class StadiumAtmosphereScope extends InheritedWidget {
  const StadiumAtmosphereScope({
    super.key,
    required this.phase,
    required super.child,
  });

  final MatchNightPhase phase;

  static MatchNightPhase of(BuildContext context) {
    return maybeOf(context) ?? MatchNightPhase.preMatch;
  }

  static MatchNightPhase? maybeOf(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<StadiumAtmosphereScope>()
        ?.phase;
  }

  @override
  bool updateShouldNotify(StadiumAtmosphereScope oldWidget) =>
      oldWidget.phase != phase;
}

/// يربط [MatchVotingCubit] بـ [StadiumAtmosphereScope] فقط عند تغيّر الجلسة.
class StadiumAtmosphereController extends StatelessWidget {
  const StadiumAtmosphereController({
    super.key,
    required this.child,
    this.hallTabActive = false,
  });

  final Widget child;
  final bool hallTabActive;

  @override
  Widget build(BuildContext context) {
    final serverNow = getIt.isRegistered<EgyptServerTimeService>()
        ? getIt<EgyptServerTimeService>().serverNowMs
        : null;

    return BlocSelector<MatchVotingCubit, MatchVotingState, MatchNightPhase>(
      selector: (s) => MatchNightAtmosphere.resolve(
        votingState: s,
        hallTabActive: hallTabActive,
        serverNowMs: serverNow,
      ),
      builder: (context, phase) {
        return StadiumAtmosphereScope(phase: phase, child: child);
      },
    );
  }
}
