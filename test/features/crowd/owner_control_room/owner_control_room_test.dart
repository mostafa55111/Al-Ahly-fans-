import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/card_repository/crowd_card_repository_paths.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/models/owner_card_record.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/owner_runtime/owner_session_rules.dart';

void main() {
  group('CrowdCardRepositoryPaths', () {
    test('isolates ahly and zamalek', () {
      expect(
        CrowdCardRepositoryPaths.card('ahly', 'c1'),
        'crowd_card_repository/ahly/cards/c1',
      );
      expect(
        CrowdCardRepositoryPaths.card('zamalek', 'c1'),
        'crowd_card_repository/zamalek/cards/c1',
      );
    });
  });

  group('OwnerSessionRules', () {
    test('rejects duplicate players', () {
      final r = OwnerSessionRules.validateNewSession(
        existing: null,
        formation: '4-3-3',
        starterIds: List.filled(11, 'same'),
        benchIds: const [],
        durationMinutes: 60,
      );
      expect(r.ok, isFalse);
    });

    test('requires eleven starters', () {
      final r = OwnerSessionRules.validateNewSession(
        existing: null,
        formation: '4-3-3',
        starterIds: List.generate(8, (i) => 'p$i'),
        benchIds: const [],
        durationMinutes: 60,
      );
      expect(r.ok, isFalse);
    });
  });

  group('OwnerCardPositionGroups', () {
    test('groups positions', () {
      expect(OwnerCardPositionGroups.groupFor('GK'), OwnerCardPositionGroups.gk);
      expect(OwnerCardPositionGroups.groupFor('ST'), OwnerCardPositionGroups.att);
    });
  });
}
