/// مستوى اشتراك القراءة حسب حالة التطبيق.
enum SessionReadTier {
  /// أمامية كاملة: جلسة + لاعبين + صوتي.
  foregroundFull,

  /// خلفية: جلسة + صوتي فقط.
  backgroundLight,

  /// خامد: ساعة الخادم فقط.
  dormantClockOnly,
}

extension SessionReadTierX on SessionReadTier {
  bool get allowsPlayersStream =>
      this == SessionReadTier.foregroundFull;

  bool get allowsSessionStream =>
      this != SessionReadTier.dormantClockOnly;
}
