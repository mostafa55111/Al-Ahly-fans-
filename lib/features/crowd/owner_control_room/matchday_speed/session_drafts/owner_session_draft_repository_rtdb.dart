import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/session_drafts/owner_session_draft.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/session_drafts/owner_session_draft_paths.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/session_drafts/owner_session_draft_repository.dart';

class OwnerSessionDraftRepositoryRtdb implements OwnerSessionDraftRepository {
  OwnerSessionDraftRepositoryRtdb(this._db);

  final FirebaseDatabase _db;

  List<OwnerSessionDraft> _parse(DataSnapshot snap, String appId) {
    if (!snap.exists || snap.value is! Map) return const [];
    final m = Map<dynamic, dynamic>.from(snap.value! as Map);
    final list = <OwnerSessionDraft>[];
    m.forEach((k, v) {
      if (k.toString().isEmpty || v is! Map) return;
      final d = OwnerSessionDraft.fromMap(
        k.toString(),
        Map<dynamic, dynamic>.from(v),
      );
      list.add(d.appId.isEmpty
          ? OwnerSessionDraft(
              id: d.id,
              formation: d.formation,
              lineup: d.lineup,
              bench: d.bench,
              durationMinutes: d.durationMinutes,
              notes: d.notes,
              state: d.state,
              updatedAt: d.updatedAt,
              appId: appId,
            )
          : d);
    });
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Stream<List<OwnerSessionDraft>> watchDrafts(String appId) {
    return _db.ref(OwnerSessionDraftPaths.root(appId)).onValue.map((e) {
      return _parse(e.snapshot, appId);
    });
  }

  @override
  Future<void> upsertDraft({
    required String appId,
    required OwnerSessionDraft draft,
  }) async {
    await _db
        .ref(OwnerSessionDraftPaths.draft(appId, draft.id))
        .set(draft.toWriteMap());
  }

  @override
  Future<void> setState({
    required String appId,
    required String draftId,
    required OwnerSessionDraftState state,
  }) async {
    await _db
        .ref(OwnerSessionDraftPaths.draft(appId, draftId))
        .update({
      'state': state.wire,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> removeDraft(String appId, String draftId) async {
    await _db.ref(OwnerSessionDraftPaths.draft(appId, draftId)).remove();
  }
}
