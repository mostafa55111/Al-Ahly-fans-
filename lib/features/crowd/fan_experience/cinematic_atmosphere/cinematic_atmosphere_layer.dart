import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_depth_fx.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_focus_orchestrator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_match_state_palette.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_transition_system.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_visibility_policy.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/match_night_atmosphere.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_calibration_exports.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/real_validation/real_device_validation_suite.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_state.dart';

/// لقطة جو سينمائي — من [MatchVotingCubit] الحالي فقط.
class CinematicAtmosphereSnapshot extends Equatable {
  const CinematicAtmosphereSnapshot({
    required this.phase,
    required this.palette,
    required this.focus,
    required this.visibility,
  });

  final MatchNightPhase phase;
  final CinematicMatchPalette palette;
  final CinematicFocusSnapshot focus;
  final CinematicVisibilityPolicy visibility;

  static CinematicAtmosphereSnapshot resolve({
    required MatchVotingState votingState,
    required bool hallTabActive,
    int? serverNowMs,
  }) {
    final phase = MatchNightAtmosphere.resolve(
      votingState: votingState,
      hallTabActive: hallTabActive,
      serverNowMs: serverNowMs,
    );
    final palette = CinematicMatchPalette.forPhase(phase);
    final focus = CinematicFocusOrchestrator.resolve(
      phase: phase,
      myVotedPlayerId: votingState.myVotedPlayerId,
      leadingPlayerId: votingState.maskLiveCompetitive
          ? null
          : votingState.leadingPlayerId,
      maskLiveCompetitive: votingState.maskLiveCompetitive,
      hallTabActive: hallTabActive,
    );
    final visibility = CinematicVisibilityPolicy.forContext(
      phase: phase,
      focus: focus,
    );
    return CinematicAtmosphereSnapshot(
      phase: phase,
      palette: palette,
      focus: focus,
      visibility: visibility,
    );
  }

  @override
  List<Object?> get props => [phase, focus, visibility];
}

class CinematicAtmosphereScope extends InheritedWidget {
  const CinematicAtmosphereScope({
    super.key,
    required this.snapshot,
    required super.child,
  });

  final CinematicAtmosphereSnapshot snapshot;

  static CinematicAtmosphereSnapshot of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<CinematicAtmosphereScope>();
    assert(scope != null, 'CinematicAtmosphereScope missing');
    return scope!.snapshot;
  }

  static CinematicAtmosphereSnapshot? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CinematicAtmosphereScope>()
        ?.snapshot;
  }

  @override
  bool updateShouldNotify(CinematicAtmosphereScope oldWidget) =>
      oldWidget.snapshot != snapshot;
}

/// Foundation → Depth FX → المحتوى (تكتيكي + تصويت).
class CinematicAtmosphereLayer extends StatelessWidget {
  const CinematicAtmosphereLayer({
    super.key,
    required this.hallTabActive,
    required this.child,
  });

  final bool hallTabActive;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final serverNow = getIt.isRegistered<EgyptServerTimeService>()
        ? getIt<EgyptServerTimeService>().serverNowMs
        : null;

    return BlocSelector<MatchVotingCubit, MatchVotingState,
        CinematicAtmosphereSnapshot>(
      selector: (s) => CinematicAtmosphereSnapshot.resolve(
        votingState: s,
        hallTabActive: hallTabActive,
        serverNowMs: serverNow,
      ),
      builder: (context, snapshot) {
        assert(() {
          final viewport = MediaQuery.sizeOf(context);
          final broadcast = BroadcastCalibrationSnapshot.resolve(
            viewport: viewport,
            phase: snapshot.phase,
            hallTabActive: hallTabActive,
          );
          RealDeviceValidationSuite.instance.recordBroadcastSnapshot(
            viewport: viewport,
            snapshot: broadcast,
            cinematic: snapshot,
          );
          return true;
        }());
        return CinematicAtmosphereScope(
          snapshot: snapshot,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CinematicDepthFx(palette: snapshot.palette),
              ),
              CinematicTransitionSystem(
                transitionKey: snapshot.phase,
                child: child,
              ),
            ],
          ),
        );
      },
    );
  }
}
