import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/presentation/cubit/crowd_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/presentation/cubit/crowd_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_foundation/stadium_foundation_safe_layout.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_formation_layout.dart';
import 'package:gomhor_alahly_clean_new/features/public_arena/presentation/cubit/squad_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/public_arena/presentation/cubit/squad_state.dart';

/// خلفية الملعب الرسمية + طبقة علوية تتبع [SquadCubit] / [CrowdCubit].
class SquadFieldPage extends StatelessWidget {
  const SquadFieldPage({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StadiumFoundationSafeLayout(
      applySafeAreaToChild: false,
      child: TacticalFormationLayout(
        formation: '4-3-3',
        child: RepaintBoundary(child: _SquadStreamDiagnostics(child: child)),
      ),
    );
  }
}

class _SquadStreamDiagnostics extends StatelessWidget {
  const _SquadStreamDiagnostics({required this.child});

  final Widget child;

  static SquadCubit? _trySquadCubit(BuildContext context) {
    try {
      return BlocProvider.of<SquadCubit>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  static CrowdCubit? _tryCrowdCubit(BuildContext context) {
    try {
      return BlocProvider.of<CrowdCubit>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_trySquadCubit(context) != null) {
      return BlocBuilder<SquadCubit, SquadState>(
        buildWhen: (p, c) => p != c,
        builder: (context, s) {
          if (kDebugMode) {
            debugPrint(
              '[SquadFieldPage] live RTDB via SquadCubit | players=${s.players.length} '
              'loading=${s.loading} err=${s.error}',
            );
          }
          return child;
        },
      );
    }
    if (_tryCrowdCubit(context) != null) {
      return BlocBuilder<CrowdCubit, CrowdState>(
        buildWhen: (p, c) => p != c,
        builder: (context, s) {
          if (kDebugMode) {
            debugPrint(
              '[SquadFieldPage] live RTDB via CrowdCubit | players=${s.players.length} '
              'loading=${s.loading}',
            );
          }
          return child;
        },
      );
    }
    return child;
  }
}
