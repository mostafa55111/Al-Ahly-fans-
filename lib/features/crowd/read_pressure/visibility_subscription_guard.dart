import 'package:gomhor_alahly_clean_new/features/crowd/read_pressure/session_read_tier.dart';

/// يمنع اشتراكات ثقيلة على تبويبات مخفية.
class VisibilitySubscriptionGuard {
  VisibilitySubscriptionGuard._();
  static final VisibilitySubscriptionGuard instance =
      VisibilitySubscriptionGuard._();

  factory VisibilitySubscriptionGuard() => instance;

  int _visibleTabIndex = 0;
  SessionReadTier _tier = SessionReadTier.foregroundFull;

  void setVisibleTab(int index) {
    _visibleTabIndex = index;
  }

  void setReadTier(SessionReadTier tier) {
    _tier = tier;
  }

  bool get stadiumTabVisible => _visibleTabIndex == 0;

  bool shouldAttachPlayersStream() =>
      stadiumTabVisible && _tier.allowsPlayersStream;

  bool shouldAttachSessionStream() => _tier.allowsSessionStream;
}
