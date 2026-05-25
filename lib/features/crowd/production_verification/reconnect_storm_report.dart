import 'package:flutter/foundation.dart';

class ReconnectStormReport {
  ReconnectStormReport._();

  static final ReconnectStormReport instance = ReconnectStormReport._();

  int resumeBursts = 0;
  int phasedRestores = 0;
  int heavyDeferred = 0;
  int stabilizationUnder3s = 0;
  int stabilizationOver3s = 0;
  int duplicateWritePrevented = 0;
  int listenerExplosionBlocked = 0;

  void recordResumeBurst() => _inc(() => resumeBursts++);
  void recordPhasedRestore() => _inc(() => phasedRestores++);
  void recordHeavyDeferred() => _inc(() => heavyDeferred++);
  void recordStabilization(Duration d) {
    _inc(() {
      if (d.inMilliseconds < 3000) {
        stabilizationUnder3s++;
      } else {
        stabilizationOver3s++;
      }
    });
  }

  void recordDuplicateWritePrevented() =>
      _inc(() => duplicateWritePrevented++);
  void recordListenerExplosionBlocked() =>
      _inc(() => listenerExplosionBlocked++);

  double get stabilizationRate {
    final total = stabilizationUnder3s + stabilizationOver3s;
    if (total <= 0) return 1;
    return stabilizationUnder3s / total;
  }

  Map<String, dynamic> snapshot() {
    if (!kDebugMode) return const {};
    return {
      'resumeBursts': resumeBursts,
      'phasedRestores': phasedRestores,
      'heavyDeferred': heavyDeferred,
      'stabilizationUnder3s': stabilizationUnder3s,
      'stabilizationOver3s': stabilizationOver3s,
      'stabilizationRate': stabilizationRate,
      'duplicateWritePrevented': duplicateWritePrevented,
      'listenerExplosionBlocked': listenerExplosionBlocked,
    };
  }

  void _inc(void Function() fn) {
    if (!kDebugMode) return;
    fn();
  }

  @visibleForTesting
  void reset() {
    resumeBursts = 0;
    phasedRestores = 0;
    heavyDeferred = 0;
    stabilizationUnder3s = 0;
    stabilizationOver3s = 0;
    duplicateWritePrevented = 0;
    listenerExplosionBlocked = 0;
  }
}
