import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter; // ignore: unused_import — BackdropFilter

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/identity/club_award_labels.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/match_vote_confirmation_dialog.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/crowd_collective_pulse_layer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/crowd_reaction_stream_layer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/presentation/widgets/fan_presence_aura.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/presentation/widgets/fan_presence_hud.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/floating_substitutes_panel.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/match_vote_percent_ring.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_bench_rail.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_card_anchor.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_card_focus_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_formation_layout.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_position_map.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_calibration_exports.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_atmosphere_layer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_breathing_motion.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_overlay_balance.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_spacing_system.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/stadium_vote_shell_vm.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/stadium_crowd_atmosphere_layer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/stadium_fx_engine.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/animation_budget_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_audio_engine.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_card_runtime_band.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_intensity_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_momentum_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_rebuild_counters.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_runtime_debug_hud.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_runtime_guards.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_runtime_overlay_registrar.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_runtime_telemetry_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_network/crowd_sync_engine.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/fan_presence/fan_presence_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/fan_presence/fan_presence_store.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/runtime/stream_lifecycle_audit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/overlay_runtime_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/fan_experience_haptics.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/fifa_card_hero_surface.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_visual_tokens.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_broadcast_layout.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_club_header_chip.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/vote_focus_animation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/widgets/match_voting_idle_surface.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/presentation/widgets/crowd_vote_loading_gate.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/fifa_card_widget.dart';

Color _glowForLayout(_PitchLayoutSlice p, CrowdAppIdentity id) {
  final g = p.glowColor.trim().toLowerCase();
  if (g == 'red' || g == 'ahly') return id.primaryColor;
  if (g == 'blue') return id.secondaryColor;
  if (g == 'white') return Colors.white70;
  return id.accentGlow;
}

MatchPitchPlayer _playerFromSlices(_PitchLayoutSlice L, _PitchCardSlice C) {
  return MatchPitchPlayer(
    id: L.id,
    name: L.name,
    imageUrl: L.imageUrl,
    rating: L.rating,
    position: L.position,
    x: L.nx,
    y: L.ny,
    votes: C.votes,
    team: '',
    glowColor: L.glowColor,
    visible: true,
    highlighted: L.highlighted,
    cardImageUrl: L.cardImageUrl,
    cardThumbnailUrl: L.cardThumbnailUrl,
    cardStyle: L.cardStyle,
    cardRarity: L.cardRarity,
    cardAnimatedOverlay: L.cardAnimatedOverlay,
    cardTheme: L.cardTheme,
    cardOverlayAssetUrl: L.cardOverlayAssetUrl,
    cardOverlayEnabled: L.cardOverlayEnabled,
    cardOverlayBlend: L.cardOverlayBlend,
    cardOverlayOpacity: L.cardOverlayOpacity,
  );
}

class _PitchLayoutSlice extends Equatable {
  const _PitchLayoutSlice({
    required this.id,
    required this.nx,
    required this.ny,
    required this.highlighted,
    required this.imageUrl,
    required this.name,
    required this.position,
    required this.glowColor,
    required this.rating,
    required this.cardImageUrl,
    required this.cardThumbnailUrl,
    required this.cardStyle,
    required this.cardRarity,
    required this.cardAnimatedOverlay,
    required this.cardTheme,
    required this.cardOverlayAssetUrl,
    required this.cardOverlayEnabled,
    required this.cardOverlayBlend,
    required this.cardOverlayOpacity,
  });

  final String id;
  final double nx;
  final double ny;
  final bool highlighted;
  final String imageUrl;
  final String name;
  final String position;
  final String glowColor;
  final int rating;
  final String cardImageUrl;
  final String cardThumbnailUrl;
  final String cardStyle;
  final String cardRarity;
  final String cardAnimatedOverlay;
  final String cardTheme;
  final String cardOverlayAssetUrl;
  final bool cardOverlayEnabled;
  final String cardOverlayBlend;
  final double cardOverlayOpacity;

