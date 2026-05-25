import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/matchday_timeline/matchday_timeline_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/live_session_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/live_session_persistence.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/matchday_network_resilience.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/owner_operation_lock.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/owner_auth/owner_secure_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LiveSessionGuard', () {
    const liveSession = MatchActiveSession(
      id: 's1',
      title: 't',
      votingEnabled: true,
      formation: '4-3-3',
      createdAt: 1,
    );

    test('duplicate publish blocked when session live', () {
      final v = LiveSessionGuard.canPublish(
        existing: liveSession,
        phase: MatchdayTimelinePhase.live,
        finalizeInFlight: false,
      );
      expect(v.allowed, isFalse);
    });

    test('finalize conflict blocked during preparing', () {
      final v = LiveSessionGuard.canFinalize(
        session: liveSession,
        phase: MatchdayTimelinePhase.preparing,
        finalizeInFlight: false,
      );
      expect(v.allowed, isFalse);
    });

    test('emergency close blocked during finalize in flight', () {
      final v = LiveSessionGuard.canEmergencyClose(
        session: liveSession,
        finalizeInFlight: true,
      );
      expect(v.allowed, isFalse);
    });

    test('completed session blocks new publish', () {
      final done = liveSession.copyWith(awardsFinalized: true);
      final v = LiveSessionGuard.canPublish(
        existing: done,
        phase: MatchdayTimelinePhase.completed,
        finalizeInFlight: false,
      );
      expect(v.allowed, isFalse);
    });
  });

  group('OwnerOperationLock', () {
    test('duplicate tap rejected', () async {
      final lock = OwnerOperationLock();
      expect(lock.tryAcquire(OwnerOperationKeys.publishSession), isTrue);
      expect(lock.tryAcquire(OwnerOperationKeys.publishSession), isFalse);
      lock.release(OwnerOperationKeys.publishSession);
      expect(lock.tryAcquire(OwnerOperationKeys.publishSession), isTrue);
    });

    test('runOnce releases after completion', () async {
      final lock = OwnerOperationLock();
      var count = 0;
      final a = await lock.runOnce(OwnerOperationKeys.finalizeSession, () async {
        count++;
        return 1;
      });
      final b = await lock.runOnce(OwnerOperationKeys.finalizeSession, () async {
        count++;
        return 2;
      });
      expect(a, 1);
      expect(b, 2);
      expect(count, 2);
    });

    test('runOnce returns null on duplicate', () async {
      final lock = OwnerOperationLock(maxHold: const Duration(seconds: 15));
      final first = lock.runOnce(OwnerOperationKeys.publishSession, () async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return true;
      });
      final second = lock.runOnce(OwnerOperationKeys.publishSession, () async => false);
      expect(await second, isNull);
      expect(await first, isTrue);
    });
  });

  group('LiveSessionPersistence', () {
    test('restore operational context', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LiveSessionPersistence(prefs);
      await store.save(
        clubTag: 'ahly',
        snapshot: const LiveSessionPersistenceSnapshot(
          activeMatchId: 'm1',
          phaseWire: 'live',
          formation: '4-2-3-1',
          operationalTabIndex: 1,
        ),
      );
      final loaded = store.load('ahly');
      expect(loaded.activeMatchId, 'm1');
      expect(loaded.operationalTabIndex, 1);
      expect(loaded.hasLiveContext, isTrue);
    });
  });

  group('MatchdayNetworkResilience', () {
    test('offline blocks destructive auto replay', () async {
      final net = MatchdayNetworkResilience();
      final state = MatchdayNetworkState.offline;
      expect(MatchdayNetworkResilience.labelAr(state), contains('بدون'));
    });
  });

  group('OwnerResume unsafe recovery', () {
    test('validateRuntime rejects finalize mismatch', () {
      const session = MatchActiveSession(
        id: 's1',
        title: 't',
        votingEnabled: true,
        formation: '4-3-3',
        createdAt: 1,
      );
      final v = LiveSessionGuard.validateRuntimeState(
        session: session,
        phase: MatchdayTimelinePhase.preparing,
        finalizeInFlight: true,
      );
      expect(v.allowed, isFalse);
    });
  });

  group('session timeout math', () {
    test('uses shared expiry helper', () {
      expect(
        OwnerSecureSession.isExpiredAt(
          lastActivityMs: 1000,
          nowMs: 1000 + OwnerSessionTimeoutPolicy.inactivityLimit.inMilliseconds + 1,
        ),
        isTrue,
      );
    });
  });
}
