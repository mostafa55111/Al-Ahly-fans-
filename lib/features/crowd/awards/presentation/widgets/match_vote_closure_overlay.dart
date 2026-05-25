import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_clock.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/awards_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/match_winner_award.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/identity/club_award_labels.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/fan_experience_haptics.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_atmosphere_layer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_transition_system.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/winner_reveal_surface.dart';

enum _ClosurePhase { hidden, ended, counting, winner, totals }

/// طبقة انتقال بعد تثبيت الجائزة — النتائج النهائية فقط.
class MatchVoteClosureOverlay extends StatefulWidget {
  const MatchVoteClosureOverlay({super.key});

  @override
  State<MatchVoteClosureOverlay> createState() => _MatchVoteClosureOverlayState();
}

class _MatchVoteClosureOverlayState extends State<MatchVoteClosureOverlay> {
  _ClosurePhase _phase = _ClosurePhase.hidden;
  MatchWinnerAward? _winner;
  String? _trackedMatchId;
  Timer? _phaseTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onSessionUpdate(context.read<MatchVotingCubit>().state);
    });
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    super.dispose();
  }

  void _reset() {
    _phaseTimer?.cancel();
    _phase = _ClosurePhase.hidden;
    _winner = null;
    _trackedMatchId = null;
  }

  Future<void> _loadWinner(String matchId, int closedAt) async {
    final club = FanAppIdentity.registryAppId;
    final year = EgyptClock.calendarYear(closedAt);
    final award = await getIt<AwardsRepository>().getMatchAward(
      clubTag: club,
      year: year,
      matchId: matchId,
    );
    if (!mounted) return;
    if (award != null) {
      setState(() => _winner = award);
      _phaseTimer?.cancel();
      _phaseTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _phase = _ClosurePhase.totals);
      });
      setState(() => _phase = _ClosurePhase.winner);
      FanExperienceHaptics.revealPulse();
    }
  }

  void _onSessionUpdate(MatchVotingState state) {
    final session = state.match;
    if (session == null || session.id.isEmpty) {
      _reset();
      return;
    }

    if (!session.awardsFinalized) {
      if (_trackedMatchId != null && session.id != _trackedMatchId) {
        _reset();
      }
      return;
    }

    if (_trackedMatchId == session.id &&
        (_phase == _ClosurePhase.winner ||
            _phase == _ClosurePhase.totals ||
            _phase == _ClosurePhase.counting)) {
      return;
    }

    _trackedMatchId = session.id;
    _phaseTimer?.cancel();
    setState(() => _phase = _ClosurePhase.ended);

    _phaseTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _phase = _ClosurePhase.counting);
      final closedAt = session.closedAtServer > 0
          ? session.closedAtServer
          : session.effectiveClosesAtServer;
      unawaited(_loadWinner(session.id, closedAt));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MatchVotingCubit, MatchVotingState>(
      listenWhen: (p, c) =>
          p.match?.awardsFinalized != c.match?.awardsFinalized ||
          p.match?.id != c.match?.id,
      listener: (context, state) => _onSessionUpdate(state),
      child: BlocBuilder<MatchVotingCubit, MatchVotingState>(
        buildWhen: (p, c) =>
            p.match?.awardsFinalized != c.match?.awardsFinalized,
        builder: (context, _) {
          if (_phase == _ClosurePhase.hidden) return const SizedBox.shrink();

          final id = CrowdAppIdentity.current;
          final cinematic = CinematicAtmosphereScope.maybeOf(context);
          final overlayAlpha = cinematic == null
              ? 0.72
              : (0.62 + cinematic.palette.fieldDarkness * 0.35).clamp(0.55, 0.82);
          return IgnorePointer(
            child: Container(
              color: Colors.black.withValues(alpha: overlayAlpha),
              alignment: Alignment.center,
              child: CinematicTransitionSystem(
                transitionKey: _phase,
                child: _buildPhaseContent(id),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhaseContent(CrowdAppIdentity id) {
    switch (_phase) {
      case _ClosurePhase.ended:
        return _MessageCard(
          key: const ValueKey('ended'),
          title: ClubAwardLabels.votingEndedTitle,
          accent: id.primaryColor,
        );
      case _ClosurePhase.counting:
        return _MessageCard(
          key: const ValueKey('counting'),
          title: ClubAwardLabels.countingMatchTitle,
          accent: id.primaryColor,
        );
      case _ClosurePhase.winner:
        final w = _winner;
        if (w == null) {
          return _MessageCard(
            key: const ValueKey('waiting'),
            title: ClubAwardLabels.countingMatchTitle,
            accent: id.primaryColor,
          );
        }
        return WinnerRevealSurface(
          key: ValueKey('w_${w.matchId}'),
          award: w,
          identity: id,
        );
      case _ClosurePhase.totals:
        final w = _winner;
        if (w == null) {
          return _MessageCard(
            key: const ValueKey('totals_wait'),
            title: ClubAwardLabels.countingMatchTitle,
            accent: id.primaryColor,
          );
        }
        return WinnerRevealSurface(
          key: ValueKey('totals_${w.matchId}'),
          award: w,
          identity: id,
          showTotals: true,
        );
      case _ClosurePhase.hidden:
        return const SizedBox.shrink(key: ValueKey('hidden'));
    }
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({super.key, required this.title, required this.accent});

  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          shadows: [Shadow(color: accent.withValues(alpha: 0.8), blurRadius: 12)],
        ),
      ),
    );
  }
}

