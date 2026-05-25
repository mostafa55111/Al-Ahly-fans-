import 'package:flutter/foundation.dart';

/// عقد الإطلاق — ما يُدعم رسمياً في Launch Candidate.
enum LaunchSupportedCapability {
  oneVotePerUserPerSession,
  immutableVoteWrite,
  oneHourVotingSession,
  autoFinalizeOnClose,
  monthlyWinnerByTotalVotes,
  seasonWinnerByTotalVotes,
  ownerOnlyCms,
  serverTimeAuthority,
}

/// غير مدعوم قبل الإطلاق — أي تفعيل = تحذير debug.
enum LaunchUnsupportedCapability {
  voteEdits,
  reactionsPersistence,
  publicChat,
  liveVotePercentages,
  publicAdminRoles,
  customUserTournaments,
  multiMatchVoting,
  realtimeLeaderboards,
}

class LaunchContract {
  LaunchContract._();

  static const supported = LaunchSupportedCapability.values;
  static const unsupported = LaunchUnsupportedCapability.values;

  static final Set<String> _activationWarnings = {};

  static bool isSupported(LaunchSupportedCapability cap) => true;

  static bool isUnsupportedActive(LaunchUnsupportedCapability cap) {
    return _activationWarnings.contains(cap.name);
  }

  static void warnUnsupported(String featureKey, {String? reason}) {
    if (!kDebugMode) return;
    _activationWarnings.add(featureKey);
    debugPrint(
      '[LaunchContract] UNSUPPORTED before launch: $featureKey'
      '${reason == null ? '' : ' ($reason)'}',
    );
  }

  static void assertSupportedOnly(String featureKey) {
    for (final cap in unsupported) {
      if (featureKey.toLowerCase().contains(cap.name.toLowerCase())) {
        warnUnsupported(featureKey, reason: 'matches_unsupported_$cap');
        return;
      }
    }
  }

  static Map<String, dynamic> snapshot() => {
        'supported': supported.map((e) => e.name).toList(),
        'unsupported': unsupported.map((e) => e.name).toList(),
        'warnings': _activationWarnings.toList(),
      };

  @visibleForTesting
  static void resetWarnings() => _activationWarnings.clear();
}
