import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_paths.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_operator_run.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_pending_op.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_match_kit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_workspace_snapshot.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_session_template.dart';

class StadiumCmsRepositoryRtdb implements StadiumCmsRepository {
  StadiumCmsRepositoryRtdb(this._db);

  final FirebaseDatabase _db;

  List<T> _parseMap<T>(
    DataSnapshot snap,
    T Function(String id, Map<dynamic, dynamic> m) fromMap,
  ) {
    if (!snap.exists || snap.value is! Map) return const [];
    final root = Map<dynamic, dynamic>.from(snap.value! as Map);
    final out = <T>[];
    root.forEach((k, v) {
      if (k.toString().isEmpty || v is! Map) return;
      out.add(fromMap(k.toString(), Map<dynamic, dynamic>.from(v)));
    });
    return out;
  }

  @override
  Stream<List<StadiumSessionTemplate>> watchCustomTemplates(String clubTag) {
    return _db
        .ref(StadiumCmsPaths.sessionTemplates(clubTag))
        .onValue
        .map((e) => _parseMap(e.snapshot, StadiumSessionTemplate.fromMap));
  }

  @override
  Future<void> upsertSessionTemplate({
    required String clubTag,
    required StadiumSessionTemplate template,
  }) async {
    await _db
        .ref(StadiumCmsPaths.sessionTemplate(clubTag, template.id))
        .set(template.toWriteMap());
  }

  @override
  Future<void> removeSessionTemplate(String clubTag, String templateId) async {
    await _db.ref(StadiumCmsPaths.sessionTemplate(clubTag, templateId)).remove();
  }

  @override
  Stream<List<StadiumMatchKit>> watchMatchKits(String clubTag) {
    return _db
        .ref(StadiumCmsPaths.matchKits(clubTag))
        .onValue
        .map((e) => _parseMap(e.snapshot, StadiumMatchKit.fromMap));
  }

  @override
  Future<void> upsertMatchKit({
    required String clubTag,
    required StadiumMatchKit kit,
  }) async {
    await _db.ref(StadiumCmsPaths.matchKit(clubTag, kit.id)).set(kit.toWriteMap());
  }

  @override
  Future<void> removeMatchKit(String clubTag, String kitId) async {
    await _db.ref(StadiumCmsPaths.matchKit(clubTag, kitId)).remove();
  }

  @override
  Future<StadiumMatchKit?> readLastLineup(String clubTag) async {
    final snap = await _db.ref(StadiumCmsPaths.lastLineup(clubTag)).get();
    if (!snap.exists || snap.value is! Map) return null;
    return StadiumMatchKit.fromMap(
      'last',
      Map<dynamic, dynamic>.from(snap.value! as Map),
    );
  }

  @override
  Future<void> writeLastLineup({
    required String clubTag,
    required StadiumMatchKit kit,
  }) async {
    await _db.ref(StadiumCmsPaths.lastLineup(clubTag)).set(kit.toWriteMap());
  }

  @override
  Future<StadiumCmsWorkspaceSnapshot?> readWorkspaceSnapshot(String clubTag) async {
    final snap = await _db.ref(StadiumCmsPaths.workspaceSnapshot(clubTag)).get();
    if (!snap.exists || snap.value is! Map) return null;
    return StadiumCmsWorkspaceSnapshot.fromMap(
      Map<dynamic, dynamic>.from(snap.value! as Map),
    );
  }

  @override
  Future<void> writeWorkspaceSnapshot({
    required String clubTag,
    required StadiumCmsWorkspaceSnapshot snapshot,
  }) async {
    await _db
        .ref(StadiumCmsPaths.workspaceSnapshot(clubTag))
        .set(snapshot.toWriteMap());
  }

  @override
  Stream<List<StadiumMatchKit>> watchSavedLineups(String clubTag) => watchMatchKits(clubTag);

  @override
  Future<void> upsertSavedLineup({
    required String clubTag,
    required StadiumMatchKit lineup,
  }) =>
      upsertMatchKit(clubTag: clubTag, kit: lineup);

  @override
  Future<void> removeSavedLineup(String clubTag, String lineupId) =>
      removeMatchKit(clubTag, lineupId);

  @override
  Stream<List<StadiumCmsPendingOp>> watchPendingOps(String clubTag) {
    return _db
        .ref(StadiumCmsPaths.pendingOps(clubTag))
        .onValue
        .map((e) => _parseMap(e.snapshot, StadiumCmsPendingOp.fromMap));
  }

  @override
  Future<List<StadiumCmsPendingOp>> readAllPendingOps(String clubTag) async {
    final snap = await _db.ref(StadiumCmsPaths.pendingOps(clubTag)).get();
    return _parseMap(snap, StadiumCmsPendingOp.fromMap);
  }

  @override
  Future<void> upsertPendingOp({
    required String clubTag,
    required StadiumCmsPendingOp op,
  }) async {
    await _db.ref(StadiumCmsPaths.pendingOp(clubTag, op.id)).set(op.toWriteMap());
  }

  @override
  Future<void> removePendingOp(String clubTag, String opId) async {
    await _db.ref(StadiumCmsPaths.pendingOp(clubTag, opId)).remove();
  }

  @override
  Future<void> saveActivationRun({
    required String clubTag,
    required StadiumCmsOperatorRun run,
  }) async {
    await _db
        .ref(StadiumCmsPaths.activationRun(clubTag, run.id))
        .set(run.toWriteMap());
  }
}
