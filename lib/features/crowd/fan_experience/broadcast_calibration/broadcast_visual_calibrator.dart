import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_color_balance.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_device_profiles.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_finish_quality.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_focus_balance.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_motion_calibrator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_readability_matrix.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_spacing_calibrator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_surface_harmony.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_visual_density.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_atmosphere_layer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/match_night_atmosphere.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/real_validation/real_device_validation_suite.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_state.dart';

/// لقطة معايرة موحّدة للبث.
class BroadcastCalibrationSnapshot extends Equatable {
  const BroadcastCalibrationSnapshot({
    required this.device,
    required this.phase,
    required this.density,
    required this.spacing,
    required this.focus,
    required this.readability,
    required this.color,
    required this.motion,
    required this.harmony,
    required this.finish,
  });

  final BroadcastDeviceProfile device;
  final MatchNightPhase phase;
  final BroadcastDensityTune density;
  final BroadcastSpacingTune spacing;
  final BroadcastFocusBalance focus;
  final BroadcastReadabilityMatrix readability;
  final BroadcastColorBalance color;
  final BroadcastMotionTune motion;
  final BroadcastSurfaceHarmony harmony;
  final BroadcastFinishQuality finish;

  static BroadcastCalibrationSnapshot resolve({
    required Size viewport,
    required MatchNightPhase phase,
    bool hallTabActive = false,
  }) {
    final device = BroadcastDeviceProfiles.resolve(viewport);
    final density = BroadcastDensityTune.forContext(
      device: device,
      phase: phase,
      hallTab: hallTabActive,
    );
    final spacing = BroadcastSpacingTune.forDevice(device);
    final focus = BroadcastFocusBalance.forPhase(phase, hallTab: hallTabActive);
    final readability = BroadcastReadabilityMatrix.forDevice(device);
    final color = BroadcastColorBalance.current();
    final motion = BroadcastMotionTune.forDevice(device);
    final harmony = BroadcastSurfaceHarmony.fromDensity(density);
    final finish = BroadcastFinishQuality.compose(
      focus: focus,
      readability: readability,
      harmony: harmony,
    );
    return BroadcastCalibrationSnapshot(
      device: device,
      phase: phase,
      density: density,
      spacing: spacing,
      focus: focus,
      readability: readability,
      color: color,
      motion: motion,
      harmony: harmony,
      finish: finish,
    );
  }

  double applyDensity(double value, double densityField) =>
      (value * densityField).clamp(0.0, 1.2);

  @override
  List<Object?> get props => [device, phase];
}

class BroadcastCalibrationScope extends InheritedWidget {
  const BroadcastCalibrationScope({
    super.key,
    required this.snapshot,
    required super.child,
  });

  final BroadcastCalibrationSnapshot snapshot;

  static BroadcastCalibrationSnapshot of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<BroadcastCalibrationScope>();
    assert(scope != null, 'BroadcastCalibrationScope missing');
    return scope!.snapshot;
  }

  static BroadcastCalibrationSnapshot? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<BroadcastCalibrationScope>()
        ?.snapshot;
  }

  @override
  bool updateShouldNotify(BroadcastCalibrationScope oldWidget) =>
      oldWidget.snapshot != snapshot;
}

/// نقطة دخول المعايرة — يوفّر [BroadcastCalibrationScope] للشجرة.
class BroadcastVisualCalibrator extends StatelessWidget {
  const BroadcastVisualCalibrator({
    super.key,
    required this.hallTabActive,
    required this.child,
  });

  final bool hallTabActive;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        return BlocSelector<MatchVotingCubit, MatchVotingState, MatchNightPhase>(
          selector: (s) => MatchNightAtmosphere.resolve(
            votingState: s,
            hallTabActive: hallTabActive,
          ),
          builder: (context, phase) {
            final snapshot = BroadcastCalibrationSnapshot.resolve(
              viewport: viewport,
              phase: phase,
              hallTabActive: hallTabActive,
            );
            assert(() {
              RealDeviceValidationSuite.instance.recordBroadcastSnapshot(
                viewport: viewport,
                snapshot: snapshot,
                cinematic: CinematicAtmosphereScope.maybeOf(context),
              );
              return true;
            }());
            return BroadcastCalibrationScope(
              snapshot: snapshot,
              child: child,
            );
          },
        );
      },
    );
  }
}
