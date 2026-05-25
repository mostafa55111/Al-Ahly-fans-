import 'package:flutter/foundation.dart';

/// معرّفات الاشتراكات الأساسية — للتتبع في debug فقط.
abstract final class CrowdStreamIds {
  static const matchSessionStream = 'match_session_stream';
  static const matchPlayersStream = 'match_players_stream';
  static const matchMyVoteStream = 'match_my_vote_stream';
  static const matchAuthStream = 'match_auth_stream';
  static const votingLifecycleSessionStream = 'voting_lifecycle_session_stream';
  static const crowdFormationStream = 'crowd_formation_stream';
  static const crowdCardsPathStream = 'crowd_cards_path_stream';
  static const eagleVoteStream = 'eagle_vote_stream';
  static const eagleEligibilityTimer = 'eagle_eligibility_timer';
  static const stadiumBannerTimer = 'stadium_banner_timer';
}

/// تتبع اشتراكات/مؤقتات Crowd — debug فقط.
class StreamLifecycleAudit {
  StreamLifecycleAudit._();

  static final StreamLifecycleAudit instance = StreamLifecycleAudit._();

  final Map<String, int> _activeSubscriptions = {};
  final Map<String, int> _activeTimers = {};

  int get activeSubscriptionCount =>
      _activeSubscriptions.values.fold<int>(0, (a, b) => a + b);

  int get activeTimerCount =>
      _activeTimers.values.fold<int>(0, (a, b) => a + b);

  Map<String, dynamic> snapshot() {
    if (!kDebugMode) return const {'enabled': false};
    return {
      'enabled': true,
      'activeSubscriptionCount': activeSubscriptionCount,
      'activeTimerCount': activeTimerCount,
      'subscriptions': Map<String, int>.from(_activeSubscriptions),
      'timers': Map<String, int>.from(_activeTimers),
    };
  }

  void onSubscribe(String id, {String? owner}) {
    if (!kDebugMode) return;
    final next = (_activeSubscriptions[id] ?? 0) + 1;
    _activeSubscriptions[id] = next;
    if (next > 1) {
      final tag = owner == null ? id : '$id@$owner';
      debugPrint(
        '[StreamLifecycle] DUPLICATE subscribe: $tag (active=$next)',
      );
      assert(
        false,
        'Duplicate stream subscribe: $tag',
      );
    }
  }

  void onCancel(String id) {
    if (!kDebugMode) return;
    final cur = _activeSubscriptions[id] ?? 0;
    if (cur <= 1) {
      _activeSubscriptions.remove(id);
    } else {
      _activeSubscriptions[id] = cur - 1;
    }
    if (cur == 0) return;
  }

  void onTimerStart(String id) {
    if (!kDebugMode) return;
    final next = (_activeTimers[id] ?? 0) + 1;
    _activeTimers[id] = next;
    if (next > 1) {
      debugPrint('[StreamLifecycle] DUPLICATE timer: $id (active=$next)');
    }
  }

  void onTimerCancel(String id) {
    if (!kDebugMode) return;
    final cur = _activeTimers[id] ?? 0;
    if (cur <= 1) {
      _activeTimers.remove(id);
    } else {
      _activeTimers[id] = cur - 1;
    }
  }

  /// يُستدعى عند dispose cubit/screen — تحذير إن بقيت اشتراكات.
  void assertClean({String? owner}) {
    if (!kDebugMode) return;
    if (_activeSubscriptions.isEmpty && _activeTimers.isEmpty) return;
    debugPrint(
      '[StreamLifecycle] LEAK? owner=$owner subs=$_activeSubscriptions timers=$_activeTimers',
    );
    assert(
      _activeSubscriptions.isEmpty && _activeTimers.isEmpty,
      'Uncancelled crowd streams/timers ($owner)',
    );
  }
}
