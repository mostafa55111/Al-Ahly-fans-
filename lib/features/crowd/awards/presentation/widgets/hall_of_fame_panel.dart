import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/design_system/theme/app_colors.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_clock.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_design_system.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/match_winner_award.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/period_winner_award.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/identity/club_award_labels.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/presentation/cubit/hall_of_fame_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/presentation/cubit/hall_of_fame_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_atmosphere_layer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_transition_system.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/hall_of_fame_prestige.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/match_night_atmosphere.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_empty_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/runtime/crowd_navigation_runtime_guard.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/fifa_card_widget.dart';

/// قاعة الشرف — نسر المباراة / الشهر / الموسم فقط.
class HallOfFamePanel extends StatefulWidget {
  const HallOfFamePanel({super.key, this.tabOpens});

  final ValueNotifier<int>? tabOpens;

  @override
  State<HallOfFamePanel> createState() => _HallOfFamePanelState();
}

class _HallOfFamePanelState extends State<HallOfFamePanel> {
  @override
  void initState() {
    super.initState();
    CrowdNavigationRuntimeGuard.instance.registerHallOverlay();
    widget.tabOpens?.addListener(_onTabOpen);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HallOfFameCubit>().load();
    });
  }

  void _onTabOpen() {
    if (mounted) context.read<HallOfFameCubit>().load();
  }

  @override
  void dispose() {
    CrowdNavigationRuntimeGuard.instance.unregisterHallOverlay();
    widget.tabOpens?.removeListener(_onTabOpen);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top + 56;
    final bottomPad = MediaQuery.paddingOf(context).bottom + 16;
    final id = CrowdAppIdentity.current;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        StadiumCmsDesign.spaceLg,
        topPad,
        StadiumCmsDesign.spaceLg,
        bottomPad,
      ),
      child: BlocBuilder<HallOfFameCubit, HallOfFameState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            );
          }
          if (state.error != null) {
            return Center(
              child: PremiumEmptyState(
                title: 'تعذر تحميل قاعة الشرف',
                subtitle: 'تحقق من الاتصال وحاول مرة أخرى',
                icon: Icons.cloud_off_outlined,
              ),
            );
          }

          final phase =
              CinematicAtmosphereScope.maybeOf(context)?.phase ??
              MatchNightPhase.hallOfFame;

          return CinematicTransitionSystem(
            transitionKey: phase,
            child: ListView(
              children: [
                if (state.lastMatch != null)
                  HallOfFamePrestigeFrame(
                    title: ClubAwardLabels.lastMatchSection,
                    identity: id,
                    child: _MatchBlock(award: state.lastMatch!, identity: id),
                  )
                else
                  _emptySlot(
                    title: ClubAwardLabels.lastMatchSection,
                    subtitle: 'سيُعرض الفائز بعد إغلاق التصويت',
                  ),
                StadiumCmsDesign.sectionGap(StadiumCmsDesign.spaceXl),
                if (state.monthly != null)
                  HallOfFamePrestigeFrame(
                    title: ClubAwardLabels.monthSection,
                    subtitle:
                        state.monthKey.isNotEmpty ? state.monthKey : null,
                    identity: id,
                    child: _PeriodBlock(award: state.monthly!, identity: id),
                  )
                else
                  _emptySlot(
                    title: ClubAwardLabels.monthSection,
                    subtitle: 'يُحدَّث مع نهاية الشهر',
                  ),
                StadiumCmsDesign.sectionGap(StadiumCmsDesign.spaceXl),
                if (state.season != null)
                  HallOfFamePrestigeFrame(
                    title: ClubAwardLabels.seasonSection,
                    subtitle: state.seasonKey.isNotEmpty
                        ? 'الموسم ${state.seasonKey}'
                        : null,
                    featured: true,
                    identity: id,
                    child: _PeriodBlock(
                      award: state.season!,
                      featured: true,
                      identity: id,
                    ),
                  )
                else
                  _emptySlot(
                    title: ClubAwardLabels.seasonSection,
                    subtitle: 'يُحدَّث مع نهاية الموسم',
                    compact: true,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _emptySlot({
    required String title,
    required String subtitle,
    bool compact = false,
  }) {
    return PremiumEmptyState(
      title: title,
      subtitle: subtitle,
      icon: Icons.emoji_events_outlined,
      compact: compact,
    );
  }
}

class _PeriodBlock extends StatelessWidget {
  const _PeriodBlock({
    required this.award,
    required this.identity,
    this.featured = false,
  });

  final PeriodWinnerAward award;
  final CrowdAppIdentity identity;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final w = featured ? 120.0 : 96.0;
    final h = featured ? 166.0 : 132.0;
    return Column(
      children: [
        FifaCardWidget(
          player: award.cardSnapshot.toPastPlayerDto(votes: award.totalVotes),
          width: w,
          height: h,
        ),
        const SizedBox(height: StadiumCmsDesign.spaceSm),
        Text(award.playerName, style: StadiumCmsDesign.title(identity)),
        Text(
          ClubAwardLabels.votesLabel(award.totalVotes),
          style: StadiumCmsDesign.subtitle,
        ),
        Text(
          ClubAwardLabels.winsLabel(award.winsCount),
          style: StadiumCmsDesign.caption,
        ),
      ],
    );
  }
}

class _MatchBlock extends StatelessWidget {
  const _MatchBlock({required this.award, required this.identity});

  final MatchWinnerAward award;
  final CrowdAppIdentity identity;

  @override
  Widget build(BuildContext context) {
    final when =
        award.closedAt > 0 ? EgyptClock.awardDateLabel(award.closedAt) : '';
    return Column(
      children: [
        FifaCardWidget(
          player: award.winnerCardSnapshot.toPastPlayerDto(
            votes: award.totalVotes,
          ),
          width: 100,
          height: 138,
          highlighted: true,
          brandPrimary: identity.primaryColor,
          brandSecondary: identity.secondaryColor,
        ),
        const SizedBox(height: StadiumCmsDesign.spaceSm),
        Text(award.winnerName, style: StadiumCmsDesign.title(identity)),
        Text(
          ClubAwardLabels.votesLabel(award.totalVotes),
          style: StadiumCmsDesign.subtitle,
        ),
        if (award.opponent.isNotEmpty)
          Text('vs ${award.opponent}', style: StadiumCmsDesign.caption),
        if (when.isNotEmpty) Text(when, style: StadiumCmsDesign.caption),
        if (award.title.isNotEmpty) Text(award.title, style: StadiumCmsDesign.caption),
      ],
    );
  }
}
