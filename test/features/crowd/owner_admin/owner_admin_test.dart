import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_entry.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/card_integrity_validator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/card_upload_protection.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/session_operational_timeline.dart';

void main() {
  group('SessionOperationalTimeline', () {
    test('live session maps to live phase', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final session = MatchActiveSession(
        id: 's1',
        title: 'test',
        votingEnabled: true,
        formation: '4-3-3',
        createdAt: 1,
        closesAtServer: now + 600000,
        openedAtServer: now - 1000,
        status: 'live',
      );
      final phase = SessionOperationalTimeline.resolvePhase(
        session: session,
        serverNowMs: now,
      );
      expect(phase, SessionOperationalPhase.live);
    });
  });

  group('CardIntegrityValidator', () {
    test('rejects missing card image', () {
      const v = CardIntegrityValidator();
      final r = v.validatePlayerCard(
        const MatchPitchPlayer(
          id: 'p1',
          name: 'x',
          imageUrl: '',
          rating: 80,
          position: 'ST',
          x: 0.5,
          y: 0.5,
          votes: 0,
          team: 'home',
          glowColor: '#FFFFFF',
        ),
      );
      expect(r.ok, isFalse);
    });
  });

  group('CardUploadProtection', () {
    test('detects duplicate image url', () {
      const guard = CardUploadProtection();
      final candidate = StadiumCardRegistryEntry(
        id: 'new',
        playerName: 'a',
        imageUrl: 'https://cdn/x.webp',
      );
      final existing = [
        StadiumCardRegistryEntry(
          id: 'old',
          playerName: 'b',
          imageUrl: 'https://cdn/x.webp',
        ),
      ];
      final r = guard.validateDuplicate(candidate: candidate, existing: existing);
      expect(r.ok, isFalse);
    });
  });

}
