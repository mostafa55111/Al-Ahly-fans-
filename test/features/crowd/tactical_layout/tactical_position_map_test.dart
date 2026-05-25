import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_layout_tokens.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_position_map.dart';

void main() {
  group('TacticalPositionMap', () {
    const formations = [
      '4-3-3',
      '4-2-3-1',
      '3-4-3',
      '4-4-2',
      '3-5-2',
    ];

    for (final f in formations) {
      test('$f has $TacticalLayoutTokens.starterCount anchors', () {
        final anchors = TacticalPositionMap.anchorsFor(f);
        expect(anchors.length, TacticalLayoutTokens.starterCount);
      });

      test('$f anchors stay inside playable band', () {
        for (final o in TacticalPositionMap.anchorsFor(f)) {
          expect(o.dx, inInclusiveRange(0.08, 0.92));
          expect(o.dy, inInclusiveRange(0.10, 0.60));
        }
      });

      test('$f is symmetric around center x=0.5', () {
        final anchors = TacticalPositionMap.anchorsFor(f);
        final gk = anchors.first;
        expect(gk.dx, closeTo(0.5, 0.02));
      });
    }

    test('normalizeFormation aliases', () {
      expect(TacticalPositionMap.normalizeFormation('433'), '4-3-3');
      expect(TacticalPositionMap.normalizeFormation('4231'), '4-2-3-1');
    });

    test('forward slots start at index 8', () {
      expect(TacticalPositionMap.isForwardSlot(7), isFalse);
      expect(TacticalPositionMap.isForwardSlot(8), isTrue);
    });
  });
}
