/// مسارات إعدادات Stadium CMS (قوالب جلسات، تشكيلات محفوظة).
class StadiumCmsPaths {
  StadiumCmsPaths._();

  static String root(String clubTag) => 'stadium_cms/${clubTag.trim().toLowerCase()}';

  static String sessionTemplates(String clubTag) => '${root(clubTag)}/session_templates';

  static String sessionTemplate(String clubTag, String id) =>
      '${sessionTemplates(clubTag)}/$id';

  static String matchKits(String clubTag) => '${root(clubTag)}/match_kits';

  static String matchKit(String clubTag, String id) => '${matchKits(clubTag)}/$id';

  /// توافق قديم.
  static String savedLineups(String clubTag) => matchKits(clubTag);

  static String savedLineup(String clubTag, String id) => matchKit(clubTag, id);

  static String lastLineup(String clubTag) => '${root(clubTag)}/workspace/last_lineup';

  static String workspaceSnapshot(String clubTag) => '${root(clubTag)}/workspace/cms_snapshot';

  static String pendingOps(String clubTag) => '${root(clubTag)}/workspace/pending_ops';

  static String pendingOp(String clubTag, String opId) => '${pendingOps(clubTag)}/$opId';

  static String activationRuns(String clubTag) => '${root(clubTag)}/workspace/activation_runs';

  static String activationRun(String clubTag, String runId) => '${activationRuns(clubTag)}/$runId';
}
