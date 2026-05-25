import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_lineup_slot.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/launch_validation/launch_validator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/saved_templates/owner_match_template.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/saved_templates/owner_match_template_paths.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/session_drafts/owner_session_draft.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/session_drafts/owner_session_draft_paths.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/owner_auth/owner_secure_session.dart';

void main() {
  group('OwnerMatchTemplatePaths', () {
    test('scopes by club', () {
      expect(
        OwnerMatchTemplatePaths.template('ahly', 't1'),
        'owner_match_templates/ahly/t1',
      );
    });
  });

  group('OwnerSessionDraftPaths', () {
    test('scopes by club', () {
      expect(
        OwnerSessionDraftPaths.draft('zamalek', 'd1'),
        'owner_session_drafts/zamalek/d1',
      );
    });
  });

  group('OwnerMatchTemplate', () {
    test('roundtrips map', () {
      const slot = StadiumLineupSlot(
        registryCardId: 'c1',
        playerName: 'Player',
        imageUrl: 'https://cdn/x.webp',
        position: 'ST',
      );
      final t = OwnerMatchTemplate(
        id: 't1',
        name: 'الأساسي',
        formation: '4-3-3',
        starters: [slot],
        bench: const [],
        createdAt: 1,
        appId: 'ahly',
      );
      final parsed = OwnerMatchTemplate.fromMap('t1', t.toWriteMap());
      expect(parsed.name, 'الأساسي');
      expect(parsed.starters.length, 1);
    });
  });

  group('OwnerSessionDraft', () {
    test('parses lifecycle states', () {
      final d = OwnerSessionDraft.fromMap('d1', {
        'formation': '4-4-2',
        'state': 'ready',
        'durationMinutes': 45,
      });
      expect(d.state, OwnerSessionDraftState.ready);
      expect(d.durationMinutes, 45);
    });
  });

  group('LaunchValidator', () {
    MatchPitchPlayer player({
      required String id,
      required String name,
      required String position,
      required double y,
      String cardImageUrl = 'https://cdn/card.webp',
    }) {
      return MatchPitchPlayer(
        id: id,
        name: name,
        imageUrl: '',
        rating: 80,
        position: position,
        x: 0.5,
        y: y,
        votes: 0,
        team: 'home',
        glowColor: 'gold',
        cardImageUrl: cardImageUrl,
      );
    }

    test('requires goalkeeper', () {
      final players = List.generate(
        11,
        (i) => player(id: 'p$i', name: 'n$i', position: 'CM', y: 0.5),
      );
      final r = LaunchValidator.validateLaunch(
        existing: null,
        formation: '4-3-3',
        players: players,
        durationMinutes: 60,
      );
      expect(r.ok, isFalse);
      expect(r.message, contains('حارس'));
    });

    test('accepts valid lineup', () {
      final players = [
        player(id: 'gk', name: 'GK', position: 'GK', y: 0.5),
        ...List.generate(
          10,
          (i) => player(id: 'p$i', name: 'n$i', position: 'CM', y: 0.5),
        ),
      ];
      final r = LaunchValidator.validateLaunch(
        existing: null,
        formation: '4-3-3',
        players: players,
        durationMinutes: 60,
      );
      expect(r.ok, isTrue);
    });

    test('rejects missing card image', () {
      final players = [
        player(
          id: 'gk',
          name: 'GK',
          position: 'GK',
          y: 0.5,
          cardImageUrl: '',
        ),
        ...List.generate(
          10,
          (i) => player(id: 'p$i', name: 'n$i', position: 'CM', y: 0.5),
        ),
      ];
      final r = LaunchValidator.validateLaunch(
        existing: null,
        formation: '4-3-3',
        players: players,
        durationMinutes: 60,
      );
      expect(r.ok, isFalse);
    });
  });

  group('OwnerSecureSession timeout', () {
    test('expires after inactivity limit', () {
      const last = 1000000;
      final now = last +
          OwnerSessionTimeoutPolicy.inactivityLimit.inMilliseconds +
          1;
      expect(
        OwnerSecureSession.isExpiredAt(lastActivityMs: last, nowMs: now),
        isTrue,
      );
    });

    test('stays active within limit', () {
      const last = 1000000;
      final now = last + OwnerSessionTimeoutPolicy.inactivityLimit.inMilliseconds;
      expect(
        OwnerSecureSession.isExpiredAt(lastActivityMs: last, nowMs: now),
        isFalse,
      );
    });
  });
}
