/// مسارات سلطة الإغلاق على الخادم.
class AuthorityRuntimePaths {
  AuthorityRuntimePaths._();

  static String leaseRoot(String clubTag) =>
      'authority_runtime/${clubTag.trim().toLowerCase()}';

  static String matchLease(String clubTag, String matchId) =>
      '${leaseRoot(clubTag)}/${matchId.trim()}';
}
