import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_operator_run.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_pending_op.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_match_kit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_workspace_snapshot.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_session_template.dart';

abstract class StadiumCmsRepository {
  Stream<List<StadiumSessionTemplate>> watchCustomTemplates(String clubTag);

  Future<void> upsertSessionTemplate({
    required String clubTag,
    required StadiumSessionTemplate template,
  });

  Future<void> removeSessionTemplate(String clubTag, String templateId);

  Stream<List<StadiumMatchKit>> watchMatchKits(String clubTag);

  Future<void> upsertMatchKit({
    required String clubTag,
    required StadiumMatchKit kit,
  });

  Future<void> removeMatchKit(String clubTag, String kitId);

  Future<StadiumMatchKit?> readLastLineup(String clubTag);

  Future<void> writeLastLineup({
    required String clubTag,
    required StadiumMatchKit kit,
  });

  Future<StadiumCmsWorkspaceSnapshot?> readWorkspaceSnapshot(String clubTag);

  Future<void> writeWorkspaceSnapshot({
    required String clubTag,
    required StadiumCmsWorkspaceSnapshot snapshot,
  });

  /// توافق قديم.
  Stream<List<StadiumMatchKit>> watchSavedLineups(String clubTag);

  Future<void> upsertSavedLineup({
    required String clubTag,
    required StadiumMatchKit lineup,
  });

  Future<void> removeSavedLineup(String clubTag, String lineupId);

  Stream<List<StadiumCmsPendingOp>> watchPendingOps(String clubTag);

  Future<List<StadiumCmsPendingOp>> readAllPendingOps(String clubTag);

  Future<void> upsertPendingOp({
    required String clubTag,
    required StadiumCmsPendingOp op,
  });

  Future<void> removePendingOp(String clubTag, String opId);

  Future<void> saveActivationRun({
    required String clubTag,
    required StadiumCmsOperatorRun run,
  });
}
