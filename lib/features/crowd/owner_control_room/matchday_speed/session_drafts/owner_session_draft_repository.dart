import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/session_drafts/owner_session_draft.dart';

abstract class OwnerSessionDraftRepository {
  Stream<List<OwnerSessionDraft>> watchDrafts(String appId);

  Future<void> upsertDraft({
    required String appId,
    required OwnerSessionDraft draft,
  });

  Future<void> setState({
    required String appId,
    required String draftId,
    required OwnerSessionDraftState state,
  });

  Future<void> removeDraft(String appId, String draftId);
}
