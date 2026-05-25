import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/awards_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/hall_of_fame_budget_policy.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/production_cost_surface_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/read_budget_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/cold_start_audit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/club_personal_legacy.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/period_winner_award.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/presentation/cubit/hall_of_fame_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/services/awards_aggregation_integrity_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/services/voting_session_lifecycle_service.dart';

class HallOfFameCubit extends Cubit<HallOfFameState> {
  HallOfFameCubit({
    required AwardsRepository awardsRepository,
    required VotingSessionLifecycleService lifecycle,
    required String clubTag,
    AwardsAggregationIntegrityService? integrity,
  })  : _awards = awardsRepository,
        _lifecycle = lifecycle,
        _integrity = integrity ?? AwardsAggregationIntegrityService(awardsRepository),
        _clubTag = clubTag.trim().toLowerCase(),
        super(const HallOfFameState());

  final AwardsRepository _awards;
  final VotingSessionLifecycleService _lifecycle;
  final AwardsAggregationIntegrityService _integrity;
  final String _clubTag;

  static const _featuredTimelineLimit = 3;
  static const _fullTimelineLimit = 24;

  Future<void> load() async {
    final renderSw = Stopwatch()..start();
    emit(state.copyWith(loading: true, error: null));
    try {
      if (!ReadBudgetGuard.instance.tryAcquire(
        ReadBudgetSurface.hallOfFame,
        reads: 3,
      )) {
        emit(state.copyWith(loading: false));
        return;
      }
      ProductionCostSurfaceReport.instance.recordRead(
        CostSurfacePath.hallOfFameFeatured,
        count: 1,
      );
      final featuredTimeline = await _awards.listRecentMatchAwards(
        clubTag: _clubTag,
        limit: _featuredTimelineLimit,
      );

      final anchorClosedAt =
          featuredTimeline.isNotEmpty ? featuredTimeline.first.closedAt : 0;
      final monthKey =
          featuredTimeline.isNotEmpty ? featuredTimeline.first.monthKey : '';
      final seasonKey =
          featuredTimeline.isNotEmpty ? featuredTimeline.first.seasonKey : '';

      PeriodWinnerAward? monthly;
      PeriodWinnerAward? season;
      if (monthKey.isNotEmpty) {
        monthly = await _awards.getMonthly(clubTag: _clubTag, monthKey: monthKey);
      }
      if (seasonKey.isNotEmpty) {
        season = await _awards.getSeason(clubTag: _clubTag, seasonKey: seasonKey);
      }

      final legacy = await _buildLegacy(monthly: monthly, season: season);

      emit(
        HallOfFameState(
          loading: false,
          lastMatch: featuredTimeline.isNotEmpty ? featuredTimeline.first : null,
          monthly: monthly,
          season: season,
          timeline: featuredTimeline,
          legacy: legacy,
          monthKey: monthKey,
          seasonKey: seasonKey,
        ),
      );
      ColdStartAudit.instance.recordStopwatch('hof_first_render', renderSw);

      unawaited(_hydrateFullTimeline(
        monthKey: monthKey,
        seasonKey: seasonKey,
        anchorClosedAt: anchorClosedAt,
        monthly: monthly,
        season: season,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _hydrateFullTimeline({
    required String monthKey,
    required String seasonKey,
    required int anchorClosedAt,
    PeriodWinnerAward? monthly,
    PeriodWinnerAward? season,
  }) async {
    final policy = HallOfFameBudgetPolicy(getIt<SharedPreferences>());
    if (!policy.shouldHydrateFullTimeline(
      clubTag: _clubTag,
      tabVisible: policy.hallTabVisible(),
    )) {
      return;
    }
    if (!policy.beginTimelineHydration(_clubTag)) return;
    try {
      ProductionCostSurfaceReport.instance.recordRead(
        CostSurfacePath.hallOfFameTimeline,
        count: 1,
      );
      if (anchorClosedAt > 0 && monthKey.isNotEmpty && seasonKey.isNotEmpty) {
        await _lifecycle.refreshPeriodAwardsIfNeeded(
          monthKey: monthKey,
          seasonKey: seasonKey,
          anchorClosedAtServerMs: anchorClosedAt,
        );
      }

      final timeline = await _awards.listRecentMatchAwards(
        clubTag: _clubTag,
        limit: _fullTimelineLimit,
      );

      await _integrity.onHallOfFameOpen(
        clubTag: _clubTag,
        monthKey: monthKey.isEmpty ? null : monthKey,
        seasonKey: seasonKey.isEmpty ? null : seasonKey,
        anchorClosedAtServerMs: anchorClosedAt,
        monthly: monthly,
        season: season,
        timeline: timeline,
      );

      if (monthKey.isNotEmpty) {
        monthly ??= await _awards.getMonthly(clubTag: _clubTag, monthKey: monthKey);
      }
      if (seasonKey.isNotEmpty) {
        season ??= await _awards.getSeason(clubTag: _clubTag, seasonKey: seasonKey);
      }

      ProductionCostSurfaceReport.instance.recordRead(
        CostSurfacePath.hallOfFameRollups,
        count: 1,
      );
      final legacy = await _buildLegacy(monthly: monthly, season: season);

      emit(
        state.copyWith(
          lastMatch: timeline.isNotEmpty ? timeline.first : state.lastMatch,
          monthly: monthly ?? state.monthly,
          season: season ?? state.season,
          timeline: timeline,
          legacy: legacy,
        ),
      );
    } catch (_) {
      // الإبقاء على المحتوى المميز عند فشل التحميل الكامل.
    } finally {
      policy.endTimelineHydration(_clubTag);
    }
  }

  Future<ClubPersonalLegacy> _buildLegacy({
    PeriodWinnerAward? monthly,
    PeriodWinnerAward? season,
  }) async {
    final rollups = await _awards.listPlayerAwardRollups(clubTag: _clubTag);
    var topId = '';
    var topName = '';
    var topWins = 0;
    rollups.forEach((id, m) {
      final w = m['matchWins'];
      final n = w is int ? w : (w is num ? w.toInt() : 0);
      if (n > topWins) {
        topWins = n;
        topId = id;
        topName = m['playerName']?.toString() ?? id;
      }
    });
    return ClubPersonalLegacy(
      topMatchWinsPlayerId: topId.isEmpty ? null : topId,
      topMatchWinsName: topName,
      topMatchWinsCount: topWins,
      monthlyPlayerId: monthly?.playerId,
      monthlyPlayerName: monthly?.playerName ?? '',
      seasonPlayerId: season?.playerId,
      seasonPlayerName: season?.playerName ?? '',
    );
  }
}