  static _PitchLayoutSlice? read(MatchVotingState s, String playerId) {
    MatchPitchPlayer? p;
    for (final e in s.players) {
      if (e.id == playerId && e.visible) {
        p = e;
        break;
      }
    }
    if (p == null) return null;
    return _PitchLayoutSlice(
      id: p.id,
      nx: p.x.clamp(0.04, 0.96),
      ny: p.y.clamp(0.06, 0.94),
      highlighted: p.highlighted,
      imageUrl: p.imageUrl,
      name: p.name,
      position: p.position,
      glowColor: p.glowColor,
      rating: p.rating,
      cardImageUrl: p.cardImageUrl,
      cardThumbnailUrl: p.cardThumbnailUrl,
      cardStyle: p.cardStyle,
      cardRarity: p.cardRarity,
      cardAnimatedOverlay: p.cardAnimatedOverlay,
      cardTheme: p.cardTheme,
      cardOverlayAssetUrl: p.cardOverlayAssetUrl,
      cardOverlayEnabled: p.cardOverlayEnabled,
      cardOverlayBlend: p.cardOverlayBlend,
      cardOverlayOpacity: p.cardOverlayOpacity,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nx,
        ny,
        highlighted,
        imageUrl,
        name,
        position,
        glowColor,
        rating,
        cardImageUrl,
        cardThumbnailUrl,
        cardStyle,
        cardRarity,
        cardAnimatedOverlay,
        cardTheme,
        cardOverlayAssetUrl,
        cardOverlayEnabled,
        cardOverlayBlend,
        cardOverlayOpacity,
      ];
}

class _PitchCardSlice extends Equatable {
  const _PitchCardSlice({
    required this.id,
    required this.votes,
    required this.totalVotes,
    required this.myVotedPlayerId,
    required this.leadingPlayerId,
    required this.votingEnabled,
    required this.hasMatch,
  });

  final String id;
  final int votes;
  final int totalVotes;
  final String? myVotedPlayerId;
  final String? leadingPlayerId;
  final bool votingEnabled;
  final bool hasMatch;

  bool get isLeader => leadingPlayerId == id && totalVotes > 0;
  bool get isSelected => myVotedPlayerId == id;
  double get pct => totalVotes > 0 ? votes / totalVotes * 100 : 0.0;

  static _PitchCardSlice? read(MatchVotingState s, String playerId) {
    MatchPitchPlayer? p;
    for (final e in s.players) {
      if (e.id == playerId && e.visible) {
        p = e;
          break;
        }
      }
    if (p == null) return null;
    final has = s.match != null && s.match!.id.isNotEmpty;
    return _PitchCardSlice(
      id: p.id,
      votes: p.votes,
      totalVotes: s.totalVotes,
      myVotedPlayerId: s.myVotedPlayerId,
      leadingPlayerId: s.leadingPlayerId,
      votingEnabled: s.match?.votingEnabled ?? false,
      hasMatch: has,
    );
  }

  @override
  List<Object?> get props =>
      [id, votes, totalVotes, myVotedPlayerId, leadingPlayerId, votingEnabled, hasMatch];
}

class _Floater {
  _Floater({required this.emoji, required this.dx, required this.dy});
  final String emoji;
  final double dx;
  final double dy;
}

class _StadiumPitchPlayerOrb extends StatelessWidget {
  const _StadiumPitchPlayerOrb({
    super.key,
    required this.playerId,
    required this.slotIndex,
    required this.identity,
    required this.cardW,
    required this.cardH,
    required this.w,
    required this.h,
    required this.votePulse,
    required this.motionPhase01,
    required this.pulseN,
    required this.shakeN,
    required this.effectiveBudget,
    required this.runtimeGuards,
    required this.crowdIntensity,
    required this.shell,
    required this.onTap,
    required this.fanPresence,
    required this.breathPhase01,
  });

