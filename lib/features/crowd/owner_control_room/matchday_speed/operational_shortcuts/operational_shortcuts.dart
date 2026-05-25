import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_entry.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/match_votes_admin_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/quick_launch/quick_launch_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/session_drafts/owner_session_draft.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/session_drafts/owner_session_draft_repository.dart';

/// اختصارات تشغيل — تقليل خطوات يوم المباراة.
class OperationalShortcuts {
  OperationalShortcuts({
    required QuickLaunchService quickLaunch,
    OwnerSessionDraftRepository? drafts,
  })  : _quickLaunch = quickLaunch,
        _drafts = drafts;

  final QuickLaunchService _quickLaunch;
  final OwnerSessionDraftRepository? _drafts;

  Future<void> reuseLastLineup(MatchVotesAdminCubit cubit) {
    return cubit.resumeWorkspace();
  }

  Future<void> duplicatePreviousSession(MatchVotesAdminCubit cubit) {
    return cubit.duplicateSession();
  }

  Future<void> launchFromLatestDraft({
    required MatchVotesAdminCubit cubit,
    required OwnerSessionDraft draft,
    required String appId,
  }) async {
    await _quickLaunch.applyDraft(cubit: cubit, draft: draft);
    await _drafts?.setState(
      appId: appId,
      draftId: draft.id,
      state: OwnerSessionDraftState.live,
    );
  }

  Future<void> swapInjuredPlayer({
    required MatchVotesAdminCubit cubit,
    required String playerId,
    required StadiumCardRegistryEntry replacementEntry,
  }) {
    return cubit.replacePitchPlayerWithRegistry(
      playerId: playerId,
      entry: replacementEntry,
    );
  }
}
