/// أعلام عزل أنظمة الجمهور القديمة — الإنتاج يعمل على MatchVoting فقط.
class LegacyCrowdFeatureFlags {
  LegacyCrowdFeatureFlags._();

  /// تصويت نسر المباراة (EagleVotingCubit + eagle_nesr RTDB).
  static const bool enableLegacyVoting = false;

  /// مسارات voting_match_center و MainNavigation القديمة.
  static const bool enableLegacyRoutes = false;

  /// مؤقتات/اشتراكات Firebase الخاصة بالتصويت القديم.
  static const bool enableLegacyStreams = false;
}