  final String playerId;
  final int slotIndex;
  final CrowdAppIdentity identity;
  final double cardW;
  final double cardH;
  final double w;
  final double h;
  final double votePulse;
  final double motionPhase01;
  final ValueNotifier<int> pulseN;
  final ValueNotifier<int> shakeN;
  final CrowdAnimationBudget effectiveBudget;
  final CrowdRuntimeGuards runtimeGuards;
  final double crowdIntensity;
  final StadiumVoteShellVm shell;
  final Future<void> Function(MatchPitchPlayer p, StadiumVoteShellVm shell, CrowdAppIdentity id) onTap;
  final FanPresenceController fanPresence;
  final double breathPhase01;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MatchVotingCubit, MatchVotingState, _PitchLayoutSlice?>(
      selector: (s) => _PitchLayoutSlice.read(s, playerId),
      builder: (context, layout) {
        if (layout == null) return const SizedBox.shrink();
        final layoutData = TacticalLayoutScope.of(context);
        final pos = TacticalFormationLayout.cardTopLeft(
          data: layoutData,
          nx: layout.nx,
          ny: layout.ny,
          slotIndex: slotIndex,
          cardW: cardW,
          cardH: cardH,
        );
        final left = pos.left;
        final top = pos.top;
        return KeyedSubtree(
          key: ValueKey('mv_${layout.id}'),
          child: Positioned(
            left: left,
            top: top,
            child: BlocSelector<MatchVotingCubit, MatchVotingState, _PitchCardSlice?>(
              selector: (s) => _PitchCardSlice.read(s, playerId),
              builder: (context, card) {
                if (card == null) return const SizedBox.shrink();
                final matchStatus = context.select(
                  (MatchVotingCubit c) => c.state.match?.status ?? 'open',
                );
                return ValueListenableBuilder<int>(
                  valueListenable: pulseN,
                  builder: (context, _, __) {
                    return ValueListenableBuilder<int>(
                      valueListenable: shakeN,
                      builder: (context, ___, ____) {
                        final glow = _glowForLayout(layout, identity);
                        final leader =
                            !shell.maskLiveCompetitive && card.isLeader;
                        final selected = card.isSelected;
                        final pct = card.pct;
                        final votingOpen = shell.votingEnabled && shell.myVotedPlayerId == null;
                        final voteLocked = shell.myVotedPlayerId != null &&
                            shell.myVotedPlayerId!.isNotEmpty;
                        final tokens = StadiumVisualTokens.of(identity);
                        final band = resolveCrowdCardRuntimeBand(
                          playerId: layout.id,
                          leadingPlayerId: shell.leadingPlayerId,
                          myVotedPlayerId: shell.myVotedPlayerId,
                          slotIndex: slotIndex,
                          totalVotes: shell.totalVotes,
                        );
                        var cardBudget = effectiveBudget;
                        if (band == CrowdCardRuntimeBand.background) {
                          cardBudget = stricterCrowdAnimationBudget(
                            cardBudget,
                            CrowdAnimationBudget.reduced,
                          );
                        }
                        if (band == CrowdCardRuntimeBand.background && runtimeGuards.strongDegrade) {
                          cardBudget = stricterCrowdAnimationBudget(
                            cardBudget,
                            CrowdAnimationBudget.minimal,
                          );
                        }
                        final suppressAnimatedAsset = band == CrowdCardRuntimeBand.background &&
                            (runtimeGuards.strongDegrade ||
                                cardBudget == CrowdAnimationBudget.minimal);
                        final mp = cardBudget == CrowdAnimationBudget.minimal ? null : motionPhase01;
                        final focus = TacticalCardFocusState.resolve(
                          votingOpen: votingOpen,
                          selected: selected,
                          voteLocked: voteLocked,
                          isLeader: leader,
                          maskLiveCompetitive: shell.maskLiveCompetitive,
                          matchStatus: matchStatus,
                          votingEnabled: shell.votingEnabled,
                        );
                        final cinematic = CinematicAtmosphereScope.maybeOf(context);
                        final broadcast = BroadcastCalibrationScope.maybeOf(context);
                        var cinematicMul = cinematic == null
                            ? 1.0
                            : CinematicOverlayBalance.cardDominanceGuard(
                                cinematic.visibility.cardOpacityFor(
                                  layout.id,
                                  cinematic.focus,
                                ),
                              );
                        if (broadcast != null) {
                          final focused = cinematic?.focus
                                  .isPlayerFocused(layout.id) ??
                              shell.myVotedPlayerId == layout.id;
                          final broadcastOp = broadcast.focus.cardOpacityFor(
                            isFocused: focused,
                          );
                          cinematicMul = focused
                              ? cinematicMul.clamp(broadcastOp, 1.0)
                              : (cinematicMul * broadcastOp)
                                  .clamp(0.55, 0.95);
                          cinematicMul *= broadcast.density.cardProminence;
                          cinematicMul = broadcast.finish.polish(cinematicMul);
                        }
                        final breatheCard = cinematic != null &&
                            cinematic.visibility.allowCardBreathing &&
                            cinematic.focus.isPlayerFocused(layout.id);

                        final pModel = _playerFromSlices(layout, card);
                        final dto = pModel.toPastPlayerDto();
                        final preserveDesignedArt = layout.cardImageUrl.trim().isNotEmpty;

                        Widget cardStack = SizedBox(
                          width: cardW + 24,
                          height: cardH + 20,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              if ((votingOpen || selected) &&
                                  (broadcast?.density.glowVisibility ?? 1.0) >
                                      0.72)
                                VoteCardGlowRing(
                                  color: selected ? tokens.cardGlow : glow,
                                  width: cardW,
                                  height: cardH,
                                  breathPhase01: breathPhase01,
                                  enabled: !preserveDesignedArt,
                                ),
                              if (selected &&
                                  !shell.maskLiveCompetitive &&
                                  shell.totalVotes > 0)
                                Positioned(
                                  width: cardW + 26,
                                  height: cardH + 26,
                                  child: CrowdRuntimeOverlayRegistrar(
                                    id: 'vote_ring_${layout.id}',
                                    kind: CrowdOverlayKind.voteRing,
                                    heavyAnimated: false,
                                    child: CrowdRebuildProbe(
                                      label: 'VoteRing',
                                      child: MatchVotePercentRing(
                                        percent: pct,
                                        size: cardW + 26,
                                        color: glow,
                                      ),
                                    ),
                                  ),
                                ),
                              Opacity(
                                opacity: cinematicMul,
                                child: CinematicBreathingMotion(
                                  enabled: breatheCard,
                                  child: TacticalCardAnchor(
                                width: cardW,
                                height: cardH,
                                accentColor: glow,
                                focus: focus,
                                emphasizeForward:
                                    TacticalPositionMap.isForwardSlot(slotIndex),
                                child: CrowdRebuildProbe(
                                  label: 'PlayerCard',
                                  child: FifaCardHeroSurface(
                                    playerName: layout.name,
                                    position: layout.position,
                                    votingOpen: votingOpen,
                                    selected: selected,
                                    locked: voteLocked,
                                    width: cardW,
                                    height: cardH,
                                    onTap: votingOpen
                                        ? () {
                                            FanExperienceHaptics.voteTap();
                                            onTap(pModel, shell, identity);
                                          }
                                        : null,
                                    child: FifaCardWidget(
                                      player: dto,
                                      width: cardW,
                                      height: cardH,
                                      highlighted: votingOpen,
                                      selected: selected,
                                      isVotingMode: true,
                                      pulseTrigger: pulseN.value,
                                      shakeTrigger: shakeN.value,
                                      onTap: null,
                                      stadiumUltraMode: true,
                                      motionPhase01: mp,
                                      liveVotePercent: shell.maskLiveCompetitive
                                          ? null
                                          : (shell.totalVotes > 0 ? pct : null),
                                      liveVotesCount:
                                          shell.maskLiveCompetitive ? null : card.votes,
                                      isVoteLeader: leader,
                                      brandPrimary: identity.primaryColor,
                                      brandSecondary: identity.secondaryColor,
                                      stadiumCrowdIntensity: crowdIntensity,
                                      stadiumFxBudget: cardBudget,
                                      stadiumSlotIndex: slotIndex,
                                      stadiumSuppressAnimatedAsset: suppressAnimatedAsset,
                                      stadiumTelemetryAssetOverlayId: 'asset_${layout.id}',
                                      stadiumLeaderPresence: leader,
                                      stadiumMyPickEmotion:
                                          selected && shell.myVotedPlayerId != null,
                                      stadiumDesignedVoteCleanSurface:
                                          dto.matchVoteDesignedCard,
                                    ),
                                  ),
                                ),
                              ),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (selected &&
                            fanPresence.isActive &&
                            shell.myVotedPlayerId == layout.id) {
                          cardStack = FanPresenceAuraRing(
                            aura: fanPresence.aura,
                            accent: identity.primaryColor,
                            phase01: motionPhase01,
                            enabled: cardBudget != CrowdAnimationBudget.minimal,
                            child: cardStack,
                          );
                        }

                        cardStack = RepaintBoundary(child: cardStack);

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            cardStack,
                          ],
                        )
                            .animate()
                            .fadeIn(duration: 240.ms, delay: (20 * slotIndex).ms)
                            .slideY(begin: 0.04, curve: Curves.easeOutCubic);
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// طبقة الملعب الرئيسية لتصويت المباراة (RTDB).
class MatchStadiumVotingLayer extends StatefulWidget {
  const MatchStadiumVotingLayer({super.key});

  @override
  State<MatchStadiumVotingLayer> createState() => _MatchStadiumVotingLayerState();
}

class _MatchStadiumVotingLayerState extends State<MatchStadiumVotingLayer>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final Map<String, ValueNotifier<int>> _pulseNs = {};
  final Map<String, ValueNotifier<int>> _shakeNs = {};
  final Set<String> _lastPlayerIds = {};

  CrowdAudioEngine? _audio;
  late final AnimationController _lightPhase;
  late final AnimationController _votePulse;
  final ValueNotifier<String?> _banner = ValueNotifier<String?>(null);
  Timer? _bannerTimer;
  String? _lastLeadId;
  final List<_Floater> _floaters = [];

  final CrowdIntensityController _intensity = CrowdIntensityController();
  final CrowdAnimationBudgetController _budget = CrowdAnimationBudgetController();
  final CrowdRuntimeGuards _runtimeGuards = CrowdRuntimeGuards();
  final CrowdVoteMomentumController _voteMomentum = CrowdVoteMomentumController();
  final ValueNotifier<List<CrowdFloatingReaction>> _emotionReactions =
      ValueNotifier<List<CrowdFloatingReaction>>(<CrowdFloatingReaction>[]);
  int _emotionSeq = 0;
  late final FanPresenceController _fanPresence;
  final CrowdSyncEngine _crowdSync = CrowdSyncEngine();

  @override
  bool get wantKeepAlive => true;

  ValueNotifier<int> _pulseFor(String id) =>
      _pulseNs.putIfAbsent(id, () => ValueNotifier<int>(0));

  ValueNotifier<int> _shakeFor(String id) =>
      _shakeNs.putIfAbsent(id, () => ValueNotifier<int>(0));

  void _pruneNotifiers(Set<String> active) {
    for (final id in _lastPlayerIds.difference(active)) {
      _pulseNs.remove(id)?.dispose();
      _shakeNs.remove(id)?.dispose();
    }
    _lastPlayerIds
      ..clear()
      ..addAll(active);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fanPresence = FanPresenceController(
      store: FanPresenceStore(
        prefs: getIt<SharedPreferences>(),
        database: FirebaseDatabase.instance,
        clubTag: FanAppIdentity.registryAppId,
      ),
      isAhlyClub: FanAppIdentity.registryAppId == 'ahly',
    );
    unawaited(_fanPresence.bind(FirebaseAuth.instance.currentUser?.uid));
    CrowdRuntimeTelemetryService.instance.acquire();
    _budget.attach();
    _audio = CrowdAudioEngine();
    _runtimeGuards.start(audio: _audio);
    unawaited(_audio!.startAmbienceLoop());
    _lightPhase = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _votePulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 720))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _votePulse.reset();
        }
      });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _runtimeGuards.dispose();
    _fanPresence.dispose();
    _voteMomentum.dispose();
    _emotionReactions.dispose();
    _budget.detach();
    CrowdRuntimeTelemetryService.instance.release();
    _bannerTimer?.cancel();
    StreamLifecycleAudit.instance.onTimerCancel(CrowdStreamIds.stadiumBannerTimer);
    _banner.dispose();
    for (final n in _pulseNs.values) {
      n.dispose();
    }
    for (final n in _shakeNs.values) {
      n.dispose();
    }
    _pulseNs.clear();
    _shakeNs.clear();
    unawaited(_audio?.dispose() ?? Future.value());
    _intensity.dispose();
    _lightPhase.dispose();
    _votePulse.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _audio?.handleAppLifecycle(state);
    _runtimeGuards.setLifecycle(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _lightPhase.stop();
        _votePulse.stop();
        _bannerTimer?.cancel();
        break;
      case AppLifecycleState.resumed:
        if (!_lightPhase.isAnimating) {
          _lightPhase.repeat();
        }
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _kickVoteFx(CrowdAppIdentity id) {
    unawaited(_audio?.playCheer() ?? Future.value());
    _votePulse.forward(from: 0);
    final r = math.Random();
    final emoji = _fanPresence.isActive
        ? _fanPresence.pickPersonalReaction(r)
        : (r.nextBool() ? id.reactionEmojiPrimary : id.reactionEmojiSecondary);
    final flo = _Floater(
      emoji: emoji,
      dx: 0.12 + r.nextDouble() * 0.76,
      dy: 0.35 + r.nextDouble() * 0.35,
    );
    setState(() => _floaters.add(flo));
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _floaters.remove(flo));
    });
  }

  void _onLeaderChanged(StadiumVoteShellVm vm, CrowdAppIdentity id) {
    final idLead = vm.leadingPlayerId;
    if (vm.totalVotes <= 0 || idLead == null) {
      _lastLeadId = idLead;
      return;
    }
    if (_lastLeadId != null && _lastLeadId != idLead) {
      HapticFeedback.heavyImpact();
      unawaited(_audio?.playLeaderSting() ?? Future.value());
      final merged = stricterCrowdAnimationBudget(_budget.tier, _runtimeGuards.guardTier);
      if (merged != CrowdAnimationBudget.minimal) {
        _votePulse.forward(from: 0);
      }
    }
    if (_lastLeadId != idLead && idLead.isNotEmpty) {
      _banner.value = id.leaderBannerDominating;
      _bannerTimer?.cancel();
      _bannerTimer?.cancel();
      StreamLifecycleAudit.instance.onTimerStart(CrowdStreamIds.stadiumBannerTimer);
      _bannerTimer = Timer(const Duration(seconds: 3), () {
        StreamLifecycleAudit.instance.onTimerCancel(CrowdStreamIds.stadiumBannerTimer);
        if (mounted) _banner.value = null;
      });
    }
    _lastLeadId = idLead;
  }

  Future<void> _onCardTap(MatchPitchPlayer p, StadiumVoteShellVm shell, CrowdAppIdentity id) async {
    final cubit = context.read<MatchVotingCubit>();
    if (!shell.hasRtdbSession) return;
    if (!shell.votingEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('التصويت مغلق حالياً')),
      );
      return;
    }

    final my = shell.myVotedPlayerId;
    if (my != null && my.isNotEmpty) {
      if (my != p.id) {
        HapticFeedback.heavyImpact();
        _shakeFor(p.id).value++;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكنك تغيير تصويتك')),
        );
        return;
      }
      HapticFeedback.selectionClick();
      _shakeFor(p.id).value++;
      return;
    }

    final confirmed = await showMatchVoteConfirmationDialog(
      context,
      playerName: p.name,
    );
    if (!confirmed || !mounted) return;

    FanExperienceHaptics.voteConfirm();
    _pulseFor(p.id).value++;

    try {
      await cubit.castVote(p.id);
      if (!mounted) return;
      final st = cubit.state;
      final matchId = st.match?.id ?? '';
      unawaited(
        _fanPresence.recordVote(
          playerId: p.id,
          playerName: p.name,
          matchId: matchId,
          pickedCurrentLeader: false,
          totalVotesAfter: 0,
        ),
      );
      FanExperienceHaptics.voteSuccess();
      _kickVoteFx(id);
      if (_fanPresence.isActive && _fanPresence.aura.prioritySync) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final list = List<CrowdFloatingReaction>.from(_emotionReactions.value);
        final r = math.Random();
        final anchor = _crowdSync.reactionAnchor(r);
        list.add(
          CrowdFloatingReaction(
            id: _emotionSeq++,
            emoji: _fanPresence.pickPersonalReaction(r),
            dx: anchor.dx,
            dy: anchor.dy,
            createdMs: now,
          ),
        );
        _emotionReactions.value = list;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ClubAwardLabels.voteRecorded)),
      );
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر التصويت: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final id = CrowdAppIdentity.current;

    return BlocListener<MatchVotingCubit, MatchVotingState>(
      listenWhen: (p, c) {
        final pm = StadiumVoteShellVm.from(p);
        final cm = StadiumVoteShellVm.from(c);
        if (pm.maskLiveCompetitive || cm.maskLiveCompetitive) return false;
        return pm.leadingPlayerId != cm.leadingPlayerId;
      },
      listener: (context, s) => _onLeaderChanged(StadiumVoteShellVm.from(s), id),
      child: BlocListener<MatchVotingCubit, MatchVotingState>(
        listener: (context, s) {
          _intensity.updateFromMatchState(s);
          _voteMomentum.ingest(s);
          final matchId = s.match?.id;
          if (matchId != null && matchId.isNotEmpty) {
            _fanPresence.onStadiumSessionOpened(matchId);
          }
          _fanPresence.observeMatchState(s);

          final now = DateTime.now().millisecondsSinceEpoch;
          final mergedPre = stricterCrowdAnimationBudget(_budget.tier, _runtimeGuards.guardTier);
          final list = List<CrowdFloatingReaction>.from(_emotionReactions.value);
          list.removeWhere((e) => now - e.createdMs > 2600);
          _crowdSync.ingestMatchState(
            s,
            momentum01: _voteMomentum.momentumValue,
            activeReactions: list.length,
          );
          final emotionDrive = _crowdSync.emotionalDriveForAudio(
            voteMomentum01: _voteMomentum.momentumValue,
            fanEngagement01: _fanPresence.profile?.engagement01() ?? 0,
          );
          _audio?.setEmotionalDrive(emotionDrive);
          _audio?.setIntensity(_intensity.value);

          for (final em in _voteMomentum.pullReactionEmojis()) {
            if (list.length >= 8) break;
            if (mergedPre == CrowdAnimationBudget.minimal && em != '⚡') continue;
            final r = math.Random();
            final anchor = _crowdSync.reactionAnchor(r);
            list.add(
              CrowdFloatingReaction(
                id: _emotionSeq++,
                emoji: em,
                dx: anchor.dx,
                dy: anchor.dy,
                createdMs: now,
              ),
            );
          }
          if (list.length < 8 && mergedPre != CrowdAnimationBudget.minimal) {
            final r = math.Random();
            final anchor = _crowdSync.reactionAnchor(r);
            list.add(
              CrowdFloatingReaction(
                id: _emotionSeq++,
                emoji: _crowdSync.pickClusterReaction(r),
                dx: anchor.dx,
                dy: anchor.dy,
                createdMs: now,
              ),
            );
          }
          _emotionReactions.value = list;
        },
        child: BlocSelector<MatchVotingCubit, MatchVotingState, StadiumVoteShellVm>(
          selector: StadiumVoteShellVm.from,
          builder: (context, shell) {
            if (shell.loading) {
              return const CrowdVoteLoadingGate();
            }
            if (shell.error != null && !shell.hasRtdbSession) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                    shell.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            );
          }

            if (!shell.hasRtdbSession) {
              return const MatchVotingIdleSurface();
            }

            _pruneNotifiers(shell.visiblePlayerIds.toSet());

          return AnimatedBuilder(
              animation: Listenable.merge([
                _lightPhase,
                _votePulse,
                _intensity,
                _budget,
                _runtimeGuards,
                _voteMomentum,
              ]),
            builder: (context, _) {
                final votePulse = Curves.easeOut.transform(_votePulse.value);
                final motion = _lightPhase.value;
              return LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final h = c.maxHeight;
                    final spacing = TacticalSpacingSystem.resolve(
                      Size(w, h),
                      calibration: BroadcastCalibrationScope.maybeOf(context),
                    );
                    final cardW = spacing.cardWidth;
                    final cardH = spacing.cardHeight;
                    final broadcastLayout =
                        StadiumVisualTokens.of(id).useBroadcastStadiumLayout;
                    final merged = stricterCrowdAnimationBudget(
                      _budget.tier,
                      _runtimeGuards.guardTier,
                    );
                    CrowdRuntimeTelemetryService.instance.setHudAnimationBudget(merged);
                    CrowdRuntimeTelemetryService.instance.commitSceneMetrics(
                      viewportPlayers: shell.visiblePlayerIds.length,
                      activeAudioLoops: _audio?.activeAudioLoops ?? 0,
                      hintActiveAnimationControllers: 2,
                    );

                    final live = _crowdSync.composeFrame(
                      lightPhase01: motion,
                      budget: merged,
                      guards: _runtimeGuards,
                      voteMomentum01: _voteMomentum.momentumValue,
                      fanPulse01: (_voteMomentum.fanPulse +
                          (_fanPresence.isActive ? _fanPresence.aura.strength * 0.14 : 0)),
                      intensity01: _intensity.value,
                    );
                    final fanPulse = live.collectiveBreath01;
                    final shakeAmp = merged == CrowdAnimationBudget.minimal
                        ? 0.0
                        : (_voteMomentum.screenShake *
                            (merged == CrowdAnimationBudget.reduced ? 0.95 : 1.75) *
                            (0.5 + 0.5 * _voteMomentum.momentumValue));
                    final ox = math.sin(motion * math.pi * 2 * 3.0) * shakeAmp;
                    final oy = math.cos(motion * math.pi * 2 * 2.1) * shakeAmp * 0.62;

                    return Transform.translate(
                      offset: Offset(ox, oy),
                      child: CrowdRuntimeDebugHud(
                        child: TacticalFormationLayout(
                          formation: shell.matchFormation,
                          benchRail: broadcastLayout
                              ? TacticalBenchRail(
                                  identity: id,
                                  shellVmSelector: StadiumVoteShellVm.from,
                                  onBenchTap: _onCardTap,
                                )
                              : null,
                          child: Builder(
                            builder: (context) {
                              final cinematic =
                                  CinematicAtmosphereScope.maybeOf(context);
                              final vis = cinematic?.visibility;
                              final palette = cinematic?.palette;
                              final broadcast =
                                  BroadcastCalibrationScope.maybeOf(context);
                              var fxOpacity = palette == null || vis == null
                                  ? 0.85
                                  : CinematicOverlayBalance.atmosphereFxOpacity(
                                      palette,
                                      vis.atmosphereFxMultiplier,
                                    );
                              if (broadcast != null) {
                                fxOpacity *= broadcast.density.atmosphereFxMul;
                                fxOpacity *= broadcast.finish.visualNoiseCap;
                              }

                              Widget atmosphereChild = StadiumCrowdAtmosphereLayer(
                                identity: id,
                                momentum: shell.momentum,
                                votePulse: votePulse,
                                intensity: _intensity.value,
                                budget: merged,
                                fanPulse: fanPulse,
                                live: live,
                              );
                              if (vis != null && !vis.showCrowdAtmosphereFx) {
                                atmosphereChild = const SizedBox.shrink();
                              } else {
                                atmosphereChild = Opacity(
                                  opacity: fxOpacity,
                                  child: atmosphereChild,
                                );
                              }

                              Widget pulseChild = CrowdCollectivePulseLayer(
                                identity: id,
                                phase: _lightPhase.value * math.pi * 2,
                                live: live,
                                budget: merged,
                              );
                              if (vis != null && !vis.showCollectivePulse) {
                                pulseChild = const SizedBox.shrink();
                              } else {
                                pulseChild = Opacity(
                                  opacity: fxOpacity,
                                  child: pulseChild,
                                );
                              }

                              Widget fxChild = StadiumFxEngine(
                                identity: id,
                                phase: _lightPhase.value * math.pi * 2,
                                votePulse: votePulse,
                                leaderGlow: shell.leaderShare,
                                intensity: _intensity.value,
                                budget: merged,
                                fanPulse: fanPulse,
                                live: live,
                              );
                              if (vis != null && !vis.showStadiumFxEngine) {
                                fxChild = const SizedBox.shrink();
                              } else {
                                fxChild = Opacity(
                                  opacity: fxOpacity,
                                  child: fxChild,
                                );
                              }

                              return Stack(
                    clipBehavior: Clip.none,
                    children: [
                          CrowdRuntimeOverlayRegistrar(
                            id: 'stadium_atmosphere',
                            kind: CrowdOverlayKind.atmosphere,
                            heavyAnimated: true,
                            child: CrowdRebuildProbe(
                              label: 'StadiumAtmosphere',
                              child: atmosphereChild,
                            ),
                          ),
                          CrowdRuntimeOverlayRegistrar(
                            id: 'crowd_collective_pulse',
                            kind: CrowdOverlayKind.atmosphere,
                            heavyAnimated: merged != CrowdAnimationBudget.minimal,
                            child: pulseChild,
                          ),
                          CrowdRuntimeOverlayRegistrar(
                            id: 'stadium_fx_engine',
                            kind: CrowdOverlayKind.stadiumFx,
                            heavyAnimated: true,
                            child: CrowdRebuildProbe(
                              label: 'StadiumFxEngine',
                              child: fxChild,
                            ),
                          ),
                        if (shell.matchTitle.isNotEmpty)
                        Positioned(
                          top: 6,
                          left: 12,
                          right: 12,
                          child: IgnorePointer(
                            child: Text(
                                shell.matchTitle,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: id.stadiumTitleStyle((w * 0.035).clamp(12.0, 16.0)),
                            ),
                          ),
                        ),
                      ValueListenableBuilder<String?>(
                        valueListenable: _banner,
                        builder: (context, text, _) {
                          if (text == null || text.isEmpty) return const SizedBox.shrink();
                          return Positioned(
                            top: MediaQuery.paddingOf(context).top + 52,
                            left: 16,
                            right: 16,
                            child: Material(
                              color: Colors.transparent,
                              child: Center(
                                child: Text(
                                  text,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    shadows: [
                                        Shadow(blurRadius: 10, color: id.primaryColor.withValues(alpha: 0.85)),
                                    ],
                                  ),
                                )
                                    .animate(key: ValueKey(text))
                                    .fadeIn(duration: 220.ms)
                                    .slideY(begin: -0.2, curve: Curves.easeOutCubic),
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        top: MediaQuery.paddingOf(context).top + 48,
                        right: 8,
                        child: IconButton(
                          tooltip: _audio?.muted == true ? 'تشغيل الصوت' : 'كتم الصوت',
                          onPressed: () {
                            setState(() {
                              if (_audio != null) _audio!.muted = !_audio!.muted;
                            });
                          },
                          icon: Icon(
                            _audio?.muted == true ? Icons.volume_off : Icons.volume_up,
                            color: Colors.white70,
                            size: 22,
                          ),
                        ),
                      ),
                        for (var i = 0; i < shell.visiblePlayerIds.length; i++)
                          _StadiumPitchPlayerOrb(
                            key: ValueKey('orb_${shell.visiblePlayerIds[i]}'),
                            playerId: shell.visiblePlayerIds[i],
                            slotIndex: i,
                            identity: id,
                            cardW: cardW,
                            cardH: cardH,
                            w: w,
                            h: h,
                            votePulse: votePulse,
                            motionPhase01: motion,
                            pulseN: _pulseFor(shell.visiblePlayerIds[i]),
                            shakeN: _shakeFor(shell.visiblePlayerIds[i]),
                            effectiveBudget: merged,
                            runtimeGuards: _runtimeGuards,
                            crowdIntensity: _intensity.value,
                            shell: shell,
                            onTap: _onCardTap,
                            fanPresence: _fanPresence,
                            breathPhase01: motion,
                          ),
                        StadiumClubHeaderChip(identity: id),
                        FanPresenceHud(
                          controller: _fanPresence,
                          topPadding: MediaQuery.paddingOf(context).top + 44,
                        ),
                      ..._floaters.map(
                        (f) => Positioned(
                          left: f.dx * w - 14,
                          top: f.dy * h - 20,
                          child: Text(
                            f.emoji,
                            style: const TextStyle(fontSize: 28),
                          ).animate().fadeIn(duration: 120.ms).moveY(begin: 18, end: -32, duration: 900.ms).fadeOut(delay: 500.ms, duration: 280.ms),
                        ),
                      ),
                        if (shell.myVotedPlayerId != null &&
                            shell.myVotedPlayerId!.isNotEmpty)
                          Positioned(
                            left: 10,
                            bottom: StadiumVisualTokens.of(id).useBroadcastStadiumLayout
                                ? StadiumBroadcastLayout.subsBarHeight(context) +
                                    MediaQuery.paddingOf(context).bottom +
                                    18
                                : 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: id.primaryColor.withValues(alpha: 0.6),
                                ),
                              ),
                              child: const Text(
                                ClubAwardLabels.voteRecorded,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        if (!broadcastLayout)
                          FloatingSubstitutesPanel(
                            identity: id,
                            shellVmSelector: StadiumVoteShellVm.from,
                            onBenchTap: _onCardTap,
                          ),
                        ValueListenableBuilder<List<CrowdFloatingReaction>>(
                          valueListenable: _emotionReactions,
                          builder: (context, react, __) {
                            return CrowdReactionStreamLayer(
                              reactions: react,
                              budget: merged,
                            );
                          },
                        ),
                      ],
                    );
                            },
                          ),
                        ),
                    ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
